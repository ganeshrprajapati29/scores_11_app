import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/config/theme_config.dart';
import '../../core/theme/app_colors.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPayment = 'card';
  String _selectedAddress = 'home';
  bool _isProcessing = false;
  
  final List<Map<String, dynamic>> _cartItems = [
    {'name': 'Cricket Bat - Pro', 'price': 2999, 'quantity': 1, 'image': 'https://picsum.photos/60/60'},
    {'name': 'Cricket Ball Pack', 'price': 499, 'quantity': 2, 'image': 'https://picsum.photos/60/60'},
  ];

  final Map<String, dynamic> _address = {
    'name': 'John Doe',
    'phone': '+91 9876543210',
    'home': '123, ABC Apartments, Near Metro Station, Mumbai - 400001',
    'office': '456, Tech Park, Sector 4, Bangalore - 560001',
  };

  double get _subtotal => _cartItems.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
  double get _shipping => 99;
  double get _tax => (_subtotal * 0.18).roundToDouble();
  double get _total => _subtotal + _shipping + _tax;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: 'Delivery Address',
              icon: Icons.location_on,
              child: Column(
                children: [
                  _buildAddressOption('home', 'Home', _address['home']),
                  _buildAddressOption('office', 'Office', _address['office']),
                ],
              ),
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
                  _buildPaymentOption('card', 'Credit/Debit Card', Icons.credit_card),
                  _buildPaymentOption('upi', 'UPI', Icons.qr_code),
                  _buildPaymentOption('wallet', 'Wallet', Icons.account_balance_wallet),
                  _buildPaymentOption('cod', 'Cash on Delivery', Icons.money),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms),
            
            _buildSection(
              title: 'Price Details',
              icon: Icons.receipt_long,
              child: Column(
                children: [
                  _buildPriceRow('Subtotal', 'â‚¹${_subtotal.toStringAsFixed(2)}'),
                  _buildPriceRow('Shipping', 'â‚¹${_shipping.toStringAsFixed(2)}'),
                  _buildPriceRow('Tax (18% GST)', 'â‚¹${_tax.toStringAsFixed(2)}'),
                  const Divider(),
                  _buildPriceRow('Total', 'â‚¹${_total.toStringAsFixed(2)}', isTotal: true),
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
                    'â‚¹${_total.toStringAsFixed(2)}',
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

  Widget _buildAddressOption(String value, String label, String address) {
    final isSelected = _selectedAddress == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedAddress = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey[300]!, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<String>(value: value, groupValue: _selectedAddress, onChanged: (v) => setState(() => _selectedAddress = v!), activeColor: AppColors.primary),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(value == 'home' ? 'Default' : 'Saved', style: const TextStyle(color: AppColors.primary, fontSize: 10)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(_address['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(_address['phone'], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(address, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
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
        ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(item['image'], width: 50, height: 50, fit: BoxFit.cover)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
          Text('Qty: ${item['quantity']}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ])),
        Text('â‚¹${(item['price'] * item['quantity']).toString()}', style: const TextStyle(fontWeight: FontWeight.bold)),
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

  Future<void> _placeOrder() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 2));
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


