# Temmy Smart Classroom — Final Pre-Launch Checklist (TEST Only)

**Date:** 2026-10-11  
**Status:** NOT APPROVED FOR PRODUCTION RELEASE  
**Scope:** Final consolidation of TEST-only source review, reported dashboard observations, and limited UI walkthroughs.  
**Safety boundary:** No Production code changed. No SQL executed, no database records/settings changed, no project or branch created, no project paused/deleted, and no paid upgrade.

## Release decision

**Do not approve Production launch yet.** This is not a claim that the application is unusable or that data has been corrupted. It means critical data-integrity and security controls have not yet been validated with adequate evidence.

The TEST website currently points to Supabase project ref `askhdgmjqezvwavfhqzj`, whose dashboard was reported as labelled **PRODUCTION**. It is not an approved isolated test database. No database write test or migration may be run against it.

## A. Improvements already committed to TEST

- [x] Student activity state is refreshed before opening; the UI warns if an old result cannot be verified because the activity is no longer available.
- [x] Teacher submission monitoring displays saved feedback.
- [x] Student logout/login flow now clears student-specific in-memory caches and uses a session-generation guard to ignore stale asynchronous responses.
- [x] TEST localStorage cleanup that could remove Production-origin keys was removed; TEST reads/writes only the unique `temmySmartClassroomTestV1` key. Source inspection verified no old cleanup script or legacy storage reads/writes remain.
- [x] GitHub Pages deployment workflow completed successfully for the storage-isolation documentation commit (`b0dfc2b845589838d16d6f6391e63b4b3db3c59e`). The subsequent TEST `index.html` storage correction commit is `0f8101b95c12cf530d1fa5039c874d541f12d640`; source was fetched back and inspected.
- [x] Grade 3 game page removes the session query parameter after reading it, when the History API is available.
- [x] Grade 3 game page declares a `no-referrer` policy.
- [x] Offline scoring/security harness was run by the user and reported 14/14 simulated checks passing.

**Evidence limitation:** These source commits were fetched back from GitHub. The logout/stale-response patch and token cleanup have not been fully verified by browser runtime tests with multiple student accounts and a real game token. The offline harness simulates validation; it does not prove live database security.

## B. P0 — Required before release approval

### B1. Safe environment and deployment identity
- [ ] Identify an approved, genuinely isolated TEST database without violating the user's constraints.
- [ ] Independently verify app URL/configuration, Supabase project reference, dashboard environment, and target branch before any write test.
- [ ] If isolation cannot be achieved without an upgrade, new project/branch, pause/deletion, or prohibited settings change, keep database tests blocked. Do not use the current project labelled PRODUCTION as a substitute.

### B2. Grading and point-ledger atomicity
- [ ] Move grading record update and point transaction insertion into one server-side atomic operation.
- [ ] Verify activity/submission ownership and require an actual authorized row to be updated.
- [ ] Reject non-integer marks; enforce 0 through activity maximum on the server.
- [ ] Ensure increases, reductions, same-score saves, retries, and failures cannot double-award points or leave the grade and ledger inconsistent.
- [ ] In isolated TEST, test first grade, increase, decrease, same-score resave, zero, maximum, fractional, negative, over-maximum, unauthorized record, and injected failure.
- **Known source finding:** Current frontend uses separate requests for grade update and point-ledger insert. Its rollback is best-effort, unchecked, and does not restore the prior `completed_at`; fractional input is floored. This is a risk identified by review, not proof of existing corruption.

### B3. Game-result integrity
- [ ] Verify deployed `record_student_game_result` matches the reviewed intended implementation.
- [ ] Reject null, negative, over-maximum, wrong-game, wrong-name, and wrong-maximum submissions at the database boundary.
- [ ] Bind the official score to the fixed game question count; never award arcade bonuses as official points.
- [ ] Verify session expiry, single use, student/game binding, and concurrency behavior.
- [ ] Verify the session claim and point transaction are atomic.
- [ ] Review function owner, `SECURITY DEFINER`, fixed search path, schema privileges, table grants, and exact EXECUTE grants.
- [ ] Review the proposed `anon` and `authenticated` EXECUTE grants against the actual browser authentication flow; justify least privilege before deployment.
- [ ] Do not execute `202610090002_harden_grade3_game_result_recording.sql` against project `askhdgmjqezvwavfhqzj` or any environment labelled PRODUCTION.

### B4. Student access and session security
- [ ] Verify access-code RPC grants, function owner/search path, safe return fields, and protections against brute-force attempts/rate abuse.
- [ ] Verify inactive students/classes, expired sessions, used tokens, and cross-student/cross-game token use are rejected.
- [ ] Review all function return values and errors for unnecessary exposure of access codes, hashes, session tokens, or other student data.
- [ ] Verify token handling in a browser. URL cleanup and `no-referrer` are mitigations only: the token remains in the initial navigation URL and may reach hosting infrastructure logs or browser history before cleanup.
- [ ] Before public launch, consider a safer token-exchange design that avoids placing a bearer secret in the URL, or formally document residual risk after review.

### B5. Row-level security, RPC permissions, and tenant isolation
- [ ] Capture complete RLS policy expressions for all teacher/student tables and related data.
- [ ] Capture deployed RPC signatures, owners, security mode, search paths, effective EXECUTE grants, and relevant schema CREATE privileges.
- [ ] Verify views, helper functions, and privileged functions do not bypass intended teacher/student boundaries.
- [ ] Verify one teacher cannot read or change another teacher's classes, students, submissions, messages, attendance, or point transactions.
- [ ] Verify students can retrieve only their own permitted profile, activities, submissions, game sessions, messages, and point history.
- **Evidence limitation:** RLS was reported enabled on several core tables, but full policy expressions and effective deployed function privileges are not fully captured. RLS enabled alone is not a complete security proof.

### B6. Duplicate and concurrent submissions
- [ ] Inspect relevant unique constraints/indexes and function logic.
- [ ] Enforce required uniqueness at the database level, not only with a pre-insert check.
- [ ] Test near-simultaneous submissions, network retries, duplicate game result calls, and retries after uncertain responses in isolated TEST.

## C. P1 — User workflow and accessibility

- [ ] In a disposable browser profile, verify TEST creates/updates only `temmySmartClassroomTestV1` and leaves any Production-origin keys unchanged. Confirm the updated TEST page is served after deployment.
- [ ] Verify normal student login, logout, refresh, back navigation, and Student A → logout → Student B switching.
- [ ] Verify delayed history/game/activity/message responses cannot update the UI after logout or account switching.
- [ ] Verify messages, history, activities, and games render correctly after normal login and after recoverable RPC errors.
- [ ] Make submitted versus scored/graded states explicit and consistent in student and teacher views.
- [ ] Verify saved teacher feedback after refresh/reopen.
- [ ] Run desktop/mobile checks and resolve the reported form-field label accessibility issues.
- [ ] Check empty, loading, expired-session, offline, and server-error messages without modifying existing records.

## D. P2 — Release and recovery evidence

- [ ] Keep a dated acceptance-test log with environment identity, steps, expected result, actual result, and evidence.
- [ ] Document application rollback and database migration recovery strategy before any release.
- [ ] Review deployment diff and confirm only the intended repository/branch is targeted.
- [ ] Require explicit release approval after all P0 gates pass.
- [ ] Keep Production changes separate from TEST changes; do not copy a migration into Production based only on static review.

## E. Current evidence classification

| Area | Evidence level | Current disposition |
|---|---|---|
| Activity refresh and teacher feedback UI changes | Committed and fetched from TEST repo | Browser acceptance still needed |
| Student cache/session guard | Committed and statically checked | Runtime race tests still needed |
| Game URL cleanup/referrer policy | Committed and fetched | Mitigation present; initial URL exposure remains |
| Offline score harness | User-reported 14/14 simulated checks | Not live database proof |
| Database functions and proposed migration | Static body/file review | Deployed metadata and integration unverified |
| RLS and RPC permissions | Partial dashboard observations and review notes | Incomplete |
| Grading/points atomicity | Frontend source review | Critical correction and isolated testing required |
| Production readiness | No P0 acceptance evidence in isolated TEST | **Not approved** |

## Next action under current constraints

Continue with read-only source review and browser checks in a disposable profile. Do not write to the database currently labelled PRODUCTION, execute SQL, or claim database controls have passed. The TEST storage correction is source-verified; browser acceptance remains pending. If a genuinely isolated TEST environment is unavailable under the user's constraints, keep database-dependent release gates explicitly blocked and preserve the current system unchanged.
