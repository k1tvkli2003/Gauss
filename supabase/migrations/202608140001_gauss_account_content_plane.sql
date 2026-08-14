-- Gauss account, content-release, and progress isolation plane.
--
-- This migration is intentionally additive. The first-generation Gauss tables
-- remain intact, but their permissive public policies are replaced with
-- authenticated owner policies. The Android client uses the versioned tables
-- below so immutable question identity survives future text, answer, and media
-- revisions without requiring an APK update.

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Lock down the first-generation tables without deleting their data.
-- ---------------------------------------------------------------------------

drop policy if exists gauss_exams_all on public.gauss_exams_history;
drop policy if exists gauss_history_all on public.gauss_user_history;
drop policy if exists gauss_srs_all on public.gauss_srs_state;
drop policy if exists gauss_questions_read on public.gauss_questions;

revoke all on table public.gauss_exams_history from anon;
revoke all on table public.gauss_user_history from anon;
revoke all on table public.gauss_srs_state from anon;
revoke all on table public.gauss_questions from anon;

grant select, insert, update, delete on table public.gauss_exams_history to authenticated;
grant select, insert, update, delete on table public.gauss_user_history to authenticated;
grant select, insert, update, delete on table public.gauss_srs_state to authenticated;
grant select on table public.gauss_questions to authenticated;

create policy gauss_legacy_questions_authenticated_read
on public.gauss_questions
for select
to authenticated
using (true);

create policy gauss_legacy_exams_owner
on public.gauss_exams_history
for all
to authenticated
using ((select auth.uid())::text = profile_id)
with check ((select auth.uid())::text = profile_id);

create policy gauss_legacy_history_owner
on public.gauss_user_history
for all
to authenticated
using ((select auth.uid())::text = profile_id)
with check ((select auth.uid())::text = profile_id);

create policy gauss_legacy_srs_owner
on public.gauss_srs_state
for all
to authenticated
using ((select auth.uid())::text = profile_id)
with check ((select auth.uid())::text = profile_id);

-- ---------------------------------------------------------------------------
-- Account profile. Authentication remains owned by auth.users.
-- ---------------------------------------------------------------------------

create table if not exists public.gauss_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint gauss_profiles_display_name_length
    check (display_name is null or char_length(display_name) between 1 and 80)
);

alter table public.gauss_profiles enable row level security;
revoke all on table public.gauss_profiles from anon;
grant select, insert, update on table public.gauss_profiles to authenticated;

drop policy if exists gauss_profiles_owner_select on public.gauss_profiles;
drop policy if exists gauss_profiles_owner_insert on public.gauss_profiles;
drop policy if exists gauss_profiles_owner_update on public.gauss_profiles;

create policy gauss_profiles_owner_select
on public.gauss_profiles
for select
to authenticated
using ((select auth.uid()) = user_id);

create policy gauss_profiles_owner_insert
on public.gauss_profiles
for insert
to authenticated
with check ((select auth.uid()) = user_id);

create policy gauss_profiles_owner_update
on public.gauss_profiles
for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

-- ---------------------------------------------------------------------------
-- Atomic, immutable content releases.
-- ---------------------------------------------------------------------------

create table if not exists public.gauss_content_releases (
  id text primary key,
  schema_version integer not null,
  corpus_sha256 text not null unique,
  question_count integer not null,
  topic_count integer not null,
  state text not null default 'draft',
  minimum_app_build integer not null default 1,
  created_at timestamptz not null default now(),
  published_at timestamptz,
  constraint gauss_content_release_id_shape
    check (id ~ '^[a-z0-9][a-z0-9._-]{2,79}$'),
  constraint gauss_content_release_hash_shape
    check (corpus_sha256 ~ '^[0-9a-f]{64}$'),
  constraint gauss_content_release_counts
    check (question_count > 0 and topic_count > 0),
  constraint gauss_content_release_state
    check (state in ('draft', 'published', 'retired')),
  constraint gauss_content_release_published_at
    check ((state = 'draft' and published_at is null) or
           (state <> 'draft' and published_at is not null))
);

create table if not exists public.gauss_content_artifacts (
  release_id text not null references public.gauss_content_releases(id) on delete restrict,
  kind text not null,
  sha256 text not null,
  payload jsonb not null,
  created_at timestamptz not null default now(),
  primary key (release_id, kind),
  constraint gauss_content_artifact_kind
    check (kind in ('question_index', 'five_question_plan', 'certification_runtime', 'media_manifest')),
  constraint gauss_content_artifact_hash_shape
    check (sha256 ~ '^[0-9a-f]{64}$')
);

create table if not exists public.gauss_question_revisions (
  question_id text not null,
  revision integer not null,
  release_id text not null references public.gauss_content_releases(id) on delete restrict,
  subject text not null,
  topic_key text not null,
  difficulty text not null,
  content_sha256 text not null,
  payload jsonb not null,
  created_at timestamptz not null default now(),
  primary key (question_id, revision),
  unique (release_id, question_id),
  constraint gauss_question_id_shape
    check (question_id ~ '^nardebam_(math|physics)_[0-9]{4}_[0-9]{4}$'),
  constraint gauss_question_revision_positive check (revision > 0),
  constraint gauss_question_subject check (subject in ('math', 'physics')),
  constraint gauss_question_content_hash_shape
    check (content_sha256 ~ '^[0-9a-f]{64}$'),
  constraint gauss_question_payload_identity
    check (payload ->> 'id' = question_id and
           payload ->> 'subject' = subject and
           payload ->> 'topic_key' = topic_key)
);

create index if not exists gauss_question_revisions_release_topic_idx
on public.gauss_question_revisions (release_id, topic_key, question_id);

create table if not exists public.gauss_content_channels (
  channel text primary key,
  release_id text not null references public.gauss_content_releases(id) on delete restrict,
  updated_at timestamptz not null default now(),
  constraint gauss_content_channel_shape
    check (channel ~ '^[a-z0-9][a-z0-9._-]{2,39}$')
);

alter table public.gauss_content_releases enable row level security;
alter table public.gauss_content_artifacts enable row level security;
alter table public.gauss_question_revisions enable row level security;
alter table public.gauss_content_channels enable row level security;

revoke all on table public.gauss_content_releases from anon;
revoke all on table public.gauss_content_artifacts from anon;
revoke all on table public.gauss_question_revisions from anon;
revoke all on table public.gauss_content_channels from anon;
grant select on table public.gauss_content_releases to authenticated;
grant select on table public.gauss_content_artifacts to authenticated;
grant select on table public.gauss_question_revisions to authenticated;
grant select on table public.gauss_content_channels to authenticated;

drop policy if exists gauss_content_releases_authenticated_read on public.gauss_content_releases;
drop policy if exists gauss_content_artifacts_authenticated_read on public.gauss_content_artifacts;
drop policy if exists gauss_question_revisions_authenticated_read on public.gauss_question_revisions;
drop policy if exists gauss_content_channels_authenticated_read on public.gauss_content_channels;

create policy gauss_content_releases_authenticated_read
on public.gauss_content_releases
for select
to authenticated
using (state in ('published', 'retired'));

create policy gauss_content_artifacts_authenticated_read
on public.gauss_content_artifacts
for select
to authenticated
using (exists (
  select 1 from public.gauss_content_releases release
  where release.id = gauss_content_artifacts.release_id
    and release.state in ('published', 'retired')
));

create policy gauss_question_revisions_authenticated_read
on public.gauss_question_revisions
for select
to authenticated
using (exists (
  select 1 from public.gauss_content_releases release
  where release.id = gauss_question_revisions.release_id
    and release.state in ('published', 'retired')
));

create policy gauss_content_channels_authenticated_read
on public.gauss_content_channels
for select
to authenticated
using (true);

-- ---------------------------------------------------------------------------
-- Account-isolated cloud progress and idempotent event stream.
-- ---------------------------------------------------------------------------

create table if not exists public.gauss_progress_snapshots (
  user_id uuid primary key references auth.users(id) on delete cascade,
  revision bigint not null default 0,
  schema_version integer not null,
  content_release_id text references public.gauss_content_releases(id) on delete set null,
  payload jsonb not null,
  updated_at timestamptz not null default now(),
  constraint gauss_progress_snapshot_revision_nonnegative check (revision >= 0),
  constraint gauss_progress_snapshot_schema_positive check (schema_version > 0)
);

create table if not exists public.gauss_user_events (
  user_id uuid not null references auth.users(id) on delete cascade,
  event_id text not null,
  event_type text not null,
  content_release_id text references public.gauss_content_releases(id) on delete set null,
  payload jsonb not null,
  client_created_at timestamptz not null,
  server_created_at timestamptz not null default now(),
  primary key (user_id, event_id),
  constraint gauss_user_event_id_length check (char_length(event_id) between 8 and 160),
  constraint gauss_user_event_type_length check (char_length(event_type) between 1 and 80)
);

create index if not exists gauss_user_events_recent_idx
on public.gauss_user_events (user_id, server_created_at desc);

create table if not exists public.gauss_feedback_reports (
  user_id uuid not null references auth.users(id) on delete cascade,
  id text not null,
  kind text not null,
  route text not null,
  note text not null,
  question_id text,
  question_revision integer,
  topic_key text,
  issue_kind text,
  session_id text,
  mission_index integer,
  selected_choice_index integer,
  screenshot_path text,
  screenshot_sha256 text,
  client_created_at timestamptz not null,
  server_created_at timestamptz not null default now(),
  primary key (user_id, id),
  constraint gauss_feedback_id_length check (char_length(id) between 8 and 160),
  constraint gauss_feedback_note_length check (char_length(note) between 1 and 4000),
  constraint gauss_feedback_question_revision check (question_revision is null or question_revision > 0),
  constraint gauss_feedback_selected_choice check (selected_choice_index is null or selected_choice_index between 0 and 3),
  constraint gauss_feedback_screenshot_hash check (screenshot_sha256 is null or screenshot_sha256 ~ '^[0-9a-f]{64}$')
);

alter table public.gauss_progress_snapshots enable row level security;
alter table public.gauss_user_events enable row level security;
alter table public.gauss_feedback_reports enable row level security;

revoke all on table public.gauss_progress_snapshots from anon;
revoke all on table public.gauss_user_events from anon;
revoke all on table public.gauss_feedback_reports from anon;
grant select, insert, update, delete on table public.gauss_progress_snapshots to authenticated;
grant select, insert on table public.gauss_user_events to authenticated;
grant select, insert on table public.gauss_feedback_reports to authenticated;

drop policy if exists gauss_progress_snapshots_owner on public.gauss_progress_snapshots;
drop policy if exists gauss_user_events_owner_read on public.gauss_user_events;
drop policy if exists gauss_user_events_owner_insert on public.gauss_user_events;
drop policy if exists gauss_feedback_reports_owner_read on public.gauss_feedback_reports;
drop policy if exists gauss_feedback_reports_owner_insert on public.gauss_feedback_reports;

create policy gauss_progress_snapshots_owner
on public.gauss_progress_snapshots
for all
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy gauss_user_events_owner_read
on public.gauss_user_events
for select
to authenticated
using ((select auth.uid()) = user_id);

create policy gauss_user_events_owner_insert
on public.gauss_user_events
for insert
to authenticated
with check ((select auth.uid()) = user_id);

create policy gauss_feedback_reports_owner_read
on public.gauss_feedback_reports
for select
to authenticated
using ((select auth.uid()) = user_id);

create policy gauss_feedback_reports_owner_insert
on public.gauss_feedback_reports
for insert
to authenticated
with check ((select auth.uid()) = user_id);

-- Existing StudyHUB accounts are not enrolled into Gauss automatically. A
-- profile is created only when an authenticated person actually opens Gauss.
create or replace function public.gauss_ensure_profile()
returns public.gauss_profiles
language plpgsql
security invoker
set search_path = ''
as $$
declare
  profile public.gauss_profiles;
begin
  if (select auth.uid()) is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;
  insert into public.gauss_profiles (user_id)
  values ((select auth.uid()))
  on conflict (user_id) do update
    set updated_at = public.gauss_profiles.updated_at
  returning * into profile;
  return profile;
end;
$$;

revoke all on function public.gauss_ensure_profile() from public, anon;
grant execute on function public.gauss_ensure_profile() to authenticated;

-- ---------------------------------------------------------------------------
-- Server-only registration throttle for Gauss instant-confirm signup.
-- ---------------------------------------------------------------------------

create table if not exists public.gauss_registration_attempts (
  id bigint generated always as identity primary key,
  key_kind text not null,
  request_hash text not null,
  attempted_at timestamptz not null default now(),
  constraint gauss_registration_key_kind check (key_kind in ('network', 'email')),
  constraint gauss_registration_hash_shape check (request_hash ~ '^[0-9a-f]{64}$')
);

create index if not exists gauss_registration_attempts_window_idx
on public.gauss_registration_attempts (key_kind, request_hash, attempted_at desc);

alter table public.gauss_registration_attempts enable row level security;
revoke all on table public.gauss_registration_attempts from anon, authenticated;

create or replace function public.gauss_claim_registration_slot(
  p_network_hash text,
  p_email_hash text
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  network_count integer;
  email_count integer;
begin
  if p_network_hash !~ '^[0-9a-f]{64}$' or p_email_hash !~ '^[0-9a-f]{64}$' then
    return false;
  end if;

  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(p_network_hash));
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(p_email_hash));

  select count(*) into network_count
  from public.gauss_registration_attempts
  where key_kind = 'network'
    and request_hash = p_network_hash
    and attempted_at >= now() - interval '1 hour';

  select count(*) into email_count
  from public.gauss_registration_attempts
  where key_kind = 'email'
    and request_hash = p_email_hash
    and attempted_at >= now() - interval '24 hours';

  if network_count >= 5 or email_count >= 3 then
    return false;
  end if;

  insert into public.gauss_registration_attempts (key_kind, request_hash)
  values ('network', p_network_hash), ('email', p_email_hash);

  delete from public.gauss_registration_attempts
  where attempted_at < now() - interval '7 days';

  return true;
end;
$$;

revoke all on function public.gauss_claim_registration_slot(text, text) from public, anon, authenticated;
grant execute on function public.gauss_claim_registration_slot(text, text) to service_role;
