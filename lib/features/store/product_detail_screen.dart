import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/config/theme_config.dart';
import '../../core/utils/friendly_error.dart';
import '../../core/widgets/custom_appbar.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/store_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final StoreService _storeService = StoreService();
  int _quantity = 1;
  int _selectedImageIndex = 0;
  bool _isAddingToCart = false;
  bool _isLoading = false;
  String? _error;
  
  Map<String, dynamic> _product = {};

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final product = await _storeService.getProductById(widget.productId);
      if (!mounted) return;
      setState(() {
        _product = _normalizeProduct(product);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load product';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _normalizeProduct(Map<String, dynamic> product) {
    final rawImages = product['images'] is List ? product['images'] as List : const [];
    final images = rawImages
        .map((image) => image is Map ? image['url']?.toString() : image?.toString())
        .whereType<String>()
        .where((url) => url.isNotEmpty)
        .toList();
    final price = (product['price'] as num?)?.toDouble() ?? 0;
    final originalPrice = (product['originalPrice'] as num?)?.toDouble() ?? price;
    return {
      ...product,
      'id': (product['_id'] ?? product['id'] ?? widget.productId).toString(),
      'name': product['name']?.toString() ?? 'Product',
      'description': product['description']?.toString() ?? '',
      'price': price,
      'originalPrice': originalPrice <= 0 ? price : originalPrice,
      'rating': (product['rating'] as num?)?.toDouble() ?? 0,
      'reviews': product['reviews'] ?? 0,
      'inStock': (product['stock'] as num? ?? 0) > 0,
      'stockCount': product['stock'] ?? 0,
      'images': images,
      'features': product['features'] is List ? product['features'] : const [],
      'specifications': {
        if (product['brand'] != null) 'Brand': product['brand'],
        if (product['category'] != null) 'Category': product['category'],
        if (product['weight'] != null) 'Weight': product['weight'],
        if (product['color'] != null) 'Color': product['color'],
      },
      'seller': {'name': 'Scores11 Store'},
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _product.isEmpty) {
      return Scaffold(
        appBar: CustomAppBar(title: 'Product'),
        body: Center(child: Text(_error ?? 'Product not found')),
      );
    }
    final originalPrice = (_product['originalPrice'] as num?)?.toDouble() ?? 0;
    final price = (_product['price'] as num?)?.toDouble() ?? 0;
    final discount = originalPrice > 0 ? ((originalPrice - price) / originalPrice * 100).round() : 0;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                tooltip: 'Share',
                icon: const Icon(Icons.share),
                onPressed: () => Share.share(
                  '${_product['name']} - ₹${((_product['price'] as num?) ?? 0).toStringAsFixed(0)} on Scores11 Store',
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  PageView.builder(
                    itemCount: (_product['images'] as List).length,
                    onPageChanged: (index) {
                      setState(() => _selectedImageIndex = index);
                    },
                    itemBuilder: (context, index) {
                      return Image.network(
                        _product['images'][index],
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        (_product['images'] as List).length,
                        (index) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _selectedImageIndex == index
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 100,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '-$discount% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Product Details
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Rating
                  Text(
                    _product['name'],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.star, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              _product['rating'].toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${_product['reviews']} reviews)',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '|',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      const SizedBox(width: 8),
                      if (_product['inStock'])
                        Text(
                          'In Stock',
                          style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w500),
                        )
                      else
                        Text(
                          'Out of Stock',
                          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w500),
                        ),
                    ],
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 16),
                  
                  // Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${_product['price']}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '₹${_product['originalPrice']}',
                        style: TextStyle(
                          fontSize: 18,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 16),
                  
                  // Quantity Selector
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Quantity:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline),
                          onPressed: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_quantity',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add_circle_outline),
                          onPressed: _quantity < (_product['stockCount'] as int)
                              ? () => setState(() => _quantity++)
                              : null,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 20),
                  
                  // Description
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _product['description'],
                    style: TextStyle(
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Features
                  Text(
                    'Key Features',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...(_product['features'] as List).map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: AppColors.success, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(feature)),
                      ],
                    ),
                  )),
                  const SizedBox(height: 20),
                  
                  // Specifications
                  Text(
                    'Specifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: (_product['specifications'] as Map<String, dynamic>)
                          .entries
                          .map((entry) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey[200]!),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.key,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                Text(
                                  entry.value.toString(),
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Seller Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.store, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _product['seller']['name'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.verified, color: AppColors.success, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Official store',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () => Navigator.pushNamed(context, '/store'),
                          child: const Text('View Shop'),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
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
          child: Row(
            children: [
              // Add to Cart Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addToCart,
                  icon: _isAddingToCart
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.shopping_cart_outlined),
                  label: Text('Add to Cart'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Buy Now Button
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/checkout');
                  },
                  icon: Icon(Icons.flash_on),
                  label: Text('Buy Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addToCart() async {
    setState(() => _isAddingToCart = true);
    try {
      await _storeService.addToCart(_product['id'].toString(), _quantity);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAddingToCart = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyError(e, fallback: 'Could not add to cart.'),
          ),
        ),
      );
      return;
    }

    if (mounted) {
      setState(() => _isAddingToCart = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added to cart successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}



