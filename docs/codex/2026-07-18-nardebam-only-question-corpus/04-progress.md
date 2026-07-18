# Progress

## Log

| Phase | Status | Outcome |
|---|---|---|
| Provenance inventory | complete | Identified 3,672 retained and 3,681 non-source records |
| Deterministic migration | complete | Shipped banks filtered; non-source seed/generated/official/review corpora removed |
| Media closure | complete | Exactly 3,410 referenced media files retained; zero orphans |
| Curriculum | complete | 29 topics projected into 9 sections and non-overlapping sets of ≤20 |
| Persistence | complete | Database schema v4 adds study records and per-shelf positions |
| Map | complete | Separate Math/Physics modes on one continuous sinuous adventure route |
| Study | complete | Continue orbit, modes, section/unit atlas, all content open |
| Study Room | complete | Resume, hypothesis, reveal, clear/revisit reflection, direct ink, full scratchpad |
| Insights | complete | Calm private reflection metrics, activity chart, subject/section progress |
| Responsive shell | complete | Floating glass phone navigation and desktop rail |
| Web deep links | complete | Router survives async offline bootstrap; regression test added |
| Quality gates | complete | Analyzer clean; 49 tests passed |
| Release artifacts | complete | Web release and signed v90 APK built and byte-verified |
| Android continuity | complete | v89→v90 update-in-place; first-install timestamp preserved |
| Native interaction | complete | Map→Study→Room plus pen stroke and instant clear verified |
| Durable documentation | complete | Task docs and modernize skill validation passed |
| Git publication | complete | Implementation commit `df9caeb` pushed to `origin/main` |

## Notable Defects Found and Closed

1. Web deep links reset to Map because a temporary non-router
   `MaterialApp` replaced the router during database bootstrap. The router is
   now mounted from the first frame and an isolated regression test covers it.
2. The local APK initially used code 1, lower than installed code 89. The
   durable version was advanced to `1.0.90+90`.
3. The first rebuilt APK used the debug certificate and could not update the
   existing personal release. The protected Gauss key was loaded from Windows
   Credential Manager in memory, producing the matching non-debug certificate.
4. A screenshot briefly captured another foreground package. Foreground
   Activity checks and Android semantic bounds replaced raw visual assumptions.
5. A raw `adb input swipe` did not create ink. A real native
   DOWN/MOVE/UP sequence proved the GestureDetector and clear state.

## Next

No required next step. Preserve signing/version continuity and rerun the
recorded gates for future releases.
