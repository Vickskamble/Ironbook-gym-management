import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/payment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class PaymentDetailScreen extends ConsumerStatefulWidget {
  final String paymentId;
  const PaymentDetailScreen({super.key, required this.paymentId});

  @override
  ConsumerState<PaymentDetailScreen> createState() =>
      _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends ConsumerState<PaymentDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final gymId = ref.watch(authProvider.select((s) => s.gymId));
    if (gymId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final paymentAsync = ref.watch(paymentDetailProvider((gymId: gymId, memberId: widget.paymentId)));
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Details'),
        actions: [
          paymentAsync.whenOrNull(
            data: (_) => PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text(AppStrings.confirmDelete),
                      content: const Text(
                          'Are you sure you want to delete this payment?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text(AppStrings.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(AppStrings.delete,
                              style: TextStyle(color: AppColors.danger)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref
                        .read(paymentListProvider(
                                ref.read(authProvider).gymId!)
                            .notifier)
                        .deletePayment(widget.paymentId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Payment deleted successfully')),
                      );
                      context.pop();
                    }
                  }
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: AppColors.danger),
                      SizedBox(width: 8),
                      Text(AppStrings.delete,
                          style: TextStyle(color: AppColors.danger)),
                    ],
                  ),
                ),
              ],
            ),
          ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: paymentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (payment) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor:
                        AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      (payment.memberName ?? '?')[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 36,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    payment.memberName ?? 'Unknown Member',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: payment.nextDueDate != null && payment.nextDueDate!.isAfter(DateTime.now())
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      payment.nextDueDate != null && payment.nextDueDate!.isAfter(DateTime.now()) ? 'Active' : 'Expired',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: payment.nextDueDate != null && payment.nextDueDate!.isAfter(DateTime.now())
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _buildInfoRow(Icons.attach_money, 'Amount',
                    currencyFormat.format(payment.amount)),
                const Divider(),
                _buildInfoRow(Icons.event_note, 'Plan',
                    payment.planName ?? 'No Plan'),
                const Divider(),
                _buildInfoRow(
                    Icons.payment, 'Payment Method', payment.method),
                const Divider(),
                _buildInfoRow(Icons.calendar_today, 'Paid Date',
                    DateFormat('dd MMM yyyy').format(payment.paidAt)),
                const Divider(),
                _buildInfoRow(Icons.update, 'Expiry Date',
                    payment.nextDueDate != null ? DateFormat('dd MMM yyyy').format(payment.nextDueDate!) : 'N/A'),
                if (payment.note != null && payment.note!.isNotEmpty) ...[
                  const Divider(),
                  _buildInfoRow(
                      Icons.notes, 'Notes', payment.note!),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
