import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/config/theme_config.dart';
import '../../core/utils/friendly_error.dart';
import '../../core/widgets/custom_appbar.dart';
import '../../data/services/store_service.dart';
import '../../core/theme/app_colors.dart';
class StoreHomeScreen extends StatefulWidget {
  const StoreHomeScreen({super.key});

  @override
  State<StoreHomeScreen> createState() => _StoreHomeScreenState();
}

class _StoreHomeScreenState extends State<StoreHomeScreen> {
  final StoreService _storeService = StoreService();
  String _selectedCategory = 'all';
  
  // Pagination state
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  
  List<Map<String, dynamic>> _products = [];
  final List<Map<String, dynamic>> _cart = [];
  int _cartCount = 0;

  /// Pagination Algorithm:
  /// int page = 1;
  /// loadMore(){
  ///   page++;
  ///   fetchProducts(page);
  /// }

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final result = await _storeService.getProducts(page: 1, category: _selectedCategory);
      setState(() {
        _products = result.products;
        _hasMore = result.hasMore;
        _currentPage = 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              friendlyError(e, fallback: 'Could not load products.'),
            ),
          ),
        );
      }
    }
  }

  /// Load more products
  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore) return;
    
    setState(() => _isLoadingMore = true);
    
    try {
      _currentPage++;
      final result = await _storeService.getProducts(
        page: _currentPage,
        category: _selectedCategory,
      );
      setState(() {
        _products.addAll(result.products);
        _hasMore = result.hasMore;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _currentPage--;
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              friendlyError(e, fallback: 'Could not load more products.'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Scores11 Store',
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart),
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
            height: 112,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              image: const DecorationImage(
                image: AssetImage('score 11/Store.png'),
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.08, end: 0),

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
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'score 11/Empty States 4.png',
                              width: 124,
                              height: 124,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.inventory_2,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No products found',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _ProductGrid(
                        products: _products,
                        isLoadingMore: _isLoadingMore,
                        hasMore: _hasMore,
                        loadMore: _loadMoreProducts,
                        cart: _cart,
                        cartCount: _cartCount,
                        onAddToCart: (product) {
                          setState(() {
                            _cart.add(product);
                            _cartCount = _cart.length;
                          });
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
          setState(() {
            _selectedCategory = value;
            _currentPage = 1;
            _hasMore = true;
          });
          _loadProducts();
        },
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}

class _ProductGrid extends StatefulWidget {
  final List<Map<String, dynamic>> products;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback loadMore;
  final List<Map<String, dynamic>> cart;
  final int cartCount;
  final Function(Map<String, dynamic>) onAddToCart;

  const _ProductGrid({
    required this.products,
    required this.isLoadingMore,
    required this.hasMore,
    required this.loadMore,
    required this.cart,
    required this.cartCount,
    required this.onAddToCart,
  });

  @override
  State<_ProductGrid> createState() => _ProductGridState();
}

class _ProductGridState extends State<_ProductGrid> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Detect when user scrolls to bottom and load more
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      widget.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {},
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: widget.products.length + (widget.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == widget.products.length) {
            return widget.isLoadingMore
                ? Center(child: CircularProgressIndicator())
                : const SizedBox.shrink();
          }
          return _ProductCard(
            product: widget.products[index],
            index: index,
            onAddToCart: widget.onAddToCart,
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final int index;
  final Function(Map<String, dynamic>) onAddToCart;

  const _ProductCard({
    required this.product,
    required this.index,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
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
                      (product['image'] ?? '').toString(),
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 120,
                        color: Colors.grey[200],
                        child: Icon(Icons.image, size: 50),
                      ),
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
                        product['name'] ?? 'Product',
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
                          Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            (product['rating'] ?? 0).toString(),
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            ' (${product['reviews'] ?? 0})',
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
                          GestureDetector(
                            onTap: () => onAddToCart(product),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.add_shopping_cart,
                                color: Colors.white,
                                size: 18,
                              ),
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



