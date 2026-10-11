# Temmy Smart Classroom — Master Audit Tracker (TEST Only)

**Last updated:** 2026-10-11  
**Status:** Work in progress; not launch approval  
**Scope:** TEST repository documentation and static/read-only findings  
**Safety boundary:** No Production changes, no SQL execution, no database writes, no Supabase configuration changes, no new projects/branches, no pause/deletion, and no paid upgrade as part of this audit.

## Status legend

- **Observed working:** A specific UI behavior was seen during a limited walkthrough. This is not broad acceptance-test proof.
- **Code reviewed:** Source/function body was inspected; live behavior and deployed permissions may still be unverified.
- **Action needed:** A correction or further review is required.
- **Blocked:** Safe verification depends on an isolated TEST database or access to read-only deployed metadata that has not been captured.
- **Done (documentation):** The finding has been recorded; the underlying technical risk may remain open.

## Priority 0 — integrity and security gates

| ID | Issue / control | Evidence so far | Required next action | Status |
|---|---|---|---|---|
| P0-01 | Isolated TEST database | TEST app points to Supabase ref `askhdgmjqezvwavfhqzj`; dashboard label reported as PRODUCTION. | Do not write to it. Establish a safe isolated TEST route that respects the no-upgrade/no-new-project/no-branch/no-settings-change constraints, or mark database tests blocked. | **Blocked** |
| P0-02 | Atomic grading and points | Frontend performs activity-record update and point-transaction insert separately; rollback is best-effort, unchecked, and does not restore prior `completed_at`. | Replace with a single server-side atomic operation after isolation; test first grade, score increase/decrease, same-score save, invalid scores, authorization and failures. | **Action needed / blocked** |
| P0-03 | Strict game-result validation | Reviewed current function excerpt does not clearly reject null inputs or over-maximum scores; game name/max can be caller-controlled. | Review and test server-side bounds, fixed official game ID/name/max, active student/class relationship, expiry, and one-use session behavior. Hardened migration remains review-only. | **Action needed / blocked** |
| P0-04 | Student access-code abuse controls | Code verification uses a stored hash in reviewed body; rate limiting and effective grants not verified. | Verify rate limiting/rotation, minimal responses, grants, owner and safe search path in isolated environment. | **Action needed / blocked** |
| P0-05 | Game-session token exposure/replay | Token is placed in the game URL query string; no replay or leakage test performed. | Review URL/history/referrer exposure, one-use semantics, token lifetime, student/game binding, and least-privilege RPC grants. | **Action needed / blocked** |
| P0-06 | Duplicate activity/game submissions | Frontend/DB function duplicate checks were observed in source, but database uniqueness/concurrency protection is unverified. | Inspect constraints and test simultaneous/retried submissions in isolated TEST. | **Action needed / blocked** |
| P0-07 | Privileged RPC permissions | Function owners, effective EXECUTE grants, schema CREATE privileges, and deployed search paths are not fully captured. | Read-only capture of deployed signatures/owners/grants/policies when safe; verify least privilege and fixed search paths. | **Blocked / incomplete evidence** |
| P0-08 | Cross-teacher/student data isolation | RLS was reported enabled on several core tables, with teacher-scoped policy patterns. Full expressions and all related tables/functions remain unverified. | Review complete policies, views, function return data and grants; test unauthorized access in isolated TEST. | **Action needed / blocked** |

## Priority 1 — student/teacher workflow

| ID | Issue / control | Evidence so far | Required next action | Status |
|---|---|---|---|---|
| P1-01 | Logout cache cleanup | Logout clears active student session and activity list; history/game/message caches are not explicitly cleared. | Clear all student-specific caches; test logout, refresh, back navigation and switching accounts. | **Action needed** |
| P1-02 | Feedback in teacher monitor | Frontend patch displays saved teacher feedback in the monitor. | Verify feedback after refresh/reopen in a safe TEST run. | **Code change committed; limited verification** |
| P1-03 | Fresh activity verification | Frontend refreshes activity state before opening; warns if cached result cannot be reverified. | Verify live/submitted/scored/closed states and stale-network behavior in safe TEST. | **Code change committed; limited verification** |
| P1-04 | Scored status clarity | Student activity list may show a generic SUBMITTED badge even when a score exists. | Make scored/submitted status unambiguous; verify student and teacher views agree. | **Action needed** |
| P1-05 | Grading input validation | Fractional score input is floored rather than rejected. | Reject non-integer values explicitly in frontend and enforce integer bounds server-side. | **Action needed / tied to P0-02** |
| P1-06 | Attendance point deltas | Reviewed function validates status and nonnegative points and checks class/student relationship. | Verify atomicity, unique record behavior, concurrent updates, and no double-award. | **Code reviewed; tests blocked** |

## Priority 2 — evidence and release controls

| ID | Issue / control | Evidence so far | Required next action | Status |
|---|---|---|---|---|
| P2-01 | Test evidence log | Limited UI walkthroughs documented in conversation; no complete repeatable acceptance suite yet. | Maintain dated test cases with expected/actual results and environment identity. | **Action needed** |
| P2-02 | Desktop/mobile UX | Some screens were observed in browser, not a complete device/browser matrix. | Run a safe UI-only layout/error-message pass; avoid writes to existing records. | **Action needed** |
| P2-03 | Recovery/rollback plan | Documentation calls for a recovery plan; no release is approved. | Document app rollback and database migration rollback strategy before release. | **Action needed** |
| P2-04 | Release authorization | No P0 acceptance evidence in an isolated TEST environment. | Require explicit review/approval before any Production deployment. | **Pending** |

## Completed documentation (not equivalent to fixing issues)

- `docs/TEST_ONLY_PRE_LAUNCH_ACTION_PLAN.md`
- `docs/TEST_ONLY_RLS_AND_RPC_PERMISSION_REVIEW.md`
- `docs/TEST_ONLY_DATABASE_FUNCTION_INVENTORY.md`
- `docs/TEST_ONLY_ATOMIC_GRADING_DESIGN.md`
- `docs/TEST_ONLY_GRADING_FRONTEND_AUDIT.md`
- `docs/TEST_ONLY_CLASSROOM_LAUNCH_READINESS.md`
- `docs/TEST_ONLY_STUDENT_ACCESS_GAME_SESSION_REVIEW.md`
- `docs/TEST_ONLY_LOGOUT_DUPLICATE_SUBMISSION_REVIEW.md`

## Improvements already committed to TEST frontend

- Refresh activity state before opening a student activity; warn when an old result cannot be verified.
- Display saved teacher feedback in the teacher submission monitor.

These were committed to the TEST repository. No Production code or database was changed by these actions.

## Current user-visible observations (limited)

- Student Portal Test showed a saved score of 5/5 and feedback: “Good attempt. Keep practising.”
- Teacher monitor showed “Scored · 5/5”.
- These observations should not be used as permission to modify/regrade the existing record.

## Blocker decision

The dashboard-labelled PRODUCTION project must not be used for test writes. If an isolated environment cannot be established without a disallowed upgrade, new project/branch, pause/deletion, or configuration change, database-dependent testing remains **blocked**. Continue only with static review and safe, read-only UI checks.

## Launch rule

**Do not declare launch-ready** until all P0 items have passing evidence from a verified isolated TEST environment, P1 workflow issues are resolved or explicitly accepted, and a separate release review is approved.
