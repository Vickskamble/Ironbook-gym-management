import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_shell.dart';
import '../../core/utils/error_handler.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/language/language_selection_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/auth/gym_setup_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/update_password_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/members/members_screen.dart';
import '../../screens/members/add_member_screen.dart';
import '../../screens/members/edit_member_screen.dart';
import '../../screens/members/member_detail_screen.dart';
import '../../screens/plans/plans_screen.dart';
import '../../screens/plans/add_plan_screen.dart';
import '../../screens/plans/edit_plan_screen.dart';
import '../../screens/plans/plan_detail_screen.dart';
import '../../screens/payments/payments_screen.dart';
import '../../screens/payments/add_payment_screen.dart';
import '../../screens/payments/payment_detail_screen.dart';
import '../../screens/attendance/attendance_screen.dart';
import '../../screens/attendance/mark_attendance_screen.dart';
import '../../screens/attendance/qr_scanner_screen.dart';
import '../../screens/staff/staff_list_screen.dart';
import '../../screens/staff/add_staff_screen.dart';
import '../../screens/staff/staff_detail_screen.dart';
import '../../screens/expenses/expenses_screen.dart';
import '../../screens/expenses/add_expense_screen.dart';
import '../../screens/reports/reports_screen.dart';
import '../../screens/import_export/import_export_screen.dart';
import '../../screens/inventory/inventory_screen.dart';
import '../../screens/inventory/add_inventory_screen.dart';
import '../../screens/inventory/add_stock_screen.dart';
import '../../screens/inventory/sell_inventory_screen.dart';
import '../../screens/inventory/sales_history_screen.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../screens/notifications/bulk_notification_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/settings/pricing_screen.dart';
import '../../screens/settings/profile_screen.dart';
import '../../screens/settings/report_issue_screen.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/admin/gym_list_screen.dart';
import '../../screens/admin/gym_detail_screen.dart';
import '../../screens/admin/staff_list_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerRefreshNotifier = ValueNotifier<int>(0);

final isFirstTimeProvider = StateProvider<bool>((ref) => true);

final routerProvider = Provider<GoRouter>((ref) {
  ErrorHandler.logInfo('RouterProvider', 'Creating GoRouter...');

  ref.listen<AuthState>(authProvider, (prev, authState) {
    if (authState.profile != null || authState.error != null || (prev?.profile != null && authState.profile == null)) {
      ErrorHandler.logStep('Router', 'Auth changed, refreshing router');
      routerRefreshNotifier.value++;
    }
  });

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: routerRefreshNotifier,
    initialLocation: '/',
    redirect: (context, state) {
      try {
        final path = state.matchedLocation;
        ErrorHandler.logStep('Router.redirect', 'Checking path: $path');

        final publicRoutes = ['/', '/language', '/onboarding'];
        if (publicRoutes.contains(path)) return null;

        final authState = ref.read(authProvider);
        final isLoggedIn = authState.profile != null;
        final isLoading = authState.isLoading;
        final role = authState.profile?.role;

        if (isLoading) {
          ErrorHandler.logStep('Router.redirect', 'Auth loading, no redirect');
          return null;
        }

        if (!isLoggedIn) {
          if (path == '/login' || path == '/signup' || path == '/forgot-password' || path == '/update-password' || path == '/language' || path == '/onboarding') return null;
          ErrorHandler.logStep('Router.redirect', 'Not logged in, redirecting to /login');
          return '/login';
        }

        if (path == '/forgot-password' || path == '/update-password') return '/dashboard';

        if (path == '/login' || path == '/signup') {
          final redirect = role == 'superadmin' ? '/admin' : '/dashboard';
          ErrorHandler.logStep('Router.redirect', 'Already logged in, redirecting to $redirect');
          return redirect;
        }

        if (path.startsWith('/admin') && role != 'superadmin') {
          ErrorHandler.logStep('Router.redirect', 'Non-admin trying /admin, redirecting to /dashboard');
          return '/dashboard';
        }

        if (authState.gymId == null && path != '/gym-setup') {
          ErrorHandler.logStep('Router.redirect', 'No gym set up, redirecting to /gym-setup');
          return '/gym-setup';
        }

        return null;
      } catch (e, stack) {
        ErrorHandler.logError('Router.redirect', e, stack);
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
        path: '/gym-setup',
        builder: (_, _) => const GymSetupScreen(),
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
      GoRoute(
        path: '/forgot-password',
        name: 'forgotPassword',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/update-password',
        name: 'updatePassword',
        builder: (_, _) => const UpdatePasswordScreen(),
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
            path: '/plans/:planId',
            name: 'planDetail',
            builder: (_, state) => PlanDetailScreen(
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
            path: '/attendance/qr-scanner',
            name: 'qrScanner',
            builder: (_, _) => const QrScannerScreen(),
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
            path: '/inventory',
            name: 'inventory',
            builder: (_, _) => const InventoryScreen(),
          ),
          GoRoute(
            path: '/inventory/add',
            name: 'addInventory',
            builder: (_, _) => const AddInventoryScreen(),
          ),
          GoRoute(
            path: '/inventory/add-stock/:id',
            name: 'addStock',
            builder: (_, state) => AddStockScreen(
              itemId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/inventory/sell/:id',
            name: 'sellInventory',
            builder: (_, state) => SellInventoryScreen(
              itemId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/inventory/sales',
            name: 'inventorySales',
            builder: (_, _) => const SalesHistoryScreen(),
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
            path: '/subscription',
            name: 'subscription',
            builder: (_, _) => const PricingScreen(),
          ),
          GoRoute(
            path: '/settings/profile',
            name: 'profile',
            builder: (_, _) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/settings/report-issue',
            name: 'reportIssue',
            builder: (_, _) => const ReportIssueScreen(),
          ),
          GoRoute(
            path: '/admin',
            name: 'adminDashboard',
            builder: (_, _) => const AdminDashboardScreen(),
            routes: [
              GoRoute(
                path: 'staff',
                name: 'adminStaffList',
                builder: (_, _) => const AdminStaffListScreen(),
              ),
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
