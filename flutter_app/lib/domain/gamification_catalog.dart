enum AchievementFamily {
  mastery,
  correction,
  exploration,
  challenge,
  consistency,
}

enum AchievementRarity {
  common('Common'),
  uncommon('Uncommon'),
  rare('Rare'),
  epic('Epic'),
  legendary('Legendary');

  const AchievementRarity(this.label);
  final String label;
}

enum AchievementMetric {
  correctAnswers,
  correctedMistakes,
  masteredTopics,
  goldChallenges,
  studyRhythm,
  completedMissions,
  practicedSubjects,
}

enum QuestCadence { daily, weekly, comeback }

enum CatalogRewardType { identityBadge, xp }

class CatalogRewardDefinition {
  const CatalogRewardDefinition({
    required this.id,
    required this.type,
    required this.amount,
    required this.claimBehavior,
  });

  final String id;
  final CatalogRewardType type;
  final int amount;
  final String claimBehavior;
}

class AchievementLevelDefinition {
  const AchievementLevelDefinition({
    required this.id,
    required this.title,
    required this.threshold,
    required this.rarity,
    required this.artToken,
  });

  final String id;
  final String title;
  final int threshold;
  final AchievementRarity rarity;
  final String artToken;
}

class AchievementDefinition {
  const AchievementDefinition({
    required this.id,
    required this.localizationKey,
    required this.title,
    required this.description,
    required this.accessibilityLabel,
    required this.family,
    required this.metric,
    required this.iconToken,
    required this.artRequirement,
    required this.antiAbuseRule,
    required this.reward,
    required this.levels,
    this.secret = false,
  });

  final String id;
  final String localizationKey;
  final String title;
  final String description;
  final String accessibilityLabel;
  final AchievementFamily family;
  final AchievementMetric metric;
  final String iconToken;
  final String artRequirement;
  final String antiAbuseRule;
  final CatalogRewardDefinition reward;
  final List<AchievementLevelDefinition> levels;
  final bool secret;
}

class QuestDefinition {
  const QuestDefinition({
    required this.id,
    required this.localizationKey,
    required this.title,
    required this.description,
    required this.cadence,
    required this.criteriaKey,
    required this.target,
    required this.reward,
    required this.expiryPolicy,
    required this.replacementPolicy,
    required this.eligibility,
    required this.active,
  });

  final String id;
  final String localizationKey;
  final String title;
  final String description;
  final QuestCadence cadence;
  final String criteriaKey;
  final int target;
  final CatalogRewardDefinition reward;
  final String expiryPolicy;
  final String replacementPolicy;
  final String eligibility;
  final bool active;
}

class CatalogSeedManifest {
  const CatalogSeedManifest({
    required this.catalogId,
    required this.version,
    required this.localizationNamespace,
    required this.migrationNotes,
  });

  final String catalogId;
  final int version;
  final String localizationNamespace;
  final String migrationNotes;
}

class AchievementSnapshot {
  const AchievementSnapshot({required this.definition, required this.current});

  final AchievementDefinition definition;
  final int current;

  int get earnedLevelCount =>
      definition.levels.where((level) => current >= level.threshold).length;

  AchievementLevelDefinition? get earnedLevel =>
      earnedLevelCount == 0 ? null : definition.levels[earnedLevelCount - 1];

  AchievementLevelDefinition? get nextLevel =>
      earnedLevelCount >= definition.levels.length
      ? null
      : definition.levels[earnedLevelCount];

  bool get completed => nextLevel == null;

  double get progress {
    final next = nextLevel;
    if (next == null) return 1;
    final previous = earnedLevel?.threshold ?? 0;
    final span = next.threshold - previous;
    if (span <= 0) return 1;
    return ((current - previous) / span).clamp(0, 1);
  }
}

abstract final class GaussGamificationCatalog {
  static const dailyQuestId = 'daily_useful_questions';
  static const dailyQuestTitle = 'Chart 10 useful answers';
  static const dailyQuestTarget = 10;
  static const dailyQuestRewardXp = 40;

  static const manifest = CatalogSeedManifest(
    catalogId: 'gauss_orbit_progression',
    version: 1,
    localizationNamespace: 'gamification.orbit',
    migrationNotes:
        'Version 1 introduces static, stable definitions. Existing XP, attempts, '
        'quests, and achievement rows remain untouched; progress is derived from '
        'the event ledger and recorded mission history.',
  );

  static const _identityReward = CatalogRewardDefinition(
    id: 'identity_badge',
    type: CatalogRewardType.identityBadge,
    amount: 1,
    claimBehavior:
        'Granted automatically and shown in the private observatory.',
  );

  static const achievements = <AchievementDefinition>[
    AchievementDefinition(
      id: 'proof_ledger',
      localizationKey: 'achievement.proof_ledger',
      title: 'Luminosity',
      description: 'Record correct answers across the archive.',
      accessibilityLabel: 'Proof ledger achievement',
      family: AchievementFamily.mastery,
      metric: AchievementMetric.correctAnswers,
      iconToken: 'proof_mark',
      artRequirement: 'Brass proof mark with one to four engraved star points.',
      antiAbuseRule:
          'Counts finalized correct answers; repeat XP caps remain independent.',
      reward: _identityReward,
      levels: [
        AchievementLevelDefinition(
          id: 'proof_ledger_1',
          title: 'Spark',
          threshold: 10,
          rarity: AchievementRarity.common,
          artToken: 'proof_mark_1',
        ),
        AchievementLevelDefinition(
          id: 'proof_ledger_2',
          title: 'Glow',
          threshold: 100,
          rarity: AchievementRarity.uncommon,
          artToken: 'proof_mark_2',
        ),
        AchievementLevelDefinition(
          id: 'proof_ledger_3',
          title: 'Radiance',
          threshold: 500,
          rarity: AchievementRarity.epic,
          artToken: 'proof_mark_3',
        ),
        AchievementLevelDefinition(
          id: 'proof_ledger_4',
          title: 'Nova',
          threshold: 1500,
          rarity: AchievementRarity.legendary,
          artToken: 'proof_mark_4',
        ),
      ],
    ),
    AchievementDefinition(
      id: 'error_alchemy',
      localizationKey: 'achievement.error_alchemy',
      title: 'Orbital correction',
      description: 'Turn earlier mistakes into correct answers.',
      accessibilityLabel: 'Error alchemy achievement',
      family: AchievementFamily.correction,
      metric: AchievementMetric.correctedMistakes,
      iconToken: 'correction_compass',
      artRequirement:
          'Split teal and brass compass with a visible repair seam.',
      antiAbuseRule:
          'Requires a finalized wrong attempt in an earlier mission and awards '
          'each corrected question once per session.',
      reward: _identityReward,
      levels: [
        AchievementLevelDefinition(
          id: 'error_alchemy_1',
          title: 'Deflection',
          threshold: 1,
          rarity: AchievementRarity.common,
          artToken: 'correction_compass_1',
        ),
        AchievementLevelDefinition(
          id: 'error_alchemy_2',
          title: 'Alignment',
          threshold: 10,
          rarity: AchievementRarity.uncommon,
          artToken: 'correction_compass_2',
        ),
        AchievementLevelDefinition(
          id: 'error_alchemy_3',
          title: 'Precision',
          threshold: 50,
          rarity: AchievementRarity.rare,
          artToken: 'correction_compass_3',
        ),
        AchievementLevelDefinition(
          id: 'error_alchemy_4',
          title: 'True course',
          threshold: 200,
          rarity: AchievementRarity.legendary,
          artToken: 'correction_compass_4',
        ),
      ],
    ),
    AchievementDefinition(
      id: 'orbit_atlas',
      localizationKey: 'achievement.orbit_atlas',
      title: 'Stellar cartography',
      description: 'Master distinct topics across the knowledge map.',
      accessibilityLabel: 'Orbit atlas achievement',
      family: AchievementFamily.exploration,
      metric: AchievementMetric.masteredTopics,
      iconToken: 'orrery_atlas',
      artRequirement:
          'Concentric orbit badge with distinct non-color tick marks.',
      antiAbuseRule:
          'A topic contributes once after a mission of at least five questions '
          'reaches eighty percent accuracy.',
      reward: _identityReward,
      levels: [
        AchievementLevelDefinition(
          id: 'orbit_atlas_1',
          title: 'Horizon',
          threshold: 1,
          rarity: AchievementRarity.common,
          artToken: 'orrery_atlas_1',
        ),
        AchievementLevelDefinition(
          id: 'orbit_atlas_2',
          title: 'Sector',
          threshold: 5,
          rarity: AchievementRarity.uncommon,
          artToken: 'orrery_atlas_2',
        ),
        AchievementLevelDefinition(
          id: 'orbit_atlas_3',
          title: 'Quadrant',
          threshold: 15,
          rarity: AchievementRarity.epic,
          artToken: 'orrery_atlas_3',
        ),
        AchievementLevelDefinition(
          id: 'orbit_atlas_4',
          title: 'Firmament',
          threshold: 29,
          rarity: AchievementRarity.legendary,
          artToken: 'orrery_atlas_4',
        ),
      ],
    ),
    AchievementDefinition(
      id: 'gold_transit',
      localizationKey: 'achievement.gold_transit',
      title: 'Zenith passage',
      description: 'Pass demanding twenty-question gold challenges.',
      accessibilityLabel: 'Gold transit achievement',
      family: AchievementFamily.challenge,
      metric: AchievementMetric.goldChallenges,
      iconToken: 'gold_transit',
      artRequirement:
          'Gold eclipse silhouette with one to four radial notches.',
      antiAbuseRule:
          'Requires at least twenty answers, eighty-five percent accuracy, and '
          'positive recorded duration; each session is idempotent.',
      reward: _identityReward,
      levels: [
        AchievementLevelDefinition(
          id: 'gold_transit_1',
          title: 'Ascent',
          threshold: 1,
          rarity: AchievementRarity.uncommon,
          artToken: 'gold_transit_1',
        ),
        AchievementLevelDefinition(
          id: 'gold_transit_2',
          title: 'Apex',
          threshold: 5,
          rarity: AchievementRarity.rare,
          artToken: 'gold_transit_2',
        ),
        AchievementLevelDefinition(
          id: 'gold_transit_3',
          title: 'Meridian',
          threshold: 20,
          rarity: AchievementRarity.epic,
          artToken: 'gold_transit_3',
        ),
        AchievementLevelDefinition(
          id: 'gold_transit_4',
          title: 'Solstice',
          threshold: 50,
          rarity: AchievementRarity.legendary,
          artToken: 'gold_transit_4',
        ),
      ],
    ),
    AchievementDefinition(
      id: 'steady_signal',
      localizationKey: 'achievement.steady_signal',
      title: 'Steady signal',
      description: 'Build a calm rhythm of days with recorded work.',
      accessibilityLabel: 'Steady signal achievement',
      family: AchievementFamily.consistency,
      metric: AchievementMetric.studyRhythm,
      iconToken: 'signal_pulse',
      artRequirement: 'Waveform badge with tier count encoded by pulse peaks.',
      antiAbuseRule:
          'Counts calendar days containing real XP events; no streak loss '
          'penalty or social pressure is applied.',
      reward: _identityReward,
      levels: [
        AchievementLevelDefinition(
          id: 'steady_signal_1',
          title: 'Signal found',
          threshold: 2,
          rarity: AchievementRarity.common,
          artToken: 'signal_pulse_1',
        ),
        AchievementLevelDefinition(
          id: 'steady_signal_2',
          title: 'Seven-day arc',
          threshold: 7,
          rarity: AchievementRarity.uncommon,
          artToken: 'signal_pulse_2',
        ),
        AchievementLevelDefinition(
          id: 'steady_signal_3',
          title: 'Stable frequency',
          threshold: 30,
          rarity: AchievementRarity.epic,
          artToken: 'signal_pulse_3',
        ),
        AchievementLevelDefinition(
          id: 'steady_signal_4',
          title: 'Century signal',
          threshold: 100,
          rarity: AchievementRarity.legendary,
          artToken: 'signal_pulse_4',
        ),
      ],
    ),
    AchievementDefinition(
      id: 'mission_archive',
      localizationKey: 'achievement.mission_archive',
      title: 'Mission archive',
      description: 'Complete missions and preserve a truthful study history.',
      accessibilityLabel: 'Mission archive achievement',
      family: AchievementFamily.mastery,
      metric: AchievementMetric.completedMissions,
      iconToken: 'archive_seal',
      artRequirement: 'Layered archive seal with engraved mission ticks.',
      antiAbuseRule:
          'Counts only completed persisted exams with at least one attempt.',
      reward: _identityReward,
      levels: [
        AchievementLevelDefinition(
          id: 'mission_archive_1',
          title: 'Launch',
          threshold: 1,
          rarity: AchievementRarity.common,
          artToken: 'archive_seal_1',
        ),
        AchievementLevelDefinition(
          id: 'mission_archive_2',
          title: 'Orbit',
          threshold: 25,
          rarity: AchievementRarity.uncommon,
          artToken: 'archive_seal_2',
        ),
        AchievementLevelDefinition(
          id: 'mission_archive_3',
          title: 'Trajectory',
          threshold: 100,
          rarity: AchievementRarity.epic,
          artToken: 'archive_seal_3',
        ),
        AchievementLevelDefinition(
          id: 'mission_archive_4',
          title: 'Deep space',
          threshold: 500,
          rarity: AchievementRarity.legendary,
          artToken: 'archive_seal_4',
        ),
      ],
    ),
    AchievementDefinition(
      id: 'dual_lens',
      localizationKey: 'achievement.dual_lens',
      title: 'Dual lens',
      description: 'Record real work in both mathematics and physics.',
      accessibilityLabel: 'Dual lens achievement',
      family: AchievementFamily.exploration,
      metric: AchievementMetric.practicedSubjects,
      iconToken: 'dual_lens',
      artRequirement:
          'Interlocking math and physics lenses with distinct shapes.',
      antiAbuseRule:
          'Each subject contributes only after a finalized non-skipped answer.',
      reward: _identityReward,
      levels: [
        AchievementLevelDefinition(
          id: 'dual_lens_1',
          title: 'Syzygy',
          threshold: 2,
          rarity: AchievementRarity.rare,
          artToken: 'dual_lens_1',
        ),
      ],
    ),
  ];

  static const quests = <QuestDefinition>[
    QuestDefinition(
      id: dailyQuestId,
      localizationKey: 'quest.daily_useful_questions',
      title: dailyQuestTitle,
      description: 'Answer ten non-skipped questions today.',
      cadence: QuestCadence.daily,
      criteriaKey: 'answered_non_skipped_on_local_day',
      target: dailyQuestTarget,
      reward: CatalogRewardDefinition(
        id: 'daily_useful_questions_xp',
        type: CatalogRewardType.xp,
        amount: dailyQuestRewardXp,
        claimBehavior:
            'Awarded automatically once through an idempotent event.',
      ),
      expiryPolicy: 'Expires at the next local calendar day boundary.',
      replacementPolicy: 'A new dated quest instance replaces the prior day.',
      eligibility:
          'Available privately every day; skipped answers do not count.',
      active: true,
    ),
    QuestDefinition(
      id: 'weekly_orbit_variety',
      localizationKey: 'quest.weekly_orbit_variety',
      title: 'Survey three orbits',
      description:
          'Complete meaningful work in three distinct topics this week.',
      cadence: QuestCadence.weekly,
      criteriaKey: 'distinct_topics_in_local_week',
      target: 3,
      reward: CatalogRewardDefinition(
        id: 'weekly_orbit_identity',
        type: CatalogRewardType.identityBadge,
        amount: 1,
        claimBehavior: 'Reserved until a versioned weekly-window rule ships.',
      ),
      expiryPolicy: 'Reserved: local-week expiry is not active in catalog v1.',
      replacementPolicy: 'Reserved: no live replacement occurs in catalog v1.',
      eligibility: 'Inactive until weekly event-window tests are implemented.',
      active: false,
    ),
    QuestDefinition(
      id: 'comeback_vector',
      localizationKey: 'quest.comeback_vector',
      title: 'Recover the signal',
      description:
          'Return gently with five meaningful answers after a long gap.',
      cadence: QuestCadence.comeback,
      criteriaKey: 'five_answers_after_three_inactive_days',
      target: 5,
      reward: CatalogRewardDefinition(
        id: 'comeback_identity',
        type: CatalogRewardType.identityBadge,
        amount: 1,
        claimBehavior: 'Reserved until inactivity eligibility is versioned.',
      ),
      expiryPolicy: 'Reserved: no pressure countdown is shown in catalog v1.',
      replacementPolicy:
          'Reserved: only one comeback window may exist at once.',
      eligibility: 'Inactive until an audited inactivity event exists.',
      active: false,
    ),
  ];

  static List<AchievementSnapshot> evaluate(
    Map<AchievementMetric, int> metrics,
  ) => [
    for (final definition in achievements)
      AchievementSnapshot(
        definition: definition,
        current: metrics[definition.metric] ?? 0,
      ),
  ];
}
