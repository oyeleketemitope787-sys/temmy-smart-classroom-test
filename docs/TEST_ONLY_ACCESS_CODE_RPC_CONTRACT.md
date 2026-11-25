# Student Access Code RPC Contract — TEST Review Draft

**Status:** Design contract only. Not executable SQL and not deployed.
**Target:** Isolated TEST Supabase project only, after project identity and schema are verified.
**Production safety:** Do not apply to project ref `askhdgmjqezvwavfhqzj` or any project/branch labelled PRODUCTION.

This contract turns the approved behaviour in `TEST_ONLY_STUDENT_ACCESS_CODE_PERSISTENCE_SPEC.md` into an API boundary. It deliberately does not assume table or column names beyond facts already documented in the repository.

## 1. Required RPC operations

### A. Read current code — `get_student_access_code`

Input:
- `p_student_id uuid`

Success result (single row):
- `student_id uuid`
- `access_code text`
- `updated_at timestamptz` (optional if a reliable rotation timestamp exists)

Requirements:
- Require an authenticated teacher session.
- Resolve the student and prove ownership through the student's class and the class's teacher ID, using the actual verified schema.
- Reject missing, inactive, or unassigned students/classes.
- Decrypt only the current student's encrypted code on the server.
- Return no hash, ciphertext, encryption key, or unrelated student fields.
- Must be read-only: no code generation, hash update, timestamp update, or rotation side effect.
- Deny execution to PUBLIC/anon; grant only the minimum required authenticated role.

### B. Rotate current code — `regenerate_student_access_code`

Input:
- `p_student_id uuid`

Success result (single row):
- `student_id uuid`
- `access_code text`
- `updated_at timestamptz` (optional)

Requirements:
- Require an authenticated teacher and prove the same student/class ownership as the read RPC.
- Generate a cryptographically secure, sufficiently long code; enforce uniqueness/collision handling.
- In one transaction, replace the student login verifier and encrypted recoverable value together.
- Keep the existing student-login verification contract compatible.
- Return the new plaintext code only to the authorised teacher for this successful call.
- A failed operation must leave the old verifier and encrypted value unchanged.
- Use row-level locking or equivalent concurrency control so simultaneous rotations cannot produce an ambiguous active code.
- Never return the old code, hash, ciphertext, key, or unrelated student data.
- Deny execution to PUBLIC/anon; grant only the minimum required authenticated role.

## 2. Encryption and secret handling

- Preserve the one-way password hash used by student login.
- Store a separately encrypted recoverable code value; never store the recoverable code in an unrestricted plaintext column.
- Keep the encryption secret in a server-side secret store (for example, Supabase Vault if available and configured).
- Do not place secrets in browser JavaScript, SQL literals, Git, localStorage, URL parameters, analytics, or logs.
- Confirm the actual supported encryption/decryption mechanism and permissions in the isolated TEST project before implementation.

## 3. Frontend behaviour mapped to the contract

| Teacher action | Required call | UI result |
|---|---|---|
| View code | `get_student_access_code` | Display current code; no rotation |
| Copy code | Use currently retrieved code | Copy only; no RPC that changes credentials |
| Regenerate | Confirm, then `regenerate_student_access_code` | Replace displayed code only after server success |
| Refresh / sign in again | `get_student_access_code` when teacher opens code panel | Same current code is returned |
| Rotation fails | No optimistic replacement | Keep old displayed code; show safe error |

The existing `openStudentCode(id)` must not call the generator. The current frontend and documented inventory disagree on the generator name (`generate_student_access_code` versus `generate_student_access`); resolve the actual deployed catalog before changing this integration.

## 4. Schema and deployment gates

Before converting this contract into SQL, capture from the isolated TEST database:
1. Exact student, class, teacher relationship and active-state columns.
2. Existing access-code hash and hint columns, constraints, indexes and triggers.
3. Full deployed definitions/signatures of `generate_student_access`, `generate_student_access_code`, `verify_student_access_code`, and `student_portal_login` (where present).
4. Function owners, SECURITY DEFINER/INVOKER settings, fixed search paths, and EXECUTE grants.
5. Whether Supabase Vault is enabled and a secure secret can be provisioned without exposing it to the client.
6. Existing login and class ownership semantics, including inactive student/class handling.

Do not infer these details from this document or the static migration files. The repository inventory explicitly says it is not proof of the deployed catalog.

## 5. Required isolated-TEST verification

- Teacher can retrieve their own student's current code.
- A second teacher cannot retrieve or rotate that code.
- Viewing and copying do not change the code.
- Code remains the same after refresh and teacher sign-out/sign-in.
- Successful rotation returns the new code and immediately invalidates the old code for login.
- Failed rotation preserves the old code and login access.
- Concurrent rotations serialize safely.
- Inactive student/class and unowned student requests are denied.
- No plaintext code, hash, ciphertext, or secret is exposed in logs or browser storage.

## 6. Current implementation status

- Approved behaviour specification exists.
- This RPC contract is a review draft.
- No access-code RPC migration has been written or executed.
- No access-code database rows or secrets have been changed.
- Frontend integration is intentionally pending the verified RPC contract and isolated TEST database.
