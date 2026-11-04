-- Supabase recorder spike — run this once in the Supabase SQL Editor.
-- One batch row per Recorder export, not one table per Recorder table:
-- the teacher dashboard stays in the main server site, Supabase is only
-- the remote relay/storage. The main site import reads these batches and
-- imports them with source:"shell", then aggregates them to Drive.
-- Free tier has NO automatic backups: Drive backup of imported batches
-- is the teacher's safety net, not Supabase's.

create table if not exists public.shell_batches (
  id uuid primary key default gen_random_uuid(),
  student_name text not null,
  batch_id text not null unique,
  export_id text,
  shell_version text,
  exported_at timestamptz,
  received_at timestamptz not null default now(),
  tables jsonb not null check (jsonb_typeof(tables) = 'object'),
  row_count integer not null default 0,
  source text not null default 'shell'
);

create index if not exists idx_shell_batches_student_time
  on public.shell_batches (student_name, received_at desc);

alter table public.shell_batches enable row level security;

-- Anon key is designed for browser use. Anyone with the anon key can
-- INSERT a batch, but cannot read, update, or delete any batch.
-- Fake posts are possible with any public endpoint: the unique
-- batch_id rejects exact duplicates, and the teacher import validates
-- table names and row shapes before anything reaches the main site.
-- Teacher reading is NOT via anon: it uses the service_role key,
-- which must never go in the shell page, in chat, or in code.
drop policy if exists student_insert on public.shell_batches;
create policy student_insert
  on public.shell_batches for insert
  to anon
  with check (true);

-- No select/update/delete policy for anon or authenticated in the spike:
-- reads go through the teacher import with service_role only.
