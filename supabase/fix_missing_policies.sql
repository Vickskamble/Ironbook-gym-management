-- ============================================================
-- IronBook — Fix Missing RLS Policies & Storage Buckets
-- Run this in your Supabase SQL Editor
-- ============================================================

-- 1. Add missing UPDATE/DELETE policies for inventory_purchases
create policy "Users can update inventory purchases at their gym"
  on public.inventory_purchases for update
  using (auth.uid() in (
    select id from public.profiles where gym_id = inventory_purchases.gym_id
  ));

create policy "Users can delete inventory purchases at their gym"
  on public.inventory_purchases for delete
  using (auth.uid() in (
    select id from public.profiles where gym_id = inventory_purchases.gym_id
  ));

-- 2. Create receipts storage bucket for expense receipts
insert into storage.buckets (id, name, public)
values ('receipts', 'receipts', true)
on conflict (id) do nothing;

create policy "Receipt files are publicly accessible"
  on storage.objects for select
  using ( bucket_id = 'receipts' );

create policy "Users can upload receipt files"
  on storage.objects for insert
  with check (
    bucket_id = 'receipts'
    and auth.role() = 'authenticated'
  );

create policy "Users can update own receipts"
  on storage.objects for update
  using (
    bucket_id = 'receipts'
    and auth.uid() = owner
  );

create policy "Users can delete own receipts"
  on storage.objects for delete
  using (
    bucket_id = 'receipts'
    and auth.uid() = owner
  );
