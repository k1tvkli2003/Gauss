# Preview-to-production Decomposition

| Element | Implementation | Responsive rule | Semantics / fallback |
|---|---|---|---|
| Orrery atmosphere | optimized raster asset + dark overlay | cover، crop per viewport | decorative، excluded from semantics |
| Theorem Star | canonical SVG/widget | fixed aspect، scalable | single image label `Gauss`/context label |
| Gauss wordmark | canonical live asset | size token per class | one accessible identity image |
| Path nodes/landmarks | dedicated visual assets + live progress/state overlays | geometry computed from available stage | buttons named by unit/set/status |
| Continuous path | CustomPainter | amplitude/node spacing from stage width | decorative; nodes carry navigation meaning |
| Nav/rail/footer | live Flutter controls | compact bottom، medium+ rail، wide extended | keyboard/focus/touch ≥48dp |
| Inspector/dock | live data and CTA | dock compact/medium، inspector expanded+ | selected node/state announced |
| Study cards/modes | live responsive widgets | 1 / 2×2 / 4 | actions remain buttons with labels |
| Question plate | live Persian content + optional ink overlay | single/split workspace | content remains selectable/readable; ink is opt-in |
| Scratch sheet | live CustomPainter | tall phone sheet، bounded large canvas | clear/close/pen size semantic controls |
| Insights metrics | live values/instruments | 2 or 4 based on usable width | labels and values not flattened |
| Loading/empty/error | live state panels | centered/bounded per class | retry/back/actions keyboard accessible |

## Asset rule
Original high-quality assets remain untouched. Any WebP/size variant is additive، tied to observed render size and visually compared before adoption.
