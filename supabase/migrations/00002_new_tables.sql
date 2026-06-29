-- Create attendance table
CREATE TABLE IF NOT EXISTS attendance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  gym_id UUID NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,
  member_id UUID NOT NULL REFERENCES members(id) ON DELETE CASCADE,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  check_in TIME NOT NULL DEFAULT CURRENT_TIME,
  check_out TIME,
  status TEXT NOT NULL DEFAULT 'Present' CHECK (status IN ('Present', 'Absent', 'Late', 'Half Day')),
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their gym attendance"
  ON attendance FOR SELECT
  USING (gym_id IN (SELECT id FROM gyms WHERE owner_id = auth.uid()));

CREATE POLICY "Users can insert attendance"
  ON attendance FOR INSERT
  WITH CHECK (gym_id IN (SELECT id FROM gyms WHERE owner_id = auth.uid()));

CREATE POLICY "Users can update attendance"
  ON attendance FOR UPDATE
  USING (gym_id IN (SELECT id FROM gyms WHERE owner_id = auth.uid()));

-- Create expenses table
CREATE TABLE IF NOT EXISTS expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  gym_id UUID NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,
  category TEXT NOT NULL,
  amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
  description TEXT NOT NULL,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  receipt TEXT,
  notes TEXT,
  status TEXT NOT NULL DEFAULT 'Active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their gym expenses"
  ON expenses FOR SELECT
  USING (gym_id IN (SELECT id FROM gyms WHERE owner_id = auth.uid()));

CREATE POLICY "Users can insert expenses"
  ON expenses FOR INSERT
  WITH CHECK (gym_id IN (SELECT id FROM gyms WHERE owner_id = auth.uid()));

CREATE POLICY "Users can update expenses"
  ON expenses FOR UPDATE
  USING (gym_id IN (SELECT id FROM gyms WHERE owner_id = auth.uid()));

-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  gym_id UUID NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'info' CHECK (type IN ('info', 'warning', 'success', 'error')),
  is_read BOOLEAN NOT NULL DEFAULT false,
  data JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their gym notifications"
  ON notifications FOR SELECT
  USING (gym_id IN (SELECT id FROM gyms WHERE owner_id = auth.uid()));

CREATE POLICY "Users can update notifications"
  ON notifications FOR UPDATE
  USING (gym_id IN (SELECT id FROM gyms WHERE owner_id = auth.uid()));

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_attendance_gym_date ON attendance(gym_id, date);
CREATE INDEX IF NOT EXISTS idx_attendance_member ON attendance(member_id);
CREATE INDEX IF NOT EXISTS idx_expenses_gym ON expenses(gym_id);
CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(gym_id, category);
CREATE INDEX IF NOT EXISTS idx_notifications_gym ON notifications(gym_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(gym_id, is_read);
