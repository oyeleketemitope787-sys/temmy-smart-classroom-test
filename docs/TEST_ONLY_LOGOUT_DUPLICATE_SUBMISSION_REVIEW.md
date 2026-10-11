# TEST-ONLY: Student Logout and Duplicate Submission Review

**Status:** Read-only frontend review; no application or database writes performed  
**Repository:** `oyeleketemitope787-sys/temmy-smart-classroom-test`, branch `main`  
**Safety boundary:** Findings only. No SQL, migrations, live write tests, Supabase configuration changes, or Production edits.

## 1. Student logout clears only part of the in-memory state

The current `studentPortalLogout()` sets `studentPortalSession` to null and clears `studentPortalActivities`, then clears the access-code input and login message. It does not explicitly clear the other in-memory caches `studentPortalHistory`, `studentPortalGames`, or `studentPortalMessages`.

The portal body is re-rendered into the signed-out state, which removes the visible portal content. However, the remaining arrays can retain previously loaded student data in JavaScript memory until they are overwritten or the page is closed/reloaded. This is a data-minimization and account-switching concern; this review did not establish that another student can currently view the cached data.

**Recommended future fix:** On logout, clear the session object and all student-specific cached arrays, reset any related UI containers/status messages, and ensure asynchronous requests started for the prior session cannot populate the next student's portal after logout or account switching. Apply and verify only after a safe isolated TEST target is available.

## 2. Duplicate submission: frontend guard is not sufficient

The frontend checks whether a submission already exists and changes the modal to a view-only state. It calls the `submit_student_activity` RPC with the student's access code, activity ID, and answer. The reviewed database function checks for an existing submission before inserting a new record.

These are useful controls, but a pre-insert existence check can be vulnerable to two near-simultaneous requests unless the database also enforces uniqueness or serializes the operation. The actual database uniqueness constraints and full function permissions have not been verified in an isolated environment, so the duplicate-race question remains **unconfirmed**.

**Recommended future fix:** Inspect constraints and the full function in an isolated TEST database. Prefer a database-enforced uniqueness rule for the intended student/activity submission identity, with the RPC handling a conflict safely and returning a clear “already submitted” result. Confirm that retrying after a network timeout cannot create a second submission.

## 3. Existing safeguards and limitations

- The frontend refreshes the live activity list before opening a submission and refuses to proceed if that refresh fails.
- The database function checks that the access code resolves to a student, that the activity belongs to the student's class, and that the activity is live.
- The current function body performs an existence check before inserting a submission.
- These checks are based on static code/function-body review, not on a live penetration test.
- No duplicate submission was intentionally attempted; no records were written or changed.

## 4. Future acceptance checks

1. Logout clears access code, session object, history, games, activities, messages, and related visible content.
2. Signing in as a second test student cannot reveal the first student's cached data.
3. A slow response from the first student's request cannot repopulate data after logout/account switching.
4. Two simultaneous submissions for the same student/activity create at most one record.
5. Retrying after a simulated timeout does not create duplicate records or duplicate points.
6. Closed, inactive, wrong-class, and unknown activities are rejected server-side.
7. The database returns a clear result for a duplicate submission without exposing another student's data.

## 5. Environment gate

The currently available Supabase project reference `askhdgmjqezvwavfhqzj` was observed with the dashboard environment label `PRODUCTION`. The account is at the Free plan's two-project limit, and the user has ruled out upgrades, new projects/branches, pausing/deleting projects, and configuration changes. Do not execute SQL, migrations, or write tests against this project. Keep the review at documentation stage until a genuinely isolated TEST database is available.
