# TEST-Only Final Game Launch Flow Review

**Date:** 2026-10-11  
**Repository:** `oyeleketemitope787-sys/temmy-smart-classroom-test`, branch `main`  
**Status:** Static source review only — not launch approval  
**Safety boundary:** No database queries or writes were executed. No Supabase settings, records, projects, branches, or Production files were changed.

## Scope reviewed

- Teacher game launch path in `index.html`
- Student portal game-session loading and launch path in `index.html`
- Grade 3 game token handling and result submission in `test-games/grade3/temmy-number-challenge.html`
- The review-only Grade 3 hardening migration
- Existing session lifecycle and audit documentation

## Positive controls present in TEST source

1. Teacher launch requests a session through `start_teacher_game_session` and only builds a launch URL when a session token is returned.
2. Student portal loads game sessions through `get_student_game_sessions`; the page shows the session expiry and creates a game URL for the selected game.
3. The game page reads the session token into in-memory state, then removes the `session` query parameter from the visible URL when the History API is available.
4. The game page sets `<meta name="referrer" content="no-referrer">`.
5. The game has a local `submissionStarted` guard to prevent repeated submission from the same page instance.
6. The browser computes the official score from correct answers, clamps it to the question count, and keeps arcade bonuses separate.
7. The result RPC response is checked for an HTTP success and exactly one returned row before the UI says that a result was saved.
8. The TEST-only proposed migration uses server-side constants for the Grade 3 game ID/name/max score, rejects null/out-of-range inputs, locks and claims a session, checks expiry and active student/class relationships, and inserts the official point transaction within the same database transaction.

These are source-level observations, not proof of deployed database behavior.

## Important limitation: token still appears in the initial navigation request

Removing the query parameter after the game document loads reduces later exposure in the address bar, screenshots, copying, and subsequent navigation. The no-referrer policy reduces Referer-header leakage from requests made by the game page.

However, the initial navigation URL still contains the bearer token. It can therefore be present in the initial request to the static hosting provider and potentially in infrastructure access logs, browser history before replacement, or copied links. A policy declared inside the destination page cannot prevent the initial request URL from being sent to that destination's hosting server. The current mitigation is useful but does not eliminate URL-token exposure.

Before a public launch, consider a safer token exchange design that avoids placing a reusable bearer secret in a URL, or explicitly document and accept the residual risk after a security review. Do not implement or test a new exchange flow against the current Supabase project labelled PRODUCTION.

## Critical database-side controls still unverified

- The current deployed `record_student_game_result` definition may not match the review-only migration.
- Effective EXECUTE grants, function owner, function search path, schema CREATE privileges, table grants, constraints, and triggers have not been fully captured.
- The prepared migration grants EXECUTE to both `anon` and `authenticated`; this needs an explicit least-privilege justification against the real browser/authentication flow before any approved deployment.
- Rate limiting for student access-code verification has not been verified.
- Database-level protection against duplicate/concurrent activity submissions has not been established.
- No live replay, expiry, invalid-score, cross-student, or concurrency tests were performed.

## Recommended disposition

**Do not grant launch/security sign-off from this review alone.**

Keep the current Supabase project and all Production resources unchanged. The current project reference `askhdgmjqezvwavfhqzj` is dashboard-labelled PRODUCTION, so do not run the prepared migration or perform write tests there.

If an isolated TEST database cannot be obtained without violating the user's no-upgrade/no-new-project/no-new-branch/no-settings-change constraints, keep database-dependent verification blocked. Continue only with read-only source review and safe UI-only checks.

## Evidence classification

- **Static source reviewed:** launch paths, token cleanup/referrer policy, client submission guard, official score separation, proposed migration logic.
- **Committed and fetched:** source changes are present in the TEST repository.
- **Not verified:** browser runtime behavior with a real token, initial request/log exposure, deployed RPC privileges, live database atomicity, replay resistance, and integration acceptance.
