import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/config/theme_config.dart';
import '../../core/widgets/custom_appbar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/friendly_error.dart';
import '../../data/services/store_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StoreService _storeService = StoreService();
  List<Map<String, dynamic>> _orders = [];
  String _query = '';

  Future<void> _openSearch() async {
    final controller = TextEditingController(text: _query);
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Search orders'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Order number or product',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          if (_query.isNotEmpty)
            TextButton(onPressed: () => Navigator.pop(ctx, ''), child: const Text('Clear')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Search'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && mounted) setState(() => _query = value.trim().toLowerCase());
  }
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _storeService.getOrders(limit: 50);
      if (!mounted) return;
      setState(() {
        _orders = orders.map(_normalizeOrder).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(e, fallback: 'Could not load orders.'))),
      );
    }
  }

  Map<String, dynamic> _normalizeOrder(Map<String, dynamic> order) {
    final items = order['items'] is List ? order['items'] as List : const [];
    final firstProduct = items.isNotEmpty && items.first is Map
        ? (items.first['product'] is Map ? items.first['product'] as Map : const {})
        : const {};
    final images = firstProduct['images'] is List ? firstProduct['images'] as List : const [];
    return {
      'id': (order['orderNumber'] ?? order['_id'] ?? order['id'] ?? '').toString(),
      'date': (order['createdAt'] ?? '').toString().split('T').first,
      'status': _titleCase((order['orderStatus'] ?? order['status'] ?? 'processing').toString()),
      'items': items.length,
      'total': order['totalAmount'] ?? order['total'] ?? 0,
      'image': images.isNotEmpty ? images.first.toString() : '',
      'raw': order,
    };
  }

  String _addr(Map<String, dynamic> order, String key) {
    final raw = order['raw'];
    final address = raw is Map ? raw['shippingAddress'] : null;
    if (address is! Map) return '';
    return (address[key] ?? (key == 'street' ? address['address'] : null) ?? '').toString();
  }

  /// Steps are ticked up to the order's real status; only the placed time is
  /// known from the backend, so other steps carry no fabricated timestamp.
  List<Widget> _statusSteps(Map<String, dynamic> order) {
    const steps = ['Order Placed', 'Processing', 'Shipped', 'Out for Delivery', 'Delivered'];
    final status = order['status'].toString().toLowerCase();
    var reached = 0;
    if (status.contains('process') || status.contains('confirm')) reached = 1;
    if (status.contains('ship')) reached = 2;
    if (status.contains('out for')) reached = 3;
    if (status.contains('deliver') && !status.contains('out for')) reached = 4;
    final cancelled = status.contains('cancel');
    return [
      for (var i = 0; i < steps.length; i++)
        _buildStatusStepper(
          steps[i],
          i == 0 ? order['date'].toString() : '',
          !cancelled && i <= reached,
        ),
      if (cancelled) _buildStatusStepper('Cancelled', '', true),
    ];
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'My Orders',
        actions: [
          IconButton(
            tooltip: 'Search orders',
            icon: Icon(Icons.search, color: _query.isEmpty ? null : AppColors.primary),
            onPressed: _openSearch,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Processing'),
            Tab(text: 'Shipped'),
            Tab(text: 'Delivered'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList('all'),
          _buildOrderList('Processing'),
          _buildOrderList('Shipped'),
          _buildOrderList('Delivered'),
        ],
      ),
    );
  }

  Widget _buildOrderList(String filter) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredOrders = _orders.where((order) {
      if (filter != 'all' && order['status'] != filter) return false;
      if (_query.isEmpty) return true;
      final text = '${order['id']} ${_firstProductName(order)}'.toLowerCase();
      return text.contains(_query);
    }).toList();

    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No orders found', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        return _buildOrderCard(order, index);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, int index) {
    Color statusColor;
    switch (order['status']) {
      case 'Delivered':
        statusColor = AppColors.success;
        break;
      case 'Shipped':
        statusColor = Colors.blue;
        break;
      case 'Out for Delivery':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showOrderDetails(order),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order #${order['id']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        order['status'],
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _orderImage(order['image']?.toString()),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${order['items']} items',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ordered on ${order['date']}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${order['total']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildActionButton('Track', () {}),
                            const SizedBox(width: 8),
                            _buildActionButton('Details', () => _showOrderDetails(order)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 100));
  }

  Widget _buildActionButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  String _firstProductName(Map<String, dynamic> order) {
    final raw = order['raw'];
    final items = raw is Map && raw['items'] is List ? raw['items'] as List : const [];
    if (items.isEmpty || items.first is! Map) return '${order['items']} items';
    final firstItem = items.first as Map;
    final product = firstItem['product'];
    if (product is Map && product['name'] != null) return product['name'].toString();
    return '${order['items']} items';
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Order #${order['id']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(order['status'], style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Order Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ..._statusSteps(order),
                const SizedBox(height: 24),
                Text('Order Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      ClipRRect(borderRadius: BorderRadius.circular(8), child: _orderImage(order['image']?.toString())),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_firstProductName(order), style: TextStyle(fontWeight: FontWeight.w500)),
                        Text('Qty: ${order['items']}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ])),
                      Text('₹${order['total']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Delivery Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_addr(order, 'name').isEmpty ? '—' : _addr(order, 'name'), style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      if (_addr(order, 'street').isNotEmpty)
                        Text(_addr(order, 'street'), style: TextStyle(color: Colors.grey[600])),
                      Text(
                        [_addr(order, 'city'), _addr(order, 'state'), _addr(order, 'pincode')]
                            .where((p) => p.isNotEmpty)
                            .join(', '),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        Icon(Icons.phone, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(_addr(order, 'phone'), style: TextStyle(color: Colors.grey[600])),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Payment Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      _buildPriceRow('Subtotal', '₹${order['total']}'),
                      _buildPriceRow('Shipping', 'FREE'),
                      const Divider(),
                      _buildPriceRow('Total', '₹${order['total']}', isTotal: true),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Download Invoice'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        child: Text('Buy Again'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _orderImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: 60,
        height: 60,
        color: Colors.grey[100],
        child: Icon(Icons.shopping_bag_outlined, color: Colors.grey[400]),
      );
    }
    return Image.network(
      imageUrl,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: 60,
        height: 60,
        color: Colors.grey[100],
        child: Icon(Icons.shopping_bag_outlined, color: Colors.grey[400]),
      ),
    );
  }

  Widget _buildStatusStepper(String title, String time, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.success : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: isCompleted ? Icon(Icons.check, color: Colors.white, size: 16) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal, color: isCompleted ? Colors.black : Colors.grey)),
                if (time.isNotEmpty) Text(time, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: isTotal ? AppColors.primary : Colors.black)),
        ],
      ),
    );
  }
}


