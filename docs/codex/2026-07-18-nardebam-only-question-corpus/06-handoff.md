# Handoff

## Outcome

The source-only migration and the Flutter Study Observatory rebuild are
implemented and release-verified. All retained questions/media are preserved,
the provider name is absent from product copy, and Android/Web run the same
local-first experience.

## Primary Changed Areas

- `scripts/migrate_to_nardebam_only.mjs` and corpus validator.
- Question-bank indexes/shards and removal of non-source seed corpora.
- `study_curriculum.dart`, database v4, progress repository, controller.
- Continuous Map, Study Observatory, Personal Constellation, and Study Room.
- Direct question ink, full scratchpad, resume, reflection, and revisit.
- Responsive router shell, floating glass navigation, and web deep-link fix.
- Android/web identity, manifest/version, release verification tooling.
- Runtime evidence and durable design/research ledgers in this folder.

## Release Truth

- APK `1.0.90 (90)` is signed with the existing private Gauss certificate.
- Update-in-place from v89 succeeded without changing first-install time.
- Web and APK contain byte-identical question banks/media.
- Analyzer and all 49 tests pass.
- Native Map, Study, Study Room, direct ink, and instant clear were exercised.

## Operational Notes

- Keep `com.gauss.app`, a monotonic version code, and the protected Gauss
  signing identity for every future Android update.
- Never commit the keystore or Credential Manager secret.
- Run the deterministic migration in dry-run mode before any future data edit.
- Do not introduce scoring until answer mappings are independently validated.
- Ink is intentionally session-local; closing a question clears it.

## Done

- Data migration, Flutter implementation, responsive/identity polish,
  persistence, drawing, tests, builds, signing continuity, and native runtime
  proof are complete.
- The modernize whole-experience identity workflow is recorded and validated.

## Remaining

No required work remains. Independent answer validation, new content,
distribution, or additional platforms are separate future scopes.

## Verification

See `05-verification.md` for exact commands, counts, hashes, signing identity,
launch times, semantic navigation, and drawing/clear evidence. Result: passed.
The implementation commit `df9caeb` is published on `origin/main`.
