# Map startup performance evidence — 2026-07-30

## Journey and conditions

The measured journey is cold navigation from the release web entry point to
the first Flutter canvas on the compact Map (411 × 890). The app was served
from a local static release bundle, in headless Chromium with SwiftShader,
fresh browser contexts, and `Cache-Control: no-store`. This removes WAN
latency but is **not** a physical Android or representative mobile-network
claim.

## Baseline evidence

The first useful canvas appeared after 1.93–3.94 seconds in repeated local
contexts (a separate first process run was 4.35 seconds). The initial resource
waterfall showed that Map mounted far-below-the-fold landmark art immediately:

| Resource | Transfer bytes | Initial-map role |
| --- | ---: | --- |
| `main.dart.js` | 3,783,153 | compiled application shell |
| `orrery_atmosphere_portrait.png` | 2,565,248 | visible background |
| `boss_observatory.png` | 1,859,706 | near-path landmark prefetch |
| `topic_shell.png` | 1,333,277 | visible node shell |
| `mira_thinking.png` | 1,195,442 | distant landmark, not visible on the first frame |

The whole-project asset inventory contains documentation, temporary evidence,
and build products as well as runtime assets, so it was used only to find
leads—not as deletion evidence.

## Change

`_StudyPathStage` now keeps its full path geometry, painter, labels, nodes,
and accessibility intact, but mounts expensive decorative landmarks only when
their position is inside a small viewport-adjacent scroll window. The window
updates in 220px scroll buckets and retains a 24%-of-viewport prefetch buffer.
The original rasters and their visual quality are unchanged when a learner
approaches them.

## After evidence and guardrails

The revised release waterfall no longer requests
`mira_thinking.png` during the first map frame. This removes its 1,195,442
bytes from the observed initial request set without converting, deleting, or
downscaling artwork. The current initial transfer measurement was
13,126,525 bytes in the local harness and contains no Mira request.

Canvas-ready timings after the edit varied from 5.27–8.44 seconds under the
headless local harness, so no first-canvas latency improvement is claimed.
The controlled result is limited to the eliminated noncritical transfer; a
real Android/web device and realistic network profile are still required for
startup percentile claims.

`map_mission_dock_test.dart` now asserts that the distant Mira asset is absent
from the initial Map tree. Focused map/phone accessibility tests pass, and the
full route geometry remains live so scroll navigation is not virtualized or
semantically reordered.

## Next measurement

If startup is a user-observed problem on target hardware, capture three cold
and warm Android/Web runs with network conditioning, frame pacing, memory,
and scroll-to-landmark timing before considering responsive variants for
visible map art. The current data does not justify reducing the visible
background, node-shell, or landmark fidelity.
