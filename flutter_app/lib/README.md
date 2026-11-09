# flutter_app/lib layout

- `app/` router, shell (floating navigation, branch motion), startup states, experience spec.
- `ui/` the design system: `tokens/` (spacing, hit targets, breakpoints, motion, composition), `theme/` (colors, ThemeData), `components/` (brand, state panel, orbital action).
- `features/<area>/` one folder per product surface. Large screens are one library split into `part` files by region, so private widgets stay private:
  - `map/` full-screen route map: header HUD, orbit navigator, path stage and nodes, mission dock, tablet inspector.
  - `study/` Study hub (`study_hub_*`) and the chapter Study room (`study_room_*`), session celebration.
  - `mission/` the five-question lesson flow: question stage, action bar, answers and solution, completion.
  - `manuscript/` the writable question surface shared by Study and Mission: content blocks, ink, scratchpad, theorem lens, progress rail.
  - `insights/`, `vault/`, `onboarding/`, `auth/`, `feedback/`.
- `domain/`, `data/`, `state/`, `backend/` non-UI layers; Map, Study, Mission, Manuscript and Insights reach `data/` only through `state/`; Vault, auth and feedback own their own services.
