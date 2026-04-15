import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

// ── Replace with your actual imports ─────────────────────────────────────────
import '../../core/theme/app_colors.dart';
import '../../core/widgets/profile_avatar.dart';
import '../../data/services/user_service.dart';
import '../../providers/auth_provider.dart';
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ── Services ──────────────────────────────────────────────────────────────────
  final UserService _userService = UserService();
  final ImagePicker _imagePicker = ImagePicker();
  final GlobalKey   _qrKey       = GlobalKey();

  // ── State ─────────────────────────────────────────────────────────────────────
  int    _profileViews         = 0;
  int    _followers            = 0;
  int    _following            = 0;
  bool   _isPro                = false;
  bool   _isLoading            = false;
  String _selectedPlayingStyle = 'All Rounder';

  List<Map<String, dynamic>> _equipment = [];
  Position? _position;

  // ── Static data ───────────────────────────────────────────────────────────────
  static const List<String> _playingStyles = [
    'Batsman', 'Bowler', 'All Rounder', 'Wicket Keeper',
    'Opening Batsman', 'Middle Order', 'Fast Bowler', 'Spinner',
  ];

  static const List<Map<String, dynamic>> _equipmentOptions = [
    {'name': 'Bat',          'icon': '🏏'},
    {'name': 'Ball',         'icon': '⚾'},
    {'name': 'Gloves',       'icon': '🧤'},
    {'name': 'Helmet',       'icon': '⛑️'},
    {'name': 'Pads',         'icon': '🦵'},
    {'name': 'Shoes',        'icon': '👟'},
    {'name': 'Kit Bag',      'icon': '🎒'},
    {'name': 'Water Bottle', 'icon': '💧'},
  ];

  // ── Lifecycle ─────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // ── Data loading ──────────────────────────────────────────────────────────────
  Future<void> _loadProfileData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final viewsResult = await _userService.getProfileViews();
      if (viewsResult['success'] == true && mounted) {
        dynamic dataRaw = viewsResult['data'];
        dynamic data = dataRaw is String ? jsonDecode(dataRaw) : dataRaw;
        data = data is Map<String, dynamic> ? data : {};
        setState(() => _profileViews = (data['views'] as int?) ?? 0);
      }

      final followersResult = await _userService.getFollowers();
      if (followersResult['success'] == true && mounted) {
        dynamic dataRaw = followersResult['data'];
        dynamic data = dataRaw is String ? jsonDecode(dataRaw) : dataRaw;
        data = data is Map<String, dynamic> ? data : {};
        setState(() => _followers = (data['followers'] as List?)?.length ?? 0);
      }

      final followingResult = await _userService.getFollowing();
      if (followingResult['success'] == true && mounted) {
        dynamic dataRaw = followingResult['data'];
        dynamic data = dataRaw is String ? jsonDecode(dataRaw) : dataRaw;
        data = data is Map<String, dynamic> ? data : {};
        setState(() => _following = (data['following'] as List?)?.length ?? 0);
      }

      final equipmentResult = await _userService.getEquipment();
      if (equipmentResult['success'] == true && mounted) {
        dynamic dataRaw = equipmentResult['data'];
        dynamic data = dataRaw is String ? jsonDecode(dataRaw) : dataRaw;
        data = data is Map<String, dynamic> ? data : {};
        setState(() => _equipment =
            List<Map<String, dynamic>>.from(data['equipment'] ?? []));
      }
    } catch (e) {
      debugPrint('Error loading profile data: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // ── Image picker ──────────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(ctx);
                final XFile? img = await _imagePicker.pickImage(
                    source: ImageSource.camera);
                if (img != null) _uploadPhoto(img.path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.pop(ctx);
                final XFile? img = await _imagePicker.pickImage(
                    source: ImageSource.gallery);
                if (img != null) _uploadPhoto(img.path);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadPhoto(String imagePath) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final result = await _userService.uploadProfilePhoto(imagePath);
      if (result['success'] == true && mounted) {
        _showSnack('Photo uploaded successfully');
      }
    } catch (e) {
      debugPrint('Error uploading photo: $e');
      if (mounted) _showSnack('Failed to upload photo', isError: true);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  // ── Location ──────────────────────────────────────────────────────────────────
  Future<void> _getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Location services are disabled', isError: true);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack('Location permission denied', isError: true);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnack('Location permissions are permanently denied', isError: true);
        return;
      }

      _position = await Geolocator.getCurrentPosition();
      final result = await _userService.updateLocation(
          _position!.latitude, _position!.longitude);
      if (result['success'] == true && mounted) {
        _showSnack('Location updated successfully');
        _loadProfileData();
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      _showSnack('Could not get location', isError: true);
    }
  }

  // ── QR Code ───────────────────────────────────────────────────────────────────
  void _showQRCode() {
    final authProvider = context.read<AuthProvider>();
    final userId       = authProvider.user?.id ?? '';
    final userName     = authProvider.user?.name ?? 'User';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text('Scores11 QR Code',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            RepaintBoundary(
              key: _qrKey,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: QrImageView(
                  data: 'scores11://user/$userId',
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(userName,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w500)),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _shareQR,
                  icon: const Icon(Icons.share),
                  label: const Text('Share QR Code'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareQR() async {
    try {
      final boundary = _qrKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image    = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final buffer = byteData.buffer.asUint8List();
      await Share.shareXFiles(
        [XFile.fromData(buffer, mimeType: 'image/png')],
        text: 'Check out my Scores11 profile!',
      );
    } catch (e) {
      debugPrint('Error sharing QR: $e');
      _showSnack('Failed to share QR code', isError: true);
    }
  }

  // ── Playing style ─────────────────────────────────────────────────────────────
  void _showPlayingStyleSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Playing Style',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _playingStyles.map((style) {
                  final isSelected = _selectedPlayingStyle == style;
                  return ChoiceChip(
                    label: Text(style),
                    selected: isSelected,
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    onSelected: (selected) async {
                      if (selected) {
                        setState(() => _selectedPlayingStyle = style);
                        setModal(() {});
                        await _userService.updatePlayingStyle(style);
                        if (mounted) Navigator.pop(ctx);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── Equipment ─────────────────────────────────────────────────────────────────
  void _showEquipmentSelector() {
    // Use a local copy so changes only commit on Save
    final localEquipment = List<Map<String, dynamic>>.from(_equipment);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('My Equipment',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () async {
                        setState(() => _equipment = localEquipment);
                        await _userService.updateEquipment(localEquipment);
                        if (mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _equipmentOptions.length,
                    itemBuilder: (_, index) {
                      final option     = _equipmentOptions[index];
                      final isSelected = localEquipment
                          .any((e) => e['name'] == option['name']);

                      return GestureDetector(
                        onTap: () {
                          setModal(() {
                            if (isSelected) {
                              localEquipment.removeWhere(
                                  (e) => e['name'] == option['name']);
                            } else {
                              localEquipment.add(Map.from(option));
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.1)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(option['icon'] as String,
                                  style: const TextStyle(fontSize: 24)),
                              const SizedBox(height: 4),
                              Text(
                                option['name'] as String,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────
  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppColors.error : null,
    ));
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  void _confirmAction({
    required String title,
    required String content,
    required String confirmLabel,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: Text(confirmLabel,
                style: TextStyle(color: confirmColor)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user         = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            tooltip: 'Show QR',
            onPressed: _showQRCode,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Profile',
            onPressed: () =>
                Navigator.pushNamed(context, '/edit-profile'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // ── Hero header ─────────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: AppColors.primaryGradient,
                          begin: Alignment.topLeft,
                          end:   Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Avatar with camera overlay
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: _pickImage,
                                child: ProfileAvatar(
                                  user: user,
                                  radius: 44,
                                  isEditable: true,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppColors.primary,
                                    child: const Icon(Icons.camera_alt,
                                        size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Name + verified badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  user?.name ?? 'User',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (user?.isEmailVerified ?? false) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.verified,
                                    color: Colors.blueAccent, size: 22),
                              ],
                            ],
                          ),

                          const SizedBox(height: 4),

                          // Email
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13),
                          ),

                          const SizedBox(height: 10),

                          // Location chip
                          GestureDetector(
                            onTap: _getCurrentLocation,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on,
                                      color: Colors.white, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    user?.address?.city ?? 'Set Location',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 12),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.edit,
                                      color: Colors.white70, size: 12),
                                ],
                              ),
                            ),
                          ),

                          // PRO badge
                          if (_isPro) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(20)),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star,
                                      color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text('PRO',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 18),

                          // Stats row
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceEvenly,
                            children: [
                              _StatItem(
                                label: 'Followers',
                                value: _formatCount(_followers),
                                onTap: () => Navigator.pushNamed(
                                    context, '/followers'),
                              ),
                              _StatDivider(),
                              _StatItem(
                                label: 'Following',
                                value: _formatCount(_following),
                                onTap: () => Navigator.pushNamed(
                                    context, '/following'),
                              ),
                              _StatDivider(),
                              _StatItem(
                                label: 'Profile Views',
                                value: _formatCount(_profileViews),
                                onTap: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Quick-action cards ────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.sports_cricket,
                                  color: AppColors.primary),
                              title: const Text('Playing Style'),
                              subtitle: Text(_selectedPlayingStyle),
                              trailing:
                                  const Icon(Icons.chevron_right),
                              onTap: _showPlayingStyleSelector,
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.inventory_2,
                                  color: AppColors.primary),
                              title: const Text('Equipment'),
                              subtitle: Text(
                                  '${_equipment.length} item${_equipment.length == 1 ? '' : 's'} selected'),
                              trailing:
                                  const Icon(Icons.chevron_right),
                              onTap: _showEquipmentSelector,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Cricket Profile button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(
                              context, '/cricket-profile'),
                          icon:
                              const Icon(Icons.sports_cricket),
                          label:
                              const Text('View Cricket Profile'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Menu sections
                    _buildMenuSection(),
                  ],
                ),
              ),
            ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  //  MENU SECTION
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildMenuSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account
          const _SectionHeader('Account'),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _MenuItem(
                  icon: Icons.people_outline,
                  title: 'Connections',
                  subtitle: 'Manage followers and following',
                  onTap: () =>
                      Navigator.pushNamed(context, '/connections'),
                ),
                const Divider(height: 1),
                _MenuItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Manage notification preferences',
                  onTap: () => Navigator.pushNamed(
                      context, '/notification-preferences'),
                ),
                const Divider(height: 1),
                _MenuItem(
                  icon: Icons.language,
                  title: 'Language',
                  subtitle: 'Change app language',
                  onTap: () =>
                      Navigator.pushNamed(context, '/language'),
                ),
                const Divider(height: 1),
                _MenuItem(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Purchase History',
                  subtitle: 'View your purchases',
                  onTap: () => Navigator.pushNamed(
                      context, '/purchase-history'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Security
          const _SectionHeader('Security'),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _MenuItem(
                  icon: Icons.email_outlined,
                  title: 'Email Verification',
                  subtitle: 'Verify your email address',
                  onTap: () async {
                    final result = await _userService.verifyEmail();
                    if (mounted) {
                      _showSnack(
                        result['success'] == true
                            ? 'Verification email sent!'
                            : 'Failed to send verification email',
                        isError: result['success'] != true,
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                _MenuItem(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  onTap: () => Navigator.pushNamed(
                      context, '/change-password'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Support
          const _SectionHeader('Support'),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _MenuItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () =>
                      Navigator.pushNamed(context, '/help'),
                ),
                const Divider(height: 1),
                _MenuItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () {},
                ),
                const Divider(height: 1),
                _MenuItem(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Danger zone
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _MenuItem(
                  icon: Icons.delete_outline,
                  title: 'Clear Data',
                  subtitle: 'Remove cached data',
                  color: Colors.orange,
                  onTap: () => _confirmAction(
                    title: 'Clear Data',
                    content:
                        'Are you sure you want to clear all cached data?',
                    confirmLabel: 'Clear',
                    confirmColor: Colors.orange,
                    onConfirm: () async {
                      final r = await _userService.clearUserData();
                      _showSnack(
                        r['success'] == true
                            ? 'Data cleared successfully'
                            : 'Failed to clear data',
                        isError: r['success'] != true,
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                _MenuItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  color: AppColors.error,
                  onTap: () => _confirmAction(
                    title: 'Logout',
                    content: 'Are you sure you want to logout?',
                    confirmLabel: 'Logout',
                    confirmColor: AppColors.error,
                    onConfirm: () {
                      context.read<AuthProvider>().logout();
                      Navigator.pushReplacementNamed(
                          context, '/login');
                    },
                  ),
                ),
                const Divider(height: 1),
                _MenuItem(
                  icon: Icons.delete_forever,
                  title: 'Delete Account',
                  subtitle: 'Permanently delete your account',
                  color: Colors.red,
                  onTap: () => _confirmAction(
                    title: 'Delete Account',
                    content:
                        'Are you sure you want to delete your account? This cannot be undone.',
                    confirmLabel: 'Delete',
                    confirmColor: Colors.red,
                    onConfirm: () async {
                      final r = await _userService.deleteAccount();
                      if (mounted && r['success'] == true) {
                        context.read<AuthProvider>().logout();
                        Navigator.pushReplacementNamed(
                            context, '/login');
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HELPER WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textHint,
            letterSpacing: 0.5,
          ),
        ),
      );
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: 30,
        width: 1,
        color: Colors.white.withOpacity(0.3),
      );
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _StatItem({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.8), fontSize: 12)),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? color;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primary),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(fontSize: 12))
          : null,
      trailing:
          Icon(Icons.chevron_right, color: color ?? AppColors.textHint),
      onTap: onTap,
    );
  }
}