# TEST-Only Follow-up Frontend Findings — Grading and Student Status

**Date:** 2026-10-11  
**Scope:** Static review of the TEST repository's current `index.html` only.  
**Safety:** No runtime action, database write, SQL execution, settings change, or Production edit was performed.

## Findings confirmed in source

### F1 — Grading and point ledger are two separate writes (critical)

In `reviewActivitySubmission()`, the frontend first updates `student_activity_records`, then separately inserts the point delta into `point_transactions`. If the second operation fails, the code attempts to roll back the first update. This is not atomic.

Additional weaknesses in the fallback:
- The rollback response is not checked.
- The prior `completed_at` value is not restored.
- The initial update does not request/verify a returned row, so an update that matches zero rows without a reported error may not be detected before the separate transaction insert.

**Required:** Move the grade update and ledger delta into one server-side transaction. Verify authorization and affected row, and test failures/retries only in isolated TEST.

### F2 — Fractional input is silently rounded down

The score handler uses `Math.floor(Number(input.value))`. This means a fractional value such as 3.9 becomes 3 rather than being rejected. An empty field can also become numeric zero through `Number('')`, depending on the exact browser value behavior.

**Required:** Explicitly require a non-empty finite integer and enforce 0 through the activity maximum in the server-side grading operation as well as the UI.

### F3 — Scored activity cards still show a generic SUBMITTED badge

`renderStudentPortalActivities()` computes the submitted flag from `record_id` or `record_status === 'submitted'`. Because a scored record has a `record_id`, the card still displays **SUBMITTED**, even when a score and feedback are available. The activity modal recognizes scored records, but the list badge does not distinguish them.

**Required:** Render clear states such as LIVE, SUBMITTED, and SCORED, with the score where appropriate. Verify student and teacher views agree after a refresh.

### F4 — Student activity modal contains a session guard, but runtime race behavior is unverified

`openStudentActivity()` captures the current session and generation counter before its RPC and checks them after the awaited call. This is a good stale-response guard in the reviewed path. However, this static inspection does not prove every asynchronous path or browser navigation scenario is race-free.

**Required:** Once safe test access is available, exercise logout/account switch while each request is pending, plus normal activity submission and refresh. Do not use the current Supabase project labelled PRODUCTION for write tests.

## Evidence boundary

These findings describe the saved TEST source. They do not prove that the same code is deployed to Production, that a failure has occurred in stored data, or that server-side policies enforce the intended behavior.

## Disposition

- F1 and F2 remain **P0 data-integrity work** before release.
- F3 remains **P1 student experience work**.
- F4 remains **runtime verification pending**.
- No Production launch approval is implied.
