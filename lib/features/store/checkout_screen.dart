import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/config/theme_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/friendly_error.dart';
import '../../core/widgets/custom_appbar.dart';
import 'package:provider/provider.dart';
import '../../data/services/store_service.dart';
import '../../providers/auth_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPayment = 'cod';
  bool _isProcessing = false;
  bool _isLoading = false;
  final StoreService _storeService = StoreService();
  
  List<Map<String, dynamic>> _cartItems = [];

  final _addressFormKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();

  double get _subtotal => _cartItems.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
  // Matches the backend order total: prices include GST, shipping is free.
  double get _total => _subtotal;

  @override
  void initState() {
    super.initState();
    _prefillAddress();
    _loadCart();
  }

  /// Prefill the delivery form from the signed-in user's profile.
  void _prefillAddress() {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    _nameCtrl.text = user.name;
    _phoneCtrl.text = user.phone ?? '';
    _streetCtrl.text = user.address?.street ?? '';
    _cityCtrl.text = user.address?.city ?? '';
    _stateCtrl.text = user.address?.state ?? '';
    _pincodeCtrl.text = user.address?.pincode ?? '';
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _phoneCtrl, _streetCtrl, _cityCtrl, _stateCtrl, _pincodeCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCart() async {
    setState(() => _isLoading = true);
    try {
      final cart = await _storeService.getCart();
      final items = cart['items'] is List ? cart['items'] as List : const [];
      if (!mounted) return;
      setState(() {
        _cartItems = items.whereType<Map>().map((item) => _normalizeCartItem(Map<String, dynamic>.from(item))).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(e, fallback: 'Could not load checkout.'))),
      );
    }
  }

  Map<String, dynamic> _normalizeCartItem(Map<String, dynamic> item) {
    final product = item['product'] is Map ? Map<String, dynamic>.from(item['product'] as Map) : <String, dynamic>{};
    final images = product['images'] is List ? product['images'] as List : const [];
    final imageUrl = images.isNotEmpty
        ? (images.first is Map ? images.first['url']?.toString() : images.first?.toString())
        : '';
    final price = (product['price'] as num?)?.toDouble() ?? (item['price'] as num?)?.toDouble() ?? 0;
    return {
      ...item,
      'id': (item['_id'] ?? item['id']).toString(),
      'productId': (product['_id'] ?? product['id'] ?? item['productId']).toString(),
      'name': product['name']?.toString() ?? item['name']?.toString() ?? 'Product',
      'price': price,
      'quantity': item['quantity'] ?? 1,
      'image': imageUrl ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Checkout', showBackButton: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: 'Delivery Address',
              icon: Icons.location_on,
              child: _buildAddressForm(),
            ).animate().fadeIn(),
            
            _buildSection(
              title: 'Order Items (${_cartItems.length})',
              icon: Icons.shopping_bag,
              child: Column(
                children: _cartItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return _buildOrderItem(item, index);
                }).toList(),
              ),
            ).animate().fadeIn(delay: 100.ms),
            
            _buildSection(
              title: 'Payment Method',
              icon: Icons.payment,
              child: Column(
                children: [
                  _buildPaymentOption('cod', 'Cash on Delivery', Icons.money),
                  _buildPaymentOption('wallet', 'Scores11 Wallet', Icons.account_balance_wallet),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms),
            
            _buildSection(
              title: 'Price Details',
              icon: Icons.receipt_long,
              child: Column(
                children: [
                  _buildPriceRow('Subtotal', '₹${_subtotal.toStringAsFixed(2)}'),
                  _buildPriceRow('Shipping', 'FREE'),
                  const Divider(),
                  _buildPriceRow('Total', '₹${_total.toStringAsFixed(2)}', isTotal: true),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Amount', style: TextStyle(fontSize: 16)),
                  Text(
                    '₹${_total.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isProcessing
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Place Order'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required IconData icon, required Widget child}) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildAddressForm() {
    InputDecoration deco(String label) => InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        );
    String? required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;
    return Form(
      key: _addressFormKey,
      child: Column(children: [
        TextFormField(controller: _nameCtrl, decoration: deco('Full name'), validator: required),
        const SizedBox(height: 10),
        TextFormField(
          controller: _phoneCtrl,
          decoration: deco('Phone'),
          keyboardType: TextInputType.phone,
          validator: (v) => (v == null || v.replaceAll(RegExp(r'\D'), '').length < 10) ? 'Valid phone required' : null,
        ),
        const SizedBox(height: 10),
        TextFormField(controller: _streetCtrl, decoration: deco('House / Street'), validator: required, maxLines: 2, minLines: 1),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextFormField(controller: _cityCtrl, decoration: deco('City'), validator: required)),
          const SizedBox(width: 10),
          Expanded(child: TextFormField(controller: _stateCtrl, decoration: deco('State'), validator: required)),
        ]),
        const SizedBox(height: 10),
        TextFormField(
          controller: _pincodeCtrl,
          decoration: deco('Pincode'),
          keyboardType: TextInputType.number,
          validator: (v) => (v == null || !RegExp(r'^\d{6}$').hasMatch(v.trim())) ? '6-digit pincode' : null,
        ),
      ]),
    );
  }

  Widget _buildPaymentOption(String value, String label, IconData icon) {
    final isSelected = _selectedPayment == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey[300]!, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Radio<String>(value: value, groupValue: _selectedPayment, onChanged: (v) => setState(() => _selectedPayment = v!), activeColor: AppColors.primary),
          Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          const Spacer(),
          if (isSelected) Icon(Icons.check_circle, color: AppColors.primary),
        ]),
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(8), child: _itemImage(item['image']?.toString())),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
          Text('Qty: ${item['quantity']}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ])),
        Text('₹${(item['price'] * item['quantity']).toString()}', style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 50));
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 16 : 14)),
          Text(value, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 16 : 14, color: isTotal ? AppColors.primary : Colors.black)),
        ],
      ),
    );
  }

  Widget _itemImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: 50,
        height: 50,
        color: Colors.grey[100],
        child: Icon(Icons.shopping_bag_outlined, color: Colors.grey[400]),
      );
    }
    return Image.network(
      imageUrl,
      width: 50,
      height: 50,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: 50,
        height: 50,
        color: Colors.grey[100],
        child: Icon(Icons.shopping_bag_outlined, color: Colors.grey[400]),
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }
    if (!(_addressFormKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete the delivery address')),
      );
      return;
    }
    setState(() => _isProcessing = true);
    try {
      await _storeService.checkout({
        'items': _cartItems.map((item) {
          final productId = item['productId'];
          return {
            'product': productId?.toString(),
            'quantity': item['quantity'] ?? 1,
          };
        }).toList(),
        'paymentMethod': _selectedPayment,
        'shippingAddress': {
          'name': _nameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'street': _streetCtrl.text.trim(),
          'city': _cityCtrl.text.trim(),
          'state': _stateCtrl.text.trim(),
          'pincode': _pincodeCtrl.text.trim(),
          'country': 'India',
        },
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(e, fallback: 'Could not place order.'))),
      );
      return;
    }
    if (mounted) {
      setState(() => _isProcessing = false);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 80),
            const SizedBox(height: 16),
            Text('Order Placed!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Your order has been placed successfully.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
          ]),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: Text('Continue Shopping'),
              ),
            ),
          ],
        ),
      );
    }
  }
}


