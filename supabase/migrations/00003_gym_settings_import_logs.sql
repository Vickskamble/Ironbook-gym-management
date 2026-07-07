-- Migration: gym_settings and import_logs tables
create table if not exists public.gym_settings (
  id              uuid primary key default uuid_generate_v4(),
  gym_id          uuid not null references public.gyms(id) on delete cascade unique,
  settings        jsonb not null default '{}'::jsonb,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

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

create index if not exists idx_gym_settings_gym_id on public.gym_settings(gym_id);
create index if not exists idx_import_logs_gym_id on public.import_logs(gym_id);

alter table public.gym_settings enable row level security;
alter table public.import_logs enable row level security;

-- Policies for gym_settings
create policy "Users can view their gym settings"
  on public.gym_settings for select
  using (gym_id = public.current_user_gym_id() or is_superadmin());

create policy "Users can insert their gym settings"
  on public.gym_settings for insert
  with check (gym_id = public.current_user_gym_id() or is_superadmin());

create policy "Users can update their gym settings"
  on public.gym_settings for update
  using (gym_id = public.current_user_gym_id() or is_superadmin());

-- Policies for import_logs
create policy "Users can view import logs for their gym"
  on public.import_logs for select
  using (gym_id = public.current_user_gym_id() or is_superadmin());

create policy "Users can insert import logs for their gym"
  on public.import_logs for insert
  with check (gym_id = public.current_user_gym_id() or is_superadmin());

-- Trigger for gym_settings updated_at
drop trigger if exists trg_gym_settings_updated_at on public.gym_settings;
create trigger trg_gym_settings_updated_at
  before update on public.gym_settings
  for each row execute function public.update_timestamp();
