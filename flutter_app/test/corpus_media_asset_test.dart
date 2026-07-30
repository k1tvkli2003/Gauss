import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/data/question_bank_repository.dart';
import 'package:gauss/domain/models.dart';

/// This is intentionally a runtime asset-decode gate, not a semantic image
/// review. It proves that every media block preserved in the shipped question
/// bank is addressable through Flutter's own bundle and accepted by Flutter's
/// image codec. Relevance/cropping/source fidelity remain certification gates.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'every bundled question-media asset resolves and decodes through Flutter',
    () async {
      final bank = QuestionBankRepository();
      await bank.initialize();

      final assets = <String>{};
      var questionCount = 0;
      for (final topic in bank.topics) {
        for (final question in await bank.loadTopic(topic.key)) {
          questionCount++;
          final blocks = <ContentBlock>[
            ...question.stem,
            for (final option in question.options) ...option,
            ...question.solution,
            ...?question.shortcut,
          ];
          assets.addAll(
            blocks.whereType<ImageBlock>().map((block) => block.asset),
          );
        }
      }

      expect(questionCount, 3672);
      expect(assets, hasLength(3410));

      final failures = <String>[];
      for (final asset in assets.toList()..sort()) {
        try {
          final byteData = await rootBundle.load('assets/$asset');
          final bytes = byteData.buffer.asUint8List(
            byteData.offsetInBytes,
            byteData.lengthInBytes,
          );
          await _decodeOnePixel(bytes);
        } catch (error) {
          if (failures.length < 80) failures.add('$asset => $error');
        }
      }

      expect(
        failures,
        isEmpty,
        reason:
            'Flutter could not load/decode ${failures.length} question-media '
            'asset(s):\n${failures.join('\n')}',
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

Future<void> _decodeOnePixel(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(
    bytes,
    targetWidth: 1,
    targetHeight: 1,
  );
  try {
    final frame = await codec.getNextFrame();
    try {
      if (frame.image.width < 1 || frame.image.height < 1) {
        throw StateError('decoder returned an empty frame');
      }
    } finally {
      frame.image.dispose();
    }
  } finally {
    codec.dispose();
  }
}
