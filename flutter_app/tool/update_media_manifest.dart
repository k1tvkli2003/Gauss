import 'dart:io';

const _start = '    # BEGIN GENERATED QUESTION MEDIA ASSETS';
const _end = '    # END GENERATED QUESTION MEDIA ASSETS';

void main() {
  final pubspec = File('pubspec.yaml');
  final mediaRoot = Directory('assets/question_media');
  if (!pubspec.existsSync() || !mediaRoot.existsSync()) {
    stderr.writeln('Run this tool from the flutter_app directory.');
    exitCode = 2;
    return;
  }

  final directories = mediaRoot
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .map((file) => file.parent.path.replaceAll('\\', '/'))
      .toSet()
      .toList()
    ..sort();
  final generated = <String>[
    _start,
    for (final directory in directories) '    - $directory/',
    _end,
  ].join('\n');

  final source = pubspec.readAsStringSync();
  final block = RegExp(
    '${RegExp.escape(_start)}[\\s\\S]*?${RegExp.escape(_end)}',
  );
  final updated = block.hasMatch(source)
      ? source.replaceFirst(block, generated)
      : source.replaceFirst('    - assets/question_media/', generated);
  if (updated == source) {
    stderr.writeln('Question media asset anchor was not found.');
    exitCode = 3;
    return;
  }
  pubspec.writeAsStringSync(updated);
  stdout.writeln('Generated ${directories.length} media asset directories.');
}
