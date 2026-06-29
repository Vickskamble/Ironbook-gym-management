import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_shell.dart';

import '../../screens/splash/splash_screen.dart';
import '../../screens/language/language_selection_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/members/members_screen.dart';
import '../../screens/members/add_member_screen.dart';
import '../../screens/members/edit_member_screen.dart';
import '../../screens/members/member_detail_screen.dart';
import '../../screens/plans/plans_screen.dart';
import '../../screens/plans/add_plan_screen.dart';
import '../../screens/plans/edit_plan_screen.dart';
import '../../screens/payments/payments_screen.dart';
import '../../screens/payments/add_payment_screen.dart';
import '../../screens/payments/payment_detail_screen.dart';
import '../../screens/attendance/attendance_screen.dart';
import '../../screens/attendance/mark_attendance_screen.dart';
import '../../screens/staff/staff_list_screen.dart';
import '../../screens/staff/add_staff_screen.dart';
import '../../screens/staff/staff_detail_screen.dart';
import '../../screens/expenses/expenses_screen.dart';
import '../../screens/expenses/add_expense_screen.dart';
import '../../screens/reports/reports_screen.dart';
import '../../screens/import_export/import_export_screen.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../screens/notifications/bulk_notification_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/settings/pricing_screen.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/admin/gym_list_screen.dart';
import '../../screens/admin/gym_detail_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final isFirstTimeProvider = StateProvider<bool>((ref) => true);

final routerProvider = Provider<GoRouter>((ref) {
  debugPrint('[Router] Creating GoRouter...');
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      try {
        final authState = ref.read(authProvider);
        final isFirstTime = ref.read(isFirstTimeProvider);
        final path = state.matchedLocation;
        final isLoggedIn = authState.profile != null;
        final isLoading = authState.isLoading;
        final role = authState.profile?.role;

        final publicRoutes = ['/', '/language', '/onboarding'];
        if (publicRoutes.contains(path)) return null;

        if (isLoading) return null;

        if (!isLoggedIn) {
          if (path == '/login' || path == '/signup') return null;
          return isFirstTime ? '/language' : '/login';
        }

        if (path == '/login' || path == '/signup') {
          return role == 'superadmin' ? '/admin' : '/dashboard';
        }

        if (path.startsWith('/admin') && role != 'superadmin') {
          return '/dashboard';
        }

        return null;
      } catch (e, stack) {
        debugPrint('[Router] Redirect error: $e\n$stack');
        return null;
      }
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: '/language',
        builder: (_, _) => const LanguageSelectionScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'register',
        builder: (_, _) => const SignupScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (_, _, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (_, _) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/members',
            name: 'members',
            builder: (_, _) => const MembersScreen(),
          ),
          GoRoute(
            path: '/members/add',
            name: 'addMember',
            builder: (_, _) => const AddMemberScreen(),
          ),
          GoRoute(
            path: '/members/edit/:id',
            name: 'editMember',
            builder: (_, state) => EditMemberScreen(
              memberId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/members/:id',
            name: 'memberDetail',
            builder: (_, state) => MemberDetailScreen(
              memberId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/plans',
            name: 'plans',
            builder: (_, _) => const PlansScreen(),
          ),
          GoRoute(
            path: '/plans/add',
            name: 'addPlan',
            builder: (_, _) => const AddPlanScreen(),
          ),
          GoRoute(
            path: '/plans/edit/:planId',
            name: 'editPlan',
            builder: (_, state) => EditPlanScreen(
              planId: state.pathParameters['planId']!,
            ),
          ),
          GoRoute(
            path: '/payments',
            name: 'payments',
            builder: (_, _) => const PaymentsScreen(),
          ),
          GoRoute(
            path: '/payments/add',
            name: 'addPayment',
            builder: (_, _) => const AddPaymentScreen(),
          ),
          GoRoute(
            path: '/payments/:id',
            name: 'paymentDetail',
            builder: (_, state) => PaymentDetailScreen(
              paymentId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/attendance',
            name: 'attendance',
            builder: (_, _) => const AttendanceScreen(),
          ),
          GoRoute(
            path: '/attendance/mark',
            name: 'markAttendance',
            builder: (_, _) => const MarkAttendanceScreen(),
          ),
          GoRoute(
            path: '/staff',
            name: 'staff',
            builder: (_, _) => const StaffListScreen(),
          ),
          GoRoute(
            path: '/staff/add',
            name: 'addStaff',
            builder: (_, _) => const AddStaffScreen(),
          ),
          GoRoute(
            path: '/staff/:id',
            name: 'staffDetail',
            builder: (_, state) => StaffDetailScreen(
              staffId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/expenses',
            name: 'expenses',
            builder: (_, _) => const ExpensesScreen(),
          ),
          GoRoute(
            path: '/expenses/add',
            name: 'addExpense',
            builder: (_, _) => const AddExpenseScreen(),
          ),
          GoRoute(
            path: '/reports',
            name: 'reports',
            builder: (_, _) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/import-export',
            name: 'importExport',
            builder: (_, _) => const ImportExportScreen(),
          ),
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            builder: (_, _) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/notifications/bulk',
            name: 'bulkNotification',
            builder: (_, _) => const BulkNotificationScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (_, _) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/settings/pricing',
            name: 'pricing',
            builder: (_, _) => const PricingScreen(),
          ),
          GoRoute(
            path: '/admin',
            name: 'adminDashboard',
            builder: (_, _) => const AdminDashboardScreen(),
            routes: [
              GoRoute(
                path: 'gyms',
                name: 'allGyms',
                builder: (_, _) => const GymListScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    name: 'gymDetail',
                    builder: (_, state) => GymDetailScreen(
                      gymId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
