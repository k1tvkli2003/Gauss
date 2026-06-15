-- ============================================================
-- Gauss Wave 3: spaced-repetition state + atomic exam save
-- Apply with: supabase db push  (or paste into the SQL editor)
--
-- Adds true SM-2-lite spaced repetition so Revenge Mode stops
-- "redeeming" a question on a single lucky correct answer, and
-- makes exam-saving atomic (exam + per-question history + SRS
-- update all succeed or all roll back together).
-- ============================================================

-- ---------- SRS STATE (SM-2 lite, per profile+question) ----------
create table if not exists public.gauss_srs_state (
  profile_id    text not null default 'local',
  question_id   uuid not null references public.gauss_questions(id) on delete cascade,
  ease          real not null default 2.5,
  interval_days int  not null default 0,
  reps          int  not null default 0,
  lapses        int  not null default 0,
  due_at        timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  primary key (profile_id, question_id)
);
create index if not exists idx_gauss_srs_due
  on public.gauss_srs_state (profile_id, due_at);

alter table public.gauss_srs_state enable row level security;
do $$ begin
  if not exists (select 1 from pg_policies where policyname = 'gauss_srs_all') then
    create policy "gauss_srs_all" on public.gauss_srs_state for all using (true) with check (true);
  end if;
end $$;

-- ---------- ATOMIC SAVE: exam + history + SRS in one transaction ----------
create or replace function public.gauss_save_exam(
  p_profile  text,
  p_config   jsonb,
  p_duration int,
  p_attempts jsonb   -- [{question_id, status, selected_option, time_taken_seconds}, ...]
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_exam_id   uuid;
  v_total     int;
  v_correct   int;
  v_wrong     int;
  v_skipped   int;
  v_score     numeric(5,2);
  a           jsonb;
  v_status    text;
  v_qid       uuid;
  s           record;
  v_ease      real;
  v_interval  int;
  v_reps      int;
  v_lapses    int;
  v_due       timestamptz;
begin
  v_total   := jsonb_array_length(p_attempts);
  v_correct := (select count(*) from jsonb_array_elements(p_attempts) e where e->>'status' = 'correct');
  v_wrong   := (select count(*) from jsonb_array_elements(p_attempts) e where e->>'status' = 'wrong');
  v_skipped := (select count(*) from jsonb_array_elements(p_attempts) e where e->>'status' = 'skipped');
  v_score   := case when v_total > 0 then round((v_correct::numeric / v_total) * 100, 2) else 0 end;

  insert into public.gauss_exams_history
    (profile_id, config, total_questions, correct_count, wrong_count, skipped_count, score_percentage, duration_seconds)
  values
    (p_profile, p_config, v_total, v_correct, v_wrong, v_skipped, v_score, p_duration)
  returning id into v_exam_id;

  for a in select * from jsonb_array_elements(p_attempts)
  loop
    v_status := a->>'status';
    v_qid    := (a->>'question_id')::uuid;

    insert into public.gauss_user_history
      (profile_id, exam_id, question_id, status, selected_option, time_taken_seconds)
    values
      (p_profile, v_exam_id, v_qid, v_status,
       nullif(a->>'selected_option','')::smallint,
       nullif(a->>'time_taken_seconds','')::int);

    -- SM-2 lite update
    select * into s from public.gauss_srs_state
      where profile_id = p_profile and question_id = v_qid;

    v_ease     := coalesce(s.ease, 2.5);
    v_reps     := coalesce(s.reps, 0);
    v_lapses   := coalesce(s.lapses, 0);
    v_interval := coalesce(s.interval_days, 0);

    if v_status = 'correct' then
      v_reps := v_reps + 1;
      if v_reps = 1 then v_interval := 1;
      elsif v_reps = 2 then v_interval := 3;
      else v_interval := ceil(v_interval * v_ease)::int;
      end if;
      v_ease := least(2.8, v_ease + 0.1);
      v_due  := now() + (v_interval || ' days')::interval;
    else
      v_lapses   := v_lapses + 1;
      v_reps     := 0;
      v_interval := 0;
      v_ease     := greatest(1.3, v_ease - 0.2);
      v_due      := now();
    end if;

    insert into public.gauss_srs_state
      (profile_id, question_id, ease, interval_days, reps, lapses, due_at, updated_at)
    values
      (p_profile, v_qid, v_ease, v_interval, v_reps, v_lapses, v_due, now())
    on conflict (profile_id, question_id) do update set
      ease          = excluded.ease,
      interval_days = excluded.interval_days,
      reps          = excluded.reps,
      lapses        = excluded.lapses,
      due_at        = excluded.due_at,
      updated_at    = excluded.updated_at;
  end loop;

  return v_exam_id;
end;
$$;

grant execute on function public.gauss_save_exam(text, jsonb, int, jsonb)
  to anon, authenticated, service_role;

-- ---------- BACKFILL: bootstrap SRS from existing history so Revenge keeps working ----------
with last_attempt as (
  select distinct on (profile_id, question_id)
    profile_id, question_id, status, solved_at
  from public.gauss_user_history
  order by profile_id, question_id, solved_at desc
),
missed as (
  select profile_id, question_id,
    count(*) filter (where status in ('wrong','skipped')) as lap
  from public.gauss_user_history
  group by profile_id, question_id
)
insert into public.gauss_srs_state
  (profile_id, question_id, ease, interval_days, reps, lapses, due_at, updated_at)
select
  m.profile_id, m.question_id, 2.5,
  case when l.status = 'correct' then 1 else 0 end,
  case when l.status = 'correct' then 1 else 0 end,
  m.lap,
  case when l.status = 'correct' then now() + interval '1 day' else now() end,
  now()
from missed m
join last_attempt l using (profile_id, question_id)
where m.lap > 0
on conflict (profile_id, question_id) do nothing;
