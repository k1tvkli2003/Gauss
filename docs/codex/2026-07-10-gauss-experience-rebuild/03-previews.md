# Previews

## Preview Policy

Every imagegen concept is a **Mock Preview** until the Flutter app reproduces it in real Android and browser screenshots. The user explicitly delegated selection and instructed Codex not to ask questions, so the strongest direction was selected autonomously. The selected preview is the binding working specification for hierarchy, component model, copy, composition, palette, typography, state treatment, and responsive transformation.

## Preview Ledger

| Name | Type | Source | Verified? | Asset/Link | Notes |
|---|---|---|---|---|---|
| A - Celestial Cartograph | Mock Preview | imagegen | no | [asset](assets/mock-preview-a-celestial-cartograph.png) | Strong cinematic atlas; rejected because desktop promoted contextual tools into primary navigation. |
| B - Field Notebook Atlas | Mock Preview | imagegen | no | [asset](assets/mock-preview-b-field-notebook-atlas.png) | Strong scholarly material language; rejected because navigation is too broad and the atlas reads more static. |
| C - Orrery of Proofs | Mock Preview - selected working spec | imagegen | no | [asset](assets/mock-preview-c-orrery-of-proofs.png) | Selected for exact three-destination shell, full curriculum visibility, strongest product identity, and best adaptive structure. |

## Mock Preview: Celestial Cartograph

- Label: Mock Preview
- Source: imagegen concept A
- Assumptions: The cinematic atlas could support the full curriculum and adaptive shell.
- Limitations: Contextual tools were promoted into primary navigation, so it was not selected.
- Verified: Visually inspected as a direction candidate; not treated as a production screenshot.
- Asset: `assets/mock-preview-a-celestial-cartograph.png`

## Mock Preview: Field Notebook Atlas

- Label: Mock Preview
- Source: imagegen concept B
- Assumptions: A scholarly paper material system could support the learning surfaces.
- Limitations: Navigation was too broad and the atlas read as more static than the product requires.
- Verified: Visually inspected as a direction candidate; its paper treatment informed the selected system.
- Asset: `assets/mock-preview-b-field-notebook-atlas.png`

## Mock Preview: Orrery of Proofs

- Label: Mock Preview
- Source: imagegen concept C
- Assumptions: A three-destination Orrery shell could preserve map-first identity across compact and expanded layouts.
- Limitations: The generated small text and populated progress were illustrative and could not be copied as live state.
- Verified: Selected autonomously and reconciled against the implemented compact/expanded release UI during browser QA.
- Asset: `assets/mock-preview-c-orrery-of-proofs.png`

## Selected Direction

**Orrery of Proofs** is the canonical concept. The implementation will borrow the cream paper question/solution material from B and the mineral island rendering quality from A.

### Product architecture

- Primary destinations: `Map`, `Practice`, `Insights`.
- Contextual routes: Arena, Result/Reward, Scratchpad, Revenge Review, Settings.
- Compact: full-screen vertical orbit slice, live HUD, bottom navigation, thumb-zone mission dock.
- Medium: rail + focused sector canvas + modal mission sheet.
- Expanded: three-item navigation rail + focused orrery canvas + docked mission inspector.
- The desktop map focuses one curriculum sector at a time; distant sectors remain visible as quiet unlabeled anchors to prevent the mock preview's label crowding.

### Overlay strategy

- Generated map/orrery background: raster scene split into background and foreground depth layers.
- Mission nodes, labels, state rings, HUD, route line, and inspector: live semantic Flutter widgets with normalized anchors.
- Question, solution, reward, and error text: always live.
- Persian learning content: live `Directionality.rtl`/locale-aware text with Vazirmatn; never baked into imagery.

### Preview limitations

- All three images are generated design mockups, not screenshots.
- Small text and exact keyboard hints are illustrative; production copy remains canonical in Dart string resources.
- The selected preview depicts a populated curriculum but not persisted user progress; production first launch begins at zero.
