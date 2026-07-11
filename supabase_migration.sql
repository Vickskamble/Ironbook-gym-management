-- ============================================================
-- IronBook Migration — Inventory Tables
-- Run this in your Supabase SQL Editor
-- ============================================================

-- 1. INVENTORY ITEMS TABLE
create table if not exists public.inventory (
  id                    uuid primary key default uuid_generate_v4(),
  gym_id                uuid not null references public.gyms(id) on delete cascade,
  name                  text not null,
  description           text default '',
  category              text not null default 'Supplements' check (category in ('Supplements','Protein','Vitamins','Equipment','Accessories','Other')),
  quantity              integer not null default 0 check (quantity >= 0),
  low_stock_threshold   integer not null default 5 check (low_stock_threshold >= 0),
  unit_price            numeric(10,2) not null default 0 check (unit_price >= 0),
  selling_price         numeric(10,2) check (selling_price >= 0),
  supplier              text default '',
  unit                  text not null default 'pcs',
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);

-- 2. INVENTORY PURCHASES (stock additions)
create table if not exists public.inventory_purchases (
  id              uuid primary key default uuid_generate_v4(),
  gym_id          uuid not null references public.gyms(id) on delete cascade,
  item_id         uuid not null references public.inventory(id) on delete cascade,
  quantity        integer not null check (quantity > 0),
  unit_price      numeric(10,2) not null default 0,
  total_price     numeric(10,2) not null default 0,
  supplier        text default '',
  purchased_at    timestamptz not null default now(),
  created_at      timestamptz not null default now()
);

-- 3. INVENTORY SALES
create table if not exists public.inventory_sales (
  id              uuid primary key default uuid_generate_v4(),
  gym_id          uuid not null references public.gyms(id) on delete cascade,
  item_id         uuid not null references public.inventory(id) on delete cascade,
  item_name       text not null default '',
  quantity        integer not null check (quantity > 0),
  unit_price      numeric(10,2) not null default 0,
  total_price     numeric(10,2) not null default 0,
  member_id       uuid references public.members(id) on delete set null,
  member_name     text default '',
  sold_by         uuid references public.profiles(id) on delete set null,
  sold_at         timestamptz not null default now(),
  note            text default '',
  created_at      timestamptz not null default now()
);

-- 4. INDEXES
create index if not exists idx_inventory_gym_id on public.inventory(gym_id);
create index if not exists idx_inventory_category on public.inventory(category);
create index if not exists idx_inventory_quantity on public.inventory(quantity);
create index if not exists idx_inventory_purchases_gym_id on public.inventory_purchases(gym_id);
create index if not exists idx_inventory_purchases_item_id on public.inventory_purchases(item_id);
create index if not exists idx_inventory_sales_gym_id on public.inventory_sales(gym_id);
create index if not exists idx_inventory_sales_item_id on public.inventory_sales(item_id);
create index if not exists idx_inventory_sales_sold_at on public.inventory_sales(sold_at);

-- 5. ROW LEVEL SECURITY
alter table public.inventory enable row level security;
alter table public.inventory_purchases enable row level security;
alter table public.inventory_sales enable row level security;

-- 6. RLS POLICIES — Gym users can only access their own gym's data
create policy "Users can view their gym inventory"
  on public.inventory for select
  using (auth.uid() in (
    select id from public.profiles where gym_id = inventory.gym_id
  ));

create policy "Users can insert their gym inventory"
  on public.inventory for insert
  with check (auth.uid() in (
    select id from public.profiles where gym_id = inventory.gym_id
  ));

create policy "Users can update their gym inventory"
  on public.inventory for update
  using (auth.uid() in (
    select id from public.profiles where gym_id = inventory.gym_id
  ));

create policy "Users can delete their gym inventory"
  on public.inventory for delete
  using (auth.uid() in (
    select id from public.profiles where gym_id = inventory.gym_id
  ));

create policy "Users can view inventory purchases"
  on public.inventory_purchases for select
  using (auth.uid() in (
    select id from public.profiles where gym_id = inventory_purchases.gym_id
  ));

create policy "Users can insert inventory purchases"
  on public.inventory_purchases for insert
  with check (auth.uid() in (
    select id from public.profiles where gym_id = inventory_purchases.gym_id
  ));

create policy "Users can view inventory sales"
  on public.inventory_sales for select
  using (auth.uid() in (
    select id from public.profiles where gym_id = inventory_sales.gym_id
  ));

create policy "Users can insert inventory sales"
  on public.inventory_sales for insert
  with check (auth.uid() in (
    select id from public.profiles where gym_id = inventory_sales.gym_id
  ));

-- 7. AUTO-UPDATE TRIGGER for inventory.updated_at
create or replace function public.handle_inventory_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists set_inventory_updated_at on public.inventory;
create trigger set_inventory_updated_at
  before update on public.inventory
  for each row execute function public.handle_inventory_updated_at();

-- ============================================================
-- Performance Indexes (attendance, members)
-- ============================================================

-- Attendance table indexes
create index if not exists idx_attendance_gym_id on public.attendance(gym_id);
create index if not exists idx_attendance_check_in on public.attendance(check_in);
create index if not exists idx_attendance_gym_checkin on public.attendance(gym_id, check_in);
create index if not exists idx_attendance_member_checkin on public.attendance(member_id, check_in);

-- Members search indexes
create index if not exists idx_members_gym_id on public.members(gym_id);
create index if not exists idx_members_phone on public.members(phone);

-- Enable pg_trgm extension for fuzzy text search (if not already enabled)
create extension if not exists pg_trgm;
create index if not exists idx_members_name_trgm on public.members using gin(name gin_trgm_ops);

-- Update gyms subscription constraint (replace 'starter' with 'free')
alter table public.gyms drop constraint if exists gyms_subscription_check;
alter table public.gyms add constraint gyms_subscription_check
  check (subscription in ('free','trial','pro','enterprise'));

-- ============================================================
-- Payment Requests Table (Online Gym Subscription Purchases)
-- ============================================================
create table if not exists public.payment_requests (
  id                   uuid primary key default uuid_generate_v4(),
  gym_id               uuid not null references public.gyms(id) on delete cascade,
  plan_type            text not null check (plan_type in ('free','trial','pro','enterprise')),
  plan_name            text not null default '',
  amount               numeric(10,2) not null check (amount > 0),
  status               text not null default 'pending' check (status in ('pending','completed','failed')),
  razorpay_order_id    text default '',
  razorpay_payment_id  text default '',
  created_by           uuid references public.profiles(id) on delete set null,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now()
);

create index if not exists idx_payment_requests_gym_id on public.payment_requests(gym_id);
create index if not exists idx_payment_requests_status on public.payment_requests(status);

alter table public.payment_requests enable row level security;

create policy "Payment requests visible to gym users"
  on public.payment_requests for select
  using (auth.uid() in (
    select id from public.profiles where gym_id = payment_requests.gym_id
  ));

create policy "Public can view payment request by ID"
  on public.payment_requests for select
  using (true);

create policy "Gym users can insert payment requests"
  on public.payment_requests for insert
  with check (auth.uid() in (
    select id from public.profiles where gym_id = payment_requests.gym_id
  ));

create policy "Service role can update payment requests"
  on public.payment_requests for update
  using (auth.role() = 'service_role');

-- Auto-update trigger for payment_requests.updated_at
create or replace function public.handle_payment_requests_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists set_payment_requests_updated_at on public.payment_requests;
create trigger set_payment_requests_updated_at
  before update on public.payment_requests
  for each row execute function public.handle_payment_requests_updated_at();
