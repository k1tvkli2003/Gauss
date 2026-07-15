# Gamification Catalog v1

Catalog ID: `gauss_orbit_progression`  
Version: 1  
Source: `flutter_app/lib/domain/gamification_catalog.dart`

## Product Principle

Progression is private, calm, truthful, and useful to one learner. Rewards reinforce completed learning work without shops, currencies, public comparison, streak punishment, ads, purchases, multiplayer, or social pressure. Immutable progress events are the source of truth.

## Achievement Families

| ID | Display title | Metric | Tier thresholds |
|---|---|---|---|
| `proof_ledger` | Luminosity | Correct finalized answers | 10, 100, 500, 1,500 |
| `error_alchemy` | Orbital correction | Earlier mistakes corrected | 1, 10, 50, 200 |
| `orbit_atlas` | Stellar cartography | Topics mastered at >=80% over >=5 questions | 1, 5, 15, 29 |
| `gold_transit` | Zenith passage | 20-question challenges passed at >=85% with positive duration | 1, 5, 20, 50 |
| `steady_signal` | Steady signal | Local calendar days containing real XP events | 2, 7, 30, 100 |
| `mission_archive` | Mission archive | Persisted completed missions with attempts | 1, 25, 100, 500 |
| `dual_lens` | Dual lens | Mathematics and physics both practiced | 2 |

Achievement rewards are identity badges granted automatically and shown in the private observatory. Tier art and semantics encode progress by shape/notches as well as color.

## Quest Definitions

| ID | Cadence | State | Contract |
|---|---|---|---|
| `daily_useful_questions` | daily | active | Answer 10 non-skipped questions on the local calendar day; automatically award 40 XP once through an idempotent event. |
| `weekly_orbit_variety` | weekly | inactive/reserved | Three distinct topics; remains inactive until local-week event-window tests ship. |
| `comeback_vector` | comeback | inactive/reserved | Five meaningful answers after three inactive days; remains inactive until eligibility is versioned and audited. |

The daily quest expires at the next local calendar-day boundary. Repository time is injected, and midnight behavior has deterministic regression coverage.

## Integrity Rules

- Preview or fake values never enter persistence.
- XP and quest rewards use stable idempotency keys in the immutable event ledger.
- Skipped answers do not count toward the daily quest.
- Preserved-archive questions cannot produce progress events.
- Repeat-answer XP caps remain independent of achievement counts.
- The obsolete mutable achievement mirror table is retained only for schema compatibility; live achievement progress is derived from events and completed missions.

## Deliberate Exclusions

Catalog v1 intentionally contains no coins, gems, shop, paid boosts, loot boxes, energy/hearts, punitive streak loss, leaderboard, account identity, friend graph, notification pressure, or monetization hooks. Adding any of these would be a new product decision, not an implied extension of this private app.

