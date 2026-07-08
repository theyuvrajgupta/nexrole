-- NexRole schema: invite allowlist, profiles, and the per-stage persistence tables.
-- Isolation model: every child table is scoped to a profile, every profile is scoped
-- to auth.uid(). RLS enforces this at the database layer (defense-in-depth), not just
-- in application code.

-- ============================================================================
-- Invite allowlist
-- ============================================================================
-- No public signup. An email must be listed here before Supabase Auth will let it
-- create an account at all (enforced by the trigger below, not just app-side checks).
create table public.allowed_emails (
  email text primary key,
  note text not null default '',
  created_at timestamptz not null default now()
);

comment on table public.allowed_emails is
  'Invite allowlist. auth.users insert is rejected for emails not listed here.';

-- Seed the owner so the very first login works without a manual dashboard step.
insert into public.allowed_emails (email, note)
values ('mail.yuvrajgupta@gmail.com', 'Owner')
on conflict (email) do nothing;

create or replace function public.enforce_allowlist()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.allowed_emails
    where lower(email) = lower(new.email)
  ) then
    raise exception 'This email is not on the invite list.'
      using errcode = 'P0001';
  end if;
  return new;
end;
$$;

create trigger enforce_allowlist_trigger
  before insert on auth.users
  for each row execute function public.enforce_allowlist();

-- ============================================================================
-- Profiles
-- ============================================================================
create table public.profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  gaps text not null default '',
  style_notes text not null default '',
  boards jsonb not null default '["LinkedIn", "Indeed", "Glassdoor"]'::jsonb,
  is_default boolean not null default false,
  created_at timestamptz not null default now()
);

create index profiles_user_id_idx on public.profiles (user_id);

alter table public.profiles enable row level security;

create policy "profiles_owner_all" on public.profiles
  for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- Shared helper: does the current user own the profile a child row points at.
-- security definer + fixed search_path so it can be used inside RLS policies
-- on every child table without each policy re-deriving the ownership chain.
create or replace function public.owns_profile(p_profile_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = p_profile_id and user_id = auth.uid()
  );
$$;

-- ============================================================================
-- Resume versions (multiple per profile; union is the source of truth)
-- ============================================================================
create table public.resume_versions (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  label text not null,
  text text not null,
  created_at timestamptz not null default now()
);

create index resume_versions_profile_id_idx on public.resume_versions (profile_id);

alter table public.resume_versions enable row level security;

create policy "resume_versions_owner_all" on public.resume_versions
  for all
  using (owns_profile(profile_id))
  with check (owns_profile(profile_id));

-- ============================================================================
-- Custom document formats
-- ============================================================================
create table public.custom_formats (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  name text not null,
  spec text not null,
  created_at timestamptz not null default now()
);

create index custom_formats_profile_id_idx on public.custom_formats (profile_id);

alter table public.custom_formats enable row level security;

create policy "custom_formats_owner_all" on public.custom_formats
  for all
  using (owns_profile(profile_id))
  with check (owns_profile(profile_id));

-- ============================================================================
-- Fit analyses (persisted JD runs; seed of the future application tracker)
-- ============================================================================
create table public.analyses (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  jd_text text not null,
  result jsonb not null,
  verdict text not null,
  archetype text not null,
  suggested_prep_format text not null,
  best_base_version text,
  created_at timestamptz not null default now()
);

create index analyses_profile_id_idx on public.analyses (profile_id);

alter table public.analyses enable row level security;

create policy "analyses_owner_all" on public.analyses
  for all
  using (owns_profile(profile_id))
  with check (owns_profile(profile_id));

-- ============================================================================
-- Generated documents (resume + cover letter per format run)
-- ============================================================================
create table public.documents (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  analysis_id uuid references public.analyses (id) on delete set null,
  format_key text not null,
  resume text not null,
  cover_letter text not null,
  bullets jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create index documents_profile_id_idx on public.documents (profile_id);

alter table public.documents enable row level security;

create policy "documents_owner_all" on public.documents
  for all
  using (owns_profile(profile_id))
  with check (owns_profile(profile_id));

-- ============================================================================
-- Interview prep runs
-- ============================================================================
create table public.interview_preps (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  analysis_id uuid references public.analyses (id) on delete set null,
  format_key text not null,
  result jsonb not null,
  created_at timestamptz not null default now()
);

create index interview_preps_profile_id_idx on public.interview_preps (profile_id);

alter table public.interview_preps enable row level security;

create policy "interview_preps_owner_all" on public.interview_preps
  for all
  using (owns_profile(profile_id))
  with check (owns_profile(profile_id));

-- ============================================================================
-- Job finder searches
-- ============================================================================
create table public.job_searches (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  role text not null,
  location text not null default '',
  result jsonb not null,
  created_at timestamptz not null default now()
);

create index job_searches_profile_id_idx on public.job_searches (profile_id);

alter table public.job_searches enable row level security;

create policy "job_searches_owner_all" on public.job_searches
  for all
  using (owns_profile(profile_id))
  with check (owns_profile(profile_id));
