import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/app/gauss_app.dart';
import 'package:gauss/app/gauss_theme.dart';
import 'package:gauss/data/local/gauss_database.dart';
import 'package:gauss/data/progress_repository.dart';
import 'package:gauss/data/question_bank_repository.dart';
import 'package:gauss/domain/models.dart';
import 'package:gauss/screens/map_screen.dart';
import 'package:gauss/state/gauss_controller.dart';
import 'package:gauss/widgets/content_blocks.dart';
import 'package:gauss/widgets/gauss_brand.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GaussDatabase database;
  late GaussController controller;

  setUpAll(() {
    database = GaussDatabase(NativeDatabase.memory());
    controller = GaussController(
      QuestionBankRepository(),
      ProgressRepository(database),
    );
  });

  tearDownAll(() async {
    controller.dispose();
    await database.close();
  });

  test(
    'Android package, activity, and approved Theorem Star icon contracts stay aligned',
    () {
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();
      final activity = File(
        'android/app/src/main/kotlin/com/gauss/app/MainActivity.kt',
      );
      final obsoleteActivity = File(
        'android/app/src/main/kotlin/com/gauss/gauss/MainActivity.kt',
      );
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      final adaptiveIconV26 = File(
        'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
      ).readAsStringSync();
      final adaptiveIconV33 = File(
        'android/app/src/main/res/mipmap-anydpi-v33/ic_launcher.xml',
      ).readAsStringSync();
      final safeForeground = File(
        'android/app/src/main/res/drawable/ic_launcher_theorem_star_safe.xml',
      ).readAsStringSync();
      final splash = File(
        'android/app/src/main/res/drawable-v21/launch_background.xml',
      ).readAsStringSync();
      final canonicalIcon = File(
        'assets/visual/brand/theorem_star_app_icon.svg',
      ).readAsStringSync();
      final webManifest = File('web/manifest.json').readAsStringSync();
      final webIndex = File('web/index.html').readAsStringSync();

      expect(gradle, contains('namespace = "com.gauss.app"'));
      expect(gradle, contains('applicationId = "com.gauss.app"'));
      expect(activity.existsSync(), isTrue);
      expect(activity.readAsStringSync(), contains('package com.gauss.app'));
      expect(obsoleteActivity.existsSync(), isFalse);
      expect(manifest, contains('android:name=".MainActivity"'));
      expect(adaptiveIconV26, contains('@drawable/ic_launcher_theorem_star_safe'));
      expect(adaptiveIconV33, contains('<monochrome'));
      expect(adaptiveIconV33, contains('@drawable/ic_launcher_theorem_star_safe'));
      expect(
        adaptiveIconV33,
        contains('@drawable/ic_launcher_theorem_star_mono_safe'),
      );
      expect(safeForeground, contains('android:insetLeft="18dp"'));
      expect(splash, contains('@drawable/ic_launcher_theorem_star'));
      expect(splash, isNot(contains('@drawable/ic_launcher_foreground')));
      expect(canonicalIcon, contains('Gauss Theorem Star app icon'));
      expect(canonicalIcon, contains('#62AE9C'));
      expect(webManifest, contains('icons/Icon-512.png'));
      expect(webManifest, contains('icons/Icon-maskable-512.png'));
      expect(webIndex, contains('icons/Icon-192.png'));
      for (final fallback in [
        'web/favicon.png',
        'web/icons/Icon-192.png',
        'web/icons/Icon-512.png',
        'web/icons/Icon-maskable-512.png',
        'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
        'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.png',
      ]) {
        expect(File(fallback).lengthSync(), greaterThan(1000), reason: fallback);
      }
    },
  );

  test('English chrome uses Manrope with Vazirmatn fallback', () {
    final theme = buildGaussTheme();
    expect(theme.textTheme.bodyMedium?.fontFamily, 'Manrope');
    expect(theme.textTheme.bodyMedium?.fontFamilyFallback, ['Vazirmatn']);
  });

  testWidgets('branded startup renders before repositories are ready', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(411, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(GaussApp(controller: controller));

    expect(find.byType(GaussWordmark), findsOneWidget);
    expect(find.text('Opening your offline observatory…'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await controller.initialize();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Practice'), findsOneWidget);
    expect(find.text('Insights'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Gauss wordmark remains a single accessible identity image', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildGaussTheme(),
        home: const Scaffold(body: Center(child: GaussWordmark())),
      ),
    );
    await tester.pump();

    final node = tester.getSemantics(find.byType(GaussWordmark));
    expect(node.label, 'Gauss');
    expect(node.flagsCollection.isImage, isTrue);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('long mixed-direction math scrolls instead of overflowing', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildGaussTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(24),
            child: ContentBlocksView(
              blocks: [
                TextBlock(
                  r'عبارت $A \cap (B \cup C) \cap (D \cup E) \cap (F \cup G) \cap (H \cup I)$ را بررسی کنید.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SingleChildScrollView &&
            widget.scrollDirection == Axis.horizontal,
      ),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('map survives phone font scale 1.5 and reduced motion', (
    tester,
  ) async {
    await _pumpMap(
      tester,
      controller: controller,
      size: const Size(411, 820),
      textScale: 1.5,
      reducedMotion: true,
    );

    expect(find.byType(MapScreen), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('map uses the tablet radial scene without overflow', (
    tester,
  ) async {
    await _pumpMap(
      tester,
      controller: controller,
      size: const Size(1280, 800),
      textScale: 1,
      reducedMotion: false,
    );

    expect(find.byType(MapScreen), findsOneWidget);
    expect(find.text('MISSION CHART'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpMap(
  WidgetTester tester, {
  required GaussController controller,
  required Size size,
  required double textScale,
  required bool reducedMotion,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  if (!controller.ready) await controller.initialize();

  await tester.pumpWidget(
    MaterialApp(
      theme: buildGaussTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reducedMotion,
        ),
        child: child!,
      ),
      home: GaussScope(
        controller: controller,
        child: const Scaffold(body: MapScreen()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}
