# TEST-ONLY: Teacher Grading Frontend Audit Findings

**Status:** Read-only code review; no application or database changes made  
**Repository reviewed:** `oyeleketemitope787-sys/temmy-smart-classroom-test`, `main`  
**Reviewed file:** `index.html` at the current TEST main revision  
**Safety boundary:** Findings only. Do not execute SQL, alter Supabase configuration/data, or modify Production.

## Finding 1 — Grade update does not verify that a row was actually updated

In `reviewActivitySubmission(recordId, activityId)`, the frontend performs an update to `student_activity_records` filtered by record ID and teacher ID. It checks `updateError`, but does not request the updated row (for example, with a returning selection) or verify that exactly one row was affected.

Depending on database/RLS behavior, a request can complete without a reported error while affecting zero rows. If that happens, the current code may continue to insert a point transaction for a non-zero score delta even though the assessment row was not saved. This is a potential failure path, not a confirmed occurrence.

**Required future fix:** Make the database grade-and-ledger operation atomic and return an explicit success/result. If a temporary frontend-only safeguard is ever considered, verify a returned row before attempting any separate ledger operation; this alone would not solve the multi-request atomicity problem.

## Finding 2 — Score input is silently rounded down

The frontend parses the score using `Math.floor(Number(input.value))`. A fractional input such as `2.9` becomes `2` rather than being rejected as invalid. The input element has `step="1"`, but browser input hints should not replace explicit validation.

**Required future fix:** Reject non-integer scores explicitly, and validate the score against the authoritative activity maximum in the database operation. Also reject null/empty/non-finite values before writing.

## Finding 3 — Rollback is best-effort and not fully checked

If inserting the point transaction fails, the frontend attempts to restore the prior status, score, and notes. It does not check whether that restoration succeeds, and the rollback update does not restore `completed_at` to its prior value. A rollback failure could leave the assessment and point ledger inconsistent.

**Required future fix:** Replace the separate update/insert/rollback requests with one database transaction. The transaction should lock the submission, re-check teacher/class/activity authorization and the current score, update the grade and feedback, insert the point delta only when non-zero, and roll back everything if any required step fails.

## Required invariants for future testing

- First grade writes one score and the matching point delta.
- Re-saving the same score creates no additional point transaction.
- Increasing/decreasing a score records only the difference.
- Feedback-only changes do not alter points.
- Invalid, fractional, null, negative, or above-maximum scores are rejected.
- A teacher cannot grade a submission outside their authorized class.
- Any failed operation leaves both assessment and ledger unchanged.
- Concurrent grading attempts cannot double-apply a delta.

## Environment gate

The current Supabase project `askhdgmjqezvwavfhqzj` is not an approved isolated test target for new grading migrations; its dashboard environment label was observed as `PRODUCTION`. The account's Free plan has reached its two-project limit, and the user has ruled out upgrading, creating projects/branches, pausing/deleting projects, or changing existing project configuration.

Therefore, these findings remain documentation only. Do not apply migrations, run SQL, perform write tests, or change frontend grading behavior until a genuinely isolated TEST database can be safely provided within the user's constraints.
