# TEST-ONLY: Classroom Launch Readiness Checklist

**Purpose:** Keep launch checks organized while the Supabase environment remains unsafe for write testing.  
**Repository:** `oyeleketemitope787-sys/temmy-smart-classroom-test` only  
**Status:** Checklist/design only; not a release approval.  
**Safety:** No database writes, SQL, configuration changes, or Production edits are authorized by this document.

## A. Confirmed from the recent UI/code review

- [x] Student portal login and live-activity list were observed working in the TEST UI.
- [x] A student submission was visible in the portal.
- [x] Teacher monitor displayed the scored result and saved feedback after the TEST-only frontend commit.
- [x] The TEST repository contains a written atomic-grading design and a frontend audit.
- [x] Production repositories were not modified during these steps.

## B. Known risks that still need resolution or controlled verification

- [ ] Atomic grading: grade, feedback, and point-ledger adjustment must be one database transaction.
- [ ] Verify the database confirms exactly one assessment row was updated before reporting success.
- [ ] Reject fractional, null, negative, and above-maximum scores explicitly; do not silently floor a fractional score.
- [ ] Confirm rollback/transaction behavior and concurrency handling in a disposable isolated database.
- [ ] Inspect the actual RLS policies and grants for activity records and all RPCs before any migration.
- [ ] Confirm duplicate submissions are prevented by a database constraint or another race-safe mechanism, not only a pre-insert check.
- [ ] Confirm the teacher can access only their own classes, students, submissions, point transactions, and game sessions.
- [ ] Confirm access-code RPCs have suitable rate limiting/abuse controls and do not expose access-code hashes or tokens.
- [ ] Confirm game-result RPCs validate the authoritative game ID, score range, student/class relationship, session expiry, and one-time session consumption.
- [ ] Review whether the student activity card should distinguish **Submitted** from **Scored**. Currently, the UI can display SUBMITTED for a record that already has a score; this is a display clarity issue, not evidence that grading failed.
- [ ] Verify student-facing scores and teacher-facing scores agree, and that bonus/game points are not confused with assessment marks.
- [ ] Verify sign-out/session expiry behavior on teacher and student portals without using real student records.

## C. Release gate

Do not call the grading and game-result flows production-ready until the critical security and accounting checks have passed in a genuinely isolated TEST Supabase project with disposable fixtures.

Current constraints remain: the available project reference `askhdgmjqezvwavfhqzj` was observed with the dashboard label `PRODUCTION`; the Free plan has two existing projects; the user does not want an upgrade, new project/branch, pause/delete operation, or configuration changes. Therefore, use read-only review only until a safe isolated test target is available.

## D. Safe next action

Continue read-only review of the TEST frontend and documentation. Do not execute migrations, issue SQL, change student data, or run any write-based acceptance test against the currently available Supabase project.
