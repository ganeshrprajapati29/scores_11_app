import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/config/theme_config.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/user_service.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final ImagePicker _imagePicker = ImagePicker();
  
  int _profileViews = 0;
  int _followers = 0;
  int _following = 0;
  bool _isPro = false;
  bool _isLoading = false;
  String _selectedPlayingStyle = 'All Rounder';
  List<Map<String, dynamic>> _equipment = [];
  final GlobalKey _qrKey = GlobalKey();

  final List<String> _playingStyles = [
    'Batsman',
    'Bowler',
    'All Rounder',
    'Wicket Keeper',
    'Opening Batsman',
    'Middle Order',
    'Fast Bowler',
    'Spinner',
  ];

  final List<Map<String, dynamic>> _equipmentOptions = [
    {'name': 'Bat', 'icon': '🏏'},
    {'name': 'Ball', 'icon': '⚾'},
    {'name': 'Gloves', 'icon': '🧤'},
    {'name': 'Helmet', 'icon': '⛑️'},
    {'name': 'Pads', 'icon': '🦵'},
    {'name': 'Shoes', 'icon': '👟'},
    {'name': 'Kit Bag', 'icon': '🎒'},
    {'name': 'Water Bottle', 'icon': '💧'},
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      // Load profile views
      final viewsResult = await _userService.getProfileViews();
      if (viewsResult['success']) {
        final data = jsonDecode(viewsResult['data']);
        setState(() => _profileViews = data['views'] ?? 0);
      }

      // Load followers
      final followersResult = await _userService.getFollowers();
      if (followersResult['success']) {
        final data = jsonDecode(followersResult['data']);
        setState(() => _followers = (data['followers'] as List?)?.length ?? 0);
      }

      // Load following
      final followingResult = await _userService.getFollowing();
      if (followingResult['success']) {
        final data = jsonDecode(followingResult['data']);
        setState(() => _following = (data['following'] as List?)?.length ?? 0);
      }

      // Load equipment
      final equipmentResult = await _userService.getEquipment();
      if (equipmentResult['success']) {
        final data = jsonDecode(equipmentResult['data']);
        setState(() => _equipment = List<Map<String, dynamic>>.from(data['equipment'] ?? []));
      }
    } catch (e) {
      debugPrint('Error loading profile data: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _imagePicker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 800,
                  maxHeight: 800,
                );
                if (image != null) {
                  _uploadPhoto(image);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _imagePicker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 800,
                  maxHeight: 800,
                );
                if (image != null) {
                  _uploadPhoto(image);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadPhoto(XFile image) async {
    setState(() => _isLoading = true);
    try {
      // Convert XFile to File
      final result = await _userService.uploadProfilePhoto(
        await _imagePicker.pickImage(source: ImageSource.gallery) as dynamic,
      );
      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo uploaded successfully')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error uploading photo: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled')),
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are permanently denied')),
        );
      }
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      final result = await _userService.updateLocation(
        position.latitude,
        position.longitude,
      );
      if (result['success'] && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location updated successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  void _showQRCode() {
    final authProvider = context.read<AuthProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Scores11 QR Code',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            RepaintBoundary(
              key: _qrKey,
              child: Container(
                padding: const EdgeInsets.all(20),
                child: QrImageView(
                  data: 'scores11://user/${authProvider.user?.id}',
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              authProvider.user?.name ?? 'User',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Capture QR code and share
                  try {
                    final boundary = _qrKey.currentContext?.findRenderObject() 
                        as RenderRepaintBoundary?;
                    if (boundary != null) {
                      final image = await boundary.toImage(pixelRatio: 3.0);
                      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                      if (byteData != null) {
                        // Share functionality would go here
                        await Share.share(
                          'Check out my Scores11 profile!',
                          subject: 'My Scores11 Profile',
                        );
                      }
                    }
                  } catch (e) {
                    debugPrint('Error sharing QR: $e');
                  }
                },
                icon: const Icon(Icons.share),
                label: const Text('Share QR Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showPlayingStyleSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Playing Style',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
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
                      await _userService.updatePlayingStyle(style);
                      if (mounted) Navigator.pop(context);
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showEquipmentSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Equipment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () async {
                      await _userService.updateEquipment(_equipment);
                      if (mounted) Navigator.pop(context);
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _equipmentOptions.length,
                  itemBuilder: (context, index) {
                    final option = _equipmentOptions[index];
                    final isSelected = _equipment.any((e) => e['name'] == option['name']);
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          if (isSelected) {
                            _equipment.removeWhere((e) => e['name'] == option['name']);
                          } else {
                            _equipment.add(option);
                          }
                        });
                        setState(() {});
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppColors.primary.withOpacity(0.1)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              option['icon'],
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              option['name'],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppColors.primary : Colors.black87,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: _showQRCode,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(context, '/edit-profile');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors.primaryGradient,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Avatar with edit option
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: _pickImage,
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white,
                                child: user?.avatar?.url != null
                                    ? ClipOval(
                                        child: Image.network(
                                          user!.avatar!.url!,
                                          width: 96,
                                          height: 96,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Text(
                                        user?.name.substring(0, 1).toUpperCase() ?? 'U',
                                        style: const TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.primary,
                                child: IconButton(
                                  icon: const Icon(Icons.camera_alt, size: 16),
                                  color: Colors.white,
                                  onPressed: _pickImage,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Name and Verified badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              user?.name ?? 'User',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (user?.isEmailVerified ?? false) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.verified, color: Colors.blueAccent, size: 24),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Location
                        GestureDetector(
                          onTap: _getCurrentLocation,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on, color: Colors.white, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  user?.address?.city ?? 'Set Location',
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Pro Version Badge
                        if (_isPro)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'PRO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        const SizedBox(height: 16),
                        
                        // Stats Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StatItem(
                              label: 'Followers',
                              value: _followers.toString(),
                              onTap: () => Navigator.pushNamed(context, '/followers'),
                            ),
                            _StatItem(
                              label: 'Following',
                              value: _following.toString(),
                              onTap: () => Navigator.pushNamed(context, '/following'),
                            ),
                            _StatItem(
                              label: 'Profile Views',
                              value: _profileViews.toString(),
                              onTap: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Playing Style
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      child: ListTile(
                        leading: const Icon(Icons.sports_cricket, color: AppColors.primary),
                        title: const Text('Playing Style'),
                        subtitle: Text(_selectedPlayingStyle),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _showPlayingStyleSelector,
                      ),
                    ),
                  ),
                  
                  // Equipment
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      child: ListTile(
                        leading: const Icon(Icons.inventory_2, color: AppColors.primary),
                        title: const Text('Equipment'),
                        subtitle: Text('${_equipment.length} items selected'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _showEquipmentSelector,
                      ),
                    ),
                  ),
                  
                  // Cricket Profile Button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/cricket-profile');
                      },
                      icon: const Icon(Icons.sports_cricket),
                      label: const Text('View Cricket Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ),
                  
                  // Menu Items
                  _buildMenuSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildMenuSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _MenuItem(
                  icon: Icons.people_outline,
                  title: 'Connections',
                  subtitle: 'Manage followers and following',
                  onTap: () {
                    Navigator.pushNamed(context, '/connections');
                  },
                ),
                const Divider(height: 1),
                _MenuItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Manage notification preferences',
                  onTap: () {
                    Navigator.pushNamed(context, '/notification-preferences');
                  },
                ),
                const Divider(height: 1),
                _MenuItem(
                  icon: Icons.language,
                  title: 'Language',
                  subtitle: 'Change app language',
                  onTap: () {
                    Navigator.pushNamed(context, '/language');
                  },
                ),
                const Divider(height: 1),
                _MenuItem(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Purchase History',
                  subtitle: 'View your purchases',
                  onTap: () {
                    Navigator.pushNamed(context, '/purchase-history');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Security',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _MenuItem(
                  icon: Icons.email_outlined,
                  title: 'Email Verification',
                  subtitle: 'Verify your email address',
                  onTap: () async {
                    final result = await _userService.verifyEmail();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result['success'] 
                              ? 'Verification email sent!' 
                              : 'Failed to send verification email'),
                        ),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                _MenuItem(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  onTap: () {
                    Navigator.pushNamed(context, '/change-password');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Support',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _MenuItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.pushNamed(context, '/help');
                  },
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
          Card(
            child: Column(
              children: [
                _MenuItem(
                  icon: Icons.delete_outline,
                  title: 'Clear Data',
                  subtitle: 'Remove cached data',
                  color: Colors.orange,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Clear Data'),
                        content: const Text('Are you sure you want to clear all cached data?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              final result = await _userService.clearUserData();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result['success'] 
                                        ? 'Data cleared successfully' 
                                        : 'Failed to clear data'),
                                  ),
                                );
                              }
                            },
                            child: const Text('Clear', style: TextStyle(color: Colors.orange)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                _MenuItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  color: AppColors.error,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              context.read<AuthProvider>().logout();
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            child: const Text('Logout', style: TextStyle(color: AppColors.error)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                _MenuItem(
                  icon: Icons.delete_forever,
                  title: 'Delete Account',
                  subtitle: 'Permanently delete your account',
                  color: Colors.red,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Account'),
                        content: const Text(
                          'Are you sure you want to delete your account? This action cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              final result = await _userService.deleteAccount();
                              if (mounted && result['success']) {
                                context.read<AuthProvider>().logout();
                                Navigator.pushReplacementNamed(context, '/login');
                              }
                            },
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
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
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
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
          ? Text(
              subtitle!,
              style: const TextStyle(fontSize: 12),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right,
        color: color ?? AppColors.textHint,
      ),
      onTap: onTap,
    );
  }
}
