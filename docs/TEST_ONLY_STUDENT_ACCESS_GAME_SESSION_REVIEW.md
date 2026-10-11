# TEST-ONLY: Student Access and Game Session Review

**Status:** Read-only review of TEST repository code; no database access or write tests performed.  
**Repository:** `oyeleketemitope787-sys/temmy-smart-classroom-test`, branch `main`  
**Safety:** Findings and recommendations only. Do not execute SQL, alter Supabase configuration/data, or modify Production.

## 1. Student access-code handling

The student portal sends the entered access code to the `student_portal_login` RPC. On success, the frontend keeps the access code in the in-memory `studentPortalSession` object and reuses it for history, live activities, and game-session retrieval. This code review did not find use of browser localStorage for this session object.

**Risks / checks still needed**
- Access codes are bearer credentials: anyone who obtains one may be able to act as that student until the code is revoked/rotated or the backend otherwise blocks access.
- The database function should use safe permissions, narrowly scoped results, and suitable brute-force/rate-limit controls. The frontend cannot enforce these controls.
- Verify that logout or returning to the portal clears the student session object, access code, cached submissions, game sessions, and messages as appropriate. This needs a read-only code-path review and safe UI verification.
- Never log raw access codes, code hashes, or session tokens.

## 2. Game-session token is placed in the URL query string

The teacher dashboard obtains a `session_token` from `start_teacher_game_session` and builds a game URL with `?session=<token>`. The game reads the token using `new URLSearchParams(location.search).get('session')`, then submits it to the `record_student_game_result` RPC endpoint.

**Why this matters:** Query-string credentials can be exposed through browser history, copied/shared URLs, screenshots, or referrer information depending on the page and browser context. The token is intended to be short-lived and single-use according to the database function review, which reduces but does not eliminate exposure risk.

**Future hardening options to review:** Prefer exchanging the token for a short-lived game session without keeping the credential in the address bar; otherwise remove the token from browser history immediately after reading it, set a restrictive `Referrer-Policy`, avoid third-party assets on token-bearing pages, and ensure tokens are high-entropy, short-lived, bound to the correct student/game, and consumed once. Any implementation change must wait for a genuinely isolated TEST environment.

## 3. Client-side score is not a security boundary

The game client calculates `officialScore` from `correctCount` and clamps it to the question count before submitting. This is useful for normal UI behavior, but browser JavaScript can be modified by a user. The database function must independently validate the authoritative game ID, score bounds, max score, student/class relationship, session expiry, and single-use session state. The reviewed migration proposal contains stronger validation, but it remains unexecuted and must not be applied to the current project.

The player name typed into the game UI is presentation data; it must not be trusted as proof of student identity. Identity should come from the server-side session record.

## 4. Known limits of this review

- This was a static code review of the TEST repository, not a live security penetration test.
- The relevant RPC bodies and policies have not all been re-verified in an isolated database.
- No access-code guessing, token replay, duplicate submission, or write-based test was performed.
- No claim is made that an exploit has occurred.

## 5. Required future acceptance checks

1. Invalid, inactive, revoked, expired, and repeated access codes are handled safely.
2. Access-code verification is rate-limited or otherwise protected against guessing.
3. Student RPCs return only data for the authenticated/verified student's own class and records.
4. Student sign-out/portal reset clears in-memory student credentials and cached sensitive data.
5. A game session is bound to the intended student and allowed game.
6. Expired, unknown, wrong-game, and already-consumed session tokens are rejected.
7. Replaying the same game-result request cannot create another point transaction.
8. Invalid scores and client-supplied identity/name changes cannot inflate points or impersonate another student.
9. Token-bearing game URLs do not leak credentials to unrelated origins or unnecessary logs/history.

## 6. Environment gate

The available Supabase project reference `askhdgmjqezvwavfhqzj` was observed with the dashboard environment label `PRODUCTION`. The Free plan is at its two-project limit, and the user has ruled out upgrading, creating a project/branch, pausing/deleting projects, or changing existing project configuration. Therefore this document does not authorize migrations, SQL, live token tests, or any database writes.
