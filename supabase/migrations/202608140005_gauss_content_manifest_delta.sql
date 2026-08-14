-- Add hash-first release manifests and bounded payload fetches. The client can
-- now reconcile an immutable release locally and request only revisions or
-- artifacts whose hashes are not already present in its verified snapshot.

create or replace function public.gauss_release_manifest(
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
  content_sha256 text
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
    revision.content_sha256
  from public.gauss_release_questions link
  join public.gauss_question_revisions revision
    on revision.question_id = link.question_id
   and revision.revision = link.revision
  where link.release_id = p_release_id
  order by link.position
  offset greatest(p_offset, 0)
  limit least(greatest(p_limit, 1), 500);
$$;

revoke all on function public.gauss_release_manifest(text, integer, integer)
from public, anon;
grant execute on function public.gauss_release_manifest(text, integer, integer)
to authenticated;

create or replace function public.gauss_release_payload_batch(
  p_release_id text,
  p_question_ids text[],
  p_revisions integer[]
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
language plpgsql
stable
security invoker
set search_path = ''
as $$
declare
  requested_count integer;
  distinct_count integer;
begin
  if p_question_ids is null or p_revisions is null then
    raise exception 'Question payload request arrays are required.'
      using errcode = '22023';
  end if;
  requested_count := cardinality(p_question_ids);
  if requested_count < 1
     or requested_count > 250
     or requested_count <> cardinality(p_revisions) then
    raise exception 'Question payload request must contain 1 through 250 matching pairs.'
      using errcode = '22023';
  end if;
  select count(distinct requested.question_id)
  into distinct_count
  from unnest(p_question_ids) as requested(question_id);
  if distinct_count <> requested_count then
    raise exception 'Question payload request contains duplicate ids.'
      using errcode = '22023';
  end if;

  return query
  select
    link.position as ordinal,
    link.question_id,
    link.revision,
    stored.subject,
    stored.topic_key,
    stored.difficulty,
    stored.content_sha256,
    stored.payload
  from unnest(p_question_ids, p_revisions) with ordinality
    as requested(question_id, revision, request_ordinal)
  join public.gauss_release_questions link
    on link.release_id = p_release_id
   and link.question_id = requested.question_id
   and link.revision = requested.revision
  join public.gauss_question_revisions stored
    on stored.question_id = link.question_id
   and stored.revision = link.revision
  order by requested.request_ordinal;
end;
$$;

revoke all on function public.gauss_release_payload_batch(text, text[], integer[])
from public, anon;
grant execute on function public.gauss_release_payload_batch(text, text[], integer[])
to authenticated;

create or replace function public.gauss_release_artifact_payloads(
  p_release_id text,
  p_kinds text[]
)
returns table (
  kind text,
  sha256 text,
  payload jsonb
)
language plpgsql
stable
security invoker
set search_path = ''
as $$
declare
  requested_count integer;
  distinct_count integer;
begin
  if p_kinds is null then
    raise exception 'Artifact payload request array is required.'
      using errcode = '22023';
  end if;
  requested_count := cardinality(p_kinds);
  if requested_count < 1 or requested_count > 4 then
    raise exception 'Artifact payload request must contain 1 through 4 kinds.'
      using errcode = '22023';
  end if;
  select count(distinct requested.kind)
  into distinct_count
  from unnest(p_kinds) as requested(kind);
  if distinct_count <> requested_count then
    raise exception 'Artifact payload request contains duplicate kinds.'
      using errcode = '22023';
  end if;

  return query
  select artifact.kind, artifact.sha256, artifact.payload
  from unnest(p_kinds) with ordinality as requested(kind, request_ordinal)
  join public.gauss_content_artifacts artifact
    on artifact.release_id = p_release_id
   and artifact.kind = requested.kind
  order by requested.request_ordinal;
end;
$$;

revoke all on function public.gauss_release_artifact_payloads(text, text[])
from public, anon;
grant execute on function public.gauss_release_artifact_payloads(text, text[])
to authenticated;
