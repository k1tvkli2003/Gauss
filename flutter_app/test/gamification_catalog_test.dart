import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/data/progress_repository.dart';
import 'package:gauss/domain/gamification_catalog.dart';

void main() {
  test('catalog v1 has stable unique ids and monotonic achievement levels', () {
    expect(GaussGamificationCatalog.manifest.version, 1);
    expect(
      GaussGamificationCatalog.achievements.map((item) => item.id).toSet(),
      {
        'proof_ledger',
        'error_alchemy',
        'orbit_atlas',
        'gold_transit',
        'steady_signal',
        'mission_archive',
        'dual_lens',
      },
    );

    final achievementIds = <String>{};
    final localizationKeys = <String>{};
    final levelIds = <String>{};
    for (final definition in GaussGamificationCatalog.achievements) {
      expect(achievementIds.add(definition.id), isTrue);
      expect(localizationKeys.add(definition.localizationKey), isTrue);
      expect(definition.description, isNotEmpty);
      expect(definition.accessibilityLabel, isNotEmpty);
      expect(definition.artRequirement, isNotEmpty);
      expect(definition.antiAbuseRule, isNotEmpty);
      expect(definition.reward.type, CatalogRewardType.identityBadge);
      expect(definition.levels, isNotEmpty);

      var previousThreshold = 0;
      for (final level in definition.levels) {
        expect(levelIds.add(level.id), isTrue);
        expect(level.threshold, greaterThan(previousThreshold));
        expect(level.artToken, isNotEmpty);
        previousThreshold = level.threshold;
      }
    }
  });

  test('quest catalog names active and deliberately reserved cadences', () {
    final questIds = GaussGamificationCatalog.quests
        .map((quest) => quest.id)
        .toSet();
    expect(questIds, hasLength(GaussGamificationCatalog.quests.length));

    final active = GaussGamificationCatalog.quests.singleWhere(
      (quest) => quest.active,
    );
    expect(active.id, 'daily_useful_questions');
    expect(active.target, ProgressRepository.dailyQuestTarget);
    expect(active.reward.amount, ProgressRepository.dailyQuestXp);
    expect(active.cadence, QuestCadence.daily);

    for (final reserved in GaussGamificationCatalog.quests.where(
      (quest) => !quest.active,
    )) {
      expect(reserved.eligibility, contains('Inactive'));
      expect(reserved.expiryPolicy, contains('Reserved'));
      expect(reserved.replacementPolicy, contains('Reserved'));
    }
  });

  test(
    'catalog evaluation exposes earned and next levels deterministically',
    () {
      final snapshots = GaussGamificationCatalog.evaluate({
        AchievementMetric.correctAnswers: 110,
        AchievementMetric.correctedMistakes: 1,
        AchievementMetric.masteredTopics: 29,
        AchievementMetric.goldChallenges: 0,
        AchievementMetric.studyRhythm: 7,
        AchievementMetric.completedMissions: 25,
        AchievementMetric.practicedSubjects: 2,
      });

      final proof = snapshots.singleWhere(
        (snapshot) => snapshot.definition.id == 'proof_ledger',
      );
      expect(proof.earnedLevel?.id, 'proof_ledger_2');
      expect(proof.nextLevel?.id, 'proof_ledger_3');
      expect(proof.progress, closeTo(10 / 400, .0001));

      final atlas = snapshots.singleWhere(
        (snapshot) => snapshot.definition.id == 'orbit_atlas',
      );
      expect(atlas.completed, isTrue);
      expect(atlas.progress, 1);

      final dual = snapshots.singleWhere(
        (snapshot) => snapshot.definition.id == 'dual_lens',
      );
      expect(dual.completed, isTrue);
      expect(dual.earnedLevel?.rarity, AchievementRarity.rare);
    },
  );
}
