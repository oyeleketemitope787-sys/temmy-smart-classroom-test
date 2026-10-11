# TEST-Only Read-Only Review: RLS and RPC Permissions

**Status:** Static repository review plus previously reported dashboard observations. Not a live database permission audit.  
**Repository:** `oyeleketemitope787-sys/temmy-smart-classroom-test`, branch `main`  
**Safety:** No SQL was executed, no Supabase settings or records were changed, and no Production application was modified.

## What is known from prior read-only inspection

- Row-level security was reported enabled for `classes`, `students`, `point_transactions`, and `student_activity_records`.
- The reported policies on `classes` constrained teacher access using `teacher_id = auth.uid()`.
- The reported policies on `students` constrained access through classes owned by `auth.uid()`.
- The reported `point_transactions` policies included teacher-scoped SELECT and INSERT checks requiring the transaction's teacher to match `auth.uid()` and the student to belong to a class owned by that teacher.
- Three policies were reported on `student_activity_records` (create, update, view), but their complete expressions were not captured in the review notes.
- The current active database function grants, function owners, and effective privileges have not been independently retrieved in this review.

These observations are useful, but they do **not** prove that every table, view, RPC, or privileged function is secure. RLS being enabled is not sufficient by itself.

## Static review of the prepared Grade 3 game migration

File: `supabase/migrations/202610090002_harden_grade3_game_result_recording.sql`

The migration is explicitly marked **REVIEW FILE ONLY — DO NOT EXECUTE YET** and warns against the currently inspected project.

Observed in the file:
- Uses `SECURITY DEFINER` and sets `search_path` to `public`.
- Revokes EXECUTE from `PUBLIC`, `anon`, and `authenticated`, then grants EXECUTE to `anon` and `authenticated`.
- Validates game ID/name, the expected maximum score, score bounds, session expiry, unused session, and active student/class relationship.
- Locks the game-session row, claims it, and writes the point transaction within the function's transaction.

### Permission and deployment questions still open

1. **Who owns the function?** Confirm the owner is the intended trusted role with only the privileges needed for the operation.
2. **Can untrusted roles create objects in schemas on the function's search path?** A fixed search path is a good control, but the schema's CREATE privileges and object resolution still need review.
3. **Are the intended callers correct?** The proposed migration grants execution to both `anon` and `authenticated`. This may be intentional for the browser's RPC call, but must be justified by the app's actual auth flow and the function's bearer-token threat model.
4. **Are all other overloads and old function grants accounted for?** Review the exact signature and all related functions, not only this one migration.
5. **Are all table writes safe under the function owner?** Confirm constraints, triggers, table grants, and row relationships in the isolated environment.
6. **Are errors and logs safe?** Do not expose raw session tokens, student access codes, hashes, or sensitive details.

No claim is made that the prepared migration is ready for deployment. It has not been executed or integration-tested.

## Required next verification — read-only first

When an approved isolated TEST database is available, a qualified reviewer should capture (without modifying data):
- exact policies and expressions for every table used by teacher/student RPCs;
- function signatures, owners, `SECURITY DEFINER` status, `search_path`, and EXECUTE grants;
- schema CREATE privileges relevant to privileged functions;
- constraints/indexes relevant to duplicate submissions and game-session uniqueness;
- table grants and any views/functions that bypass or supplement RLS.

Until isolation is confirmed, do not use the project currently labelled PRODUCTION to run test writes or migrations. If the only available route requires an upgrade, new project/branch, pause, deletion, or a configuration change the user has ruled out, mark the database audit **blocked** and preserve the current state.

## Current disposition

- **Observed:** Some core tables have RLS enabled and teacher-scoped policies were reported.
- **Reviewed statically:** The proposed Grade 3 game function has several meaningful server-side validations and a transaction-oriented single-use-session flow.
- **Not verified:** Complete policy expressions, active function grants/owners, schema privileges, full concurrency behavior, and live RPC acceptance tests.
- **Decision:** No database changes and no launch/security sign-off on this evidence alone.
