# Student Access Code Persistence — Approved TEST Implementation Specification

**Status:** Approved behaviour; implementation design only. Not deployed to the database.
**Repository:** `oyeleketemitope787-sys/temmy-smart-classroom-test`, branch `main`
**Environment safety:** The current TEST website has been observed querying Supabase project `askhdgmjqezvwavfhqzj`, whose dashboard label was reported as PRODUCTION. Do not run migrations, alter RPCs, or write credential data against that project. Production remains untouched.

## 1. Required teacher experience

Every student must have one active, unique access code associated with that student's record and class.

The teacher's student register must provide:
- Student name and class association.
- Current access code visible on demand in the teacher portal.
- A Copy action that copies the current code without changing it.
- A separate Regenerate action protected by a confirmation step.
- A visible updated code immediately after the server confirms successful regeneration.

The code must remain the same after page refresh, navigation, teacher sign-out/sign-in, and ordinary viewing/copying. It must not be regenerated as a side effect of viewing.

## 2. Regeneration contract

Regeneration is an intentional credential rotation:
1. Teacher is authenticated and owns the student's active class.
2. Teacher explicitly chooses Regenerate and confirms.
3. Server generates a cryptographically random code, stores its verifier and recoverable encrypted representation atomically, and invalidates the previous verifier in the same transaction.
4. Server returns the new code only to the authorised teacher for that one successful operation.
5. UI immediately replaces the previously displayed code with the returned code and updates its cached current-code value.
6. If the server operation fails, the old code remains valid and visible; the UI must not show a speculative new code.
7. Repeated clicks/retries must not silently rotate multiple times. Disable the action while pending and handle uncertain network outcomes by re-fetching the current code before offering another rotation.

## 3. Security and storage requirements

The current reviewed design stores a bcrypt-style hash and a non-secret code hint. A one-way hash is suitable for student login verification but cannot be used to recover the original code for teacher display.

Do not store access codes as unrestricted plaintext. The implementation needs:
- Existing bcrypt-style verifier retained for student login.
- A separately encrypted recoverable code value, encrypted server-side using a key held outside ordinary application tables (for example, a Supabase Vault secret).
- No encryption key or service-role key in browser JavaScript, Git, SQL migration literals, or client-visible settings.
- Server-side retrieval RPC that authenticates the teacher, proves ownership through student -> class -> teacher, decrypts only that student's current code, and returns the minimum necessary fields.
- Regeneration RPC with the same ownership checks and transactionally updates verifier + encrypted value.
- Fixed safe search_path, least-privilege EXECUTE grants, safe error messages, and rate/abuse controls.
- No raw code, decrypted value, hash, or key in logs, analytics, or error telemetry.
- Code rotation invalidates the old code for student login immediately.

## 4. Frontend changes required

The current `index.html` implementation has these behaviours:
- `openStudentCode(id)` calls `generate_student_access_code`, so viewing a code currently rotates it.
- `loadCloudClasses()` selects student rows and maps `student_code_hint`, not a recoverable code.
- `renderStudents()` currently offers a menu action labelled by the translation key `students.generateAccessCode`.
- `openAddStudent()` calls `generate_student_access_code` once after inserting the student and shows the returned code in the one-time confirmation.

After the backend contract is deployed in an isolated TEST database:
- Change the student row menu to separate **View / Copy Access Code** and **Regenerate Access Code** actions.
- View / Copy must call the non-rotating retrieval RPC.
- Regenerate must confirm, call the rotation RPC, then replace the displayed code only after a successful response.
- Add a persistent teacher-only code panel or student-register column with a Copy button.
- After student creation, retain the returned code in the teacher UI and ensure it can subsequently be retrieved through the authorised retrieval RPC.
- Preserve all existing student history, class, points, portal login, and multilingual behaviour.
- Do not put access codes in localStorage, URL parameters, or persistent browser caches.

## 5. Existing function and environment facts

The repository's `docs/TEST_ONLY_DATABASE_FUNCTION_INVENTORY.md` describes a reviewed function named `generate_student_access` that hashes and returns a code once. The current frontend calls `generate_student_access_code`. These names/signatures must be reconciled against the actual deployed function catalog before writing a migration.

The inventory explicitly states that it is a static review, not proof that deployed function definitions or grants match reviewed source. The repository's master audit tracker records the current Supabase reference as `askhdgmjqezvwavfhqzj`, with the dashboard label reported as PRODUCTION, and marks isolated TEST database access as blocked.

## 6. Required gate before SQL or UI integration

Do not execute SQL or change the connected cloud database until an isolated TEST database is established and verified. In that isolated environment:
1. Capture actual table columns, constraints, indexes, triggers, function signatures/bodies, owners, search_path and EXECUTE grants.
2. Identify the actual student access-code hash storage and login verification path.
3. Confirm Supabase Vault availability and provision the encryption secret through the secure dashboard/secret-management path (never commit the secret).
4. Write and review a migration matching the actual schema and current login verifier.
5. Test create, retrieve, copy, refresh, sign-out/sign-in, rotate, old-code rejection, new-code acceptance, failed rotation rollback, cross-teacher denial, inactive student/class denial, and concurrent rotation.
6. Only then wire the frontend to the verified RPC names and deploy to the TEST website.

## 7. Acceptance criteria

- Viewing/copying a code never changes it.
- Same code remains available after reload and teacher re-authentication.
- Regeneration replaces the teacher-visible code immediately after server success.
- Previous code is rejected after successful regeneration; new code works.
- Failed regeneration leaves previous code valid and visible.
- Teacher A cannot retrieve or rotate Teacher B's student's code.
- No plaintext code or encryption key is stored in an unprotected database field or exposed in client storage.
- Production repository and Production database remain untouched.
