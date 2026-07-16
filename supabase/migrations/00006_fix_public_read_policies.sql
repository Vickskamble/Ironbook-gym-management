-- Remove public read access on payment_requests
drop policy if exists "Public can view payment request by ID" on public.payment_requests;

-- Add INSERT/DELETE policies for notifications
create policy "Users can insert notifications for their gym"
  on public.notifications for insert
  with check (gym_id in (select id from public.gyms where owner_id = auth.uid()));

create policy "Users can delete notifications for their gym"
  on public.notifications for delete
  using (gym_id in (select id from public.gyms where owner_id = auth.uid()));

-- Add UPDATE policy for issue_reports
create policy "Users can update their own reports"
  on public.issue_reports for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Restrict admin profile insert to their own gym
drop policy if exists "Admins can insert profiles" on public.profiles;
create policy "Admins can insert profiles"
  on public.profiles for insert
  to authenticated
  with check (
    (auth.uid() in (select id from public.profiles where role in ('admin', 'superadmin') and gym_id = profiles.gym_id))
    or
    (auth.uid() = id)
  );
