-- Complete the account-scoped private feedback lane. Reports remain durable in
-- the local outbox first; authenticated clients can then idempotently upsert
-- metadata and an optional PNG under their own private Storage prefix.

alter table public.gauss_feedback_reports
  add column if not exists content_release_id text
  references public.gauss_content_releases(id) on delete set null;

alter table public.gauss_feedback_reports
  drop constraint if exists gauss_feedback_note_length;
alter table public.gauss_feedback_reports
  drop constraint if exists gauss_feedback_content_present;
alter table public.gauss_feedback_reports
  drop constraint if exists gauss_feedback_screenshot_binding;
alter table public.gauss_feedback_reports
  add constraint gauss_feedback_note_length
  check (char_length(note) between 0 and 4000),
  add constraint gauss_feedback_content_present
  check (char_length(note) > 0 or screenshot_path is not null),
  add constraint gauss_feedback_screenshot_binding
  check (
    (screenshot_path is null and screenshot_sha256 is null)
    or (
      screenshot_path is not null
      and screenshot_sha256 is not null
      and screenshot_path like user_id::text || '/%'
    )
  );

grant update on table public.gauss_feedback_reports to authenticated;

drop policy if exists gauss_feedback_reports_owner_insert
on public.gauss_feedback_reports;
drop policy if exists gauss_feedback_reports_owner_update
on public.gauss_feedback_reports;

create policy gauss_feedback_reports_owner_insert
on public.gauss_feedback_reports
for insert
to authenticated
with check (
  (select auth.uid()) = user_id
  and (
    screenshot_path is null
    or screenshot_path like user_id::text || '/%'
  )
);

create policy gauss_feedback_reports_owner_update
on public.gauss_feedback_reports
for update
to authenticated
using ((select auth.uid()) = user_id)
with check (
  (select auth.uid()) = user_id
  and (
    screenshot_path is null
    or screenshot_path like user_id::text || '/%'
  )
);

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'gauss-feedback-private',
  'gauss-feedback-private',
  false,
  8388608,
  array['image/png']::text[]
)
on conflict (id) do update
set public = false,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists gauss_feedback_storage_owner_select
on storage.objects;
drop policy if exists gauss_feedback_storage_owner_insert
on storage.objects;
drop policy if exists gauss_feedback_storage_owner_update
on storage.objects;

create policy gauss_feedback_storage_owner_select
on storage.objects
for select
to authenticated
using (
  bucket_id = 'gauss-feedback-private'
  and owner_id = (select auth.uid()::text)
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

create policy gauss_feedback_storage_owner_insert
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'gauss-feedback-private'
  and owner_id = (select auth.uid()::text)
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

create policy gauss_feedback_storage_owner_update
on storage.objects
for update
to authenticated
using (
  bucket_id = 'gauss-feedback-private'
  and owner_id = (select auth.uid()::text)
  and (storage.foldername(name))[1] = (select auth.uid()::text)
)
with check (
  bucket_id = 'gauss-feedback-private'
  and owner_id = (select auth.uid()::text)
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);
