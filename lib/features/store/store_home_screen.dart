import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/config/theme_config.dart';
import '../../core/widgets/custom_appbar.dart';

class StoreHomeScreen extends StatefulWidget {
  const StoreHomeScreen({super.key});

  @override
  State<StoreHomeScreen> createState() => _StoreHomeScreenState();
}

class _StoreHomeScreenState extends State<StoreHomeScreen> {
  String _selectedCategory = 'all';
  final List<Map<String, dynamic>> _products = [
    {'id': '1', 'name': 'Cricket Bat - Pro', 'price': 2999, 'originalPrice': 4999, 'image': 'https://picsum.photos/200/200', 'rating': 4.5, 'reviews': 128, 'category': 'equipment'},
    {'id': '2', 'name': 'Cricket Ball Pack', 'price': 499, 'originalPrice': 799, 'image': 'https://picsum.photos/200/200', 'rating': 4.2, 'reviews': 86, 'category': 'equipment'},
    {'id': '3', 'name': 'Cricket Helmet', 'price': 1299, 'originalPrice': 1999, 'image': 'https://picsum.photos/200/200', 'rating': 4.7, 'reviews': 234, 'category': 'gear'},
    {'id': '4', 'name': 'Cricket Gloves', 'price': 899, 'originalPrice': 1499, 'image': 'https://picsum.photos/200/200', 'rating': 4.3, 'reviews': 67, 'category': 'gear'},
    {'id': '5', 'name': 'Cricket Shoes', 'price': 2499, 'originalPrice': 3999, 'image': 'https://picsum.photos/200/200', 'rating': 4.6, 'reviews': 189, 'category': 'shoes'},
    {'id': '6', 'name': 'Cricket Jersey', 'price': 799, 'originalPrice': 1299, 'image': 'https://picsum.photos/200/200', 'rating': 4.4, 'reviews': 312, 'category': 'apparel'},
    {'id': '7', 'name': 'Cricket Kit Bag', 'price': 1799, 'originalPrice': 2999, 'image': 'https://picsum.photos/200/200', 'rating': 4.5, 'reviews': 145, 'category': 'equipment'},
    {'id': '8', 'name': 'Cricket Pad Set', 'price': 1599, 'originalPrice': 2499, 'image': 'https://picsum.photos/200/200', 'rating': 4.1, 'reviews': 78, 'category': 'gear'},
  ];

  final List<Map<String, dynamic>> _cart = [];
  int _cartCount = 0;

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _products.where((p) {
      if (_selectedCategory == 'all') return true;
      return p['category'] == _selectedCategory;
    }).toList();

    return Scaffold(
      appBar: CustomAppbar(
        title: 'Cric11 Store',
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.pushNamed(context, '/cart');
                },
              ),
              if (_cartCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_cartCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Categories
          Container(
            height: 50,
            color: Colors.white,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip('All', 'all'),
                _buildCategoryChip('Equipment', 'equipment'),
                _buildCategoryChip('Gear', 'gear'),
                _buildCategoryChip('Shoes', 'shoes'),
                _buildCategoryChip('Apparel', 'apparel'),
              ],
            ),
          ).animate().fadeIn(),
          
          // Products Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                return _buildProductCard(product, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String value) {
    final isSelected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedCategory = value);
        },
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, int index) {
    final discount = ((product['originalPrice'] - product['price']) / product['originalPrice'] * 100).round();
    
    return Container(
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
          onTap: () {
            Navigator.pushNamed(context, '/product-detail', arguments: product['id']);
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      product['image'],
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '-$discount%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              // Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            product['rating'].toString(),
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            ' (${product['reviews']})',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '₹${product['originalPrice']}',
                                style: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey[400],
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                '₹${product['price']}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.add_shopping_cart,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 50)).scale(begin: const Offset(0.95, 0.95));
  }
}

