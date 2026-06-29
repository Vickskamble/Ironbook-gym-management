import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/payment_model.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final gymId = ref.watch(authProvider).gymId;
    if (gymId == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: Text('No gym selected')),
      );
    }

    final paymentsAsync = ref.watch(paymentListProvider(gymId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: paymentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
          data: (payments) {
            final now = DateTime.now();
            final thisMonthPayments = payments
                .where((p) => p.paidAt.month == now.month && p.paidAt.year == now.year)
                .toList();
            final monthlyTotal =
                thisMonthPayments.fold<double>(0, (sum, p) => sum + p.finalAmount);

            List<PaymentModel> filtered;
            switch (_filter) {
              case 'Paid':
                filtered = payments.where((p) => p.method != 'pending').toList();
                break;
              case 'Pending':
                filtered = payments.where((p) => p.method == 'pending').toList();
                break;
              case 'This Month':
                filtered = thisMonthPayments;
                break;
              default:
                filtered = payments;
            }

            return Column(
              children: [
                _buildSummaryCard(monthlyTotal, thisMonthPayments.length),
                const SizedBox(height: 12),
                _buildFilterChips(payments.length, thisMonthPayments.length),
                const SizedBox(height: 12),
                Expanded(child: _buildPaymentList(filtered)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double total, int count) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withValues(alpha: 0.1),
            const Color(0xFF10B981).withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x2610B981)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Collected This Month',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                Text('Rs${total.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                const SizedBox(height: 2),
                Text('$count transaction${count == 1 ? '' : 's'}',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Text('\u{1F4B0}', style: TextStyle(fontSize: 36)),
        ],
      ),
    );
  }

  Widget _buildFilterChips(int totalCount, int monthCount) {
    final chips = [
      ('All ($totalCount)', 'All'),
      ('Paid', 'Paid'),
      ('Pending', 'Pending'),
      ('This Month ($monthCount)', 'This Month'),
    ];

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: chips.map((c) {
          final selected = _filter == c.$2;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => setState(() => _filter = c.$2),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                ),
                child: Text(c.$1,
                    style: TextStyle(
                        color: selected ? Colors.white : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentList(List<PaymentModel> payments) {
    if (payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('\u{1F4B0}', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('No transactions yet',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final p = payments[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('\u{2713}',
                        style: TextStyle(color: Color(0xFF10B981), fontSize: 20, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.memberName ?? 'Unknown',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 1),
                      Text(p.planName ?? 'No plan',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text('Rs${p.finalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                          const Spacer(),
                          Icon(Icons.calendar_today_rounded, size: 11, color: AppColors.textMuted),
                          const SizedBox(width: 3),
                          Text(_formatDate(p.paidAt),
                              style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Text('Paid',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => context.push('/payments/${p.id}'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0x336366F1),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text('Receipt',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF818CF8))),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
