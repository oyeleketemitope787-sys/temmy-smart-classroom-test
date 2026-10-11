# TEST-ONLY: Atomic Teacher Grading Design

**Status:** Design only — not implemented  
**Scope:** Teacher-assessed live activities in Temmy Smart Classroom  
**Environment:** TEST repository documentation only  
**Hard safety boundary:** Do not execute SQL or modify any Supabase project as part of this design. In particular, never apply a proposed migration to project ref `askhdgmjqezvwavfhqzj` or any Supabase environment labelled PRODUCTION.

## 1. Confirmed current behavior

The current frontend function `reviewActivitySubmission(recordId, activityId)`:

1. Reads the target submission from `student_activity_records`, scoped by record ID, activity ID, and the signed-in teacher ID.
2. Validates the submitted score against the activity's maximum points.
3. Updates `student_activity_records` with status `scored`, the new `points_awarded`, `completed_at`, and `notes`.
4. If the score changed, separately inserts a `point_transactions` row for the score difference.
5. If that insert fails, attempts to restore the previous submission state, but does not check whether the restoration succeeded.

This is a potential consistency risk because the assessment update, point transaction, and attempted rollback are separate requests. This review has not established that an inconsistency has occurred in existing records.

## 2. Desired behavior

A future database operation should save the assessment and corresponding point adjustment as one atomic transaction: either every required change succeeds, or none of them persists.

### Required validation and authorization

- Require an authenticated teacher identity from the trusted database session; never accept a caller-supplied teacher ID as authoritative.
- Verify the teacher owns the activity's class and the target submission belongs to that activity and class.
- Validate that the activity and submission are in an allowed state for grading.
- Require a non-null integer score in the inclusive range 0 to the activity's validated maximum.
- Validate maximum points from the authoritative activity record, not from browser-provided values.
- Treat feedback as text and preserve empty feedback according to the chosen application rule.
- Handle missing records and unauthorized access without exposing another teacher's or student's records.

### Atomic write sequence

Within one database transaction:

1. Lock the target submission row to serialize concurrent grading attempts.
2. Re-read and validate the current score, status, activity maximum, class ownership, and student relationship.
3. Compute `delta = new_score - old_score`.
4. Update the submission's status, score, feedback, and completion timestamp.
5. If `delta != 0`, insert exactly one corresponding `point_transactions` row.
6. Return a clear result containing the saved score, maximum, delta, and status.

If any required step fails, the transaction must roll back all changes. A successful retry with the same score should not create another point transaction because the new delta is zero. Concurrent attempts must not double-apply a score difference.

## 3. Point-accounting invariants

- A grade change from 0 to 5 adds 5 points.
- A grade change from 5 to 3 subtracts 2 points.
- Re-saving 3 as 3 adds or subtracts 0 points and creates no new transaction.
- Feedback-only edits do not change points.
- A failed grade save must not leave a point transaction behind.
- A failed point transaction must not leave a new grade or feedback behind.
- The displayed assessment score and the point ledger must remain consistent.

These are design examples, not instructions to change or test current records.

## 4. Security requirements

- Use a narrowly scoped database function with a trusted authorization check.
- Review function ownership, execution grants, row-level security policies, and `search_path` before implementation.
- Revoke unnecessary access and grant execution only to the intended role(s).
- Do not rely on client-side controls for authorization.
- Avoid exposing access codes, session tokens, or unnecessary student data in logs and error messages.
- Confirm that the function cannot grade submissions belonging to another teacher or class.

## 5. Isolated-environment gate

Do not implement or execute a migration until all of the following are true:

- A separate, isolated TEST Supabase project is available without upgrading the plan or disturbing existing projects.
- Its project reference and environment identity are confirmed from the dashboard.
- The schema, constraints, existing triggers, RLS policies, and function grants have been reviewed read-only.
- A disposable fixture dataset is available and contains no real student records.
- The migration has been reviewed for authorization, locking, rollback behavior, grants, and compatibility.
- Tests can be performed only against the isolated project.
- Production repositories and databases remain untouched.

If a separate isolated project cannot be created within the existing constraints, keep this work at design/review stage.

## 6. Acceptance tests for a future isolated TEST environment

1. First grading of a submission records the expected score and one point delta.
2. Re-saving the same score creates no additional point transaction.
3. Raising the score records only the positive difference.
4. Lowering the score records only the negative difference.
5. Editing feedback alone does not change the point ledger.
6. A score below zero, above the authoritative maximum, or otherwise invalid is rejected.
7. A teacher cannot grade a submission from another teacher's class.
8. A failure during the transaction leaves both grade and point ledger unchanged.
9. Two concurrent grading requests do not double-apply the score difference.
10. Repeating a request after a successful save does not duplicate points.

## 7. Explicitly out of scope

- No SQL execution.
- No Supabase schema or configuration changes.
- No changes to student scores, feedback, activity status, or point transactions.
- No changes to the Production classroom repository.
- No project creation, deletion, pausing, upgrade, or branch creation.
- No frontend grading-code change until the isolated database and design are reviewed.

## 8. Next review step

Read the schema and policy definitions in an isolated TEST environment, then prepare a migration proposal for review only. Do not execute it until the project identity, permissions, and rollback strategy have been independently verified.
