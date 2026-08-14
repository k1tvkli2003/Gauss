import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'feedback_models.dart';
import 'feedback_repository.dart';

enum GaussFeedbackExportStatus { saved, cancelled }

final class GaussFeedbackExportResult {
  const GaussFeedbackExportResult({
    required this.status,
    required this.fileName,
  });

  final GaussFeedbackExportStatus status;
  final String fileName;
}

abstract interface class GaussFeedbackArchiveSaver {
  Future<GaussFeedbackExportResult> save({
    required Uint8List bytes,
    required String fileName,
  });
}

/// Uses Android's system document picker without opening a share sheet.
///
/// Bytes are staged in app-private cache, and the native side accepts only a
/// canonical file below that cache boundary before copying it to the selected
/// document URI. No broad storage permission is requested.
final class GaussAndroidFeedbackArchiveSaver
    implements GaussFeedbackArchiveSaver {
  GaussAndroidFeedbackArchiveSaver({
    MethodChannel? channel,
    Future<Directory> Function()? temporaryDirectory,
    DateTime Function()? clock,
  }) : _channel =
           channel ?? const MethodChannel('com.gauss.app/feedback_export'),
       _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory,
       _clock = clock ?? DateTime.now;

  static const _directoryName = 'gauss_feedback_exports_v1';
  static const _maximumAge = Duration(days: 1);

  final MethodChannel _channel;
  final Future<Directory> Function() _temporaryDirectory;
  final DateTime Function() _clock;

  @override
  Future<GaussFeedbackExportResult> save({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (!RegExp(r'^gauss-feedback-[A-Za-z0-9._-]+\.zip$').hasMatch(fileName)) {
      throw ArgumentError.value(fileName, 'fileName', 'Unsafe export name.');
    }
    final root = await _temporaryDirectory();
    final directory = Directory(
      '${root.path}${Platform.pathSeparator}$_directoryName',
    );
    await directory.create(recursive: true);
    await _purgeStale(directory);
    final nonce = _clock().toUtc().microsecondsSinceEpoch;
    final partial = File(
      '${directory.path}${Platform.pathSeparator}$nonce.partial',
    );
    final staged = File(
      '${directory.path}${Platform.pathSeparator}$nonce-$fileName',
    );
    await partial.writeAsBytes(bytes, flush: true);
    await partial.rename(staged.path);
    try {
      final response = await _channel.invokeMapMethod<String, Object?>(
        'saveArchive',
        <String, Object?>{'sourcePath': staged.path, 'fileName': fileName},
      );
      final status = response?['status'];
      if (status == 'cancelled') {
        return GaussFeedbackExportResult(
          status: GaussFeedbackExportStatus.cancelled,
          fileName: fileName,
        );
      }
      if (status != 'saved') {
        throw PlatformException(
          code: 'invalid_export_result',
          message: 'Android returned an invalid feedback export result.',
        );
      }
      return GaussFeedbackExportResult(
        status: GaussFeedbackExportStatus.saved,
        fileName: fileName,
      );
    } finally {
      if (await staged.exists()) await staged.delete();
      if (await partial.exists()) await partial.delete();
    }
  }

  Future<void> _purgeStale(Directory directory) async {
    final cutoff = _clock().subtract(_maximumAge);
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) continue;
      try {
        if ((await entity.stat()).modified.isBefore(cutoff)) {
          await entity.delete();
        }
      } catch (_) {
        // Cleanup is best-effort; the fresh export still has a unique name.
      }
    }
  }
}

final class GaussFeedbackExporter {
  GaussFeedbackExporter({
    required this.repository,
    GaussFeedbackArchiveSaver? saver,
    Future<PackageInfo> Function()? packageInfoResolver,
    DateTime Function()? clock,
  }) : _saver = saver ?? GaussAndroidFeedbackArchiveSaver(),
       _packageInfoResolver = packageInfoResolver ?? PackageInfo.fromPlatform,
       _clock = clock ?? DateTime.now;

  final GaussFeedbackRepository repository;
  final GaussFeedbackArchiveSaver _saver;
  final Future<PackageInfo> Function() _packageInfoResolver;
  final DateTime Function() _clock;

  Future<GaussFeedbackExportResult> export() async {
    final generatedAt = _clock().toUtc();
    final stamp = generatedAt.toIso8601String().replaceAll(
      RegExp(r'[:.]'),
      '-',
    );
    final fileName = 'gauss-feedback-$stamp.zip';
    final snapshot = await repository.createExportSnapshot();
    final packageInfo = await _readPackageInfo();
    final bytes = buildArchive(
      snapshot,
      generatedAt: generatedAt,
      packageInfo: packageInfo,
    );
    return _saver.save(bytes: bytes, fileName: fileName);
  }

  Future<PackageInfo?> _readPackageInfo() async {
    try {
      return await _packageInfoResolver();
    } catch (_) {
      return null;
    }
  }

  static Uint8List buildArchive(
    GaussFeedbackExportSnapshot snapshot, {
    required DateTime generatedAt,
    PackageInfo? packageInfo,
  }) {
    final archive = Archive();
    final entries = snapshot.entries.map(_entryJson).toList(growable: false);
    final screenshotManifest = <String, Object?>{};
    for (final entry in snapshot.entries) {
      final bytes = snapshot.screenshots[entry.id];
      if (bytes == null) continue;
      final name = '${entry.id}.png';
      archive.addFile(
        ArchiveFile('screenshots/$name', bytes.lengthInBytes, bytes),
      );
      screenshotManifest[entry.id] = <String, Object?>{
        'file': 'screenshots/$name',
        'sha256': sha256.convert(bytes).toString(),
        'width_px': entry.screenshotWidthPx,
        'height_px': entry.screenshotHeightPx,
        'pixel_ratio': entry.screenshotPixelRatio,
      };
    }
    final manifest = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(<String, Object?>{
        'schema_version': 1,
        'generated_at': generatedAt.toUtc().toIso8601String(),
        'application': 'Gauss',
        'app_version': packageInfo?.version,
        'build_number': packageInfo?.buildNumber,
        'component': <String, Object?>{
          'id': 'flutter.private-feedback-capture',
          'source_version': '1.2.2',
          'adaptation': 'gauss-private-account-outbox-v2',
        },
        'entry_count': entries.length,
        'screenshots_included': screenshotManifest.length,
        'screenshot_pixels_redacted': false,
        'entries': entries,
        'screenshots': screenshotManifest,
      }),
    );
    archive.addFile(ArchiveFile('manifest.json', manifest.length, manifest));

    final report = utf8.encode(_markdownReport(snapshot.entries, generatedAt));
    archive.addFile(ArchiveFile('report.md', report.length, report));
    return ZipEncoder().encodeBytes(archive);
  }

  static Map<String, Object?> _entryJson(GaussFeedbackEntry entry) => {
    'id': entry.id,
    'kind': entry.kind.name,
    'route': entry.route,
    'note': entry.note,
    'question_id': entry.questionId,
    'question_revision': entry.questionRevision,
    'topic_key': entry.topicKey,
    'issue_kind': entry.questionIssueKind,
    'session_id': entry.sessionId,
    'mission_index': entry.missionIndex,
    'selected_choice_index': entry.selectedChoiceIndex,
    'sync_state': entry.syncState.name,
    'created_at': entry.createdAt.toUtc().toIso8601String(),
    'updated_at': entry.updatedAt.toUtc().toIso8601String(),
  };

  static String _markdownReport(
    List<GaussFeedbackEntry> entries,
    DateTime generatedAt,
  ) {
    final output = StringBuffer()
      ..writeln('# Gauss private feedback')
      ..writeln()
      ..writeln('Generated: ${generatedAt.toUtc().toIso8601String()}')
      ..writeln()
      ..writeln(
        '> Screenshot pixels are exported exactly as captured and are not redacted.',
      );
    for (final entry in entries) {
      output
        ..writeln()
        ..writeln('## ${entry.kind.label} — ${entry.id}')
        ..writeln()
        ..writeln('- Route: `${entry.route}`')
        ..writeln('- Created: ${entry.createdAt.toUtc().toIso8601String()}')
        ..writeln('- Sync: ${entry.syncState.name}');
      if (entry.questionId != null) {
        output.writeln(
          '- Question: `${entry.questionId}` revision ${entry.questionRevision ?? 1}',
        );
      }
      if (entry.note.isNotEmpty) {
        output
          ..writeln()
          ..writeln(entry.note);
      }
    }
    return output.toString();
  }
}
