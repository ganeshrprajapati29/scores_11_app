import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/config/theme_config.dart';
import '../../core/services/location_service.dart';
import '../../core/utils/debounce.dart';
import '../../data/models/discovery_model.dart';
import '../../data/services/discovery_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen>
    with SingleTickerProviderStateMixin {
  final DiscoveryService _discoveryService = DiscoveryService();
  final LocationService _locationService = LocationService();
  
  late TabController _tabController;
  
  // Debounce for search
  Debounce? _debounce;
  
  // Data
  List<DiscoveryItem> _items = [];
  List<String> _locations = ['All Locations'];
  String _selectedLocation = 'All Locations';
  String _selectedType = 'all';
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isMapView = false;
  
  // Location
  double? _currentLatitude;
  double? _currentLongitude;
  String _currentAddress = '';
  
  // Map
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  final LatLng _defaultLocation = const LatLng(19.0760, 72.8777); // Mumbai
  
  // Categories
  final List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'name': 'All', 'icon': Icons.apps},
    {'id': 'player', 'name': 'Players', 'icon': Icons.person},
    {'id': 'umpire', 'name': 'Umpires', 'icon': Icons.sports_cricket},
    {'id': 'commentator', 'name': 'Commentators', 'icon': Icons.mic},
    {'id': 'ground', 'name': 'Grounds', 'icon': Icons.stadium},
    {'id': 'opponentTeam', 'name': 'Teams', 'icon': Icons.groups},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _debounce = Debounce(delay: const Duration(milliseconds: 500));
    _initLocation();
  }

  @override
  void dispose() {
    _debounce?.dispose();
    _tabController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    setState(() => _isLoading = true);
    
    // Get current location
    final position = await _locationService.getCurrentPosition();
    if (position != null) {
      _currentLatitude = position.latitude;
      _currentLongitude = position.longitude;
      _currentAddress = await _locationService.getCurrentLocationAddress() ?? '';
    }
    
    // Load data
    await _loadLocations();
    await _loadItems();
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadLocations() async {
    try {
      final locations = await _discoveryService.getLocations();
      if (locations.isNotEmpty) {
        setState(() {
          _locations = ['All Locations', ...locations];
        });
      }
    } catch (e) {
      print('Error loading locations: $e');
    }
  }

  Future<void> _loadItems() async {
    try {
      setState(() => _isLoading = true);
      
      final response = await _discoveryService.getAllDiscoveryItems(
        type: _selectedType,
        location: _selectedLocation == 'All Locations' ? null : _selectedLocation,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        latitude: _currentLatitude,
        longitude: _currentLongitude,
        radius: 50, // 50km radius
      );

      if (response['success'] == true) {
        final List<dynamic> docs = response['data']['docs'] ?? [];
        setState(() {
          _items = docs.map((item) => DiscoveryItem.fromJson(item)).toList();
          _updateMarkers();
        });
      }
    } catch (e) {
      print('Error loading items: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateMarkers() {
    final markers = <Marker>{};
    
    for (var item in _items) {
      if (item.latitude != null && item.longitude != null) {
        markers.add(
          Marker(
            markerId: MarkerId(item.id),
            position: LatLng(item.latitude!, item.longitude!),
            infoWindow: InfoWindow(
              title: item.name,
              snippet: item.typeName,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _getMarkerHue(item.type),
            ),
            onTap: () => _showItemDetails(item),
          ),
        );
      }
    }
    
    setState(() => _markers = markers);
  }

  double _getMarkerHue(String type) {
    switch (type) {
      case 'player':
        return BitmapDescriptor.hueBlue;
      case 'umpire':
        return BitmapDescriptor.hueOrange;
      case 'commentator':
        return BitmapDescriptor.hueViolet;
      case 'ground':
        return BitmapDescriptor.hueGreen;
      case 'opponentTeam':
      case 'tournamentTeam':
        return BitmapDescriptor.hueRed;
      default:
        return BitmapDescriptor.hueRed;
    }
  }

  void _showItemDetails(DiscoveryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildItemDetailsSheet(item),
    );
  }

  Widget _buildItemDetailsSheet(DiscoveryItem item) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Image
          if (item.image != null)
            Container(
              height: 150,
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(item.image!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          // Details
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and badges
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (item.isPro)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryDark],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (item.isVerified)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.verified,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Type
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.typeName,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.location,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (item.distance != null)
                        Text(
                          item.distanceText,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Rating
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        item.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${item.views} views)',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Bio/Details
                  if (item.bio != null) ...[
                    Text(
                      item.bio!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Contact buttons
                  Row(
                    children: [
                      if (item.phone != null)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Call phone
                            },
                            icon: const Icon(Icons.phone),
                            label: const Text('Call'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      if (item.phone != null && item.email != null)
                        const SizedBox(width: 12),
                      if (item.email != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Send email
                            },
                            icon: const Icon(Icons.email),
                            label: const Text('Email'),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // View on map button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        if (item.latitude != null && item.longitude != null) {
                          _mapController?.animateCamera(
                            CameraUpdate.newLatLng(
                              LatLng(item.latitude!, item.longitude!),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('View on Map'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E88E5),
              Color(0xFF1565C0),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header
              _buildHeader(),
              // Tab Bar
              _buildTabBar(),
              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _tabController.index == 0
                          ? _buildListView()
                          : _buildMapView(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Discover',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() => _isMapView = false);
                        _tabController.animateTo(0);
                      },
                      icon: Icon(
                        Icons.list,
                        color: !_isMapView ? Colors.white : Colors.white70,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() => _isMapView = true);
                        _tabController.animateTo(1);
                      },
                      icon: Icon(
                        Icons.map,
                        color: _isMapView ? Colors.white : Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Current location
          if (_currentAddress.isNotEmpty)
            GestureDetector(
              onTap: _showLocationPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.my_location, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _currentAddress,
                        style: const TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down,
                        color: Colors.white, size: 18),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 12),
          // Search bar with debounce
          TextField(
            onChanged: (value) {
              _searchQuery = value;
              _debounce?.run(() {
                _loadItems();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search players, umpires, grounds...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
          const SizedBox(height: 12),
          // Category chips
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedType == category['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          category['icon'],
                          size: 16,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(category['name']),
                      ],
                    ),
                    onSelected: (selected) {
                      setState(() => _selectedType = category['id']);
                      _loadItems();
                    },
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                );
              },
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: AppColors.primary,
        unselectedLabelColor: Colors.white,
        tabs: const [
          Tab(text: 'List View'),
          Tab(text: 'Map View'),
        ],
        onTap: (index) {
          setState(() => _isMapView = index == 1);
        },
      ),
    );
  }

  Widget _buildListView() {
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No items found',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadItems,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return _buildListItem(item).animate().fadeIn(
                delay: Duration(milliseconds: index * 50),
                duration: 300.ms,
              );
        },
      ),
    );
  }

  Widget _buildListItem(DiscoveryItem item) {
    return GestureDetector(
      onTap: () => _showItemDetails(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.primary.withValues(alpha: 0.1),
                image: item.image != null
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(item.image!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: item.image == null
                  ? Icon(
                      _getCategoryIcon(item.type),
                      color: AppColors.primary,
                      size: 30,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.isPro)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryDark],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (item.isVerified)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.verified,
                            color: AppColors.primary,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.typeName,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.location,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.distance != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.distanceText,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Rating
            Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      item.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _currentLatitude != null && _currentLongitude != null
            ? LatLng(_currentLatitude!, _currentLongitude!)
            : _defaultLocation,
        zoom: 12,
      ),
      markers: _markers,
      onMapCreated: (controller) {
        _mapController = controller;
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
    );
  }

  IconData _getCategoryIcon(String type) {
    switch (type) {
      case 'player':
        return Icons.person;
      case 'umpire':
        return Icons.sports_cricket;
      case 'commentator':
        return Icons.mic;
      case 'ground':
        return Icons.stadium;
      case 'opponentTeam':
      case 'tournamentTeam':
        return Icons.groups;
      default:
        return Icons.person;
    }
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Location',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Current location option
            ListTile(
              leading: const Icon(Icons.my_location, color: AppColors.primary),
              title: const Text('Use Current Location'),
              subtitle: Text(_currentAddress.isNotEmpty ? _currentAddress : 'Tap to get location'),
              onTap: () async {
                Navigator.pop(context);
                await _initLocation();
              },
            ),
            const Divider(),
            // Location list
            const Text(
              'Popular Locations',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _locations.length,
                itemBuilder: (context, index) {
                  final location = _locations[index];
                  return ListTile(
                    leading: const Icon(Icons.location_city),
                    title: Text(location),
                    trailing: _selectedLocation == location
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () {
                      setState(() => _selectedLocation = location);
                      Navigator.pop(context);
                      _loadItems();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
