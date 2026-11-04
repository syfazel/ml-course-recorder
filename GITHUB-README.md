# ml-course-recorder — v2 infrastructure (ready to push, not yet pushed)

This folder is the GitHub-ready snapshot for the new course site:
static frontend + Supabase backend, closed Auth, no public signup.

## What is here
- `v2-schema.sql` — v2 tables (profiles, v2_progress, v2_quiz_attempts,
  v2_mistakes, v2_teach_backs, v2_lab_notebooks, v2_events) with RLS.
  Authenticated only; NO anon policy (unlike the spike table shell_batches).
  Teacher gate is `app_metadata.role = 'teacher'`, set via Auth Admin API.
- `supabase-recorder.js` / `schema.sql` — spike recorder (shell_batches),
  kept as the remote-recording foundation and bridge reference.
- `../v2-skeleton/` — skeleton frontend spec and code (login via Supabase
  Auth, Day 0 sample lesson, sample quiz, teacher dashboard skeleton).

## What is NOT here, by design
- No secret/service_role key, no teacher password, no student password,
  no student email. Auth accounts are created via the Auth Admin API
  (service_role, via the secure vault card) with invitation, so users set
  their own passwords from their email link.
- No push to an unrelated repo. The target repo is a new private
  `ml-course-recorder` repo, included in the Muse GitHub App installation.
  Until that installation includes it, push is blocked — see below.

## GitHub blocker (verified 2026-11-04)
- GitHub is connected as syfazel, but the installation still covers only
  4 repos: pied-piper-trader, shirif, desktop-tutorial, eco-journal-app.
  No ml-course-recorder repo exists, and repo creation via the App
  returned 403 "Resource not accessible by integration" on 2026-11-04.
- To unblock: update the installation (link in chat) to include a new
  private ml-course-recorder repo, or to allow all repositories, then
  tell Muse. Muse then creates/pushes without touching the 4 unrelated repos.
