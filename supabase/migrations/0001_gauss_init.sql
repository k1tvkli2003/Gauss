-- ============================================================
-- Gauss: Elite Math/Physics trainer (Iranian Konkur curriculum)
-- Tables are namespaced with gauss_ to coexist inside the
-- shared StudyHUB Supabase project.
-- Apply with: supabase db push   (or paste into the SQL editor)
-- ============================================================

-- ---------- QUESTIONS ----------
create table if not exists public.gauss_questions (
  id              uuid primary key default gen_random_uuid(),
  subject         text not null check (subject in ('math','physics')),
  category        text not null,
  sub_category    text,
  difficulty      text not null check (difficulty in ('above_average','hard','very_hard','olympiad')),
  question_text   text not null,              -- markdown + LaTeX ($...$ , $$...$$)
  image_url       text,
  option_1        text not null,
  option_2        text not null,
  option_3        text not null,
  option_4        text not null,
  correct_option_index smallint not null check (correct_option_index between 1 and 4),
  classic_solution text not null,             -- Persian "khodmooni" step-by-step
  smart_shortcut   text,                      -- Persian test-taking shortcut
  source           text default 'seed',       -- 'seed' | 'jules' | 'manual'
  created_at       timestamptz not null default now()
);
create index if not exists idx_gauss_questions_filter
  on public.gauss_questions (subject, category, difficulty);

-- ---------- EXAMS HISTORY ----------
create table if not exists public.gauss_exams_history (
  id               uuid primary key default gen_random_uuid(),
  profile_id       text not null default 'local',
  config           jsonb,
  total_questions  int  not null,
  correct_count    int  not null default 0,
  wrong_count      int  not null default 0,
  skipped_count    int  not null default 0,
  score_percentage numeric(5,2) not null default 0,
  duration_seconds int,
  created_at       timestamptz not null default now()
);
create index if not exists idx_gauss_exams_profile
  on public.gauss_exams_history (profile_id, created_at desc);

-- ---------- USER HISTORY ----------
create table if not exists public.gauss_user_history (
  id                 uuid primary key default gen_random_uuid(),
  profile_id         text not null default 'local',
  exam_id            uuid references public.gauss_exams_history(id) on delete set null,
  question_id        uuid not null references public.gauss_questions(id) on delete cascade,
  status             text not null check (status in ('correct','wrong','skipped')),
  selected_option    smallint check (selected_option between 1 and 4),
  time_taken_seconds int,
  solved_at          timestamptz not null default now()
);
create index if not exists idx_gauss_history_profile  on public.gauss_user_history (profile_id, solved_at desc);
create index if not exists idx_gauss_history_question on public.gauss_user_history (question_id);
create index if not exists idx_gauss_history_status   on public.gauss_user_history (profile_id, status);

-- ---------- RLS (personal single-user app on the public anon key) ----------
alter table public.gauss_questions      enable row level security;
alter table public.gauss_exams_history  enable row level security;
alter table public.gauss_user_history   enable row level security;

create policy "gauss_questions_read"  on public.gauss_questions     for select using (true);
create policy "gauss_exams_all"       on public.gauss_exams_history for all using (true) with check (true);
create policy "gauss_history_all"     on public.gauss_user_history  for all using (true) with check (true);
