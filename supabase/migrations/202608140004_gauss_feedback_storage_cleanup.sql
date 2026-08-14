-- Let an authenticated owner remove only their own private feedback objects.
-- The application currently retains submitted reports, but this keeps account
-- deletion, privacy tooling, and temporary end-to-end proofs clean.

drop policy if exists gauss_feedback_storage_owner_delete
on storage.objects;

create policy gauss_feedback_storage_owner_delete
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'gauss-feedback-private'
  and owner_id = (select auth.uid()::text)
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);
