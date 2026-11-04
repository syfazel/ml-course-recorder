-- Teacher SELECT policy for the spike table shell_batches.
-- Run in Supabase SQL Editor. This does NOT change INSERT behaviour:
-- anon INSERT (spike recorder) stays as it was, and no anon SELECT is added.
-- Teacher gate here is by teacher email, not by app_metadata role, so that
-- teacher reading works with a normal Supabase Auth login, without a
-- service_role API call (whose surrogate swap was not observed to work
-- through the VM proxy on 2026-11-04).
-- Replace TEACHER_EMAIL below with the teacher's Auth email before running.
-- Default teacher email for this project is syfazel@gmail.com (project owner).

create policy shell_batches_teacher_select on public.shell_batches
  for select
  using ((auth.jwt() ->> 'email') = 'syfazel@gmail.com');
