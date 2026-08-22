import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/app/gauss_app.dart';
import 'package:gauss/app/gauss_design_system.dart';
import 'package:gauss/app/gauss_theme.dart';
import 'package:gauss/data/local/gauss_database.dart';
import 'package:gauss/data/progress_repository.dart';
import 'package:gauss/data/question_bank_repository.dart';
import 'package:gauss/domain/models.dart';
import 'package:gauss/domain/study_curriculum.dart';
import 'package:gauss/screens/map_screen.dart';
import 'package:gauss/state/gauss_controller.dart';
import 'package:gauss/widgets/content_blocks.dart';
import 'package:gauss/widgets/first_run_tour.dart';
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
      final vectorForeground = File(
        'android/app/src/main/res/drawable/ic_launcher_theorem_star.xml',
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
      expect(
        adaptiveIconV26,
        contains('@drawable/ic_launcher_theorem_star_safe'),
      );
      expect(adaptiveIconV33, contains('<monochrome'));
      expect(
        adaptiveIconV33,
        contains('@drawable/ic_launcher_theorem_star_safe'),
      );
      expect(
        adaptiveIconV33,
        contains('@drawable/ic_launcher_theorem_star_mono_safe'),
      );
      expect(safeForeground, contains('android:insetLeft="14dp"'));
      expect(vectorForeground, isNot(contains('gauss_icon_background')));
      expect(vectorForeground, contains('#FFE5A0'));
      expect(vectorForeground, contains('#62AE9C'));
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
        expect(
          File(fallback).lengthSync(),
          greaterThan(1000),
          reason: fallback,
        );
      }
    },
  );

  test('English chrome uses Manrope with Vazirmatn fallback', () {
    final theme = buildGaussTheme();
    expect(theme.textTheme.bodyMedium?.fontFamily, 'Manrope');
    expect(theme.textTheme.bodyMedium?.fontFamilyFallback, ['Vazirmatn']);
  });

  test('adaptive window classes meet the exact Gauss boundary contract', () {
    expect(GaussWindowClass.fromWidth(0), GaussWindowClass.compact);
    expect(GaussWindowClass.fromWidth(599), GaussWindowClass.compact);
    expect(GaussWindowClass.fromWidth(600), GaussWindowClass.medium);
    expect(GaussWindowClass.fromWidth(1023), GaussWindowClass.medium);
    expect(GaussWindowClass.fromWidth(1024), GaussWindowClass.expanded);
    expect(GaussWindowClass.fromWidth(1439), GaussWindowClass.expanded);
    expect(GaussWindowClass.fromWidth(1440), GaussWindowClass.wide);
    expect(GaussWindowClass.medium.usesNavigationRail, isTrue);
    expect(GaussWindowClass.expanded.showsPersistentInspector, isTrue);
    expect(GaussWindowClass.wide.extendsNavigationRail, isTrue);

    expect(
      GaussWindowHeightClass.fromHeight(479),
      GaussWindowHeightClass.compact,
    );
    expect(
      GaussWindowHeightClass.fromHeight(480),
      GaussWindowHeightClass.medium,
    );
    expect(
      GaussWindowHeightClass.fromHeight(899),
      GaussWindowHeightClass.medium,
    );
    expect(
      GaussWindowHeightClass.fromHeight(900),
      GaussWindowHeightClass.expanded,
    );

    final portrait = GaussViewport.fromSize(const Size(800, 1280));
    expect(portrait.widthClass, GaussWindowClass.medium);
    expect(portrait.heightClass, GaussWindowHeightClass.expanded);
    expect(portrait.isPortrait, isTrue);
    expect(portrait.supportsTwoPane, isFalse);

    final landscape = GaussViewport.fromSize(const Size(1280, 800));
    expect(landscape.widthClass, GaussWindowClass.expanded);
    expect(landscape.heightClass, GaussWindowHeightClass.medium);
    expect(landscape.isLandscape, isTrue);
    expect(landscape.supportsTwoPane, isTrue);
    expect(landscape.supportsThreePane, isTrue);
    expect(landscape.showsPersistentInspector, isTrue);
    expect(landscape.extendsNavigationRail, isTrue);

    final splitScreen = GaussViewport.fromSize(const Size(900, 479));
    expect(splitScreen.isConstrainedLandscape, isTrue);
    expect(splitScreen.supportsTwoPane, isFalse);
    expect(splitScreen.showsPersistentInspector, isFalse);

    final shortWide = GaussViewport.fromSize(const Size(1440, 479));
    expect(shortWide.extendsNavigationRail, isFalse);
    expect(shortWide.supportsThreePane, isFalse);
  });

  test('source provenance name stays out of user-facing app copy', () {
    final surfaces = <File>[
      ...Directory('lib')
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart')),
      File('web/index.html'),
      File('web/manifest.json'),
    ];
    for (final surface in surfaces) {
      final copy = surface.readAsStringSync();
      expect(copy, isNot(contains('Nardebam')), reason: surface.path);
      expect(copy, isNot(contains('نردبام')), reason: surface.path);
    }
  });

  test('the private Android app exposes no sharing runtime', () {
    final runtimeSurfaces = <File>[
      ...Directory('lib')
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart')),
      ...Directory('android')
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where(
            (file) => file.path.endsWith('.kt') || file.path.endsWith('.java'),
          ),
      File('pubspec.yaml'),
    ];
    for (final surface in runtimeSurfaces) {
      final source = surface.readAsStringSync();
      expect(source, isNot(contains('Icons.share')), reason: surface.path);
      expect(source, isNot(contains('Share.share')), reason: surface.path);
      expect(source, isNot(contains('share_plus')), reason: surface.path);
      expect(source, isNot(contains('ACTION_SEND')), reason: surface.path);
      expect(
        source,
        isNot(contains('Intent.createChooser')),
        reason: surface.path,
      );
    }
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

    await tester.runAsync(controller.initialize);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Skip'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('gauss-floating-navigation-dock')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Map'), findsOneWidget);
    expect(find.byKey(const ValueKey('gauss-nav-study')), findsOneWidget);
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

  testWidgets(
    'the first-run tour remains operable at 320dp and 200 percent text',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var dismissed = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildGaussTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: FirstRunTour(onDismiss: () => dismissed = true),
        ),
      );
      await tester.pump();

      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      expect(dismissed, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the live shell switches chrome at the exact window boundaries', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    if (!controller.ready) await tester.runAsync(controller.initialize);
    if (controller.needsTour) await controller.markTourSeen();

    await tester.binding.setSurfaceSize(const Size(599, 820));
    await tester.pumpWidget(GaussApp(controller: controller));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.byKey(const ValueKey('gauss-floating-navigation-dock')),
      findsOneWidget,
    );
    expect(find.byType(NavigationRail), findsNothing);

    await tester.binding.setSurfaceSize(const Size(600, 820));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(
      find.byKey(const ValueKey('gauss-floating-navigation-dock')),
      findsNothing,
    );
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
      isFalse,
    );

    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
      isTrue,
    );

    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
      isTrue,
    );

    await tester.binding.setSurfaceSize(const Size(1440, 479));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
      isFalse,
    );
    expect(tester.takeException(), isNull);
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

  testWidgets('map survives phone font scale 2.0 and reduced motion', (
    tester,
  ) async {
    await _pumpMap(
      tester,
      controller: controller,
      size: const Size(411, 820),
      textScale: 2,
      reducedMotion: true,
    );

    expect(find.byType(MapScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('map-study-dock-action')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('map lesson dock clears live footer at 100 and 200 percent text', (
    tester,
  ) async {
    addTearDown(() {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetPadding();
      tester.view.resetViewPadding();
    });
    if (!controller.ready) await tester.runAsync(controller.initialize);
    if (controller.needsTour) await controller.markTourSeen();
    tester.platformDispatcher.textScaleFactorTestValue = 1;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 48, bottom: 48);
    tester.view.viewPadding = const FakeViewPadding(top: 48, bottom: 48);

    tester.view.physicalSize = const Size(320, 760);
    await tester.pumpWidget(GaussApp(controller: controller));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    for (final textScale in const [1.0, 2.0]) {
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      await tester.pump();
      for (final size in const [
        Size(320, 711),
        Size(320, 760),
        Size(390, 844),
        Size(411, 891),
      ]) {
        tester.view.physicalSize = size;
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));

        final dock = find.byKey(const ValueKey('map-study-dock'));
        final navigation = find.byKey(
          const ValueKey('gauss-floating-navigation-dock'),
        );
        final copy = find.byKey(const ValueKey('map-study-dock-copy'));
        final emblem = find.byKey(const ValueKey('map-study-dock-emblem'));
        final action = find.byKey(const ValueKey('map-study-dock-action'));
        final readings = find.byKey(const ValueKey('map-study-dock-readings'));
        final caseLabel = '$size at ${textScale}x text';

        expect(dock, findsOneWidget, reason: '$caseLabel lesson dock');
        expect(navigation, findsOneWidget, reason: '$caseLabel footer');
        expect(
          readings,
          textScale >= 1.55 ? findsNothing : findsOneWidget,
          reason:
              '$caseLabel uses progressive disclosure for duplicated dock metadata',
        );
        final dockRect = tester.getRect(dock);
        final navigationRect = tester.getRect(navigation);
        final floatingFooterRect = navigationRect;
        var destinationWidthSum = 0.0;
        expect(
          floatingFooterRect.height,
          closeTo(GaussMetrics.compactNavigationHeight, .5),
          reason:
              '$caseLabel footer glass must hug the destination height with '
              'no hidden Material safe-area reservoir.',
        );
        expect(
          (floatingFooterRect.center.dx - size.width / 2).abs(),
          lessThanOrEqualTo(.5),
          reason: '$caseLabel footer must keep an exact center axis.',
        );
        for (final label in const ['map', 'study', 'insights']) {
          final destination = find.byKey(ValueKey('gauss-nav-$label'));
          final destinationRect = tester.getRect(destination);
          destinationWidthSum += destinationRect.width;
          expect(
            destinationRect.width,
            closeTo(textScale >= 1.3 ? 58 : 82, .5),
          );
          expect(destinationRect.height, greaterThanOrEqualTo(48));
          expect(destination.hitTestable(), findsOneWidget);
          expect(
            destinationRect.left,
            greaterThanOrEqualTo(floatingFooterRect.left - .5),
          );
          expect(
            destinationRect.right,
            lessThanOrEqualTo(floatingFooterRect.right + .5),
          );
          final destinationTexts = find.descendant(
            of: destination,
            matching: find.byType(Text),
          );
          expect(
            destinationTexts,
            textScale >= 1.3 ? findsNothing : findsOneWidget,
            reason:
                '$caseLabel accessibility footer uses its explicit semantic '
                'symbol language instead of breaking destination words.',
          );
          final semanticLabel =
              '${label[0].toUpperCase()}${label.substring(1)}';
          expect(
            find.descendant(
              of: destination,
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Semantics &&
                    widget.properties.label == semanticLabel,
              ),
            ),
            findsOneWidget,
          );
          for (final text in tester.widgetList<Text>(destinationTexts)) {
            expect(text.overflow, isNot(TextOverflow.ellipsis));
          }
          for (final element in destinationTexts.evaluate()) {
            final textRect = tester.getRect(
              find.byElementPredicate((candidate) => candidate == element),
            );
            expect(textRect.left, greaterThanOrEqualTo(destinationRect.left));
            expect(textRect.right, lessThanOrEqualTo(destinationRect.right));
            expect(textRect.top, greaterThanOrEqualTo(destinationRect.top));
            expect(textRect.bottom, lessThanOrEqualTo(destinationRect.bottom));
          }
        }
        expect(
          floatingFooterRect.width,
          closeTo(destinationWidthSum, .5),
          reason:
              '$caseLabel footer frame must exactly hug its measured '
              'destinations without an arbitrary width reservoir.',
        );
        expect(
          floatingFooterRect.width,
          lessThanOrEqualTo(size.width - GaussSpacing.space24),
        );
        expect(
          floatingFooterRect.top - dockRect.bottom,
          greaterThanOrEqualTo(GaussMetrics.mapOverlayGap),
          reason:
              '$caseLabel Current Mission must clear the complete floating '
              'footer frame, not only the NavigationBar inside it.',
        );
        expect(
          size.height - navigationRect.bottom,
          greaterThanOrEqualTo(48 + GaussMetrics.compactNavigationOuterInset),
          reason:
              '$caseLabel footer must clear the Android Home/Back gesture '
              'region plus its optical gap.',
        );
        expect(
          navigationRect.top - dockRect.bottom,
          greaterThanOrEqualTo(GaussMetrics.mapOverlayGap),
          reason:
              '$caseLabel needs a visible dock/footer optical gap; '
              'dock=$dockRect nav=$navigationRect',
        );
        expect(
          (dockRect.center.dx - size.width / 2).abs(),
          lessThanOrEqualTo(.5),
          reason:
              '$caseLabel selected lesson instrument must use the screen center axis.',
        );
        final allNodes = find.byWidgetPredicate((widget) {
          final key = widget.key;
          return key is ValueKey<String> && key.value.startsWith('map-node-');
        });
        final liveNodes = allNodes.hitTestable();
        final pathRect = tester.getRect(
          find.byKey(const ValueKey('map-study-path-scroll')),
        );
        expect(
          allNodes,
          findsWidgets,
          reason:
              '$caseLabel must keep a real lesson instrument in the map '
              'viewport; path=$pathRect dock=$dockRect footer=$navigationRect',
        );
        final firstNodeRect = tester.getRect(
          find.byElementPredicate(
            (candidate) => candidate == allNodes.evaluate().first,
          ),
        );
        expect(
          pathRect.bottom,
          greaterThan(dockRect.bottom),
          reason:
              '$caseLabel route canvas must continue behind the floating '
              'mission glass instead of ending in a blank obstruction band.',
        );
        expect(
          liveNodes,
          findsWidgets,
          reason:
              '$caseLabel must keep at least one route node operable; '
              'path=$pathRect firstNode=$firstNodeRect dock=$dockRect '
              'navigation=$navigationRect',
        );
        for (final element in liveNodes.evaluate()) {
          final nodeRect = tester.getRect(
            find.byElementPredicate((candidate) => candidate == element),
          );
          expect(
            nodeRect.overlaps(dockRect),
            isFalse,
            reason:
                '$caseLabel route node must not sit under the lesson dock: '
                '$nodeRect vs $dockRect',
          );
          expect(
            nodeRect.overlaps(navigationRect),
            isFalse,
            reason:
                '$caseLabel route node must not sit under the footer: '
                '$nodeRect vs $navigationRect',
          );
        }

        final copyRect = tester.getRect(copy);
        final emblemRect = tester.getRect(emblem);
        final actionRect = tester.getRect(action);
        final readingsRect = textScale >= 1.55
            ? null
            : tester.getRect(readings);
        expect(
          copyRect.overlaps(actionRect),
          isFalse,
          reason: '$caseLabel lesson copy and action must never share space',
        );
        expect(
          copyRect.width,
          lessThan(dockRect.width - 96),
          reason:
              '$caseLabel only the central copy plaque may blur the route; '
              'the dock must not reintroduce a full-width opaque bar.',
        );
        expect(emblemRect.overlaps(copyRect), isFalse);
        expect(emblemRect.overlaps(actionRect), isFalse);
        if (readingsRect != null) {
          expect(
            readingsRect.overlaps(actionRect),
            isFalse,
            reason:
                '$caseLabel wrapped readings and the primary action need a gap',
          );
        }
        expect(actionRect.width, greaterThanOrEqualTo(48));
        expect(actionRect.height, greaterThanOrEqualTo(48));
        expect(
          find.descendant(of: action, matching: find.byType(FilledButton)),
          findsNothing,
          reason: '$caseLabel primary lesson action is a symbolic orbit gate.',
        );
        expect(
          find.descendant(of: action, matching: find.text('OPEN')),
          findsNothing,
          reason: '$caseLabel action meaning belongs to semantics, not a box.',
        );
        if (readingsRect != null) {
          expect(
            copyRect.contains(readingsRect.topLeft) &&
                copyRect.contains(readingsRect.bottomRight),
            isTrue,
            reason:
                '$caseLabel five-question progress belongs inside the one '
                'Mission Compass plaque, not in a second floating strip',
          );
        }

        final dockTexts = find.descendant(
          of: dock,
          matching: find.byType(Text),
        );
        for (final text in tester.widgetList<Text>(dockTexts)) {
          expect(
            text.overflow,
            isNot(TextOverflow.ellipsis),
            reason: '$caseLabel must not hide a critical dock phrase',
          );
        }
        for (final element in dockTexts.evaluate()) {
          final textRect = tester.getRect(
            find.byElementPredicate((candidate) => candidate == element),
          );
          expect(
            dockRect.contains(textRect.topLeft) &&
                dockRect.contains(textRect.bottomRight),
            isTrue,
            reason:
                '$caseLabel dock text must stay inside its glass frame: '
                '${(element.widget as Text).data} at $textRect vs $dockRect',
          );
        }
        final exception = tester.takeException();
        if (exception case FlutterError error) {
          final diagnostics = error.diagnostics
              .map((node) => node.toStringDeep())
              .join('\n');
          final overflowingFlexes = tester.allRenderObjects
              .whereType<RenderFlex>()
              .where((render) => render.toString().contains('OVERFLOWING'))
              .map((render) => render.toStringDeep())
              .join('\n');
          fail(
            '$caseLabel overflow\n$diagnostics\n'
            'Overflowing flexes:\n$overflowingFlexes',
          );
        }
        expect(exception, isNull, reason: '$caseLabel overflow');
      }
    }
  });

  testWidgets('phone map header keeps progress values on one readable line', (
    tester,
  ) async {
    await _pumpMap(
      tester,
      controller: controller,
      size: const Size(390, 844),
      textScale: 1,
      reducedMotion: false,
    );

    expect(find.bySemanticsLabel('0 of 325 questions charted'), findsNothing);
    final orbitReading = find.textContaining('0 / 325');
    expect(orbitReading, findsOneWidget);
    final orbitReadingText = tester.widget<Text>(orbitReading);
    expect(orbitReadingText.maxLines, 1);
    expect(orbitReadingText.softWrap, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone map reveals the first route node above its action dock', (
    tester,
  ) async {
    const size = Size(390, 844);
    await _pumpMap(
      tester,
      controller: controller,
      size: size,
      textScale: 1,
      reducedMotion: true,
    );

    final section = GaussStudyCurriculum.forSubject(Subject.math).first;
    final firstNode = GaussStudyCurriculum.nodesFor(
      section,
      controller.topics,
    ).first;
    final finder = find.byKey(ValueKey('map-node-${firstNode.key}'));
    final aura = find.byKey(ValueKey('map-node-aura-${firstNode.key}'));
    final orbitSelector = find.byKey(const ValueKey('map-orbit-selector'));
    expect(finder, findsOneWidget);
    expect(aura, findsOneWidget);
    expect(
      tester.getCenter(finder).dy,
      greaterThan(
        tester.getBottomRight(orbitSelector).dy + GaussSpacing.space16,
      ),
    );
    expect(
      tester.getRect(aura).top,
      greaterThanOrEqualTo(
        tester.getBottomRight(orbitSelector).dy + GaussSpacing.space12,
      ),
      reason:
          'The complete selected-station aura must clear the Orbit header, '
          'not only its mathematical centre.',
    );
    expect(
      tester.getCenter(finder).dy,
      lessThan(
        size.height -
            GaussMetrics.mapBottomObstruction(GaussWindowClass.compact),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'phone map ends with its final lesson in the live route field instead of dead air',
    (tester) async {
      const size = Size(390, 844);
      await _pumpMap(
        tester,
        controller: controller,
        size: size,
        textScale: 1,
        reducedMotion: true,
      );

      final section = GaussStudyCurriculum.forSubject(Subject.math).first;
      final lastNode = GaussStudyCurriculum.nodesFor(
        section,
        controller.topics,
      ).last;
      final route = find.byKey(const ValueKey('map-study-path-scrollable'));
      await tester.fling(route, const Offset(0, -12000), 12000);
      await tester.pumpAndSettle();

      final lastLesson = find.byKey(ValueKey('map-node-${lastNode.key}'));
      final pathRect = tester.getRect(
        find.byKey(const ValueKey('map-study-path-scroll')),
      );
      final dockRect = tester.getRect(
        find.byKey(const ValueKey('map-study-dock')),
      );
      expect(lastLesson, findsOneWidget);
      final lastRect = tester.getRect(lastLesson);
      expect(
        lastRect.center.dy,
        greaterThan(pathRect.top + pathRect.height * .35),
        reason:
            'Max scroll must compose the final lesson in the route field, '
            'not pin it above a viewport of empty sky.',
      );
      expect(
        lastRect.bottom,
        lessThanOrEqualTo(dockRect.top - GaussMetrics.mapOverlayGap),
        reason: 'The final lesson still has to clear Mission Compass.',
      );
      expect(lastLesson.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'phone Map keeps chapter threshold translucent and restores the lesson in the upper route field',
    (tester) async {
      const size = Size(390, 844);
      if (!controller.ready) {
        await tester.runAsync(controller.initialize);
      }
      await controller.selectTopic('patterns_sequences');
      addTearDown(() => controller.selectTopic('sets'));
      await _pumpMap(
        tester,
        controller: controller,
        size: size,
        textScale: 1,
        reducedMotion: true,
      );

      final route = tester.getRect(
        find.byKey(const ValueKey('map-study-path-scroll')),
      );
      final gate = find.byKey(const ValueKey('map-section-gate-2'));
      final lesson = find.byKey(
        const ValueKey('map-node-patterns_sequences:0:5'),
      );
      final gateInstrument = find.descendant(
        of: gate,
        matching: find.byKey(const ValueKey('map-section-gate-instrument')),
      );
      final gateContainer = tester.widget<Container>(gateInstrument);
      final decoration = gateContainer.decoration! as BoxDecoration;

      expect(decoration.borderRadius, isNull);
      expect(decoration.boxShadow, isNull);
      expect(decoration.border, isA<Border>());
      expect(
        tester.getCenter(lesson).dy,
        lessThan(route.top + route.height * .58),
        reason:
            'Restoring a chapter should place its live lesson above the '
            'dock-owned lower field, not bury it at viewport center.',
      );
      final gateRect = tester.getRect(gateInstrument);
      final lessonRect = tester.getRect(lesson);
      expect(
        lessonRect.top - gateRect.bottom,
        greaterThanOrEqualTo(12),
        reason:
            'The chapter annotation needs a readable optical gap before its '
            'first instrument. gate=$gateRect lesson=$lessonRect',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'compact Map folds Chapter 1 into Orbit and names five-question nodes by concept',
    (tester) async {
      await _pumpMap(
        tester,
        controller: controller,
        size: const Size(390, 844),
        textScale: 1,
        reducedMotion: true,
      );

      final section = GaussStudyCurriculum.forSubject(Subject.math).first;
      final firstNode = GaussStudyCurriculum.nodesFor(
        section,
        controller.topics,
      ).first;
      final semanticLabel = controller.studySetLabel(firstNode);

      expect(
        find.byKey(const ValueKey('map-active-chapter-summary')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('map-section-gate-1')), findsNothing);
      final nextChapter = find.byKey(const ValueKey('map-section-gate-2'));
      expect(
        nextChapter,
        findsNothing,
        reason:
            'A distant chapter must remain lazy until the route approaches it.',
      );
      expect(find.text('CHAPTER 1'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('map-study-path-scroll')),
          matching: find.text(semanticLabel),
        ),
        findsOneWidget,
      );
      expect(find.text(firstNode.setLabel), findsNothing);
      expect(semanticLabel, isNot(startsWith('Session')));
      expect(semanticLabel, 'Finite & Infinite Sets');

      final route = find.byKey(const ValueKey('map-study-path-scroll'));
      await tester.dragUntilVisible(nextChapter, route, const Offset(0, -260));
      await tester.pump();
      expect(nextChapter, findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Dual Orbit subject controls are distinct 48dp targets', (
    tester,
  ) async {
    await _pumpMap(
      tester,
      controller: controller,
      size: const Size(390, 844),
      textScale: 1,
      reducedMotion: true,
    );

    final math = find.byKey(const ValueKey('map-subject-math'));
    final physics = find.byKey(const ValueKey('map-subject-physics'));
    final mathRect = tester.getRect(math);
    final physicsRect = tester.getRect(physics);
    expect(mathRect.width, greaterThanOrEqualTo(48));
    expect(mathRect.height, greaterThanOrEqualTo(48));
    expect(physicsRect.width, greaterThanOrEqualTo(48));
    expect(physicsRect.height, greaterThanOrEqualTo(48));
    expect(mathRect.overlaps(physicsRect), isFalse);
    expect(find.bySemanticsLabel('Mathematics study path'), findsOneWidget);
    expect(find.bySemanticsLabel('Physics study path'), findsOneWidget);

    final mathSection = GaussStudyCurriculum.forSubject(Subject.math).first;
    final mathNode = GaussStudyCurriculum.nodesFor(
      mathSection,
      controller.topics,
    ).first;
    expect(
      find.byKey(ValueKey('map-node-math-station-${mathNode.key}')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(ValueKey('map-node-${mathNode.key}')),
        matching: find.byType(TopicGlyph),
      ),
      findsNothing,
      reason: 'Math identity belongs to the astrolabe body, not an overlay.',
    );

    await tester.tap(physics);
    await tester.pumpAndSettle();
    final physicsSection = GaussStudyCurriculum.forSubject(
      Subject.physics,
    ).first;
    final physicsNode = GaussStudyCurriculum.nodesFor(
      physicsSection,
      controller.topics,
    ).first;
    expect(
      find.byKey(ValueKey('map-node-physics-station-${physicsNode.key}')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(ValueKey('map-node-${physicsNode.key}')),
        matching: find.byType(TopicGlyph),
      ),
      findsNothing,
      reason: 'Physics identity belongs to the gyroscope body, not an overlay.',
    );
    await tester.tap(find.byKey(const ValueKey('map-subject-math')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'compact Map header keeps brand, progress, and flanks on exact axes',
    (tester) async {
      Future<void> verifyHeader(Size size, double textScale) async {
        await _pumpMap(
          tester,
          controller: controller,
          size: size,
          textScale: textScale,
          reducedMotion: true,
        );

        final frame = tester.getRect(
          find.byKey(const ValueKey('map-compact-header-frame')),
        );
        final wordmark = tester.getRect(
          find.byKey(const ValueKey('map-compact-centered-wordmark')),
        );
        final crest = tester.getRect(
          find.byKey(const ValueKey('map-course-progress-crest')),
        );
        final leading = tester.getRect(
          find.byKey(const ValueKey('map-compact-identity-track')),
        );
        final trailing = tester.getRect(
          find.byKey(const ValueKey('map-compact-subject-track')),
        );
        final daily = tester.getRect(
          find.byKey(const ValueKey('map-daily-progress-button')),
        );
        final subjects = tester.getRect(
          find.byKey(const ValueKey('map-subject-dual-orbit')),
        );
        final streakOrbit = tester.getRect(
          find.byKey(const ValueKey('map-daily-streak-orbit')),
        );
        final xpOrbit = tester.getRect(
          find.byKey(const ValueKey('map-daily-xp-orbit')),
        );
        final mathOrbit = tester.getRect(
          find.byKey(const ValueKey('map-subject-math')),
        );
        final physicsOrbit = tester.getRect(
          find.byKey(const ValueKey('map-subject-physics')),
        );

        expect(wordmark.center.dx, closeTo(frame.center.dx, .5));
        expect(crest.center.dx, closeTo(frame.center.dx, .5));
        expect(leading.size, trailing.size);
        expect(
          frame.center.dx - leading.center.dx,
          closeTo(trailing.center.dx - frame.center.dx, .5),
        );
        expect(daily.size, subjects.size);
        expect(daily.center.dy, closeTo(subjects.center.dy, .5));
        expect(streakOrbit.size, xpOrbit.size);
        expect(mathOrbit.size, physicsOrbit.size);
        expect(streakOrbit.size, mathOrbit.size);
        expect(
          (streakOrbit.center.dx + xpOrbit.center.dx) / 2,
          closeTo(daily.center.dx, .5),
        );
        expect(
          (mathOrbit.center.dx + physicsOrbit.center.dx) / 2,
          closeTo(subjects.center.dx, .5),
        );
        expect(streakOrbit.height, greaterThanOrEqualTo(48));
        expect(xpOrbit.height, greaterThanOrEqualTo(48));
        expect(wordmark.bottom, lessThanOrEqualTo(daily.top));
        expect(wordmark.bottom, lessThanOrEqualTo(crest.top));
        expect(wordmark.bottom, lessThanOrEqualTo(subjects.top));
        expect(frame.contains(wordmark.topLeft), isTrue);
        expect(frame.contains(crest.bottomRight), isTrue);
        expect(tester.takeException(), isNull);
      }

      await verifyHeader(const Size(390, 844), 1);
      await verifyHeader(const Size(320, 760), 2);
    },
  );

  testWidgets(
    'compact Map exposes daily streak without crowding subject controls',
    (tester) async {
      await _pumpMap(
        tester,
        controller: controller,
        size: const Size(320, 760),
        textScale: 2,
        reducedMotion: true,
      );

      final daily = find.byKey(const ValueKey('map-daily-progress-button'));
      final math = find.byKey(const ValueKey('map-subject-math'));
      final physics = find.byKey(const ValueKey('map-subject-physics'));
      final dailyRect = tester.getRect(daily);
      expect(dailyRect.height, greaterThanOrEqualTo(48));
      expect(dailyRect.overlaps(tester.getRect(math)), isFalse);
      expect(dailyRect.overlaps(tester.getRect(physics)), isFalse);
      expect(
        find.bySemanticsLabel(RegExp('Open daily progress.*day streak')),
        findsOneWidget,
      );

      await tester.tap(daily);
      await tester.pumpAndSettle();

      expect(find.text('DAILY ORBIT'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('map-gamification-hud')),
        findsOneWidget,
      );
      expect(find.text('DAY STREAK'), findsOneWidget);
      final sheet = find.byKey(const ValueKey('map-daily-orbit-sheet'));
      final close = find.byKey(const ValueKey('map-daily-orbit-close'));
      expect(tester.getRect(close).width, greaterThanOrEqualTo(48));
      expect(tester.getRect(close).height, greaterThanOrEqualTo(48));
      for (final text in tester.widgetList<Text>(
        find.descendant(of: sheet, matching: find.byType(Text)),
      )) {
        expect(
          text.overflow,
          isNot(TextOverflow.ellipsis),
          reason: 'Daily Orbit must reflow instead of hiding a phrase.',
        );
      }
      await tester.ensureVisible(
        find.textContaining('A missed day can use one calm grace day.'),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Daily Orbit follows its content on tall phones and survives tablet resize',
    (tester) async {
      const phoneSize = Size(430, 1000);
      await _pumpMap(
        tester,
        controller: controller,
        size: phoneSize,
        textScale: 1,
        reducedMotion: true,
        safePadding: const EdgeInsets.only(bottom: 24),
      );

      await tester.tap(find.byKey(const ValueKey('map-daily-progress-button')));
      await tester.pumpAndSettle();

      final sheet = find.byKey(const ValueKey('map-daily-orbit-sheet'));
      final explanation = find.textContaining(
        'A missed day can use one calm grace day.',
      );
      final phoneSheetRect = tester.getRect(sheet);
      expect(
        phoneSheetRect.height,
        lessThan(phoneSize.height * .7),
        reason: 'A short Daily Orbit must not reserve a tall empty field.',
      );
      expect(
        phoneSheetRect.bottom - tester.getRect(explanation).bottom,
        inInclusiveRange(24, 48),
        reason: 'Only the intentional gesture-safe footer gap should remain.',
      );

      await tester.binding.setSurfaceSize(const Size(800, 1000));
      await tester.pumpAndSettle();
      final tabletSheetRect = tester.getRect(sheet);
      expect(tabletSheetRect.height, lessThanOrEqualTo(760));
      expect(
        tester
            .getRect(find.byKey(const ValueKey('map-gamification-hud')))
            .width,
        lessThanOrEqualTo(760),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'compact Orbit chapter summary reflows at 320dp and 200 percent text',
    (tester) async {
      await _pumpMap(
        tester,
        controller: controller,
        size: const Size(320, 760),
        textScale: 2,
        reducedMotion: true,
      );

      final selector = find.byKey(const ValueKey('map-orbit-selector'));
      final chapter = find.byKey(const ValueKey('map-active-chapter-summary'));
      final centerAxis = find.byKey(const ValueKey('map-orbit-center-axis'));
      final orbitTitle = find.byKey(const ValueKey('map-active-orbit-title'));
      final selectorRect = tester.getRect(selector);
      final chapterRect = tester.getRect(chapter);
      final centerAxisRect = tester.getRect(centerAxis);
      expect(selectorRect.contains(chapterRect.topLeft), isTrue);
      expect(selectorRect.contains(chapterRect.bottomRight), isTrue);
      expect(
        (centerAxisRect.center.dx - selectorRect.center.dx).abs(),
        lessThanOrEqualTo(.5),
        reason:
            'Equal index and disclosure tracks must keep the selected Orbit '
            'identity on the exact screen axis.',
      );
      expect(
        (chapterRect.center.dx - selectorRect.center.dx).abs(),
        lessThanOrEqualTo(.5),
        reason: 'The selected chapter summary must be truly centered.',
      );
      expect(
        find.descendant(of: orbitTitle, matching: find.text('Algebraic')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: orbitTitle, matching: find.text('foundations')),
        findsOneWidget,
      );
      final orbitTitleRect = tester.getRect(orbitTitle);
      for (final word in const ['Algebraic', 'foundations']) {
        final wordFinder = find.descendant(
          of: orbitTitle,
          matching: find.text(word),
        );
        final wordText = tester.widget<Text>(wordFinder);
        expect(wordText.maxLines, 1);
        expect(wordText.softWrap, isFalse);
        final wordRect = tester.getRect(wordFinder);
        expect(wordRect.left, greaterThanOrEqualTo(orbitTitleRect.left - .5));
        expect(wordRect.right, lessThanOrEqualTo(orbitTitleRect.right + .5));
        expect(wordRect.top, greaterThanOrEqualTo(orbitTitleRect.top - .5));
        expect(wordRect.bottom, lessThanOrEqualTo(orbitTitleRect.bottom + .5));
      }
      for (final text in tester.widgetList<Text>(
        find.descendant(of: selector, matching: find.byType(Text)),
      )) {
        expect(text.overflow, isNot(TextOverflow.ellipsis));
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Orbit Navigator keeps courses and chapters reachable', (
    tester,
  ) async {
    await _pumpMap(
      tester,
      controller: controller,
      size: const Size(411, 820),
      textScale: 1,
      reducedMotion: false,
    );

    expect(find.byKey(const ValueKey('map-orbit-selector')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('map-orbit-selector')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('orbit-navigator')), findsOneWidget);
    expect(find.text('ORBIT NAVIGATOR'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('orbit-navigator-course-switch')),
      findsOneWidget,
    );
    final mathChapters = GaussStudyCurriculum.forSubject(Subject.math);
    expect(
      find.byKey(const ValueKey('orbit-navigator-chapter-list')),
      findsOneWidget,
    );
    for (final chapter in mathChapters) {
      final beacon = find.byKey(ValueKey('orbit-chapter-${chapter.id}'));
      expect(beacon, findsOneWidget);
      expect(tester.getRect(beacon).width, greaterThanOrEqualTo(48));
      expect(tester.getRect(beacon).height, greaterThanOrEqualTo(48));
    }
    await tester.tap(
      find.byKey(ValueKey('orbit-chapter-${mathChapters[1].id}')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Functions and equations'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('orbit-navigator-continue')),
      findsOneWidget,
    );
    expect(find.text('Continue here'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('orbit-navigator')),
        matching: find.byType(FilledButton),
      ),
      findsNothing,
      reason: 'Chapter continuation is a symbolic orbit gate, not a form CTA.',
    );
    await tester.tap(find.byKey(const ValueKey('orbit-navigator-continue')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('orbit-navigator')), findsNothing);
    expect(find.text('Functions and equations'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Map restores the exact durable learning topic on first frame', (
    tester,
  ) async {
    if (!controller.ready) {
      await tester.runAsync(controller.initialize);
    }
    await controller.selectTopic('patterns_sequences');
    await _pumpMap(
      tester,
      controller: controller,
      size: const Size(411, 820),
      textScale: 1,
      reducedMotion: true,
    );

    expect(find.text('Patterns & Sequences'), findsWidgets);
    expect(
      find.byKey(const ValueKey('map-active-chapter-summary')),
      findsOneWidget,
    );
    final route = find.byKey(const ValueKey('map-study-path-scroll'));
    final scrollable = find.descendant(
      of: route,
      matching: find.byType(Scrollable),
    );
    expect(
      tester.state<ScrollableState>(scrollable).position.pixels,
      greaterThan(0),
      reason:
          'The path camera must restore the selected topic, not leave its '
          'header and lesson dock pointing at an off-screen route segment.',
    );
    final restoredNode = find.byKey(
      const ValueKey('map-node-patterns_sequences:0:5'),
    );
    expect(restoredNode, findsOneWidget);
    final routeRect = tester.getRect(route);
    final restoredNodeRect = tester.getRect(restoredNode);
    expect(
      routeRect.overlaps(restoredNodeRect),
      isTrue,
      reason: 'The exact durable topic node must be visible in the route.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Orbit Navigator reflows at 320dp and 200 percent text without hiding copy',
    (tester) async {
      await _pumpMap(
        tester,
        controller: controller,
        size: const Size(320, 700),
        textScale: 2,
        reducedMotion: true,
      );

      await tester.tap(find.byKey(const ValueKey('map-orbit-selector')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final navigator = find.byKey(const ValueKey('orbit-navigator'));
      expect(navigator, findsOneWidget);
      final navigatorRect = tester.getRect(navigator);
      final close = find.byKey(const ValueKey('orbit-navigator-close'));
      expect(tester.getRect(close).width, greaterThanOrEqualTo(48));
      expect(tester.getRect(close).height, greaterThanOrEqualTo(48));
      final header = find.byKey(const ValueKey('orbit-navigator-header'));
      final courseSummary = find.byKey(
        const ValueKey('orbit-navigator-course-summary'),
      );
      expect(
        tester.getRect(header).contains(tester.getRect(courseSummary).topLeft),
        isTrue,
      );
      expect(
        tester
            .getRect(header)
            .contains(tester.getRect(courseSummary).bottomRight),
        isTrue,
      );
      final courseSwitch = find.byKey(
        const ValueKey('orbit-navigator-course-switch'),
      );
      expect(
        find.descendant(of: courseSwitch, matching: find.byType(Text)),
        findsNothing,
        reason:
            'At 200 percent text the dual orbit uses symbols and semantics '
            'instead of clipping course names.',
      );
      final chapters = GaussStudyCurriculum.forSubject(Subject.math);
      for (final chapter in chapters) {
        final beacon = find.byKey(ValueKey('orbit-chapter-${chapter.id}'));
        expect(beacon, findsOneWidget);
        expect(tester.getRect(beacon).width, greaterThanOrEqualTo(48));
        expect(tester.getRect(beacon).height, greaterThanOrEqualTo(48));
      }
      final navigatorTexts = find.descendant(
        of: navigator,
        matching: find.byType(Text),
      );
      for (final text in tester.widgetList<Text>(navigatorTexts)) {
        expect(
          text.overflow,
          isNot(TextOverflow.ellipsis),
          reason: 'Navigator content must reflow instead of hiding a phrase.',
        );
      }
      for (final element in navigatorTexts.evaluate()) {
        final textRect = tester.getRect(
          find.byElementPredicate((candidate) => candidate == element),
        );
        expect(
          textRect.left,
          greaterThanOrEqualTo(navigatorRect.left - .5),
          reason: 'Navigator text escaped its left edge: $textRect',
        );
        expect(
          textRect.right,
          lessThanOrEqualTo(navigatorRect.right + .5),
          reason: 'Navigator text escaped its right edge: $textRect',
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'map uses the tablet continuous path inspector without overflow',
    (tester) async {
      await _pumpMap(
        tester,
        controller: controller,
        size: const Size(1280, 800),
        textScale: 1,
        reducedMotion: false,
      );

      expect(find.byType(MapScreen), findsOneWidget);
      expect(find.text('STUDY INSPECTOR'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'map owns dedicated portrait landscape accessible and short tablet states',
    (tester) async {
      if (!controller.ready) await tester.runAsync(controller.initialize);

      for (final profile in const [
        (size: Size(800, 1280), textScale: 1.0, inspector: false),
        (size: Size(1280, 800), textScale: 1.0, inspector: true),
        (size: Size(1280, 800), textScale: 2.0, inspector: false),
        (size: Size(1440, 479), textScale: 1.0, inspector: false),
      ]) {
        await _pumpMap(
          tester,
          controller: controller,
          size: profile.size,
          textScale: profile.textScale,
          reducedMotion: true,
        );

        expect(
          find.byKey(const ValueKey('map-study-inspector')),
          profile.inspector ? findsOneWidget : findsNothing,
          reason: '${profile.size} @ ${profile.textScale}',
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '${profile.size} @ ${profile.textScale}',
        );
      }
    },
  );
}

Future<void> _pumpMap(
  WidgetTester tester, {
  required GaussController controller,
  required Size size,
  required double textScale,
  required bool reducedMotion,
  EdgeInsets? safePadding,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  if (!controller.ready) {
    await tester.runAsync(controller.initialize);
  }

  await tester.pumpWidget(
    MaterialApp(
      theme: buildGaussTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reducedMotion,
          padding: safePadding,
          viewPadding: safePadding,
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
