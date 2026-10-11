# TEST-Only Student Session Lifecycle Review and Proposed Correction

**Status:** Static frontend code review; no application code changed in this document commit.  
**Repository:** `oyeleketemitope787-sys/temmy-smart-classroom-test`, branch `main`  
**Safety:** No SQL or database writes, no Supabase settings changes, and no Production changes.

## Scope inspected

The current TEST `index.html` was fetched from GitHub and the following paths were reviewed:
- `studentPortalLogin()`
- `studentPortalLogout()`
- `loadStudentPortalHistory()`
- `loadStudentPortalGames()`
- `loadStudentPortalActivities()`
- `loadStudentMessages()`
- `renderPortal()`

This is a static review only. No live login/logout or account-switching tests were performed.

## Confirmed findings

### F1 — Logout does not explicitly clear all student-specific caches

Current handler:
```js
function studentPortalLogout(){
  studentPortalSession=null;studentPortalActivities=[];
  const input=document.getElementById('studentAccessCode');if(input)input.value='';
  const msg=document.getElementById('studentPortalLoginMsg');if(msg)msg.textContent='';
  renderPortal();
}
```

It clears the active session and activities, but does not explicitly clear:
- `studentPortalHistory`
- `studentPortalGames`
- `studentPortalMessages`

Other functions may clear some caches under some conditions, but logout itself should synchronously clear every student-specific in-memory cache. This is important on shared classroom devices.

### F2 — Asynchronous responses can outlive the session that initiated them

Several loaders check `studentPortalSession` before starting an RPC, await the response, and then write the response into global cache variables. The reviewed history and game loaders do not re-check that the same student session is still active after the await. Similar review is needed for activity and message loaders.

Potential sequence:
1. Student A starts loading history or games.
2. Student A logs out or another student signs in before the request completes.
3. Student A's earlier response returns and writes data into a shared cache after the session has changed.

This is a race condition identified by code inspection, not evidence that a leak has been observed in use. The fix should bind each response to the session identity that started it and discard stale results.

### F3 — Login flow does not visibly invalidate the previous session before verification

The current login function reads a code, calls `student_portal_login`, then sets `studentPortalSession` after success and loads history, activities and games. The reviewed snippet does not show an explicit in-flight login guard or request/session generation counter. The exact behavior of concurrent login clicks and switching accounts should be hardened and tested.

### F4 — Message loader has more than one asynchronous RPC

The message loader fetches messages, then calls `mark_student_messages_read`, then updates UI state. The active session should be checked again after each awaited call before storing/rendering results or marking messages read. This is particularly important if a student logs out or switches account during loading.

## Recommended correction design (not yet implemented)

1. Create one helper that clears all student-specific state:
   - set `studentPortalSession = null`
   - clear activities, history, games, and messages arrays
   - clear access-code input and login status
   - reset student portal content to the signed-out state
2. Use a monotonically increasing session/request generation number. Increment it on logout and whenever a new login attempt/session begins.
3. Each async loader captures the current generation and student ID (and, where needed, session object identity) before the RPC. After every `await`, return without updating global state or UI if the generation/session has changed.
4. On a new login attempt, prevent duplicate submissions and make account switching explicit. Do not leave the previous student's visible data in place while a different code is being verified.
5. After a successful login, load the student's data only for that new session. Handle each error without rendering data from a previous session.
6. On logout, clear caches synchronously before rendering the signed-out screen.
7. Do not store access codes or student-specific results in persistent browser storage. Keep credentials out of logs and user-visible error details where not needed.
8. Test in an isolated TEST environment: logout with each loader in flight, immediate A-to-B account switch, two rapid login clicks, slow/error responses, browser back/refresh, and messages completing after logout.

## Acceptance criteria

- After logout, no student name, points/history, activity, game session, or message from the previous session is displayed.
- A response started under Student A can never populate the UI/cache after Student A logs out or Student B becomes active.
- A delayed login response cannot overwrite a more recent login attempt.
- Message responses and read-status calls are ignored if the initiating session is no longer current.
- Normal login, history, activities, games and messages continue to work for the active student.
- No tests use the database project currently labelled PRODUCTION for write operations.

## Disposition

- **Code reviewed:** Logout does not explicitly clear all student caches; async loaders have potential stale-response races.
- **Recommended:** Implement centralized cache clearing and session-generation checks in TEST only, after reviewing the patch carefully.
- **Not done:** No frontend code change was made in this commit; no live behavior was claimed as verified.
- **Safety blocker:** Use only UI-safe review until a genuinely isolated TEST database is available. Database writes are not needed to document these frontend findings.
