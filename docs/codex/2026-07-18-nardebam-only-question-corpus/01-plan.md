# Plan

## Delivery Strategy

The implementation is organized around independently provable contracts:
corpus preservation, trustworthy study behavior, continuous-path information
architecture, responsive visual implementation, release artifact parity, and
Android runtime continuity.

## Steps

| Step | Status | Evidence |
|---|---|---|
| Audit provenance, question counts, media references, and consumers | complete | Deterministic migration dry-run and strict validator |
| Filter all shipped/legacy banks and remove non-source corpora | complete | 3,672 → 3,672 idempotent state; zero removal targets remain |
| Build curriculum hierarchy and continuous Math/Physics route | complete | `study_curriculum.dart`, map implementation, coverage tests |
| Replace mission/dashboard assumptions with Study Room and private reflection | complete | Database v4, repositories, controller, Study/Insights/Room screens |
| Add question ink, instant clear, and full-sheet scratchpad | complete | Widget tests plus native Android semantic/drawing proof |
| Perfect responsive identity, navigation, backgrounds, and deep links | complete | Phone/desktop release captures and URL bootstrap regression |
| Validate source/web/APK parity, tests, signing, and Android runtime | complete | 49 tests, strict verifier, signed v90 install and runtime proof |
| Update durable docs/skill guidance and publish main-only Git state | complete | Docs/skill validators passed; implementation commit `df9caeb` is on `origin/main` |

## Authoritative Interfaces

- `flutter_app/assets/question_bank/`: released Flutter corpus.
- `app/src/main/assets/question_bank/`: canonical mirrored source artifact.
- `data/seed/comprehensive/nardebam/`: retained normalized source material.
- `flutter_app/lib/domain/study_curriculum.dart`: curriculum projection.
- `flutter_app/lib/data/progress_repository.dart`: private study records and
  positions.
- `flutter_app/lib/app/gauss_app.dart`: routes and responsive shell.
- `scripts/migrate_to_nardebam_only.mjs`: deterministic migration.
- `scripts/validate_comprehensive_dataset.mjs`: strict structural/media gate.
- `flutter_app/tool/verify_release_artifacts.ps1`: cross-artifact byte parity,
  package, and signing gate.

## Risk Controls

- Source mappings remain unscored until independently verified.
- Ink is session-local and cannot mutate the preserved question corpus.
- No deletion begins until migration count checks pass.
- Release APKs must retain `com.gauss.app`, monotonic version code, and the
  recorded Gauss signing certificate.
- Web router remains mounted through offline bootstrap so deep links survive.

## Final Acceptance

All technical, runtime, documentation, security, and publication acceptance
checks are complete. The implementation commit `df9caeb` is published on
`origin/main`; the final status-only commit records closure.
