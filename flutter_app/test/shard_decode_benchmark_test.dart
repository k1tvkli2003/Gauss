@Tags(['benchmark'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/data/question_bank_repository.dart';

/// Measures the real cost of opening the heaviest study shards. The study
/// room decodes a whole topic shard before it can show its first question,
/// so this is the latency the learner actually waits on.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('report decode cost for the heaviest shards', () async {
    final repository = QuestionBankRepository();
    await repository.initialize();
    final heaviest =
        repository.topics.toList()
          ..sort((a, b) => b.questionCount.compareTo(a.questionCount));

    for (final topic in heaviest.take(4)) {
      final fresh = QuestionBankRepository();
      await fresh.initialize();
      final watch = Stopwatch()..start();
      final questions = await fresh.loadTopic(topic.key);
      watch.stop();
      // ignore: avoid_print
      print(
        'BENCH ${topic.key} count=${questions.length} '
        'cold=${watch.elapsedMilliseconds}ms',
      );

      final warm = Stopwatch()..start();
      await fresh.loadTopic(topic.key);
      warm.stop();
      // ignore: avoid_print
      print('BENCH ${topic.key} warm=${warm.elapsedMilliseconds}ms');
    }
  });

  test('report lookup cost for curated shelves', () async {
    final repository = QuestionBankRepository();
    await repository.initialize();
    // Worst case for the revisit/gem shelves: an id that lives in the last
    // shard, forcing a scan across the whole library.
    final lastTopic = repository.topics.last;
    final lastQuestion = (await repository.loadTopic(lastTopic.key)).last;

    final cold = QuestionBankRepository();
    await cold.initialize();
    final watch = Stopwatch()..start();
    final found = await cold.questionsByIds([lastQuestion.id]);
    watch.stop();
    // ignore: avoid_print
    print(
      'BENCH questionsByIds(scan) found=${found.length} '
      'cold=${watch.elapsedMilliseconds}ms',
    );

    final hinted = QuestionBankRepository();
    await hinted.initialize();
    final hintedWatch = Stopwatch()..start();
    final hintedFound = await hinted.questionsByIds(
      [lastQuestion.id],
      topicByQuestionId: {lastQuestion.id: lastTopic.key},
    );
    hintedWatch.stop();
    // ignore: avoid_print
    print(
      'BENCH questionsByIds(hinted) found=${hintedFound.length} '
      'cold=${hintedWatch.elapsedMilliseconds}ms',
    );
    expect(hintedFound.single.id, found.single.id);
  });
}
