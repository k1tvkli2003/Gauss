import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/data/question_bank_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('decoded topics stay bounded and the latest use survives', () async {
    final bank = QuestionBankRepository();
    await bank.initialize();
    final keys = bank.topics.map((topic) => topic.key).toList();
    expect(keys.length, greaterThan(QuestionBankRepository.maxDecodedTopics));

    for (final key in keys) {
      await bank.loadTopic(key);
    }
    final loaded = keys.where(bank.isTopicLoaded).toList();
    expect(loaded, hasLength(QuestionBankRepository.maxDecodedTopics));
    expect(bank.isTopicLoaded(keys.last), isTrue);
    expect(bank.isTopicLoaded(keys.first), isFalse);

    // Touching an old topic re-decodes it with identical content.
    final again = await bank.loadTopic(keys.first);
    expect(again, isNotEmpty);
    expect(bank.isTopicLoaded(keys.first), isTrue);
  });
}
