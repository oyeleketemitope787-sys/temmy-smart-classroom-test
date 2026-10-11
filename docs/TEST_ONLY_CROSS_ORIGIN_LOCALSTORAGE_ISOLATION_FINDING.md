# TEST-Only Cross-Origin Storage Isolation Finding

**Date:** 2026-10-12  
**Scope:** Read-only comparison of `index.html` on TEST and Production default branches. No application or database state was changed by this review.

## Finding: TEST clean-up script can remove Production browser-local data

**Severity: High — fix before further opening the TEST website in a browser on the same GitHub Pages origin.**

The TEST page's initial script checks the marker `temmyProductionCleanV1`. If absent, it removes these localStorage keys:

- `temmySmartClassroomV2`
- `temmySmartClassroomV3`
- `temmySmartClassroomV4`
- `temmySmartClassroomV4_1`
- `temmySmartClassroomV4_2`
- `temmySmartClassroomV4_3`
- `temmySmartClassroomFinal`
- `temmySmartClassroomV5`
- `temmyCleanMasterV1`

It then sets `temmyProductionCleanV1`.

The Production page uses `temmyCleanMasterV1` as its own cleanup marker and uses several of the same data keys, including `temmySmartClassroomV5`, for localStorage reads/writes. GitHub Pages project sites under the same `<user>.github.io` origin share origin-scoped localStorage even when their URL paths differ. Therefore, the TEST cleanup can remove the Production cleanup marker and stored data; a later Production visit can then rerun its cleanup script. This is a source-level risk confirmed by comparing both repository files, not a claim that a user's data has already been lost.

## Required safe correction

1. Do not open the TEST site again in a browser on the shared origin until its storage behavior is corrected, if preserving Production browser-local data is important.
2. In TEST only, remove the destructive legacy-key cleanup and give TEST all localStorage keys with a unique TEST namespace.
3. Do not migrate, clear, rename, or otherwise modify Production browser storage as part of this fix.
4. Review every localStorage read/write in TEST and verify there is no fallback read from Production's legacy keys.
5. Then test in a disposable browser profile or isolated origin. Confirm that visiting TEST leaves Production-origin keys unchanged.

## Constraints and status

- No Production source was changed.
- No database or SQL operation was performed.
- No Supabase setting, project, or branch was changed.
- This document records a review finding only; the code correction has **not** yet been applied.
- Continue to honor the user's restriction against database writes, SQL execution, paid upgrades, new projects/branches, or changes to Production.

## Evidence

- Production source: `oyeleketemitope787-sys/temmy-smart-classroom/index.html`, default branch at review time.
- TEST source: `oyeleketemitope787-sys/temmy-smart-classroom-test/index.html`, default branch at review time.
- Both files were fetched read-only from GitHub. The TEST source cleanup references and Production source cleanup references were compared directly.
