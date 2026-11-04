-- v2 schema for ml-course-recorder — static frontend + Supabase Auth
-- Run once in Supabase SQL Editor. This does NOT touch shell_batches (spike table, kept).
-- Teacher gate, revised 2026-11-04: by Auth email, not by app_metadata role.
-- Reason: setting app_metadata role needs the Auth Admin API with a
-- service_role key, whose surrogate swap was not observed to work through
-- the VM proxy (401 on 2026-11-04). Email is in the Auth JWT after login,
-- so a teacher who signs up with the teacher email can read student rows
-- with a normal Auth login, with no service_role call and no password in chat.
-- Teacher email for this project: syfazel@gmail.com (project owner).
-- If the teacher email ever changes, update the policy predicate below.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('teacher','student')),
  display_name text,
  created_at timestamptz not null default now()
);

create table if not exists public.v2_progress (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  unit_id text not null,
  status text not null default 'not_started',
  score numeric,
  updated_at timestamptz not null default now(),
  unique (student_id, unit_id)
);

create table if not exists public.v2_quiz_attempts (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  unit_id text not null,
  question_index int not null,
  chosen int,
  correct boolean not null,
  concept text,
  created_at timestamptz not null default now()
);

create table if not exists public.v2_mistakes (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  unit_id text not null,
  kind text not null,
  detail text,
  created_at timestamptz not null default now()
);

create table if not exists public.v2_teach_backs (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  unit_id text not null,
  text_body text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.v2_lab_notebooks (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  unit_id text not null,
  code jsonb not null default '[]'::jsonb,
  layout jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  unique (student_id, unit_id)
);

create table if not exists public.v2_events (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  event_type text not null,
  unit_id text,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.v2_progress enable row level security;
alter table public.v2_quiz_attempts enable row level security;
alter table public.v2_mistakes enable row level security;
alter table public.v2_teach_backs enable row level security;
alter table public.v2_lab_notebooks enable row level security;
alter table public.v2_events enable row level security;

-- Profiles: a user reads/inserts only their own profile. Teacher reads all profiles
-- via the email predicate in the data-table policies below, not via a
-- service_role call, to avoid recursion and to avoid the Auth Admin API.
drop policy if exists profiles_self on public.profiles;
create policy profiles_self on public.profiles
  for all using (auth.uid() = id) with check (auth.uid() = id);

-- Helper predicate, inlined in each policy (no function, so no extra privilege):
-- student: auth.uid() = student_id
-- teacher: (auth.jwt() ->> 'email') = 'syfazel@gmail.com'

drop policy if exists v2_progress_access on public.v2_progress;
create policy v2_progress_access on public.v2_progress
  for all using (auth.uid() = student_id or (auth.jwt() ->> 'email') = 'syfazel@gmail.com')
  with check (auth.uid() = student_id);

drop policy if exists v2_quiz_access on public.v2_quiz_attempts;
create policy v2_quiz_access on public.v2_quiz_attempts
  for all using (auth.uid() = student_id or (auth.jwt() ->> 'email') = 'syfazel@gmail.com')
  with check (auth.uid() = student_id);

drop policy if exists v2_mistakes_access on public.v2_mistakes;
create policy v2_mistakes_access on public.v2_mistakes
  for all using (auth.uid() = student_id or (auth.jwt() ->> 'email') = 'syfazel@gmail.com')
  with check (auth.uid() = student_id);

drop policy if exists v2_teachbacks_access on public.v2_teach_backs;
create policy v2_teachbacks_access on public.v2_teach_backs
  for all using (auth.uid() = student_id or (auth.jwt() ->> 'email') = 'syfazel@gmail.com')
  with check (auth.uid() = student_id);

drop policy if exists v2_lab_access on public.v2_lab_notebooks;
create policy v2_lab_access on public.v2_lab_notebooks
  for all using (auth.uid() = student_id or (auth.jwt() ->> 'email') = 'syfazel@gmail.com')
  with check (auth.uid() = student_id);

drop policy if exists v2_events_access on public.v2_events;
create policy v2_events_access on public.v2_events
  for all using (auth.uid() = student_id or (auth.jwt() ->> 'email') = 'syfazel@gmail.com')
  with check (auth.uid() = student_id);
