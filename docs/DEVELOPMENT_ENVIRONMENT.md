# TEST Development Environment

**Last verified:** 26 November 2026  
**Repository:** `oyeleketemitope787-sys/temmy-smart-classroom-test`  
**Working directory used during setup:** `/home/user/projects/temmy-smart-classroom-test`

This document records the local tools verified for development and testing of the TEST application. It does not describe or authorize any production changes.

## Verified local environment

| Component | Version / location | Verification |
|---|---|---|
| Ubuntu | 26.04.1 LTS | `cat /etc/os-release` |
| Node.js | v26.13.0 | `which node` |
| npm | 11.20.0 | `npm --version` |
| Git | 2.53.0 | `git --version` |
| Deno | 2.9.8 | `deno --version` |
| Supabase CLI | 3.4.0 | `supabase --version` |

Deno execution was also tested successfully with:

```bash
deno eval 'console.log("Temmy TEST Edge Function environment is ready")'
```

## Supabase CLI installation

The Supabase CLI was installed system-wide in Ubuntu from the official Supabase GitHub release package.

- Release: `v3.4.0`
- Package: `supabase_3.4.0_linux_amd64.deb`
- Official release URL: https://github.com/supabase/cli/releases/download/v3.4.0/supabase_3.4.0_linux_amd64.deb
- Download location used: `/tmp/supabase_3.4.0_linux_amd64.deb`
- Package inspection: `dpkg-deb -I /tmp/supabase_3.4.0_linux_amd64.deb`
- Installation command: `sudo apt install /tmp/supabase_3.4.0_linux_amd64.deb`
- Final verification: `supabase --version` returned `3.4.0`.

The downloaded installer was kept in `/tmp`; it was not added to this repository. The CLI is installed on the Ubuntu machine, not bundled with the application.

## Repository structure observed during setup

The project root contained:

- `index.html`
- `js/`
- `locales/`
- `test-games/`
- `docs/`
- `supabase/`

The `supabase/` directory contained the existing migrations:

- `202610090001_secure_game_result_recording.sql`
- `202610090002_harden_grade3_game_result_recording.sql`

At the time of inspection, no `supabase/functions/` directory, `supabase/config.toml`, or root `package.json` was present. Do not assume these files have since been created; inspect the repository before adding or changing configuration.

## Current setup checkpoint

- Node.js, npm, Git, Deno and Supabase CLI are installed and verified.
- The Supabase CLI has **not yet been authenticated** in this setup sequence.
- The CLI has **not yet been linked** to a Supabase project.
- No Edge Function has been created or deployed as part of this environment setup.
- No production project was accessed or changed.
- No application source files or database records were changed by the environment checks or CLI installation.

## Next steps

1. Authenticate the CLI with `supabase login`.
2. Confirm the authenticated account.
3. Link only the TEST project after verifying its project reference.
4. Inspect the resulting local Supabase configuration.
5. Prepare and test Edge Functions locally before any deployment.

## Security and change-control rules

- Work on the TEST project only. The separate production project must remain untouched.
- Never put Supabase access tokens, database passwords, service-role keys, or other secrets in source files, documentation, commits, screenshots, or chat messages.
- Do not commit the CLI installer binary; install the CLI separately on each development machine as needed.
- Do not apply migrations, change application code, or deploy functions without explicit approval.
- Inspect command output and confirm the target project before every remote operation.
