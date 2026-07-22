# Layout Precision Ledger

## Equations
- window class: `w < 600` compact؛ `600 ≤ w < 1024` medium؛ `1024 ≤ w < 1440` expanded؛ `w ≥ 1440` wide.
- page gutter: compact 16؛ medium 20؛ expanded 24؛ wide 32 logical pixels.
- touch target: `max(visual size, 48)` in both axes.
- Study modes: compact `1×4`؛ medium `2×2`؛ expanded/wide `4×1` when usable width supports it.
- two-pane Study Room: activate only when `usable content width ≥ 840`; pane gap 18؛ prompt/response ratio 11:10.
- Map center target: node Y minus half of visible stage after measured bottom obstruction.

## Alignment
- app chrome and headings start-align in LTR; preserved question content uses RTL.
- radial/path objects align to computed stage center, not page/shell center.
- Inspector and dock own the selected-node CTA; no duplicate primary CTA at the same breakpoint.

## Measured closure
- compact navigation height 68 + outer inset 10؛ Map dock height 76 and bottom 92؛ intentional gap 14.
- phone Map release screenshot shows dock ending at y753 and navigation starting at y767 in an 844px viewport.
- Study Room changes from single to split exactly at 839/840dp in widget proof.
- Insights metric cards use a 138px base extent and add up to 34px at 200% text.
- all core Study/Insights/Study Room/Vault surfaces passed 200% text + reduced motion at 411×820 and 1024×800.

## Pending measurement
- comparable release/profile frame timing on emulator; no physical-device claim.
