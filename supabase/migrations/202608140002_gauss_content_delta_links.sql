-- Convert the already-empty initial content plane into reusable immutable
-- revisions plus per-release links. The data-copy step keeps this migration
-- safe if a draft was inserted between the two deployments.

create table if not exists public.gauss_release_questions (
  release_id text not null references public.gauss_content_releases(id) on delete restrict,
  question_id text not null,
  revision integer not null,
  position integer not null,
  primary key (release_id, question_id),
  unique (release_id, position),
  constraint gauss_release_question_position_nonnegative check (position >= 0)
);

do $migration$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'gauss_question_revisions'
      and column_name = 'release_id'
  ) then
    execute $copy$
      insert into public.gauss_release_questions (
        release_id,
        question_id,
        revision,
        position
      )
      select
        source.release_id,
        source.question_id,
        source.revision,
        row_number() over (
          partition by source.release_id
          order by source.subject, source.topic_key, source.question_id
        ) - 1
      from public.gauss_question_revisions source
      where not exists (
        select 1 from public.gauss_release_questions link
        where link.release_id = source.release_id
          and link.question_id = source.question_id
      )
    $copy$;
  end if;
end
$migration$;

drop policy if exists gauss_question_revisions_authenticated_read
on public.gauss_question_revisions;

alter table public.gauss_question_revisions
  drop constraint if exists gauss_question_revisions_release_id_question_id_key;
alter table public.gauss_question_revisions
  drop constraint if exists gauss_question_revisions_release_id_fkey;
drop index if exists public.gauss_question_revisions_release_topic_idx;
alter table public.gauss_question_revisions drop column if exists release_id;

alter table public.gauss_release_questions
  drop constraint if exists gauss_release_questions_question_revision_fkey;
alter table public.gauss_release_questions
  add constraint gauss_release_questions_question_revision_fkey
  foreign key (question_id, revision)
  references public.gauss_question_revisions(question_id, revision)
  on delete restrict;

create index if not exists gauss_question_revisions_topic_idx
on public.gauss_question_revisions (topic_key, question_id, revision desc);
create index if not exists gauss_release_questions_revision_idx
on public.gauss_release_questions (question_id, revision);

alter table public.gauss_release_questions enable row level security;
revoke all on table public.gauss_release_questions from anon;
grant select on table public.gauss_release_questions to authenticated;

drop policy if exists gauss_release_questions_authenticated_read
on public.gauss_release_questions;

create policy gauss_question_revisions_authenticated_read
on public.gauss_question_revisions
for select
to authenticated
using (exists (
  select 1
  from public.gauss_release_questions link
  join public.gauss_content_releases release on release.id = link.release_id
  where link.question_id = gauss_question_revisions.question_id
    and link.revision = gauss_question_revisions.revision
    and release.state in ('published', 'retired')
));

create policy gauss_release_questions_authenticated_read
on public.gauss_release_questions
for select
to authenticated
using (exists (
  select 1 from public.gauss_content_releases release
  where release.id = gauss_release_questions.release_id
    and release.state in ('published', 'retired')
));

drop function if exists public.gauss_release_payload(text);

create or replace function public.gauss_release_payload(
  p_release_id text,
  p_offset integer,
  p_limit integer
)
returns table (
  ordinal integer,
  question_id text,
  revision integer,
  subject text,
  topic_key text,
  difficulty text,
  content_sha256 text,
  payload jsonb
)
language sql
stable
security invoker
set search_path = ''
as $$
  select
    link.position as ordinal,
    link.question_id,
    link.revision,
    revision.subject,
    revision.topic_key,
    revision.difficulty,
    revision.content_sha256,
    revision.payload
  from public.gauss_release_questions link
  join public.gauss_question_revisions revision
    on revision.question_id = link.question_id
   and revision.revision = link.revision
  where link.release_id = p_release_id
  order by link.position
  offset greatest(p_offset, 0)
  limit least(greatest(p_limit, 1), 500);
$$;

revoke all on function public.gauss_release_payload(text, integer, integer)
from public, anon;
grant execute on function public.gauss_release_payload(text, integer, integer)
to authenticated;
