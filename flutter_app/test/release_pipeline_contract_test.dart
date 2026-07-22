import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only Flutter may publish the Gauss Android package', () {
    final workflow = File(
      '../.github/workflows/release-apk.yml',
    ).readAsStringSync();
    final flutterGradle = File(
      'android/app/build.gradle.kts',
    ).readAsStringSync();
    final legacyGradle = File('../app/build.gradle.kts').readAsStringSync();
    final legacyStrings = File(
      '../app/src/main/res/values/strings.xml',
    ).readAsStringSync();

    expect(workflow, contains('working-directory: flutter_app'));
    expect(workflow, contains('flutter build apk --release'));
    expect(workflow, contains('set +o pipefail'));
    expect(workflow, contains('yes | sdkmanager --licenses >/dev/null'));
    expect(
      workflow,
      contains('flutter_app/build/app/outputs/flutter-apk/app-release.apk'),
    );
    expect(workflow, isNot(contains(':app:assembleRelease')));
    expect(
      workflow,
      isNot(contains('app/build/outputs/apk/release/app-release.apk')),
    );
    expect(
      workflow,
      contains(
        'Refusing to publish an APK signed with the Android debug certificate.',
      ),
    );
    expect(flutterGradle, contains('applicationId = "com.gauss.app"'));
    expect(flutterGradle, contains('Gauss release signing is fail-closed'));
    expect(flutterGradle, contains('debug-signed release APKs are forbidden'));
    expect(flutterGradle, isNot(contains('signingConfigs.getByName("debug")')));
    for (final variable in const [
      'GAUSS_KEYSTORE_PATH',
      'GAUSS_KEYSTORE_PASSWORD',
      'GAUSS_KEY_ALIAS',
      'GAUSS_KEY_PASSWORD',
    ]) {
      expect(flutterGradle, contains(variable));
    }
    expect(legacyGradle, contains('applicationId = "com.gauss.legacy"'));
    expect(legacyStrings, contains('Gauss Legacy Archive'));
  });
}
