-- ============================================================
-- Fix: Missing INSERT policy for profiles table
-- ============================================================
create policy "Users can insert profiles at their gym"
  on public.profiles for insert
  with check (
    gym_id = current_user_gym_id()
  );

-- ============================================================
-- Fix: UPDATE policy for profiles — allow owners to update
-- staff profiles even when gym_id is null (auto-profile trigger
-- creates profiles without gym_id)
-- ============================================================
drop policy if exists "Owners can update staff at their gym" on public.profiles;

create policy "Owners can update staff at their gym"
  on public.profiles for update
  using (
    (gym_id = public.current_user_gym_id() or gym_id is null)
    and exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('owner', 'superadmin', 'admin')
    )
  );

-- ============================================================
-- Fix: gyms subscription CHECK constraint too restrictive
-- 'trial' plan exists in code but DB only allows free/pro/enterprise
-- ============================================================
alter table public.gyms
  drop constraint if exists gyms_subscription_check;

alter table public.gyms
  add constraint gyms_subscription_check
  check (subscription in ('free', 'trial', 'pro', 'enterprise'));

-- ============================================================
-- Fix: Storage bucket setup for avatars
-- Run these in Supabase Dashboard -> SQL Editor
-- ============================================================
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

create policy "Avatar images are publicly accessible"
  on storage.objects for select
  using ( bucket_id = 'avatars' );

create policy "Users can upload avatar images"
  on storage.objects for insert
  with check (
    bucket_id = 'avatars'
    and auth.role() = 'authenticated'
  );

create policy "Users can update own avatar"
  on storage.objects for update
  using (
    bucket_id = 'avatars'
    and auth.uid() = owner
  );

create policy "Users can delete own avatar"
  on storage.objects for delete
  using (
    bucket_id = 'avatars'
    and auth.uid() = owner
  );
