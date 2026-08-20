create table if not exists public.consultant_verification_submissions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  consultant_type text not null check (consultant_type in ('admission_consultant', 'academy_staff', 'instructor')),
  career_summary text,
  evidence_paths text[] not null check (cardinality(evidence_paths) between 1 and 5),
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  submitted_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewer_id uuid references auth.users(id) on delete set null,
  reviewer_note text
);

create index if not exists consultant_verification_submissions_user_id_idx
  on public.consultant_verification_submissions(user_id, submitted_at desc);

alter table public.consultant_verification_submissions enable row level security;

create policy "verification applicant reads own or admin reads all"
  on public.consultant_verification_submissions for select to authenticated
  using (user_id = (select auth.uid()) or (select auth.jwt() -> 'app_metadata' ->> 'gachi_role') = 'admin');

create policy "verification applicant submits own"
  on public.consultant_verification_submissions for insert to authenticated
  with check (user_id = (select auth.uid()) and status = 'pending' and reviewer_id is null and reviewed_at is null);

create policy "verification admin reviews submissions"
  on public.consultant_verification_submissions for update to authenticated
  using ((select auth.jwt() -> 'app_metadata' ->> 'gachi_role') = 'admin')
  with check ((select auth.jwt() -> 'app_metadata' ->> 'gachi_role') = 'admin');

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('consultant-verification', 'consultant-verification', false, 10485760,
  array['application/pdf', 'image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy "verification files applicant reads own or admin reads all"
  on storage.objects for select to authenticated
  using (bucket_id = 'consultant-verification' and ((storage.foldername(name))[1] = (select auth.uid()::text)
    or (select auth.jwt() -> 'app_metadata' ->> 'gachi_role') = 'admin'));

create policy "verification files applicant uploads to own folder"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'consultant-verification'
    and (storage.foldername(name))[1] = (select auth.uid()::text));
