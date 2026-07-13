import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../models/gym_model.dart';
import '../../repositories/payment_request_repository.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/error_handler.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/primary_button.dart';
import '../../core/services/subscription_service.dart';

class PricingScreen extends ConsumerStatefulWidget {
  const PricingScreen({super.key});

  @override
  ConsumerState<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends ConsumerState<PricingScreen> {
  String? _upgradingPlan;
  final bool _showFreeBanner = true;
  bool _isAnnual = false;
  RealtimeChannel? _realtimeChannel;
  Razorpay? _razorpay;

  @override
  void initState() {
    super.initState();
    _initRazorpay();
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) {
    ErrorHandler.logInfo('PricingScreen', 'Payment success: ${response.paymentId}');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful! Activating plan...'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    ErrorHandler.logError('PricingScreen', response.message, null);
    if (mounted) {
      setState(() => _upgradingPlan = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${response.message ?? "Please try again"}'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  void dispose() {
    _razorpay?.clear();
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  void _listenForPayment(String requestId) {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = Supabase.instance.client
        .channel('payment-request-$requestId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'payment_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: requestId,
          ),
          callback: (payload) {
            final newStatus = payload.newRecord['status'] as String?;
            if (newStatus == 'completed' && mounted) {
              _realtimeChannel?.unsubscribe();
              ref.read(authProvider.notifier).refreshGym();
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  title: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
                  content: const Text(
                    'Payment verified! Your plan has been activated.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        setState(() => _upgradingPlan = null);
                      },
                      child: const Text('OK', style: TextStyle(color: AppColors.primary)),
                    ),
                  ],
                ),
              );
            }
          },
        )
        .subscribe();
  }

  Future<void> _initiatePayment(String planName) async {
    final authState = ref.read(authProvider);
    final gymId = authState.gymId;
    if (gymId == null) return;

    final tier = SubscriptionService.getTier(planName.toLowerCase());
    if (tier == null || tier.price <= 0) return;

    setState(() => _upgradingPlan = planName);

    try {
      final repo = PaymentRequestRepository(Supabase.instance.client);
      final request = await repo.create(
        gymId: gymId,
        planType: planName.toLowerCase(),
        planName: tier.name,
        amount: tier.price,
      );

      _listenForPayment(request['id']);

      final response = await Supabase.instance.client.functions.invoke(
        'handle-payment',
        body: {
          'action': 'create-order',
          'request_id': request['id'],
        },
      );

      final orderData = response.data as Map<String, dynamic>;
      _razorpay!.open({
        'key': orderData['key_id'],
        'order_id': orderData['id'],
        'amount': orderData['amount'],
        'name': 'IronBook',
        'description': orderData['description'] ?? '${tier.name} Plan',
        'theme': {'color': '#6366F1'},
      });
    } catch (e, stack) {
      ErrorHandler.logError('PricingScreen._initiatePayment', e, stack);
      if (mounted) {
        setState(() => _upgradingPlan = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final gymAsync = ref.watch(gymProvider(authState.gymId ?? ''));
    final gym = gymAsync.asData?.value ?? authState.gym;
    final isFree = gym == null || gym.subscription == 'free';
    final currentPlan = gym?.subscription ?? 'free';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildCurrentPlanBanner(gym),
                  if (_showFreeBanner || isFree) ...[
                    const SizedBox(height: 20),
                    _buildPlanCard(
                      tier: SubscriptionService.getTier('free')!,
                      isCurrent: isFree,
                      isUpgrading: false,
                      onUpgrade: null,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 3,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Choose a Plan',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildBillingToggle(),
                  const SizedBox(height: 20),
                  ...SubscriptionService.tiers
                      .where((t) => t.id != 'free')
                      .map(
                        (tier) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildPlanCard(
                            tier: tier,
                            isCurrent: tier.id == currentPlan,
                            isUpgrading: _upgradingPlan == tier.name,
                            onUpgrade: tier.id == currentPlan
                                ? null
                                : () => _confirmSwitch(tier.name),
                          ),
                        ),
                      ),
                  const SizedBox(height: 32),
                  _buildTrustFooter(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPlanBanner(GymModel? gym) {
    if (gym == null) return const SizedBox.shrink();

    final isActive = gym.isActive;
    final subscription = gym.subscription;
    final expiresAt = gym.subscriptionExpiresAt;
    final tier = SubscriptionService.getTier(subscription);
    final planLabel = tier?.name ?? 'Free';
    final statusLabel = isActive ? 'Active' : 'Expired';
    final statusColor = isActive ? AppColors.success : AppColors.danger;

    int? daysRemaining;
    if (expiresAt != null) {
      daysRemaining = expiresAt.difference(DateTime.now()).inDays;
      if (daysRemaining < 0) daysRemaining = 0;
    }

    return GlassContainer(
      borderColor: statusColor.withValues(alpha: 0.6),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                planLabel,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (expiresAt != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Expires: ${_formatDate(expiresAt)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (daysRemaining != null && isActive) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$daysRemaining days remaining',
                    style: TextStyle(
                      fontSize: 13,
                      color: daysRemaining <= 7
                          ? AppColors.warning
                          : AppColors.textSecondary,
                      fontWeight: daysRemaining <= 7
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ],
          if (subscription == 'free') ...[
            const SizedBox(height: 14),
            Text(
              'Upgrade to unlock premium features',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required SubscriptionTier tier,
    required bool isCurrent,
    required bool isUpgrading,
    required VoidCallback? onUpgrade,
  }) {
    final isFree = tier.id == 'free';
    final useAnnual = _isAnnual && tier.annualPrice > 0;
    final displayPrice = useAnnual ? tier.annualPrice : tier.price;
    final displayPeriod = useAnnual ? tier.annualPeriod : tier.period;
    final priceDisplay = displayPrice == 0
        ? 'Free'
        : '\u20B9${_formatPrice(displayPrice.toDouble())}';

    final savingsPercent = tier.annualPrice > 0 && tier.price > 0
        ? ((1 - (tier.annualPrice / (tier.price * 12))) * 100).round()
        : 0;

    return GlassContainer(
      borderColor: isCurrent
          ? AppColors.primary.withValues(alpha: 0.3)
          : tier.isPopular
              ? AppColors.primary.withValues(alpha: 0.5)
              : null,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (tier.isPopular && !isCurrent) ...[
                _buildPopularBadge(),
                const SizedBox(width: 10),
              ],
              Text(
                tier.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.3,
                ),
              ),
              if (isCurrent) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Text(
                    'Current Plan',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                priceDisplay,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              if (displayPeriod.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 2),
                  child: Text(
                    displayPeriod,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          if (useAnnual && savingsPercent > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.savings_rounded, size: 14, color: AppColors.success),
                const SizedBox(width: 4),
                Text(
                  'Save $savingsPercent% with annual billing',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 22),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 18),
          ...tier.features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      f,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (!isFree && onUpgrade != null) ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: PrimaryButton(
                text: _getButtonLabel(tier.name),
                loading: isUpgrading,
                onPressed: onUpgrade,
              ),
            ),
          ],
          if (isCurrent && !isFree)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: PrimaryButton(
                text: 'Current Plan',
                backgroundColor: AppColors.surface2,
                onPressed: null,
              ),
            ),
          if (isFree && !isCurrent)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: PrimaryButton(
                text: 'Free \u2014 Get Started',
                onPressed: onUpgrade,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPopularBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 12, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'Most Popular',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isAnnual = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isAnnual ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Monthly',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: !_isAnnual ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isAnnual = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isAnnual ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Annual',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _isAnnual ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Save 2',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _trustItem(Icons.lock_rounded, 'Secure Payment'),
            const SizedBox(width: 24),
            _trustItem(Icons.replay_rounded, '7-Day Refund'),
            const SizedBox(width: 24),
            _trustItem(Icons.headset_mic_rounded, 'Priority Support'),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Switch or cancel anytime. No hidden charges.',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _trustItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getButtonLabel(String targetPlanName) {
    if (targetPlanName.toLowerCase() == 'trial') return 'Try for ₹1';
    final authState = ref.read(authProvider);
    final current = authState.gym?.subscription ?? 'free';
    final isDowngrade = SubscriptionService.isDowngrade(current, targetPlanName.toLowerCase());
    return isDowngrade ? 'Downgrade' : 'Upgrade';
  }

  Future<void> _confirmSwitch(String planName) async {
    final authState = ref.read(authProvider);
    final current = authState.gym?.subscription ?? 'free';
    final isDowngrade = SubscriptionService.isDowngrade(current, planName.toLowerCase());

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        title: Text(
          '${isDowngrade ? 'Downgrade' : 'Switch'} to $planName?',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          isDowngrade
              ? 'Your current subscription will be replaced with the $planName plan. Some features may become unavailable.'
              : 'You will be redirected to the payment page to complete the purchase.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              isDowngrade ? 'Downgrade' : 'Pay Online',
              style: TextStyle(
                color: isDowngrade ? AppColors.warning : AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _performSwitch(planName, isDowngrade);
    }
  }

  Future<void> _performSwitch(String planName, bool isDowngrade) async {
    final authState = ref.read(authProvider);
    final gym = authState.gym;
    final gymId = authState.gymId;

    if (gymId == null || gym == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gym information not available')),
        );
      }
      return;
    }

    setState(() => _upgradingPlan = planName);

    try {
      if (isDowngrade) {
        final service = ref.read(subscriptionServiceProvider);
        await service.downgradePlan(gymId: gymId, plan: planName.toLowerCase(), context: context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Downgraded to $planName'),
              backgroundColor: AppColors.success,
            ),
          );
          ref.invalidate(authProvider);
        }
      } else {
        await _initiatePayment(planName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${e.toString()}'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _upgradingPlan = null);
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      final thousands = (price / 1000).floor();
      final remainder = (price % 1000).toInt();
      return '$thousands,${remainder.toString().padLeft(3, '0')}';
    }
    return price.toStringAsFixed(0);
  }
}
