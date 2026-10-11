# Temmy Smart Classroom — TEST-Only Pre-Launch Action Plan

**Status:** Audit plan only — NOT launch approval  
**Scope:** TEST repository documentation and read-only review findings  
**Safety boundary:** Do not modify Production, run SQL, alter database records, change Supabase settings, create branches/projects, pause/delete projects, or upgrade a plan as part of this plan. The currently inspected Supabase project `askhdgmjqezvwavfhqzj` is dashboard-labelled PRODUCTION, so it is not a safe isolated test database.

## Executive decision

**Do not declare launch-ready yet.** Several user-facing flows have been observed working, and two TEST-branch frontend improvements were committed. However, critical grading/point-accounting and access/session controls still require a safe isolated test environment and evidence-based verification.

The current plan is deliberately split into:
1. **P0 — integrity and security gates**
2. **P1 — student/teacher experience and session hygiene**
3. **P2 — final evidence and release checklist**

## P0 — Must be resolved before launch

### P0.1 — Establish a genuinely isolated TEST database
- [ ] Obtain an explicitly isolated TEST Supabase environment through an approved route that does not require upgrading, creating another project, creating a branch, or changing the existing project.
- [ ] Before any write test, independently verify the project reference, dashboard environment/branch, app configuration, and target database.
- [ ] If isolation cannot be established under the current constraints, keep database-dependent checks blocked; do not substitute the existing project labelled PRODUCTION.
- **Evidence so far:** The TEST site's configuration points at project `askhdgmjqezvwavfhqzj`; the dashboard labels that project PRODUCTION. A prior new-project dialog was cancelled.
- **Gate:** No SQL or data-mutating test until the isolation gate is satisfied.

### P0.2 — Make grading and point accounting atomic
- [ ] Replace the frontend's separate activity-record update and point-transaction insert with a single server-side atomic operation.
- [ ] Verify that the activity record exists and belongs to the teacher/activity before changing it; reject a zero-row or unauthorized update.
- [ ] Enforce integer scores in the range 0 through the activity maximum. Reject fractional input instead of silently flooring it.
- [ ] Calculate the point delta from the previously saved score and new score exactly once; repeated saves must not award points twice.
- [ ] If any operation fails, all grading and ledger changes must roll back together.
- [ ] Test first grading, increasing a mark, reducing a mark, same-mark resave, invalid/fractional/out-of-range marks, unauthorized activity, and injected failure.
- **Evidence so far:** Current frontend uses separate requests and attempts a best-effort rollback if the ledger insert fails; rollback success is not checked and the prior `completed_at` value is not restored. A fractional score is silently floored. These are code-review findings, not proof that data corruption has occurred.
- **Gate:** Pass all tests in isolated TEST before launch.

### P0.3 — Harden game-result recording at the database boundary
- [ ] Review and validate the server function's input handling for null, negative, over-maximum, wrong-game, expired, reused, or mismatched sessions.
- [ ] Enforce the official question count/game identifier on the server, not just in the browser.
- [ ] Ensure session consumption and point-ledger insertion are atomic and replay-resistant.
- [ ] Review function execution grants and `search_path` settings before any approved deployment.
- [ ] Run the acceptance cases in an isolated TEST database only.
- **Evidence so far:** The inspected database function caps the points inserted but may retain caller-supplied score metadata above the maximum; null handling and grants/search-path need further verification. A hardened migration file exists as review-only documentation/code and must not be executed against the current project.
- **Gate:** Do not execute the prepared migration or change the current database as part of this audit.

### P0.4 — Verify student access and session protections
- [ ] Confirm student-code verification has appropriate rate limiting/abuse controls.
- [ ] Verify game session tokens cannot be replayed, reused, or accepted for a different student/game.
- [ ] Review whether tokens in query strings can leak through browser history, logs, referrers, or copied URLs; adopt a safer transport if needed.
- [ ] Confirm function grants are least-privilege and privileged functions use a fixed safe search path.
- [ ] Verify inactive students/classes and expired codes/sessions are rejected.
- **Evidence so far:** Access codes are held in the client session and a game token is passed in the URL. The frontend clamps scores, but that is not a security boundary. No penetration or replay testing has been performed.
- **Gate:** Security tests require an isolated environment; do not test by altering existing records.

### P0.5 — Enforce duplicate-submission protection under concurrency
- [ ] Inspect existing database constraints and function logic for duplicate submissions.
- [ ] Ensure uniqueness is enforced at the database level where the product rules require one submission per student/activity.
- [ ] Test two near-simultaneous submissions, retries after a timeout, and resubmission after a failed response.
- **Evidence so far:** Frontend pre-checks and database-side duplicate checking were observed, but database uniqueness/race protection has not been verified.
- **Gate:** No live duplicate-submission experiments against the current project.

## P1 — Important student/teacher experience and session hygiene

### P1.1 — Clear cached student data on logout
- [ ] On logout, clear the student session and all student-specific in-memory caches, including activity history, game sessions, and messages.
- [ ] Ensure no previous student's information is rendered after logout or a second student's login.
- [ ] Test logout, refresh, back navigation, and switching between two test student accounts in isolated TEST.
- **Evidence so far:** The logout handler clears the active session and activity list, but does not explicitly clear history, game-session, and message caches.

### P1.2 — Verify activity feedback and current status
- [x] Refresh live-activity data before opening an activity so stale cached activity state is not blindly trusted.
- [x] Show a warning when a cached activity/result cannot be verified because the activity is no longer available.
- [x] Display saved teacher feedback in the teacher's submission monitor.
- [ ] Verify that scored submissions are clearly labelled as scored/graded for students and teachers, rather than only showing a generic submitted state where applicable.
- [ ] Test live, submitted, scored, closed, and unavailable states without changing the existing reviewed record.
- **Evidence so far:** The two frontend improvements above were committed to the TEST repository and fetched back for verification. The Student Portal Test was observed displaying 5/5 and feedback; the teacher monitor showed Scored 5/5. This is a limited UI observation, not a full acceptance test.

### P1.3 — Confirm assessment lifecycle and feedback consistency
- [ ] Verify a teacher can see the student's saved answer, score, and feedback after reopening the submission.
- [ ] Verify the student sees the exact awarded mark and feedback after refresh/relogin.
- [ ] Confirm closing an activity prevents new submissions but does not silently erase a prior result.
- [ ] Confirm an RPC/network failure gives a clear message and does not present stale data as newly verified.
- **Evidence so far:** A previously reviewed Student Portal Test showed a saved 5/5 and feedback. Do not regrade, reset, or change this existing record merely to retest it.

### P1.4 — Review access control and row-level security
- [ ] Read-only inspect policies for every table and RPC used by teacher/student flows, including activity records and student access/session tables.
- [ ] Confirm teachers can access only their own classes, students, activities, submissions, and point transactions.
- [ ] Confirm student-facing functions expose only that student's permitted data.
- [ ] Verify anonymous/authenticated grants are intentional and match the function's intended caller.
- **Evidence so far:** RLS was observed enabled on classes, students, point transactions, and student activity records. Some policy expressions and function grants remain unverified; RLS being enabled alone does not establish correctness.

## P2 — Release evidence and operating readiness

- [ ] Maintain a test log with test case, expected result, actual result, date, environment reference, and pass/fail.
- [ ] Separate **observed working**, **code-reviewed**, **not tested**, and **blocked by environment** items.
- [ ] Confirm class/student creation, login/logout, awarding points, point history, activities, grading/feedback, and games using safe test identities and an isolated database.
- [ ] Confirm mobile/desktop layout and user-visible error messages.
- [ ] Verify a rollback/recovery approach for application changes before release.
- [ ] Review all changes on the TEST repository and explicitly approve any proposed Production release separately.
- [ ] Keep the prepared game hardening migration review-only until an isolated target is confirmed and deployment is explicitly authorized.

## Already observed or completed (limited scope)

- Student Portal Test was observed showing **5/5** and the saved feedback “Good attempt. Keep practising.”
- Teacher activity monitor was observed showing **Scored · 5/5**.
- TEST frontend was updated to refresh activity state before opening an activity and to warn when the result cannot be re-verified.
- TEST frontend was updated to display saved teacher feedback in the teacher monitor.
- Documentation-only reviews exist for atomic grading, frontend grading risks, launch readiness, game/session access, and logout/duplicate-submission risks.

These observations do **not** mean the whole platform has passed launch acceptance testing.

## Explicitly out of scope for this plan

- Any change to the Production repository or Production application.
- Any SQL execution or data mutation against `askhdgmjqezvwavfhqzj`.
- Any Supabase settings, project, branch, billing, pause, or deletion change.
- Regrading or changing the already-reviewed Student Portal Test record.
- Claiming security, concurrency, or database integrity tests passed when they have not been run in an isolated environment.

## Release decision rule

**Launch approval remains pending** until the P0 items have been resolved and supported by passing evidence in a verified isolated TEST environment. If the existing account/project constraints prevent safe isolation, preserve the current state and report the blocked tests clearly rather than weakening the safety boundary.
