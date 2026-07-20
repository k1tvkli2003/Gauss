# Perfectionize program — completion record

All seven phases shipped to `main`. Every phase was verified and pushed on
its own commit, so any point is resumable.

| Phase | Commit | Scope |
|---|---|---|
| 1 | `aadebd59` | Spaced revisit orbit, dead-route hygiene, startup trim |
| 2 | `6a83b78f` | Study-native reward engine v2 + achievement catalog rebind |
| 3 | `1e8daab3` | Level HUD, daily quest, catalog seals, set-complete recap, Mira |
| 4 | `6345294c` | Hypothesis comparison, gem shelf, alignment ledger |
| 5 | `ed84a98c` | Jump finder, second-pass shuffle, subject balance dial |
| 6 | `03df8172` | Measurement-first performance pass |
| 7 | `425742a6`, `d9a050ec` | Vault backup/restore, first-run tour, Android widget |

## Final verification

- `flutter analyze --no-pub`: **0 issues**
- `flutter test --no-pub`: **74/74 green** (was 50 at program start)
- `flutter build apk --release`: **succeeds** (135.2 MB), proving the new
  Kotlin widget provider, layout, and manifest receiver compile

## Schema changes (all additive, no rows rewritten)

- v5 — `study_records.hypothesis_matched`
- v6 — `app_flags` table, pre-seeded so upgrading learners skip the tour

## Defects found and fixed along the way

Several were found *by* the new tests rather than by inspection:

1. **Startup brick** (pre-program, `02590f6e`): a stale mission draft
   referencing deleted corpus ids threw during hydration and permanently
   blocked boot. Now retires quietly.
2. **Synthetic topic mastery**: `revenge`/`review` sessions could mint
   `topic_mastered` events and inflate the orbit-atlas achievement.
3. **Metric plates clipped** their last line on narrow phones; cell ratio now
   derives from cell width.
4. **Curated shelf lookup** decoded almost the whole library (134 ms → 1 ms).
5. **Backup timestamps** were read from filesystem mtime, which a copy can
   inherit from its source; now parsed from the name written at creation.
6. **First-run tour overflowed** at font scale 1.5; the card now sizes from
   available height and scrolls its own copy.
7. **Observatory header overflowed** once the vault action joined the row;
   the divider and offline pip now stand down on narrow phones.

## Decisions recorded rather than built

- **No compute isolate for shard decode.** Measured 46 ms cold / 0 ms warm on
  the heaviest shard — below a frame budget and paid once per topic. See
  `02-performance-measurements.md`. Re-measure on a low-end device before
  revisiting.
- **Restore is staged, not immediate.** Swapping the database while Drift
  holds it open risks live progress, so the swap happens at the next cold
  start with the replaced store kept aside.

## Permanently out of scope (user decision)

Timed exam simulator; persistent per-question scratchpad. Plus the standing
AGENTS.md boundaries: no leagues, streak penalties, online AI tutor, or ML
adaptive difficulty.

## Not verified here

On-device run and screenshots. The APK builds and the suite is green, but
nothing in this program was exercised on a physical device or emulator.
