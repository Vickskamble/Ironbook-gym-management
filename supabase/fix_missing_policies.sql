-- ============================================================
-- IronBook — Fix Missing RLS Policies, Storage Buckets & RBAC
-- Run this in your Supabase SQL Editor
-- ============================================================

-- 1. Drop old permissive policies before recreating with role checks
drop policy if exists "Users can view their gym inventory" on public.inventory;
drop policy if exists "Users can insert their gym inventory" on public.inventory;
drop policy if exists "Users can update their gym inventory" on public.inventory;
drop policy if exists "Users can delete their gym inventory" on public.inventory;
drop policy if exists "Users can view inventory purchases" on public.inventory_purchases;
drop policy if exists "Users can insert inventory purchases" on public.inventory_purchases;
drop policy if exists "Users can update inventory purchases at their gym" on public.inventory_purchases;
drop policy if exists "Users can delete inventory purchases at their gym" on public.inventory_purchases;
drop policy if exists "Users can view inventory sales" on public.inventory_sales;
drop policy if exists "Users can insert inventory sales" on public.inventory_sales;

-- 2. Create receipts storage bucket for expense receipts
insert into storage.buckets (id, name, public)
values ('receipts', 'receipts', true)
on conflict (id) do nothing;

drop policy if exists "Receipt files are publicly accessible" on storage.objects;
create policy "Receipt files are publicly accessible"
  on storage.objects for select
  using ( bucket_id = 'receipts' );

drop policy if exists "Users can upload receipt files" on storage.objects;
create policy "Users can upload receipt files"
  on storage.objects for insert
  with check (
    bucket_id = 'receipts'
    and auth.role() = 'authenticated'
  );

drop policy if exists "Users can update own receipts" on storage.objects;
create policy "Users can update own receipts"
  on storage.objects for update
  using (
    bucket_id = 'receipts'
    and auth.uid() = owner
  );

drop policy if exists "Users can delete own receipts" on storage.objects;
create policy "Users can delete own receipts"
  on storage.objects for delete
  using (
    bucket_id = 'receipts'
    and auth.uid() = owner
  );

-- ============================================================
-- 3. Staff creation fix — bypass RLS for profile update
--    auth.signUp() hijacks the admin session, so the subsequent
--    profiles.update() fails RLS. This RPC uses security definer
--    to bypass RLS while still authorizing the caller.
-- ============================================================
-- ============================================================
-- 3b. Helper: check if current user is admin-level at their gym
-- ============================================================
create or replace function public.is_gym_admin()
returns boolean language sql stable security definer
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role in ('owner', 'admin', 'superadmin')
  )
$$;

-- ============================================================
-- 4. Restrict write operations to admin-level roles only
--    Staff/trainer should only view data and mark attendance
-- ============================================================

-- Drop existing write policies that are too permissive
do $$ declare
  rec record;
begin
  -- Drop insert policies on all data tables
  for rec in
    select policyname, tablename from pg_policies
    where schemaname = 'public'
    and tablename in ('members','plans','payments','expenses','inventory','inventory_sales','inventory_purchases')
    and policyname like '%insert%'
  loop
    execute format('drop policy if exists %I on public.%I', rec.policyname, rec.tablename);
  end loop;
  -- Drop update policies on all data tables
  for rec in
    select policyname, tablename from pg_policies
    where schemaname = 'public'
    and tablename in ('members','plans','payments','expenses','inventory','inventory_sales','inventory_purchases')
    and policyname like '%update%'
  loop
    execute format('drop policy if exists %I on public.%I', rec.policyname, rec.tablename);
  end loop;
  -- Drop delete policies on all data tables
  for rec in
    select policyname, tablename from pg_policies
    where schemaname = 'public'
    and tablename in ('members','plans','payments','expenses','inventory','inventory_sales','inventory_purchases')
    and policyname like '%delete%'
  loop
    execute format('drop policy if exists %I on public.%I', rec.policyname, rec.tablename);
  end loop;
end $$;

-- MEMBERS: staff/trainer can create/update, only admins can delete
create policy "Staff can insert members"
  on public.members for insert
  with check (gym_id = public.current_user_gym_id());

create policy "Staff can update members"
  on public.members for update
  using (gym_id = public.current_user_gym_id());

create policy "Admins can delete members"
  on public.members for delete
  using (gym_id = public.current_user_gym_id() and public.is_gym_admin());

-- PLANS: only admins can write
create policy "Admins can insert plans"
  on public.plans for insert
  with check (gym_id = public.current_user_gym_id() and public.is_gym_admin());

create policy "Admins can update plans"
  on public.plans for update
  using (gym_id = public.current_user_gym_id() and public.is_gym_admin());

create policy "Admins can delete plans"
  on public.plans for delete
  using (gym_id = public.current_user_gym_id() and public.is_gym_admin());

-- PAYMENTS: staff/trainer can create, only admins can delete
create policy "Staff can insert payments"
  on public.payments for insert
  with check (gym_id = public.current_user_gym_id());

create policy "Staff can update payments"
  on public.payments for update
  using (gym_id = public.current_user_gym_id());

create policy "Admins can delete payments"
  on public.payments for delete
  using (gym_id = public.current_user_gym_id() and public.is_gym_admin());

-- EXPENSES: staff/trainer can create, only admins can delete
create policy "Staff can insert expenses"
  on public.expenses for insert
  with check (gym_id = public.current_user_gym_id());

create policy "Staff can update expenses"
  on public.expenses for update
  using (gym_id = public.current_user_gym_id());

create policy "Admins can delete expenses"
  on public.expenses for delete
  using (gym_id = public.current_user_gym_id() and public.is_gym_admin());

-- INVENTORY: staff/trainer can create/update, only admins can delete
create policy "Staff can insert inventory"
  on public.inventory for insert
  with check (gym_id = public.current_user_gym_id());

create policy "Staff can update inventory"
  on public.inventory for update
  using (gym_id = public.current_user_gym_id());

create policy "Admins can delete inventory"
  on public.inventory for delete
  using (gym_id = public.current_user_gym_id() and public.is_gym_admin());

-- INVENTORY_SALES: staff/trainer can create/update, only admins can delete
create policy "Staff can insert inventory sales"
  on public.inventory_sales for insert
  with check (gym_id = public.current_user_gym_id());

create policy "Staff can update inventory sales"
  on public.inventory_sales for update
  using (gym_id = public.current_user_gym_id());

create policy "Admins can delete inventory sales"
  on public.inventory_sales for delete
  using (gym_id = public.current_user_gym_id() and public.is_gym_admin());

-- INVENTORY_PURCHASES: staff/trainer can create/update, only admins can delete
create policy "Staff can insert inventory purchases"
  on public.inventory_purchases for insert
  with check (gym_id = public.current_user_gym_id());

create policy "Staff can update inventory purchases"
  on public.inventory_purchases for update
  using (gym_id = public.current_user_gym_id());

create policy "Admins can delete inventory purchases"
  on public.inventory_purchases for delete
  using (gym_id = public.current_user_gym_id() and public.is_gym_admin());

-- ATTENDANCE: staff/trainer can insert & update (mark check-in/out), only admins delete
create policy "Staff can insert attendance"
  on public.attendance for insert
  with check (gym_id = public.current_user_gym_id());

create policy "Staff can update attendance"
  on public.attendance for update
  using (gym_id = public.current_user_gym_id());

create policy "Admins can delete attendance"
  on public.attendance for delete
  using (gym_id = public.current_user_gym_id() and public.is_gym_admin());

-- PROFILES: only admins can directly insert (auto-trigger handles signup)
drop policy if exists "Users can insert profiles at their gym" on public.profiles;
create policy "Admins can insert profiles"
  on public.profiles for insert
  with check (public.is_gym_admin());

drop policy if exists "Owners can update staff at their gym" on public.profiles;
create policy "Admins can update staff at their gym"
  on public.profiles for update
  using (
    (gym_id = public.current_user_gym_id() or gym_id is null)
    and public.is_gym_admin()
  );

drop policy if exists "Superadmins can delete profiles" on public.profiles;
create policy "Admins can delete profiles at their gym"
  on public.profiles for delete
  using (
    (gym_id = public.current_user_gym_id() or is_superadmin())
    and public.is_gym_admin()
  );

-- GYMS: only owners can update their gym, anyone can view
drop policy if exists "Owners can update own gym" on public.gyms;
create policy "Owners can update own gym"
  on public.gyms for update
  using ((owner_id = auth.uid() and public.current_user_gym_id() = id) or is_superadmin());

drop policy if exists "Users can insert gyms" on public.gyms;
create policy "Owners can insert gyms"
  on public.gyms for insert
  with check (owner_id = auth.uid() or is_superadmin());

-- ============================================================
-- 5. Staff creation fix — bypass RLS for profile update
-- ============================================================
create or replace function public.update_staff_profile(
  p_target_user_id uuid,
  p_name text default null,
  p_phone text default null,
  p_role text default null,
  p_gym_id uuid default null,
  p_is_active boolean default null,
  p_avatar_url text default null
) returns jsonb language plpgsql security definer set search_path = ''
as $$
declare
  v_caller_role text;
  v_caller_gym_id uuid;
  v_result jsonb;
begin
  -- Get caller's role and gym_id
  select role, gym_id into v_caller_role, v_caller_gym_id
  from public.profiles
  where id = auth.uid();

  -- Only allow owners, admins, or superadmins
  if v_caller_role is null or v_caller_role not in ('owner', 'admin', 'superadmin') then
    raise exception 'Only gym owners, admins, or superadmins can update staff profiles';
  end if;

  -- For non-superadmins, ensure the target belongs to the same gym
  if v_caller_role != 'superadmin' then
    if p_gym_id is null then
      raise exception 'gym_id is required';
    end if;
    if p_gym_id != v_caller_gym_id then
      raise exception 'Cannot update staff from a different gym';
    end if;
  end if;

  -- Update the profile
  update public.profiles
  set
    name = coalesce(p_name, name),
    phone = coalesce(p_phone, phone),
    role = coalesce(p_role, role),
    gym_id = coalesce(p_gym_id, gym_id),
    is_active = coalesce(p_is_active, is_active),
    avatar_url = coalesce(p_avatar_url, avatar_url)
  where id = p_target_user_id;

  -- Return updated profile
  select row_to_json(public.profiles)::jsonb into v_result
  from public.profiles
  where id = p_target_user_id;

  return v_result;
end;
$$;
