# Lesson and chapter structure audit (2026-11-10)

Requirement (owner): question distribution across chapters must be real and
correct; chapter and lesson structure must be logical.

## Audit findings

1. Topic assignment is consistent with the source book: each of the 29 topics
   (18 math, 11 physics) is one unbroken run of source question numbers, with
   no interleaving. The chapter level reflects the book's own structure.
2. The registry has 263 units (screened taxonomy). 437 questions (12%) have no
   registry unit (screening status only); they sit in an explicit per-chapter
   "Mixed problems" unit and are not guessed.
3. The old plan (`screened-taxonomy-five-question-v1`) clustered by the
   *proposed* subtopic (about 2,995 distinct labels), so only 14% of lessons
   stayed inside one unit; 263 lessons spanned three units.

## Change (plan v2, `registry-unit-five-question-v2`, revision 2)

`flutter_app/tool/generate_five_question_plan.dart` now builds each chapter as
registry units in pedagogical order, each unit easy to hard, cut into
consecutive fives; only a chapter's final remainder is filled with explicitly
marked mastery reviews. Result: 77% of lessons are single-unit, 150 span two
adjacent units, 18 span three or four (tiny units). 3,672 primaries, 48 review
slots, no short lessons. Unit questions are always consecutive.

## Done in this change

- Titles: each lesson is titled by its registry unit; a part counter ("2/5")
  shows where it sits inside a unit that spans several lessons.
- `migrateStudyPlan` now clears stale slot markers and positions when the plan
  version changes, then re-seeds them from per-question reflections (test:
  `study_plan_recut_migration_test.dart`; it fails without the fix).
- The content release store ignores any release or cached release whose plan
  revision is lower than the bundled plan (test: `online_content_path_test.dart`).
- The Map reserves the dock's real height from the measured lesson title.
- New guards: `study_plan_structure_test.dart`, `subtopic_index_test.dart`,
  `corpus_reachability_test.dart`.
- Receipt test: questions, index, certification and media still equal the
  published release; only the lesson plan differs until republished.

## Owner action required

Republish so online devices receive the same structure (the app already
works without it, using the bundled plan):

    python3 scripts/publish_gauss_content.py --release-id gauss-2026.11.10.1 \
        --minimum-app-build <versionCode of the APK that contains this change> --publish

needs SUPABASE_ACCESS_TOKEN. Then commit the receipt it writes to
data/content-releases/. Do not set the minimum build above the APK that ships
this change.

## Known limits

- No question is left in "Mixed problems"; 3 are best-guess placements (below).
- Unit placement of the 434 formerly unclassified questions is a content review
  by one reviewer (see below), not the screening pipeline.
- 168 lessons span two or more adjacent units; 576 of 744 (77%) are single-unit.
- Lesson/unit correctness of the 3,235 reviewed rows rests on the earlier
  screening review; this audit checked consistency with the source book order,
  not each question's mathematical content.

## The 437 unclassified questions (2026-11-11)

Tried to place them into registry units without a review:
- Overlap with registry concept tags: unusable (different vocabularies;
  under 1% of reviewed questions classified at any threshold).
- Nearest reviewed neighbours by shared proposed tags (leave-one-out on
  reviewed questions): best rule about 96% precision for 20% coverage, 98%
  for 11%. For the 437 it yields 6 confident suggestions, and 193 have no
  similar reviewed question at all.

Decision (2026-11-11, owner): place every one by judgment instead.

Done: each question was read (stem, or the printed solution where the stem is
a scan placeholder) and placed in the registry unit of its own chapter that
fits it. The result is `data/certification/v1/unit-assignments.json`, an
overlay; the frozen manifest is untouched. `scripts/build_subtopic_index.py`
and `flutter_app/tool/generate_five_question_plan.dart` both read it, and the
build fails if an overlay unit is not in the question's chapter. Plan revision
is now 3.

- All 437 placed. Three are best guesses at the nearest graph unit of their
  chapter: math 0427 (abs-value graphs), 0731 and 0732 (trigonometric graphs;
  they are function-graph questions printed inside the trigonometry run).
- Units: 242 (was 263 plus 27 mixed; the mixed units are gone). Lessons
  still 744; 576 single-unit.
- Data finding: 331 of the 3,672 shipped questions (65 of these 437) have a
  scan-placeholder stem ("must be checked against the scan"). Those 65 were
  placed from the printed solution. The question text of all 331 still needs
  repair; this is separate from unit placement.
- Online devices keep the older plan until the owner republishes content
  (the revision guard prefers the newer bundled plan).
