import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/services/location_service.dart';
import '../../core/utils/debounce.dart';
import '../../data/models/discovery_model.dart';
import '../../data/services/discovery_service.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  static const _primary = Color(0xFF1A56DB);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFE8EEFF);
  static const _bg = Color(0xFFF7F9FE);

  final DiscoveryService _discoveryService = DiscoveryService();
  final LocationService _locationService = LocationService();
  final Debounce _debounce = Debounce(delay: const Duration(milliseconds: 420));
  final TextEditingController _searchController = TextEditingController();

  List<DiscoveryItem> _items = [];
  List<String> _locations = ['All Locations'];
  String _selectedLocation = 'All Locations';
  String _selectedType = 'all';
  String _searchQuery = '';
  bool _isLoading = true;
  bool _showMap = false;

  double? _currentLatitude;
  double? _currentLongitude;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  final LatLng _defaultLocation = const LatLng(19.0760, 72.8777);

  final List<_DiscoveryCategory> _categories = const [
    _DiscoveryCategory('all', 'All', 'Explore', Icons.apps_rounded, Color(0xFF1A56DB)),
    _DiscoveryCategory('opponentTeam', 'Opponent Team', 'Find teams', Icons.groups_2_rounded, Color(0xFFEF4444)),
    _DiscoveryCategory('player', 'Join Player', 'Players', Icons.person_add_alt_1_rounded, Color(0xFF10B981)),
    _DiscoveryCategory('tournamentTeam', 'Tournament Team', 'Teams', Icons.diversity_3_rounded, Color(0xFF7C3AED)),
    _DiscoveryCategory('tournament', 'Tournaments', 'Cups', Icons.emoji_events_rounded, Color(0xFFF59E0B)),
    _DiscoveryCategory('ground', 'Ground', 'Venues', Icons.stadium_rounded, Color(0xFF0EA5E9)),
    _DiscoveryCategory('umpire', 'Umpire', 'Officials', Icons.sports_rounded, Color(0xFF14B8A6)),
    _DiscoveryCategory('scorer', 'Scorer', 'Score desk', Icons.edit_note_rounded, Color(0xFF6366F1)),
    _DiscoveryCategory('commentator', 'Commentator', 'Voice', Icons.mic_rounded, Color(0xFFEC4899)),
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _debounce.dispose();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() => _isLoading = true);
    try {
      final position = await _locationService.getCurrentPosition();
      _currentLatitude = position?.latitude;
      _currentLongitude = position?.longitude;
    } catch (_) {
      _currentLatitude = null;
      _currentLongitude = null;
    }
    await Future.wait([_loadLocations(), _loadItems(showLoader: false)]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadLocations() async {
    try {
      final locations = await _discoveryService.getLocations();
      if (!mounted) return;
      setState(() => _locations = ['All Locations', ...locations.where((item) => item.trim().isNotEmpty)]);
    } catch (_) {
      if (!mounted) return;
      setState(() => _locations = ['All Locations']);
    }
  }

  Future<void> _loadItems({bool showLoader = true}) async {
    if (showLoader && mounted) setState(() => _isLoading = true);
    try {
      final response = await _discoveryService.getAllDiscoveryItems(
        type: _selectedType,
        location: _selectedLocation == 'All Locations' ? null : _selectedLocation,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        latitude: _currentLatitude,
        longitude: _currentLongitude,
        radius: 50,
        limit: 60,
        sortBy: 'rating',
      );
      final data = response['data'];
      final docs = data is Map ? (data['docs'] as List? ?? const []) : const [];
      final items = docs
          .whereType<Map>()
          .map((item) => DiscoveryItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      if (!mounted) return;
      setState(() {
        _items = items;
        _markers = _buildMarkers(items);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = [];
        _markers = {};
      });
    } finally {
      if (showLoader && mounted) setState(() => _isLoading = false);
    }
  }

  Set<Marker> _buildMarkers(List<DiscoveryItem> items) {
    return items
        .where((item) => item.latitude != null && item.longitude != null)
        .map((item) => Marker(
              markerId: MarkerId(item.id),
              position: LatLng(item.latitude!, item.longitude!),
              infoWindow: InfoWindow(title: item.name, snippet: item.typeName),
              icon: BitmapDescriptor.defaultMarkerWithHue(_markerHue(item.type)),
              onTap: () => _showItemDetails(item),
            ))
        .toSet();
  }

  double _markerHue(String type) {
    switch (type) {
      case 'player':
        return BitmapDescriptor.hueGreen;
      case 'ground':
        return BitmapDescriptor.hueAzure;
      case 'umpire':
      case 'scorer':
        return BitmapDescriptor.hueOrange;
      case 'commentator':
        return BitmapDescriptor.hueViolet;
      case 'tournament':
        return BitmapDescriptor.hueYellow;
      default:
        return BitmapDescriptor.hueRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _showMap ? _buildMapView() : _buildListArea(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Looking',
                  style: TextStyle(color: _ink, fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ),
              _IconToggle(
                icon: _showMap ? Icons.view_agenda_rounded : Icons.map_rounded,
                label: _showMap ? 'List' : 'Map',
                onTap: () => setState(() => _showMap = !_showMap),
              ),
              const SizedBox(width: 8),
              _IconToggle(icon: Icons.tune_rounded, label: 'City', onTap: _showLocationPicker),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (value) {
              _searchQuery = value.trim();
              _debounce.run(_loadItems);
            },
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search team, player, tournament, ground...',
              prefixIcon: const Icon(Icons.search_rounded, color: _muted),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, color: _muted),
                      onPressed: () {
                        _searchController.clear();
                        _searchQuery = '';
                        _loadItems();
                      },
                    ),
              filled: true,
              fillColor: _bg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 86,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final selected = category.id == _selectedType;
                return _CategoryButton(
                  category: category,
                  selected: selected,
                  onTap: () {
                    setState(() => _selectedType = category.id);
                    _loadItems();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  _selectedLocation == 'All Locations' ? 'All locations' : _selectedLocation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${_items.length} result${_items.length == 1 ? '' : 's'}',
                style: const TextStyle(color: _primary, fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListArea() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }
    if (_items.isEmpty) {
      return RefreshIndicator(
        color: _primary,
        onRefresh: _loadItems,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 76, 24, 120),
          children: const [
            Icon(Icons.search_off_rounded, size: 58, color: Color(0xFFCBD5E1)),
            SizedBox(height: 14),
            Text('No profiles found', textAlign: TextAlign.center, style: TextStyle(color: _ink, fontSize: 17, fontWeight: FontWeight.w900)),
            SizedBox(height: 6),
            Text('Try another category, city, or search keyword.', textAlign: TextAlign.center, style: TextStyle(color: _muted, height: 1.4)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _primary,
      onRefresh: _loadItems,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 112),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _DiscoveryCard(
          item: _items[index],
          color: _categoryColor(_items[index].type),
          icon: _categoryIcon(_items[index].type),
          onTap: () => _showItemDetails(_items[index]),
        ),
      ),
    );
  }

  Widget _buildMapView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }
    return GoogleMap(
      key: const ValueKey('looking-map'),
      initialCameraPosition: CameraPosition(
        target: _currentLatitude != null && _currentLongitude != null
            ? LatLng(_currentLatitude!, _currentLongitude!)
            : _defaultLocation,
        zoom: 11,
      ),
      markers: _markers,
      onMapCreated: (controller) => _mapController = controller,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
    );
  }

  void _showItemDetails(DiscoveryItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DiscoveryDetailsSheet(
        item: item,
        color: _categoryColor(item.type),
        icon: _categoryIcon(item.type),
        onMapTap: item.latitude == null || item.longitude == null
            ? null
            : () {
                Navigator.pop(context);
                setState(() => _showMap = true);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(item.latitude!, item.longitude!), 14));
                });
              },
      ),
    );
  }

  void _showLocationPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (context) => SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          itemCount: _locations.length + 1,
          separatorBuilder: (_, __) => const Divider(height: 1, color: _line),
          itemBuilder: (context, index) {
            if (index == 0) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('Choose location', style: TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w900)),
              );
            }
            final location = _locations[index - 1];
            final selected = location == _selectedLocation;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(location == 'All Locations' ? Icons.public_rounded : Icons.location_on_rounded, color: selected ? _primary : _muted),
              title: Text(location, style: TextStyle(color: selected ? _primary : _ink, fontWeight: selected ? FontWeight.w900 : FontWeight.w700)),
              trailing: selected ? const Icon(Icons.check_circle_rounded, color: _primary) : null,
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedLocation = location);
                _loadItems();
              },
            );
          },
        ),
      ),
    );
  }

  IconData _categoryIcon(String type) {
    return _categories
        .firstWhere(
          (category) => category.id == type,
          orElse: () => const _DiscoveryCategory('all', 'All', 'Explore', Icons.apps_rounded, _primary),
        )
        .icon;
  }

  Color _categoryColor(String type) {
    return _categories
        .firstWhere(
          (category) => category.id == type,
          orElse: () => const _DiscoveryCategory('all', 'All', 'Explore', Icons.apps_rounded, _primary),
        )
        .color;
  }
}

class _DiscoveryCategory {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _DiscoveryCategory(this.id, this.title, this.subtitle, this.icon, this.color);
}

class _IconToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _IconToggle({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: _DiscoveryScreenState._bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _DiscoveryScreenState._line),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: _DiscoveryScreenState._primary),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(color: _DiscoveryScreenState._ink, fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  final _DiscoveryCategory category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryButton({required this.category, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 104,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? category.color : _DiscoveryScreenState._bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? category.color : _DiscoveryScreenState._line),
          boxShadow: selected
              ? [BoxShadow(color: category.color.withOpacity(0.22), blurRadius: 14, offset: const Offset(0, 6))]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(category.icon, color: selected ? Colors.white : category.color, size: 22),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: selected ? Colors.white : _DiscoveryScreenState._ink, fontSize: 12, fontWeight: FontWeight.w900),
                ),
                Text(
                  category.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: selected ? Colors.white.withOpacity(0.78) : _DiscoveryScreenState._muted, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoveryCard extends StatelessWidget {
  final DiscoveryItem item;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _DiscoveryCard({required this.item, required this.color, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final chips = _detailChips(item).take(3).toList();
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _DiscoveryScreenState._line),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AvatarBox(item: item, color: color, icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name.isEmpty ? item.typeName : item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _DiscoveryScreenState._ink, fontSize: 15, fontWeight: FontWeight.w900),
                          ),
                        ),
                        if (item.isVerified) const Icon(Icons.verified_rounded, color: _DiscoveryScreenState._primary, size: 17),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.typeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 14, color: _DiscoveryScreenState._muted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.location.isEmpty ? 'Location not added' : item.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _DiscoveryScreenState._muted, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    if (chips.isNotEmpty) ...[
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: chips.map((chip) => _MiniChip(label: chip)).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                      Text(item.rating.toStringAsFixed(1), style: const TextStyle(color: _DiscoveryScreenState._ink, fontWeight: FontWeight.w900, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Icon(Icons.chevron_right_rounded, color: _DiscoveryScreenState._muted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarBox extends StatelessWidget {
  final DiscoveryItem item;
  final Color color;
  final IconData icon;

  const _AvatarBox({required this.item, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: item.image == null || item.image!.trim().isEmpty
            ? Icon(icon, color: color, size: 28)
            : CachedNetworkImage(
                imageUrl: item.image!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Icon(icon, color: color, size: 28),
              ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;

  const _MiniChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: _DiscoveryScreenState._bg, borderRadius: BorderRadius.circular(999), border: Border.all(color: _DiscoveryScreenState._line)),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _DiscoveryScreenState._muted, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}

class _DiscoveryDetailsSheet extends StatelessWidget {
  final DiscoveryItem item;
  final Color color;
  final IconData icon;
  final VoidCallback? onMapTap;

  const _DiscoveryDetailsSheet({required this.item, required this.color, required this.icon, this.onMapTap});

  @override
  Widget build(BuildContext context) {
    final details = _detailChips(item);
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          children: [
            Center(
              child: Container(width: 42, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(999))),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AvatarBox(item: item, color: color, icon: icon),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: const TextStyle(color: _DiscoveryScreenState._ink, fontSize: 20, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 5),
                      Text(item.typeName, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Text(item.location.isEmpty ? 'Location not added' : item.location, style: const TextStyle(color: _DiscoveryScreenState._muted, height: 1.3)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _Metric(icon: Icons.star_rounded, label: item.rating.toStringAsFixed(1), sub: 'Rating'),
                const SizedBox(width: 10),
                _Metric(icon: Icons.visibility_rounded, label: '${item.views}', sub: 'Views'),
                const SizedBox(width: 10),
                _Metric(icon: item.isVerified ? Icons.verified_rounded : Icons.schedule_rounded, label: item.isVerified ? 'Verified' : 'Listed', sub: 'Status'),
              ],
            ),
            if ((item.bio ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text('About', style: TextStyle(color: _DiscoveryScreenState._ink, fontSize: 15, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(item.bio!, style: const TextStyle(color: _DiscoveryScreenState._muted, height: 1.5)),
            ],
            if (details.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text('Details', style: TextStyle(color: _DiscoveryScreenState._ink, fontSize: 15, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: details.map((detail) => _MiniChip(label: detail)).toList()),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                if ((item.phone ?? '').trim().isNotEmpty)
                  Expanded(child: _SheetButton(icon: Icons.phone_rounded, label: 'Call', color: color, onTap: () {})),
                if ((item.phone ?? '').trim().isNotEmpty && (item.email ?? '').trim().isNotEmpty) const SizedBox(width: 10),
                if ((item.email ?? '').trim().isNotEmpty)
                  Expanded(child: _SheetButton(icon: Icons.email_rounded, label: 'Email', color: color, onTap: () {})),
              ],
            ),
            if (onMapTap != null) ...[
              const SizedBox(height: 10),
              _SheetButton(icon: Icons.map_rounded, label: 'View on map', color: color, onTap: onMapTap!),
            ],
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;

  const _Metric({required this.icon, required this.label, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: _DiscoveryScreenState._bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: _DiscoveryScreenState._line)),
        child: Column(
          children: [
            Icon(icon, color: _DiscoveryScreenState._primary, size: 19),
            const SizedBox(height: 5),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _DiscoveryScreenState._ink, fontWeight: FontWeight.w900, fontSize: 12)),
            Text(sub, style: const TextStyle(color: _DiscoveryScreenState._muted, fontSize: 10, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SheetButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

List<String> _detailChips(DiscoveryItem item) {
  final details = item.details;
  final chips = <String>[];

  void add(String? label, dynamic value) {
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty && text != 'null') chips.add(label == null ? text : '$label: $text');
  }

  add(null, item.availability);
  add('Role', details['role']);
  add('Team', details['team']);
  add('Coach', details['coach']);
  add('Captain', details['captain']);
  add('Matches', details['matches']);
  add('Capacity', details['capacity']);
  add('Bat', details['battingStyle']);
  add('Bowl', details['bowlingStyle']);
  add('Fee', item.hourlyRate == null ? null : item.hourlyRate!.round());

  final stats = details['stats'];
  if (stats is Map) {
    add('Runs', stats['runs']);
    add('Wkts', stats['wickets']);
    add('SR', stats['strikeRate']);
  }

  return chips;
}
