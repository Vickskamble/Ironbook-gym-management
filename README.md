# IronBook

A SaaS Multi-Gym Management App built with Flutter + Supabase.

## Features

- **Member Management** — Add, edit, search, track membership expiry
- **Plans** — Create membership plans with pricing & duration
- **Payments** — Record payments with discounts, multiple methods (Cash/UPI/Card)
- **Attendance** — Check-in/check-out tracking, QR code scanner
- **Staff** — Role-based staff management (owner, admin, trainer, staff)
- **Expenses** — Track gym expenses by category
- **Reports** — Export PDF/CSV/Excel (members, revenue, attendance, expenses)
- **Notifications** — Real-time via Supabase Realtime, in-app alerts
- **Import/Export** — Bulk import members from CSV, export all reports
- **Admin Panel** — Superadmin dashboard for multi-gym management
- **Multi-language** — English, Hindi, Marathi

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Riverpod, GoRouter) |
| Backend | Supabase (PostgreSQL, Auth, Realtime, Storage) |
| State | Riverpod (StateNotifier + FutureProvider) |
| Routing | GoRouter (auth guards, shell routes) |
| Reports | PDF, Excel, CSV |
| Scanning | Mobile Scanner (QR) |

## Setup

### Prerequisites
- Flutter SDK >= 3.11.4
- Supabase project

### Steps

```bash
# 1. Clone
git clone https://github.com/your-username/ironbook.git
cd ironbook

# 2. Create .env file
cp .env.example .env

# 3. Add your Supabase credentials in .env
#    Get these from your Supabase project dashboard
#    Settings → API → Project URL + anon key
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here

# 4. Run database migrations
#    Open supabase_schema.sql in Supabase SQL Editor and run it
#    Then run supabase_migration.sql

# 5. (Optional) Seed demo data
#    Open supabase/seed.sql in Supabase SQL Editor and run it

# 6. Install dependencies & run
flutter pub get
flutter run
```

### Database Setup
1. Go to your Supabase project dashboard
2. Open **SQL Editor**
3. Copy-paste and run **`supabase_schema.sql`** (creates all tables, indexes, RLS policies, triggers)
4. Then run **`supabase_migration.sql`** (creates gym_settings & import_logs tables)
5. (Optional) Run **`supabase/seed.sql`** for demo data

## Project Structure

```
lib/
├── core/
│   ├── constants/        # Colors, strings
│   ├── router/           # GoRouter + auth guards
│   ├── services/         # Notifications, offline queue, subscription
│   ├── theme/            # Dark theme
│   └── utils/            # Validators, error handler, network
├── models/               # Data models (member, plan, payment, etc.)
├── providers/            # Riverpod state providers
├── repositories/         # Supabase data access layer
├── screens/              # UI screens (auth, members, plans, etc.)
└── widgets/              # Reusable widgets (glass, buttons, cards)
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `SUPABASE_URL` | Yes | Supabase project URL |
| `SUPABASE_ANON_KEY` | Yes | Supabase anonymous key |

## Security

- Row-Level Security (RLS) enforced on all tables
- Field whitelisting prevents mass assignment
- Role escalation protection at API and DB level
- CSV formula injection protection
- File upload validation (type, size, magic bytes)
- Password minimum 8 characters
- No PII in application logs

## License

MIT
