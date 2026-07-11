-- ============================================================
-- IronBook SaaS Gym Management — Supabase Schema
-- Run this in your Supabase SQL Editor
-- ============================================================

-- 0. EXTENSIONS
create extension if not exists "uuid-ossp";
create extension if not exists pg_trgm;

-- ============================================================
-- 1. TABLES
-- ============================================================

-- 1a. PROFILES (extends auth.users)
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  gym_id      uuid,                       -- nullable for superadmins
  name        text not null,
  email       text not null,
  phone       text not null default '',
  role        text not null default 'owner' check (role in ('owner','superadmin','admin','trainer','staff')),
  avatar_url  text,
  language    text not null default 'en' check (language in ('en','hi','mr')),
  is_active   boolean not null default true,
  last_login  timestamptz,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- 1b. GYMS
create table if not exists public.gyms (
  id                    uuid primary key default uuid_generate_v4(),
  name                  text not null,
  address               text not null default '',
  phone                 text not null default '',
  type                  text,
  owner_id              uuid references public.profiles(id) on delete set null,
  subscription          text not null default 'free' check (subscription in ('free','pro','enterprise')),
  subscription_expires_at timestamptz,
  is_active             boolean not null default true,
  logo_url              text,
  website               text,
  established_year      integer,
  total_capacity        integer default 0,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);

-- 1c. PLANS
create table if not exists public.plans (
  id            uuid primary key default uuid_generate_v4(),
  gym_id        uuid not null references public.gyms(id) on delete cascade,
  name          text not null,
  description   text not null default '',
  price         numeric(10,2) not null default 0,
  duration_days integer not null default 30,
  features      jsonb not null default '[]'::jsonb,
  color         text default '#6366F1',
  is_active     boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- 1d. MEMBERS
create table if not exists public.members (
  id                uuid primary key default uuid_generate_v4(),
  gym_id            uuid not null references public.gyms(id) on delete cascade,
  name              text not null,
  phone             text not null,
  email             text default '',
  gender            text default '' check (gender in ('','Male','Female','Other')),
  age               integer check (age is null or (age >= 1 and age <= 120)),
  address           text default '',
  plan_id           uuid references public.plans(id) on delete set null,
  plan_name         text default '',
  join_date         date not null default current_date,
  membership_start  date not null default current_date,
  membership_end    date not null,
  status            text not null default 'Active' check (status in ('Active','Expired','Paused','Deleted')),
  profile_pic       text,
  emergency_contact text default '',
  blood_group       text default '',
  notes             text default '',
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

-- 1e. PAYMENTS
create table if not exists public.payments (
  id            uuid primary key default uuid_generate_v4(),
  gym_id        uuid not null references public.gyms(id) on delete cascade,
  member_id     uuid not null references public.members(id) on delete cascade,
  member_name   text not null,
  plan_id       uuid references public.plans(id) on delete set null,
  plan_name     text default '',
  amount        numeric(10,2) not null check (amount > 0),
  discount      numeric(10,2) not null default 0 check (discount >= 0),
  final_amount  numeric(10,2) not null check (final_amount >= 0),
  paid_at       timestamptz not null default now(),
  method        text not null default 'Cash' check (method in ('Cash','UPI','Card','Cheque','Other')),
  transaction_id text default '',
  note          text default '',
  next_due_date date,
  created_by    uuid references public.profiles(id) on delete set null,
  created_at    timestamptz not null default now()
);

-- 1f. ATTENDANCE
create table if not exists public.attendance (
  id                uuid primary key default uuid_generate_v4(),
  gym_id            uuid not null references public.gyms(id) on delete cascade,
  member_id         uuid not null references public.members(id) on delete cascade,
  member_name       text not null,
  member_phone      text not null default '',
  check_in          timestamptz not null default now(),
  check_out         timestamptz,
  duration_minutes  integer,
  marked_by         uuid references public.profiles(id) on delete set null,
  created_at        timestamptz not null default now()
  -- unique index added below instead
);

-- NOTE: 'staff' table was removed.
-- Staff management uses public.profiles with role-based access.
-- All Dart code (StaffRepository, staff screens) works with public.profiles.

-- 1h. EXPENSES
create table if not exists public.expenses (
  id            uuid primary key default uuid_generate_v4(),
  gym_id        uuid not null references public.gyms(id) on delete cascade,
  category      text not null default 'Other' check (category in ('Rent','Electricity','Water','Equipment','Salary','Maintenance','Marketing','Supplements','Other')),
  title         text not null,
  amount        numeric(10,2) not null check (amount > 0),
  expense_date  date not null default current_date,
  paid_by       text default '',
  receipt_url   text,
  note          text default '',
  created_by    uuid references public.profiles(id) on delete set null,
  created_at    timestamptz not null default now()
);

-- 1i. NOTIFICATIONS
create table if not exists public.notifications (
  id          uuid primary key default uuid_generate_v4(),
  gym_id      uuid not null references public.gyms(id) on delete cascade,
  title       text not null,
  body        text not null,
  type        text not null default 'system' check (type in ('expiry_alert','payment_due','new_member','attendance','system','general')),
  is_read     boolean not null default false,
  member_id   uuid references public.members(id) on delete cascade,
  created_at  timestamptz not null default now()
);

-- ============================================================
-- 2. INDEXES
-- ============================================================

create index if not exists idx_profiles_gym_id on public.profiles(gym_id);
create index if not exists idx_profiles_role on public.profiles(role);

create index if not exists idx_gyms_owner_id on public.gyms(owner_id);
create index if not exists idx_gyms_subscription on public.gyms(subscription);

create index if not exists idx_plans_gym_id on public.plans(gym_id);
create index if not exists idx_plans_is_active on public.plans(is_active);

create index if not exists idx_members_gym_id on public.members(gym_id);
create index if not exists idx_members_status on public.members(status);
create index if not exists idx_members_phone on public.members(phone);
create index if not exists idx_members_membership_end on public.members(membership_end);
create index if not exists idx_members_name on public.members using gin(name gin_trgm_ops);

create index if not exists idx_payments_gym_id on public.payments(gym_id);
create index if not exists idx_payments_member_id on public.payments(member_id);
create index if not exists idx_payments_paid_at on public.payments(paid_at);

create index if not exists idx_attendance_gym_id on public.attendance(gym_id);
create index if not exists idx_attendance_member_id on public.attendance(member_id);
create index if not exists idx_attendance_check_in on public.attendance(check_in);
create unique index if not exists idx_attendance_unique_entry on public.attendance(gym_id, member_id, ((check_in at time zone 'UTC')::date));


create index if not exists idx_expenses_gym_id on public.expenses(gym_id);
create index if not exists idx_expenses_category on public.expenses(category);
create index if not exists idx_expenses_date on public.expenses(expense_date);

create index if not exists idx_notifications_gym_id on public.notifications(gym_id);
create index if not exists idx_notifications_is_read on public.notifications(is_read);
create index if not exists idx_notifications_type on public.notifications(type);

-- ============================================================
-- 3. ROW LEVEL SECURITY
-- ============================================================

alter table public.profiles enable row level security;
alter table public.gyms enable row level security;
alter table public.plans enable row level security;
alter table public.members enable row level security;
alter table public.payments enable row level security;
alter table public.attendance enable row level security;

alter table public.expenses enable row level security;
alter table public.notifications enable row level security;

-- Helper: get the current user's gym_id
-- Reset all existing policies before recreation
do $$ declare
  rec record;
begin
  for rec in
    select policyname, tablename, schemaname
    from pg_policies
    where schemaname = 'public'
  loop
    execute format('drop policy if exists %I on %I.%I', rec.policyname, rec.schemaname, rec.tablename);
  end loop;
end $$;

create or replace function public.current_user_gym_id()
returns uuid language sql stable security definer
as $$
  select gym_id from public.profiles where id = auth.uid()
$$;

-- Helper: check if user is superadmin
create or replace function public.is_superadmin()
returns boolean language sql stable security definer
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'superadmin'
  )
$$;

-- 3a. PROFILES RLS
create policy "Users can view own profile"
  on public.profiles for select
  using (id = auth.uid() or is_superadmin());

create policy "Staff can view profiles at their gym"
  on public.profiles for select
  using (gym_id = public.current_user_gym_id() or is_superadmin());

create policy "Users can update own profile (non-role fields)"
  on public.profiles for update
  using (id = auth.uid())
  with check (
    id = auth.uid() and
    (role is null or role = (select role from public.profiles where id = auth.uid()))
  );

create policy "Superadmins can update any profile"
  on public.profiles for update
  using (is_superadmin());

create policy "Superadmins can delete profiles"
  on public.profiles for delete
  using (is_superadmin());

create policy "Owners can update staff at their gym"
  on public.profiles for update
  using (gym_id = public.current_user_gym_id() and exists (
    select 1 from public.profiles
    where id = auth.uid() and role in ('owner', 'admin')
  ));

-- 3b. GYMS RLS
create policy "Owners can view own gym"
  on public.gyms for select
  using (owner_id = auth.uid() or is_superadmin());

create policy "Staff can view their gym"
  on public.gyms for select
  using (id = public.current_user_gym_id() or is_superadmin());

create policy "Owners can update own gym"
  on public.gyms for update
  using (owner_id = auth.uid() or is_superadmin());

create policy "Users can insert gyms"
  on public.gyms for insert
  with check (owner_id = auth.uid() or is_superadmin());

-- 3c. PLANS RLS
create policy "Users can view plans for their gym"
  on public.plans for select
  using (gym_id = public.current_user_gym_id() or is_superadmin());

create policy "Users can insert plans for their gym"
  on public.plans for insert
  with check (gym_id = public.current_user_gym_id() or is_superadmin());

create policy "Users can update plans for their gym"
  on public.plans for update
  using (gym_id = public.current_user_gym_id() or is_superadmin());

create policy "Users can delete plans for their gym"
  on public.plans for delete
  using (gym_id = public.current_user_gym_id() or is_superadmin());

-- 3d. MEMBERS RLS
create policy "Users can view members for their gym"
  on public.members for select
  using (gym_id = public.current_user_gym_id() or is_superadmin());

create policy "Users can insert members for their gym"
  on public.members for insert
  with check (gym_id = public.current_user_gym_id() or is_superadmin());

create policy "Users can update members for their gym"
  on public.members for update
  using (gym_id = public.current_user_gym_id() or is_superadmin());

create policy "Users can delete members for their gym"
  on public.members for delete
  using (gym_id = public.current_user_gym_id() or is_superadmin());

-- (Repeat the same pattern for payments, attendance, staff, expenses, notifications)

-- 3e. PAYMENTS RLS
create policy "Users can view payments for their gym"
  on public.payments for select
  using (gym_id = public.current_user_gym_id() or is_superadmin());

create policy "Users can insert payments for their gym"
  on public.payments for insert
  with check (gym_id = public.current_user_gym_id() or is_superadmin());

create policy "Users can update payments for their gym"
  on public.payments for update
  using (gym_id = public.current_user_gym_id() or is_superadmin());

create policy "Users can delete payments for their gym"
  on public.payments for delete
  using (gym_id = public.current_user_gym_id() or is_superadmin());

-- 3f. ATTENDANCE RLS
create policy "Users can view attendance for their gym"
  on public.attendance for select
  using (gym_id = public.current_user_gym_id() or is_superadmin());

create policy "Users can insert attendance for their gym"
  on public.attendance for insert
  with check (gym_id = public.current_user_gym_id() or is_superadmin());

create policy "Users can update attendance for their gym"
  on public.attendance for update
  using (gym_id = public.current_user_gym_id() or is_superadmin());

create policy "Users can delete attendance for their gym"
  on public.attendance for delete
  using (gym_id = public.current_user_gym_id() or is_superadmin());

-- 3g. EXPENSES RLS
create policy "Users can view expenses for their gym"
  on public.expenses for select
  using (gym_id = public.current_user_gym_id() or is_superadmin());

create policy "Users can insert expenses for their gym"
  on public.expenses for insert
  with check (gym_id = public.current_user_gym_id() or is_superadmin());

create policy "Users can update expenses for their gym"
  on public.expenses for update
  using (gym_id = public.current_user_gym_id() or is_superadmin());

create policy "Users can delete expenses for their gym"
  on public.expenses for delete
  using (gym_id = public.current_user_gym_id() or is_superadmin());

-- 3i. NOTIFICATIONS RLS
create policy "Users can view notifications for their gym"
  on public.notifications for select
  using (gym_id = public.current_user_gym_id() or is_superadmin());

create policy "Users can insert notifications for their gym"
  on public.notifications for insert
  with check (gym_id = public.current_user_gym_id() or is_superadmin());

create policy "Users can update notifications for their gym"
  on public.notifications for update
  using (gym_id = public.current_user_gym_id() or is_superadmin());

create policy "Users can delete notifications for their gym"
  on public.notifications for delete
  using (gym_id = public.current_user_gym_id() or is_superadmin());

-- ============================================================
-- 4. TRIGGERS
-- ============================================================

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, name, email, phone)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'name', split_part(new.email, '@', 1)),
    new.email,
    coalesce(new.raw_user_meta_data ->> 'phone', '')
  );
  return new;
end;
$$;

create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Auto-update updated_at columns
create or replace function public.update_timestamp()
returns trigger language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace trigger trg_profiles_updated_at
  before update on public.profiles
  for each row execute function public.update_timestamp();

create or replace trigger trg_gyms_updated_at
  before update on public.gyms
  for each row execute function public.update_timestamp();

create or replace trigger trg_plans_updated_at
  before update on public.plans
  for each row execute function public.update_timestamp();

create or replace trigger trg_members_updated_at
  before update on public.members
  for each row execute function public.update_timestamp();

-- ============================================================
-- 4b. SIGNUP COMPLETION (handles email-confirmation flow)
-- ============================================================

-- Completes profile + gym creation when email confirmation is enabled
-- (session-less signup — runs with security definer to bypass RLS)
create or replace function public.complete_signup(
  p_user_id uuid,
  p_name text,
  p_phone text,
  p_gym_name text,
  p_gym_address text,
  p_gym_type text default ''
) returns jsonb language plpgsql security definer set search_path = ''
as $$
declare
  new_gym_id uuid;
  profile_row record;
begin
  update public.profiles
  set name = p_name, phone = p_phone, role = 'owner'
  where id = p_user_id;

  insert into public.gyms (name, address, phone, type, owner_id)
  values (p_gym_name, p_gym_address, p_phone, nullif(p_gym_type, ''), p_user_id)
  returning id into new_gym_id;

  update public.profiles set gym_id = new_gym_id
  where id = p_user_id;

  select * from public.profiles where id = p_user_id into profile_row;
  return row_to_json(profile_row)::jsonb;
end;
$$;

-- ============================================================
-- 5. MISSING TABLES (referenced by Dart code but not yet created)
-- ============================================================

-- 5a. GYM SETTINGS (key-value config per gym)
create table if not exists public.gym_settings (
  id              uuid primary key default uuid_generate_v4(),
  gym_id          uuid not null references public.gyms(id) on delete cascade unique,
  settings        jsonb not null default '{}'::jsonb,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

-- 5b. IMPORT LOGS (tracks CSV/Excel import history)
create table if not exists public.import_logs (
  id            uuid primary key default uuid_generate_v4(),
  gym_id        uuid not null references public.gyms(id) on delete cascade,
  admin_id      uuid references public.profiles(id) on delete set null,
  type          text not null default 'members_csv',
  total_rows    integer not null default 0,
  inserted      integer not null default 0,
  skipped       integer not null default 0,
  errors        text not null default '',
  created_at    timestamptz not null default now()
);

-- Indexes
create index if not exists idx_gym_settings_gym_id on public.gym_settings(gym_id);
create index if not exists idx_import_logs_gym_id on public.import_logs(gym_id);

-- RLS
alter table public.gym_settings enable row level security;
alter table public.import_logs enable row level security;

create policy "Users can view their gym settings"
  on public.gym_settings for select
  using (gym_id = public.current_user_gym_id() or is_superadmin());

create policy "Users can insert their gym settings"
  on public.gym_settings for insert
  with check (gym_id = public.current_user_gym_id() or is_superadmin());

create policy "Users can update their gym settings"
  on public.gym_settings for update
  using (gym_id = public.current_user_gym_id() or is_superadmin());

create or replace trigger trg_gym_settings_updated_at
  before update on public.gym_settings
  for each row execute function public.update_timestamp();

create policy "Users can view import logs for their gym"
  on public.import_logs for select
  using (gym_id = public.current_user_gym_id() or is_superadmin());

create policy "Users can insert import logs for their gym"
  on public.import_logs for insert
  with check (gym_id = public.current_user_gym_id() or is_superadmin());


