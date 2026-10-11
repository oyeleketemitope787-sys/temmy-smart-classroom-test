# TEST-Only Database Function Inventory and Review Queue

**Status:** Static review inventory; not a database permission audit or deployment approval.  
**Repository:** `oyeleketemitope787-sys/temmy-smart-classroom-test`, branch `main`  
**Safety:** Read-only review and documentation only. No SQL was executed, no database rows or settings were changed, and Production was not modified.

## Scope and confidence

This inventory combines the function bodies previously shared for review with the two migration files present in this TEST repository. It does not prove that the currently deployed database definitions match those files, and it does not establish the effective privileges of deployed functions. Those checks remain blocked until an isolated TEST database is available.

## Function-by-function review queue

| Function | What the reviewed body does | Outstanding review item | Current status |
|---|---|---|---|
| `verify_student_access_code` | Verifies a submitted code against a stored bcrypt-style hash using `extensions.crypt`; checks access/student active state. | Confirm execution grants, owner, fixed search path, safe return fields, brute-force/rate-limit protections, and that errors do not reveal secrets. | Needs permission review and safe tests |
| `student_portal_login` | Verifies the code, checks the class is active, updates last-login timestamps, returns student/class identity. | Confirm grants/search path and that only the intended student's minimal profile is returned. Check inactive class/student behavior. | Needs permission review and safe tests |
| `get_student_live_activities` | Resolves the student from the code and returns live, active activities for that student's class, joined to that student's record. | Verify function signature/return columns, grants, ownership, search path, student scoping, and behavior for no/invalid code. | Body reviewed; deployed permissions unverified |
| `get_student_point_history` | Called by the frontend with the student access code to load point history. | Full function body and grants must be reviewed; confirm results are limited to the student and do not leak teacher/classmate records. | Incomplete review |
| `get_student_game_sessions` | Verifies the student code and returns unexpired, unused sessions including the session token and game identifier. | Confirm minimal token exposure, grants/search path, active class/student checks, and no cross-student session disclosure. | Body reviewed; permissions unverified |
| `generate_student_access` | Requires an authenticated teacher, checks student/class activity and ownership, generates an uppercase access code, stores a hash, returns the code once. | Verify EXECUTE grants, function owner/search path, randomness and collision handling, rate/rotation policy, and that a teacher cannot generate codes for another teacher's students. | Body reviewed; permissions unverified |
| `start_teacher_game_session` | Requires authenticated teacher; validates game ID, active class ownership and active student; inserts a session token with a 30-minute expiry. | Validate game IDs against allowed games; verify grants, owner/search path, student/class relationship, token entropy and least-privilege return. | Body reviewed; permissions unverified |
| `record_student_game_result` (currently described function) | Locks a session, checks expiry/use/game match, claims it, and inserts points in the same transaction. | The reviewed deployed-body excerpt capped inserted points but did not clearly reject null inputs or score above max; caller-controlled game name/maximum were not constrained to a specific official game. The hardened migration proposes stronger checks but remains review-only. | Critical; migration not executed |
| `record_student_punctuality` | Validates status and nonnegative points, checks class ownership and student membership, then inserts/updates punctuality and a point delta. | Verify all grants/ownership/search path, unique constraint and concurrent updates, idempotency, and transaction atomicity between attendance and point ledger. | Body reviewed; concurrency/permissions unverified |
| `submit_student_activity` | Verifies the student code, activity/class relationship and live status, checks for an existing submission, then inserts a submission. | Verify database uniqueness or other race protection against concurrent duplicates; ensure returned data and error messages are safe and grants are least-privilege. | Body reviewed; race protection unverified |

## Cross-cutting checks required for every privileged function

For each function, capture the deployed signature and verify:
1. Whether it is `SECURITY DEFINER` or `SECURITY INVOKER`, and whether that choice is necessary.
2. Function owner and exact EXECUTE grants to `PUBLIC`, `anon`, `authenticated`, and any service role.
3. A fixed, safe `search_path` for privileged functions and safe schema CREATE privileges.
4. Input validation for NULL, empty strings, invalid IDs, unauthorized ownership, and inactive/expired entities.
5. Minimum return data; no raw access codes, hashes, or reusable tokens in logs or unnecessary results.
6. Atomicity and concurrency behavior for multi-step writes.
7. Rate limiting or abuse controls for access-code verification.
8. Tests showing one teacher/student cannot read or change another teacher/student's data.

## Migration-file review notes

The TEST repository currently contains two migration files:
- `202610090001_secure_game_result_recording.sql`
- `202610090002_harden_grade3_game_result_recording.sql`

Both are code files, not proof of deployment. The second explicitly says **REVIEW FILE ONLY. DO NOT EXECUTE THIS MIGRATION YET**, identifies game `grade3-temmy-number-challenge`, official maximum score 15, and warns never to run it against project `askhdgmjqezvwavfhqzj` or a branch labelled PRODUCTION.

The second file includes a transaction, fixed `search_path`, explicit argument bounds, student/class revalidation, session locking/consumption, and explicit EXECUTE grants. These are positive design features, but function ownership, actual environment, table constraints, and integration behavior remain unverified.

## Recommended order of work

1. **Keep current environment unchanged.** Do not run SQL against the project labelled PRODUCTION.
2. **Review read-only policy expressions and deployed function metadata** only when a safe, approved route exists.
3. **Resolve the isolated TEST environment constraint** without upgrading, creating a new project/branch, pausing, deleting, or changing project settings against the user's stated constraints.
4. **Only after isolation is verified**, run controlled tests for unauthorized access, expired/used sessions, duplicate/concurrent submissions, score bounds, attendance point deltas, and grading atomicity.
5. Record actual evidence for each test. Do not mark a function “passed” based solely on reading its source.

## Current conclusion

Several functions have sensible ownership checks and input validation in the reviewed bodies. However, the audit is incomplete because effective deployed grants, complete policy expressions, concurrency constraints, and live integration tests have not been verified. **No launch/security sign-off is implied.**
