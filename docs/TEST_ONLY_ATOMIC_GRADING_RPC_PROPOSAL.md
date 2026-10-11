# TEST-Only Atomic Grading RPC — Implementation Proposal

**Date:** 2026-10-11  
**Status:** Proposal for review only — NOT implemented, NOT executed  
**Repository:** `oyeleketemitope787-sys/temmy-smart-classroom-test`, branch `main`  
**Safety:** No SQL was executed. No database, existing student record, point transaction, Supabase setting, or Production repository was changed.

## Decision

The frontend now rejects empty/fractional/out-of-range scores and the student activity list distinguishes LIVE, SUBMITTED, and SCORED. The remaining critical issue is that grading and point accounting are two separate requests.

The correct fix is a narrowly scoped server-side database operation that performs both changes inside one transaction. This file is a design contract, not a migration, because the active database schema, complete policy expressions, deployed function signatures, grants, triggers, and ownership have not been verified in an isolated environment.

## Proposed RPC contract

Proposed name: `public.grade_student_activity_submission`

Inputs:
- `p_record_id uuid` — target student activity record.
- `p_activity_id uuid` — activity the teacher is grading.
- `p_score integer` — requested score.
- `p_notes text` — optional teacher feedback.

The function must derive the teacher identity from the authenticated database session (for example, `auth.uid()`). It must not trust a teacher ID supplied by the browser.

Success response should clearly return:
- submission ID;
- final status;
- saved score;
- authoritative maximum score;
- point delta applied;
- whether a ledger row was inserted.

A missing, unauthorized, inactive, or invalid record must not return another teacher's/student's data.

## Required transaction algorithm

Within a single database transaction:

1. Reject missing/invalid inputs, including a null score and any score that is not an integer in the inclusive range 0 through the authoritative activity maximum.
2. Lock the activity submission row to serialize concurrent grading requests.
3. Join/re-check the submission, activity, class, and student relationships; verify the authenticated teacher owns the relevant class and the record belongs to the requested activity.
4. Verify the activity/submission status is eligible for grading according to the final product rule.
5. Read the old saved score, treating an ungraded/null score according to an explicit, reviewed rule.
6. Compute `delta = new_score - old_score`.
7. Update the submission status to `scored`, save score and notes, and set `completed_at` according to a reviewed rule (preserve existing timestamp on regrade unless product requirements say otherwise).
8. If and only if `delta <> 0`, insert exactly one point transaction using the trusted teacher/student/activity values derived from the database.
9. Return the final values.
10. If any required step fails, abort the entire transaction so neither the grade nor the point ledger changes alone.

The function must be safe under concurrent requests. A lock on the submission row and all authorization/score reads must be inside the transaction.

## Required invariants

| Operation | Expected ledger change |
|---|---:|
| First grade from 0 to 5 | +5 |
| Regrade from 5 to 3 | -2 |
| Save 3 again as 3 | 0; no ledger row |
| Feedback-only edit | 0; no ledger row |
| Invalid score or unauthorized record | No changes |
| Failure inserting ledger row | No grade or ledger changes |
| Two concurrent grading requests | No duplicate delta |

If an ungraded record has a null score, the product must explicitly decide whether its old score is treated as zero. The implementation must not silently assume this without checking actual schema/data rules.

## Frontend integration after environment gate

Replace the two-request pattern in `reviewActivitySubmission()` with one call to the approved RPC. The browser should:
- validate input for immediate user feedback;
- send only record ID, activity ID, score, and notes;
- display success only after the RPC returns a valid success result;
- refresh class points and the teacher monitor after success;
- show a safe error on failure without trying a client-side rollback.

Client validation is only for usability; the database function remains the authority.

## Permissions and function security review

Before implementation, a reviewer must establish:
- the actual authenticated teacher flow and intended caller role;
- exact function signature and any existing overloads;
- function owner and whether `SECURITY DEFINER` is necessary;
- fixed safe `search_path` and schema CREATE privileges;
- minimum EXECUTE grants and removal of unnecessary access;
- table grants, RLS policies, triggers, constraints, and relevant indexes;
- whether the function owner can perform the required writes without bypassing intended tenant isolation;
- safe error handling and no sensitive code/token logging.

Do not assume the same `anon`/ `authenticated` grants used by the game function are appropriate for teacher grading. Teacher grading should be available only through a verified teacher-authenticated path.

## Environment gate — do not bypass

The currently inspected Supabase project ref `askhdgmjqezvwavfhqzj` is dashboard-labelled `PRODUCTION`. It is not an approved target for grading RPC development or write tests.

Do not:
- execute SQL or this proposal against that project;
- change existing database records or settings;
- create a project/branch, pause/delete a project, or upgrade the plan under the user's current constraints;
- deploy this proposal to Production.

If no isolated TEST database can be made available within those constraints, retain this proposal as review-only and mark database implementation/testing blocked.

## Acceptance suite for an isolated TEST environment

1. First grade and point delta are saved together.
2. Same-score resave creates no extra ledger row.
3. Score increase/decrease applies only the delta.
4. Feedback-only edit creates no point change.
5. Empty, fractional, negative, above-maximum, and null scores are rejected.
6. Unauthorized teacher/class/activity combinations are rejected.
7. Failure at the ledger insert rolls back the grade update.
8. Concurrent requests do not double-apply points.
9. Repeating a successful request does not duplicate the delta.
10. Teacher monitor and student portal display consistent status/score after refresh.

## Current disposition

- Frontend integer validation: **committed to TEST; static verification only**.
- Student LIVE/SUBMITTED/SCORED labels: **committed to TEST; static verification only**.
- Atomic grade/ledger operation: **design specified; not implemented due environment/schema gate**.
- Database integration tests: **blocked**.
- Production release: **not approved by this proposal**.
