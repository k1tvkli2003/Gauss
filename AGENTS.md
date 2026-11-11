# Gauss Project Instructions

- For the adventure learning frontend, treat the island progression map as the primary screen surface. Map and lesson/mission hub views should be full-screen map-first experiences with HUD, rewards, navigation, and lesson actions layered as game overlays, not dashboards containing a small map card.
- Keep every app-chrome string in English. Learning data and question/answer prose may keep its source language, but every numeral rendered inside questions, answers, solutions, and their accessible descriptions must use ASCII `0-9`. Preserve immutable source data: normalize live text at the rendering boundary, and keep media with embedded non-ASCII numerals quarantined until a reviewed derived asset replaces it.
- Gauss is a private single-user product. Prefer crafted personal delight, local-first truth, and humane progression; do not add auth, monetization, public leagues, or social pressure unless the user changes that scope.
- Do not use subagents for Gauss work unless the user explicitly reverses this instruction; keep implementation, review, and final proof in the primary task.
- When the user authorizes Gauss subagents, turn frozen audit findings into exclusive builder slices; do not leave capable agents in advisory-only roles.
- In Gauss Critics/Perfect cycles, do not create a PDF unless the user explicitly asks for one. Treat findings as an internal execution queue and count progress only after the corresponding code, tests, and Android runtime evidence pass.
- The active Gauss release target is Flutter/Dart on Android. Preserve shared code, but do not spend the current rebuild cycle on web builds or web-specific polish unless the user reopens that scope.
- Model every learnable Map node as one logical five-question micro-lesson. Group questions by screened taxonomy, concepts, prerequisites, and difficulty progression rather than raw source order; preserve every source question and use explicitly marked mastery/review mixes for unavoidable remainders instead of creating short sessions or discarding data.
- Treat responsive composition as a release gate: at 320dp phones, representative phones, tablets, RTL/LTR content, and 200% text, no critical phrase may be clipped or ellipsized, no control may fall below 48dp, and no component, overlay, footer, or dock may collide or be packed into an unreadable row. Reflow the composition instead of shrinking it until it fits.
- Keep the Android emulator as a living preview after verified UI chunks. Install debug/profile variants beside the signed personal package, refresh and launch the changed route, and capture Android evidence without uninstalling or replacing `com.gauss.app` or its data.
- Use Duolingo-like path clarity and Clash Royale-like reward/arena feedback as interaction references for motion, transitions, and object positioning, while keeping implementation original and native to the active Flutter Android/web stack.
- The owner's house UI reference is SonusKt (`docs/design-references/sonuskt-ui-kit.md`): use its floating pill bottom navigation (GlassNavBar), its fade-through route motion, spring/color selection animation, and its component vocabulary in Gauss and in every other project of the owner, ported natively and dressed in each project's own palette.
- For day-bound quests, rewards, and streaks, inject the domain clock and test local-midnight boundaries. A purely decorative current-time display need not share that clock unless it affects persisted behavior.

## Vendored design skills

Project-scope copies live in both `.claude/skills/` (Claude Code) and `.agents/skills/` (Codex); keep the two trees in sync (they differ only where a skill names its own tree path). Gauss instructions above win wherever a vendored skill disagrees (Flutter/Android scope, 48dp targets, English chrome, ASCII numerals, map-first composition, no subagents).

- Visual and interaction direction: `DESIGN.md` (read before UI work).
- `ui-ux-pro-max` (nextlevelbuilder/ui-ux-pro-max-skill v2.15.0, MIT): searchable design data. Query the Flutter stack first, e.g. `python3 .claude/skills/ui-ux-pro-max/scripts/search.py "<query>" --stack flutter`. Verify each result against Gauss scope before applying it; ignore web-only guidance.

<!-- antislop:start -->
## antislop
For UI, copy, people, mobile layout, or code comments work, read `.claude/skills/antislop/SKILL.md` (core; mirrored in `.agents/skills/`) and then the skill for the task:
- UI / visual: `.claude/skills/antislop-ui/SKILL.md`
- Copy & text: `.claude/skills/antislop-copywriting/SKILL.md`
- People: `.claude/skills/antislop-human/SKILL.md`
- Mobile / responsive: `.claude/skills/antislop-layoutmobile/SKILL.md`
- Code comments: `.claude/skills/antislop-code/SKILL.md`
Before starting, follow the core's "Two Usage Modes" section in strict order: explicit session instruction first, then global preference, then ask. A session instruction always wins. For a resolved mode, say `antislop active: <mode> (session override).` or `antislop active: <mode> (global preference).` once before presenting findings or making edits, using the actual mode and source. Acknowledging the user's request without naming the source does not replace this notice.
Only an explicit choice of antislop during or after selects a session mode. A request to review, audit, or avoid file edits does not select a mode; read the global preference in that case. Another skill's mode does not select antislop's mode.
If the mode is unresolved, ask during/after and end the response; wait for the answer before any UI review, planning, or concept. For read-only tasks, put the active-mode notice only at the start of the final answer, never in progress messages. For editing tasks, announce before the first edit and omit it from the final answer.
In mode 2 (after), write audits to `docs/anti-slop/audit-NNN-YYYY-MM-DD.md`, not a PDF.
To update antislop later: replace the six `antislop*` folders in both skill trees from the upstream release (miqdadbadjuber/anti-slop, MIT).
<!-- antislop:end -->
