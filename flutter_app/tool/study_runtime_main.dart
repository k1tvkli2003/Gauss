import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:gauss/app/gauss_app.dart';
import 'package:gauss/auth/gauss_account_session.dart';
import 'package:gauss/domain/models.dart';

/// Isolated Android continuation probe, never used by the release entrypoint.
/// Four reflections are fixture setup; the fifth is saved through real UI.
Future<void> main() async {
  const shuffleProbe = bool.fromEnvironment('GAUSS_SHUFFLE_PROBE');
  late GaussAccountSession session;
  late String topicKey;
  final report = <String, dynamic>{};
  var firstFrameReady = false;
  enableFlutterDriverExtension(
    handler: (message) async {
      if (message == 'ready') return jsonEncode({'ready': firstFrameReady});
      if (message == 'evidence') {
        final shelf = await session.controller.loadStudyShelf(
          topicKey,
          count: 5,
        );
        return jsonEncode({
          ...report,
          'persisted_records': shelf.records.length,
          'encountered_slots': shelf.encounteredSlotIds.length,
        });
      }
      return jsonEncode({'error': 'Unsupported study probe request'});
    },
  );
  SemanticsBinding.instance.ensureSemantics();
  // Unique, local-only account avoids resetting any prior preview or user DB.
  session = await GaussAccountSession.open(
    'gauss-study-probe-${DateTime.now().microsecondsSinceEpoch}',
  );
  await session.controller.markTourSeen();
  topicKey = session.controller.topics.first.key;
  final shelf = await session.controller.loadStudyShelf(topicKey, count: 5);
  final next = await session.controller.loadStudyShelf(
    topicKey,
    offset: 5,
    count: 5,
  );
  for (var index = 0; index < (shuffleProbe ? 0 : 4); index++) {
    await session.controller.saveStudyReflection(
      question: shelf.questions[index],
      shelfKey: shelf.key,
      hypothesisChoiceIndex: null,
      reflection: StudyReflection.clear,
      slot: shelf.slots[index],
    );
  }
  report.addAll({
    'topic_key': topicKey,
    'first_question_id': shelf.questions.first.id,
    'last_question_id': shelf.questions.last.id,
    'next_question_id': next.questions.first.id,
    'fixture_reflections': shuffleProbe ? 0 : 4,
  });
  runApp(
    GaussApp(
      controller: session.controller,
      accountEmail: 'local-study-probe',
      initialLocation: '/study/chapter/$topicKey?offset=0&count=5',
    ),
  );
  WidgetsBinding.instance.addPostFrameCallback((_) => firstFrameReady = true);
}
