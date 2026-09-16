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
import '../../core/utils/logout_helper.dart';
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  // ── Services ──────────────────────────────────────────────────────────────────
  final UserService _userService = UserService();
  final ImagePicker _imagePicker = ImagePicker();
  final GlobalKey _qrKey = GlobalKey();

  // ── State ─────────────────────────────────────────────────────────────────────
  int _profileViews = 0;
  int _followers = 0;
  int _following = 0;
  bool _isPro = false;
  bool _isLoading = false;
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

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  dynamic _decodeApiData(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return jsonDecode(value);
    }
    return value;
  }

  int _countFrom(dynamic value, String key) {
    final data = _decodeApiData(value);
    if (data is List) return data.length;
    if (data is Map) {
      final nested = data[key] ?? data['data'] ?? data['items'];
      if (nested is List) return nested.length;
      if (nested is num) return nested.toInt();
      final total = data['total'] ?? data['count'];
      if (total is num) return total.toInt();
    }
    return 0;
  }

  List<Map<String, dynamic>> _equipmentFrom(dynamic value) {
    final data = _decodeApiData(value);
    final raw = data is List
        ? data
        : data is Map
            ? data['equipment'] ?? data['data'] ?? data['items']
            : null;
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // ── Data loading ──────────────────────────────────────────────────────────────
  Future<void> _loadProfileData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await context.read<AuthProvider>().checkAuth();

      final fullProfileResult = await _userService.getFullProfile();
      if (fullProfileResult['success'] == true && mounted) {
        final data = _decodeApiData(fullProfileResult['data']);
        if (data is Map) {
          final social = data['social'];
          final stats = data['stats'];
          final user = data['user'];
          setState(() {
            _profileViews = _countFrom(social is Map ? social : stats, 'profileViews');
            _followers = _countFrom(social is Map ? social : data, 'followers');
            _following = _countFrom(social is Map ? social : data, 'following');
            _equipment = _equipmentFrom(data['equipment']);
            if (user is Map) {
              _selectedPlayingStyle =
                  user['playingStyle']?.toString() ??
                  user['cricketProfile']?['playingStyle']?.toString() ??
                  _selectedPlayingStyle;
            }
          });
        }
      }

      final viewsResult = await _userService.getProfileViews();
      if (viewsResult['success'] == true && mounted) {
        setState(() => _profileViews = _countFrom(viewsResult['data'], 'views'));
      }

      final followersResult = await _userService.getFollowers();
      if (followersResult['success'] == true && mounted) {
        setState(() => _followers = _countFrom(followersResult['data'], 'followers'));
      }

      final followingResult = await _userService.getFollowing();
      if (followingResult['success'] == true && mounted) {
        setState(() => _following = _countFrom(followingResult['data'], 'following'));
      }

      final equipmentResult = await _userService.getEquipment();
      if (equipmentResult['success'] == true && mounted) {
        setState(() => _equipment = _equipmentFrom(equipmentResult['data']));
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Update Photo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              _buildBottomSheetOption(
                icon: Icons.camera_alt_rounded,
                label: 'Take Photo',
                onTap: () async {
                  Navigator.pop(ctx);
                  final XFile? img = await _imagePicker.pickImage(
                      source: ImageSource.camera);
                  if (img != null) _uploadPhoto(img.path);
                },
              ),
              const SizedBox(height: 10),
              _buildBottomSheetOption(
                icon: Icons.photo_library_rounded,
                label: 'Choose from Gallery',
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
      ),
    );
  }

  Widget _buildBottomSheetOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0F172A),
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.grey.shade400),
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
    final user = authProvider.user;
    final userId = user?.id ?? '';
    final userName = user?.name ?? 'User';
    final playerId = (user?.cricketProfile?['playerId'] ??
            user?.cricketProfile?['_id'] ??
            userId)
        .toString();
    final qrData = Uri(
      scheme: 'scores11',
      host: 'profile',
      path: userId,
      queryParameters: {
        'playerId': playerId,
        'name': userName,
        'app': 'scores11',
      },
    ).toString();

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
            const SizedBox(height: 12),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Scores11 QR',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Scan to view profile or add player',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            RepaintBoundary(
              key: _qrKey,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.sports_cricket,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Scores11',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 190,
                      backgroundColor: Colors.white,
                      embeddedImage: const AssetImage('assets/images/logo.png'),
                      embeddedImageStyle: const QrEmbeddedImageStyle(
                        size: Size(34, 34),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'scores11://profile/$userId',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              userName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _shareQR,
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text(
                    'Share QR Code',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
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
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final buffer = byteData.buffer.asUint8List();
      await Share.shareXFiles(
        [XFile.fromData(buffer, mimeType: 'image/png')],
        text: 'Scan my Scores11 QR to view my cricket profile and connect.',
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Playing Style',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose your primary playing style',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _playingStyles.map((style) {
                  final isSelected = _selectedPlayingStyle == style;
                  return GestureDetector(
                    onTap: () async {
                      setState(() => _selectedPlayingStyle = style);
                      setModal(() {});
                      await _userService.updatePlayingStyle(style);
                      // Completing the cricket profile may have just
                      // promoted this account to the 'player' role server
                      // side; refresh so nav updates without a re-login.
                      if (mounted) {
                        await context.read<AuthProvider>().checkAuth();
                      }
                      if (mounted) Navigator.pop(ctx);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        style,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
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
    final localEquipment = List<Map<String, dynamic>>.from(_equipment);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Equipment',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        setState(() => _equipment = localEquipment);
                        await _userService.updateEquipment(localEquipment);
                        if (mounted) Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
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
                      final option = _equipmentOptions[index];
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
                                ? AppColors.primary.withOpacity(0.08)
                                : const Color(0xFFF8F9FC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(option['icon'] as String,
                                  style: const TextStyle(fontSize: 22)),
                              const SizedBox(height: 5),
                              Text(
                                option['name'] as String,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? AppColors.primary
                                      : const Color(0xFF64748B),
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
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      backgroundColor: isError
          ? const Color(0xFFEF4444)
          : const Color(0xFF16A34A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
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
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: confirmColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning_amber_rounded,
                    color: confirmColor, size: 26),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                content,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        onConfirm();
                      },
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: confirmColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            confirmLabel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              color: AppColors.primary,
              strokeWidth: 2.5,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeroHeader(user),
                    const SizedBox(height: 16),
                    _buildCricketInfoCard(),
                    const SizedBox(height: 12),
                    _buildCricketProfileButton(),
                    const SizedBox(height: 8),
                    _buildMenuSection(),
                  ],
                ),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      title: const Text(
        'Profile',
        style: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: const Color(0xFFE2E8F0), height: 1),
      ),
      actions: [
        _buildAppBarButton(Icons.qr_code_rounded, _showQRCode),
        _buildAppBarButton(Icons.edit_rounded,
            () => Navigator.pushNamed(context, '/edit-profile')),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildAppBarButton(IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF64748B), size: 20),
        onPressed: onTap,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2.5,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading profile...',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(dynamic user) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: const Color(0xFFE2E8F0)),
        ),
      ),
      child: Column(
        children: [
          // Gradient banner
          Container(
            width: double.infinity,
            height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              image: const DecorationImage(
                image: AssetImage('score 11/Player Profile cover page.png'),
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                opacity: 0.28,
              ),
            ),
          ),

          // Avatar overlapping the banner
          Transform.translate(
            offset: const Offset(0, -36),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: ProfileAvatar(
                          user: user,
                          radius: 44,
                          isEditable: true,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),

                // Name row
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          user?.name ?? 'User',
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user?.isEmailVerified ?? false) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.verified_rounded,
                            color: AppColors.primary, size: 20),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // Email
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 10),

                // Location chip
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _getCurrentLocation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on_rounded,
                                color: AppColors.primary, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              user?.address?.city ?? 'Set Location',
                              style: TextStyle(
                                color: const Color(0xFF475569),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.edit_rounded,
                                color: Colors.grey.shade400, size: 11),
                          ],
                        ),
                      ),
                    ),
                    if (_isPro) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded,
                                color: Colors.white, size: 13),
                            SizedBox(width: 3),
                            Text(
                              'PRO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 20),

                // Stats row
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(
                        label: 'Followers',
                        value: _formatCount(_followers),
                        onTap: () =>
                            Navigator.pushNamed(context, '/connections'),
                      ),
                      Container(
                          width: 1, height: 32,
                          color: const Color(0xFFE2E8F0)),
                      _buildStatItem(
                        label: 'Following',
                        value: _formatCount(_following),
                        onTap: () =>
                            Navigator.pushNamed(context, '/connections'),
                      ),
                      Container(
                          width: 1, height: 32,
                          color: const Color(0xFFE2E8F0)),
                      _buildStatItem(
                        label: 'Profile Views',
                        value: _formatCount(_profileViews),
                        onTap: _loadProfileData,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCricketInfoCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildInfoTile(
              icon: Icons.sports_cricket_rounded,
              title: 'Playing Style',
              subtitle: _selectedPlayingStyle,
              onTap: _showPlayingStyleSelector,
            ),
            Container(height: 1, color: const Color(0xFFF1F5F9)),
            _buildInfoTile(
              icon: Icons.inventory_2_rounded,
              title: 'Equipment',
              subtitle:
                  '${_equipment.length} item${_equipment.length == 1 ? '' : 's'} selected',
              onTap: _showEquipmentSelector,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCricketProfileButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/cricket-profile'),
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sports_cricket_rounded,
                  color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'View Cricket Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
          _buildSectionHeader('Account'),
          _buildMenuCard([
            _buildMenuItem(
              icon: Icons.people_outline_rounded,
              title: 'Connections',
              subtitle: 'Manage followers and following',
              onTap: () => Navigator.pushNamed(context, '/connections'),
            ),
            _buildMenuItem(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Manage notification preferences',
              onTap: () => Navigator.pushNamed(context, '/settings/notifications'),
            ),
            _buildMenuItem(
              icon: Icons.language_rounded,
              title: 'Language',
              subtitle: 'Change app language',
              onTap: () => Navigator.pushNamed(context, '/settings/preferences'),
            ),
            _buildMenuItem(
              icon: Icons.shopping_bag_outlined,
              title: 'Purchase History',
              subtitle: 'View your purchases',
              onTap: () =>
                  Navigator.pushNamed(context, '/orders'),
              isLast: true,
            ),
          ]),

          const SizedBox(height: 16),

          // Security
          _buildSectionHeader('Security'),
          _buildMenuCard([
            _buildMenuItem(
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
              isLast: true,
            ),
          ]),

          const SizedBox(height: 16),

          // Support
          _buildSectionHeader('Support'),
          _buildMenuCard([
            _buildMenuItem(
              icon: Icons.help_outline_rounded,
              title: 'Help & Support',
              onTap: () => Navigator.pushNamed(context, '/help-support'),
            ),
            _buildMenuItem(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () => Navigator.pushNamed(context, '/privacy-policy'),
            ),
            _buildMenuItem(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              onTap: () => Navigator.pushNamed(context, '/terms'),
              isLast: true,
            ),
          ]),

          const SizedBox(height: 16),

          // Danger zone
          _buildMenuCard([
            _buildMenuItem(
              icon: Icons.delete_outline_rounded,
              title: 'Clear Data',
              subtitle: 'Remove cached data',
              color: const Color(0xFFF97316),
              onTap: () => _confirmAction(
                title: 'Clear Data',
                content:
                    'Are you sure you want to clear all cached data?',
                confirmLabel: 'Clear',
                confirmColor: const Color(0xFFF97316),
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
            _buildMenuItem(
              icon: Icons.logout_rounded,
              title: 'Logout',
              color: AppColors.error,
              onTap: () => _confirmAction(
                title: 'Logout',
                content: 'Are you sure you want to logout?',
                confirmLabel: 'Logout',
                confirmColor: AppColors.error,
                onConfirm: () async {
                  await performLogout(context);
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                },
              ),
            ),
            _buildMenuItem(
              icon: Icons.delete_forever_rounded,
              title: 'Delete Account',
              subtitle: 'Permanently delete your account',
              color: const Color(0xFFDC2626),
              onTap: () => _confirmAction(
                title: 'Delete Account',
                content:
                    'Are you sure you want to delete your account? Your profile will be deactivated immediately and all your data will be permanently removed within 30 days. This cannot be undone.',
                confirmLabel: 'Delete',
                confirmColor: const Color(0xFFDC2626),
                onConfirm: () async {
                  final r = await _userService.deleteAccount();
                  if (mounted && r['success'] == true) {
                    await performLogout(context);
                    if (!context.mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  }
                },
              ),
              isLast: true,
            ),
          ]),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade400,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? color,
    bool isLast = false,
  }) {
    final iconColor = color ?? AppColors.primary;
    final titleColor = color ?? const Color(0xFF0F172A);

    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            color: Colors.transparent,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 19),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: titleColor,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: color ?? const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Container(
            height: 1,
            margin: const EdgeInsets.only(left: 66),
            color: const Color(0xFFF1F5F9),
          ),
      ],
    );
  }
}
