-- ============================================================
-- SEED DATA — Dev/test ke liye dummy data
-- YE PRODUCTION MEIN KABHI MAT CHALANA
-- ============================================================

-- Only insert if tables are empty
do $$
begin
  if not exists (select 1 from public.gyms limit 1) then
    -- Demo Gym
    insert into public.gyms (id, name, address, phone, owner_id, subscription)
    values (
      '00000000-0000-0000-0000-000000000001',
      'IronBook Demo Gym',
      '123 Fitness Street, Mumbai',
      '9876543210',
      (select id from public.profiles limit 1),
      'free'
    );

    -- Demo Plans
    insert into public.plans (gym_id, name, description, price, duration_days, features) values
      ('00000000-0000-0000-0000-000000000001', 'Basic', 'Basic plan', 999, 30, '["Gym Access","Locker"]'::jsonb),
      ('00000000-0000-0000-0000-000000000001', 'Standard', 'Standard plan', 1999, 90, '["Gym Access","Locker","Trainer"]'::jsonb),
      ('00000000-0000-0000-0000-000000000001', 'Premium', 'Premium plan', 2999, 180, '["Gym Access","Locker","Trainer","Steam"]'::jsonb);

    -- Demo Members
    insert into public.members (gym_id, name, phone, email, plan_name, status, membership_start, membership_end) values
      ('00000000-0000-0000-0000-000000000001', 'Rahul Sharma', '9876543211', 'rahul@test.com', 'Basic', 'Active', current_date, current_date + interval '30 days'),
      ('00000000-0000-0000-0000-000000000001', 'Priya Patel', '9876543212', 'priya@test.com', 'Premium', 'Active', current_date, current_date + interval '180 days'),
      ('00000000-0000-0000-0000-000000000001', 'Amit Singh', '9876543213', 'amit@test.com', 'Standard', 'Expired', current_date - interval '60 days', current_date - interval '30 days');
  end if;
end $$;
