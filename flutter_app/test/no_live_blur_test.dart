import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// A BackdropFilter re-samples everything behind it on every frame. Gauss
// chrome sits on near-opaque ink, where that blur is invisible but still paid
// for over the animated map, so live blurs stay out of the app.
void main() {
  test('no BackdropFilter or ImageFilter.blur in lib', () {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trimLeft();
        if (line.startsWith('//')) continue;
        if (line.contains('BackdropFilter(') ||
            line.contains('ImageFilter.blur(')) {
          offenders.add('${entity.path}:${i + 1}');
        }
      }
    }
    expect(offenders, isEmpty);
  });
}
