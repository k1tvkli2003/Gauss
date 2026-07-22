# Performance Ledger

## Baseline conditions
- revision: `8e404ca4`
- build: widget-test VM for decode timings؛ existing release artifacts for size only
- device: Windows host + Android emulator for screenshots؛ no physical-device claim
- cache: benchmark prints cold/warm per test process
- runs: one baseline suite; informational، not statistical

## Baseline observations
| Journey / metric | Baseline | Confidence |
|---|---:|---|
| `questionsByIds` scan | 130ms in latest suite | low; one run |
| `questionsByIds` hinted | 2ms | low; one run |
| heaviest shard decode cold | 9–56ms latest suite | low; host/test VM |
| Web `main.dart.js` | 3,780,986 bytes existing artifact | medium; exact artifact |
| universal APK | 141,817,909 bytes existing artifact | medium; exact artifact |

## Budgets
- no regression in question/data correctness or visual fidelity.
- release/profile Map scroll target: p95 frame ≤16.7ms when measurable; emulator results diagnostic only.
- no unbounded image cache or full-resolution decode for small visual role.
- exact build size recorded before/after; size improvement is not accepted if screenshot fidelity falls.

## Experiments
| Experiment | Result | Decision |
|---|---:|---|
| Release web rebuild after adaptive slices | `main.dart.js` 3,786,439 bytes | +5,453 bytes / +0.14% accepted for adaptive/state behavior |
| Release web total | 131,110,291 bytes؛ assets 87,082,189 bytes؛ 3,521 files | dominated by preserved corpus/media؛ no destructive optimization |
| `IntrinsicHeight` paired atlas candidate | failed intrinsic layout around shrink-wrapped viewport | rejected and removed؛ natural-height rows retained |
| Parallel fresh-Chrome captures | Flutter attach timeout under three simultaneous cold clients | use sequential or bounded parallel capture; no product defect |

## Final artifact observation
- final Web: 3,521 files / 131,092,669 bytes / `main.dart.js` 3,768,732 bytes.
- final signed APK: 141,719,881 bytes; corpus/media preservation verifier passes exactly.

## Still pending
- physical-device raster/battery/thermal run. The software-rendered AVD result remains diagnostic only.
