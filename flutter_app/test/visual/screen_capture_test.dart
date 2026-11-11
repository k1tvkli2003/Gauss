// Renders real app routes to PNG for design review. Opt-in only:
//   GAUSS_CAPTURE_DIR=/abs/out flutter test test/visual/screen_capture_test.dart
@Tags(['capture'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/app/gauss_app.dart';
import 'package:gauss/data/local/gauss_database.dart';
import 'package:gauss/data/progress_repository.dart';
import 'package:gauss/data/question_bank_repository.dart';
import 'package:gauss/state/gauss_controller.dart';

final _outDir = Platform.environment['GAUSS_CAPTURE_DIR'];
final _routes =
    (Platform.environment['GAUSS_CAPTURE_ROUTES'] ??
            '/map,/study,/insights,/vault,/study/revisit')
        .split(',');
const _allSizes = <String, (Size, double)>{
  'phone': (Size(390, 844), 1.0),
  'narrow-2x': (Size(320, 640), 2.0),
  'tab-port': (Size(800, 1280), 1.0),
  'tab-land': (Size(1280, 800), 1.0),
  'tab-land-1.5x': (Size(1280, 800), 1.5),
  'split': (Size(640, 800), 1.0),
};
final _sizes = {
  for (final name
      in (Platform.environment['GAUSS_CAPTURE_SIZES'] ?? 'phone,narrow-2x')
          .split(','))
    name: _allSizes[name]!,
};

Future<void> _loadFonts() async {
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      loader.addFont(rootBundle.load(f));
    }
    await loader.load();
  }

  await family('Manrope', ['assets/fonts/manrope_variable.ttf']);
  await family('Vazirmatn', [
    'assets/fonts/vazirmatn_regular.ttf',
    'assets/fonts/vazirmatn_semibold.ttf',
    'assets/fonts/vazirmatn_bold.ttf',
    'assets/fonts/vazirmatn_extrabold.ttf',
    'assets/fonts/vazirmatn_black.ttf',
  ]);
  final sdk =
      Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path;
  final icons = File(
    '$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
    await loader.load();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture routes', (tester) async {
    await tester.runAsync(_loadFonts);
    final database = GaussDatabase(NativeDatabase.memory());
    final controller = GaussController(
      QuestionBankRepository(),
      ProgressRepository(database),
    );
    await tester.runAsync(controller.initialize);
    await tester.runAsync(controller.markTourSeen);
    Directory(_outDir!).createSync(recursive: true);
    final reports = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      reports.add(details.toString());
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);

    for (final entry in _sizes.entries) {
      final (size, textScale) = entry.value;
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      for (final route in _routes) {
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: GaussApp(
              key: UniqueKey(),
              controller: controller,
              initialLocation: route,
            ),
          ),
        );
        for (var i = 0; i < 6; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 120)),
          );
          await tester.pump(const Duration(milliseconds: 300));
        }
        await tester.runAsync(() async {
          for (final element in find.byType(Image).evaluate()) {
            final image = (element.widget as Image).image;
            await precacheImage(image, element);
          }
        });
        await tester.pump(const Duration(milliseconds: 900));
        final expand = Platform.environment['GAUSS_CAPTURE_TAP'];
        if (expand != null) {
          // Open the part card, then the first chapter, for expanded states.
          for (final key in expand.split(',')) {
            final target = find.byKey(ValueKey(key));
            if (target.evaluate().isEmpty) {
              await tester.scrollUntilVisible(
                target,
                300,
                scrollable: find.byType(Scrollable).first,
              );
            }
            await tester.ensureVisible(target);
            await tester.pump(const Duration(milliseconds: 200));
            await tester.tap(target, warnIfMissed: false);
            for (var i = 0; i < 4; i++) {
              await tester.runAsync(
                () => Future<void>.delayed(const Duration(milliseconds: 60)),
              );
              await tester.pump(const Duration(milliseconds: 250));
            }
          }
        }
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final name = '${entry.key}${route.replaceAll('/', '_')}'.replaceAll(
          ':',
          '',
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1.5);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File(
            '$_outDir/$name.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
        });
        final err = tester.takeException();
        if (err != null || reports.isNotEmpty) {
          File(
            '$_outDir/$name.error.txt',
          ).writeAsStringSync('$err\n\n${reports.join('\n---\n')}');
        }
        reports.clear();
      }
    }
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    await tester.runAsync(database.close);
    tester.view.reset();
    tester.platformDispatcher.clearAllTestValues();
  }, skip: _outDir == null);
}
