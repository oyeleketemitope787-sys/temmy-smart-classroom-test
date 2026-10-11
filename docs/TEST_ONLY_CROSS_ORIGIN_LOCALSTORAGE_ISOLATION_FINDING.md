# TEST-Only Cross-Origin Storage Isolation Finding

**Date:** 2026-10-12  
**Scope:** Read-only comparison of `index.html` on TEST and Production default branches. No application or database state was changed by this review.

## Finding: TEST clean-up script can remove Production browser-local data

**Severity: High — source correction committed to TEST; browser acceptance verification remains pending.**

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

## Correction committed to TEST

The TEST-only `index.html` correction is committed and fetched back from GitHub:

- Removed the startup cleanup script that deleted shared legacy keys and altered the Production cleanup marker.
- Replaced legacy storage fallback reads with the single unique key `temmySmartClassroomTestV1`.
- Changed TEST saves to write only to `temmySmartClassroomTestV1`.
- Confirmed by source inspection that the TEST file no longer contains the prior cleanup marker, legacy-key reads, or legacy-key writes.

No attempt was made to migrate existing local-only data from legacy keys, because those keys are shared-origin and cannot safely be assumed to belong to TEST.

## Remaining verification

1. Do not treat the source correction as a completed browser acceptance test. After the deployed TEST page updates, verify in a disposable browser profile that TEST creates/updates only `temmySmartClassroomTestV1` and leaves Production keys unchanged.
2. Do not migrate, clear, rename, or otherwise modify Production browser storage as part of this fix.
3. Recheck the browser console and basic teacher/student UI after deployment, without submitting or changing database records.

## Constraints and status

- No Production source was changed.
- No database or SQL operation was performed.
- No Supabase setting, project, or branch was changed.
- The source correction is applied in TEST only; browser acceptance verification remains pending.
- Continue to honor the user's restriction against database writes, SQL execution, paid upgrades, new projects/branches, or changes to Production.

## Evidence

- Production source: `oyeleketemitope787-sys/temmy-smart-classroom/index.html`, default branch at review time.
- TEST source: `oyeleketemitope787-sys/temmy-smart-classroom-test/index.html`, default branch at review time.
- Both files were fetched read-only from GitHub. The TEST source cleanup references and Production source cleanup references were compared directly.
