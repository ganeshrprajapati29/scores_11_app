import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_appbar.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_loader.dart';
import '../../core/utils/friendly_error.dart';
import '../../data/services/subscription_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  List<Map<String, dynamic>> _plans = [];
  Map<String, dynamic>? _currentSubscription;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final plans = await _subscriptionService.getPlans();
      final currentSubscription = await _subscriptionService.getCurrentSubscription();
      setState(() {
        _plans = plans;
        _currentSubscription = currentSubscription.isNotEmpty ? currentSubscription : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = friendlyError(e, fallback: 'Could not load subscription details.');
        _isLoading = false;
      });
    }
  }

  Future<void> _subscribe(String planId) async {
    try {
      final result = await _subscriptionService.subscribe(planId, {
        'paymentMethod': 'card',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription successful!'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e, fallback: 'Something went wrong. Please try again.')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Subscription Plans',
        showBackButton: true,
      ),
      body: _isLoading
          ? const CustomLoader()
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      CustomButton(text: 'Retry', onPressed: _loadData),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_currentSubscription != null) ...[
                          _buildCurrentSubscriptionCard(),
                          const SizedBox(height: 24),
                        ],
                        Text(
                          'Available Plans',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._plans.map((plan) => _buildPlanCard(plan)),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildCurrentSubscriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF1E88E5)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Current Plan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _currentSubscription?['planName'] ?? 'Premium',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Expires: ${_currentSubscription?['endDate'] ?? 'N/A'}',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final isActive = _currentSubscription?['planId'] == plan['id'];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppColors.primary : Colors.grey.shade200,
          width: isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                plan['name'] ?? 'Plan',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Active',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${plan['price'] ?? '0'}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '/${plan['duration'] ?? 'month'}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Features:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...((plan['features'] as List<dynamic>?)?.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(Icons.check, color: AppColors.success, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(feature.toString())),
              ],
            ),
          ))?.toList() ?? []),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: isActive ? 'Current Plan' : 'Subscribe',
              onPressed: isActive ? null : () => _subscribe(plan['id']),
            ),
          ),
        ],
      ),
    );
  }
}


