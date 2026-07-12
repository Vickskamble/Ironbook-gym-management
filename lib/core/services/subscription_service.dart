import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../repositories/gym_repository.dart';
import 'payment_service.dart';

class SubscriptionTier {
  final String id;
  final String name;
  final double price;
  final double annualPrice;
  final String period;
  final String annualPeriod;
  final List<String> features;
  final int memberLimit;
  final int maxPlans;
  final int locationLimit;
  final bool isPopular;
  final bool hasCustomBranding;
  final bool hasDedicatedManager;
  final bool hasApiAccess;
  final bool hasWhiteLabel;

  const SubscriptionTier({
    required this.id,
    required this.name,
    required this.price,
    required this.period,
    this.annualPrice = 0,
    this.annualPeriod = '',
    required this.features,
    required this.memberLimit,
    this.maxPlans = 3,
    required this.locationLimit,
    this.isPopular = false,
    this.hasCustomBranding = false,
    this.hasDedicatedManager = false,
    this.hasApiAccess = false,
    this.hasWhiteLabel = false,
  });
}

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService(GymRepository(Supabase.instance.client));
});

class SubscriptionService {
  final GymRepository _gymRepository;

  SubscriptionService(this._gymRepository);

  static const List<SubscriptionTier> tiers = [
    SubscriptionTier(
      id: 'free',
      name: 'Free',
      price: 0,
      period: '',
      annualPrice: 0,
      annualPeriod: '',
      features: [
        'Up to 25 members',
        'Up to 3 membership plans',
        'Basic member management',
        'Manual attendance',
        'Basic fee collection',
        'Basic dashboard reports',
        'Single branch',
      ],
      memberLimit: 25,
      maxPlans: 3,
      locationLimit: 1,
    ),
    SubscriptionTier(
      id: 'pro',
      name: 'Pro',
      price: 499,
      period: '/month',
      annualPrice: 4999,
      annualPeriod: '/year',
      features: [
        'Up to 200 members',
        'Unlimited membership plans',
        'QR code attendance & check-in',
        'Fee collection & expense tracking',
        'Staff management',
        'WhatsApp reminders (100/mo)',
        'Excel / PDF export & import',
        'Bulk notifications',
        'Advanced reports & analytics',
        'Up to 2 branches',
        'Custom branding (logo)',
        'Priority email support',
      ],
      memberLimit: 200,
      maxPlans: -1,
      locationLimit: 2,
      isPopular: true,
      hasCustomBranding: true,
    ),
    SubscriptionTier(
      id: 'enterprise',
      name: 'Enterprise',
      price: 999,
      period: '/month',
      annualPrice: 9999,
      annualPeriod: '/year',
      features: [
        'Unlimited members',
        'Unlimited membership plans',
        'All Pro features',
        'Unlimited WhatsApp reminders',
        'Inventory management',
        'Unlimited branches',
        'Dedicated account manager',
        'API access',
        'White-label option',
        'Phone & chat priority support',
        'Custom integrations',
        'Early access to new features',
      ],
      memberLimit: -1,
      maxPlans: -1,
      locationLimit: -1,
      hasCustomBranding: true,
      hasDedicatedManager: true,
      hasApiAccess: true,
      hasWhiteLabel: true,
    ),
    SubscriptionTier(
      id: 'trial',
      name: 'Trial',
      price: 1,
      period: '/week',
      annualPrice: 0,
      annualPeriod: '',
      features: [
        'Full Pro access for 7 days',
        'Up to 200 members & unlimited plans',
        'QR code attendance & check-in',
        'Fee collection & expense tracking',
        'Staff management',
        'WhatsApp reminders (100/mo)',
        'Excel / PDF export & import',
        'Bulk notifications',
        'Advanced reports & analytics',
        'Up to 2 branches',
        'Custom branding (logo)',
        'Priority email support',
      ],
      memberLimit: 200,
      maxPlans: -1,
      locationLimit: 2,
      hasCustomBranding: true,
    ),
  ];

  static final Map<String, SubscriptionTier> _tierMap =
      {for (final t in tiers) t.id: t};

  static final _planOrder = ['free', 'trial', 'pro', 'enterprise'];

  static List<String> getPlanFeatures(String plan) {
    final tier = _tierMap[plan.toLowerCase()];
    return tier?.features ?? _tierMap['free']!.features;
  }

  static SubscriptionTier? getTier(String planName) {
    return _tierMap[planName.toLowerCase()];
  }

  static double getPlanPrice(String plan) {
    return _tierMap[plan.toLowerCase()]?.price ?? 0;
  }

  static String getPlanPriceString(String plan) {
    final tier = _tierMap[plan.toLowerCase()];
    if (tier == null || tier.price == 0) return 'Free';
    return '₹${_formatPrice(tier.price)}';
  }

  static String _formatPrice(double price) {
    if (price >= 1000) {
      final thousands = (price / 1000).floor();
      final remainder = (price % 1000).toInt();
      return '$thousands,${remainder.toString().padLeft(3, '0')}';
    }
    return price.toStringAsFixed(0);
  }

  static int compareTiers(String planA, String planB) {
    final idxA = _planOrder.indexOf(planA.toLowerCase());
    final idxB = _planOrder.indexOf(planB.toLowerCase());
    return idxA.compareTo(idxB);
  }

  static bool isDowngrade(String currentPlan, String targetPlan) {
    return compareTiers(currentPlan, targetPlan) > 0;
  }

  static bool isUpgrade(String currentPlan, String targetPlan) {
    return compareTiers(currentPlan, targetPlan) < 0;
  }

  Future<SubscriptionTier?> getCurrentPlan(String gymId) async {
    try {
      final gym = await _gymRepository.getGym(gymId);
      return _tierMap[gym.subscription.toLowerCase()];
    } catch (e) {
      return null;
    }
  }

  Future<bool> processPayment({
    required double amount,
    required BuildContext context,
    String description = 'IronBook Subscription',
  }) async {
    final service = PaymentService();
    final result = await service.processPayment(
      amount: amount,
      description: description,
      context: context,
    );
    return result.success;
  }

  Future<void> upgradePlan({
    required String gymId,
    required String plan,
    required BuildContext context,
  }) async {
    final tier = _tierMap[plan.toLowerCase()];
    if (tier == null) throw Exception('Invalid plan: $plan');

    if (tier.price > 0) {
      final paymentSuccess = await processPayment(
        amount: tier.price,
        context: context,
        description: '$plan Plan - IronBook Subscription',
      );
      if (!paymentSuccess) {
        throw Exception('Payment failed or cancelled.');
      }
    }

    await _gymRepository.updateSubscription(
      gymId,
      plan.toLowerCase(),
      tier.price == 0 ? null : DateTime.now().add(const Duration(days: 30)),
    );
  }

  Future<void> downgradePlan({
    required String gymId,
    required String plan,
    BuildContext? context,
  }) async {
    final tier = _tierMap[plan.toLowerCase()];
    if (tier == null) throw Exception('Invalid plan: $plan');

    await _gymRepository.updateSubscription(
      gymId,
      plan.toLowerCase(),
      tier.price == 0 ? null : DateTime.now().add(const Duration(days: 30)),
    );
  }
}
