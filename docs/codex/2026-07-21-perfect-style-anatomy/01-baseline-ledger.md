# Baseline anatomy and mismatch ledger

Captured from the release web bundle before this pass at 390x844, 768x1024,
and 1440x900. Evidence lives in `assets/baseline/`.

| Surface | Evidence | Severity | Baseline mismatch | Intended correction |
| --- | --- | --- | --- | --- |
| Android release | APK signing + attempted update | P0 | Current release artifact used the Android debug certificate and could not update the protected Gauss install. | Make release signing fail closed, test the contract, rebuild with the protected identity, and prove in-place update. |
| Web startup | Browser console | P0 | Vault startup called `path_provider` on web and reported `MissingPluginException`. | Add an explicit capability boundary and a truthful browser state without invoking native file APIs. |
| First run | `phone-tour.png` + semantic tree | P1 | Tour darkened the map but left global navigation visible and reachable behind it. | Move the tour to the app-shell layer; remove navigation and background semantics while active. |
| Map, expanded | `tablet-map.png`, `desktop-map.png` | P1 | The path is clear but nodes and landmarks are underscaled, leaving the astronomical stage materially emptier than the accepted direction. | Preserve the continuous path while adding proportional astrolabe structure, a strong first landmark, richer interval landmarks, and width-class node geometry. |
| Product copy | map, Study, Insights | P1 | Repeated engineering terms such as “source questions” and “preserved coordinates” weaken the crafted observatory voice and truncate on phone. | Use concise learner-facing language while keeping the unverified-answer trust boundary explicit. |
| Insights header | `phone-insights.png` | P2 | Long technical inventory subtitle truncates; Android-only Vault action appears on web. | Use a short offline inventory line and expose Vault only where its native capability exists. |
| Navigation | all widths | Pass | Three stable destinations, floating glass mobile bar, and desktop rail match the product’s core anatomy. | Preserve; only isolate it during first-run modal state. |
| Study path | all widths | Pass | Subject switch, sections, units, continuous nodes, selection, and inspector create clear spatial hierarchy. | Preserve behavior and improve scale/composition only. |

## Baseline responsive evidence

- Phone: `assets/baseline/phone-{tour,map,study,insights}.png`
- Tablet: `assets/baseline/tablet-{map,study,insights}.png`
- Desktop: `assets/baseline/desktop-{map,study,insights}.png`
