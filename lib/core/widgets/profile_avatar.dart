import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/user_model.dart';
import '../theme/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  final UserModel? user;
  final double radius;
  final double? heroRadius;
  final VoidCallback? onTap;
  final bool showOnlineIndicator;
  final bool isEditable;

  const ProfileAvatar({
    super.key,
    this.user,
    this.radius = 24.0,
    this.heroRadius,
    this.onTap,
    this.showOnlineIndicator = false,
    this.isEditable = false,
  });

  @override
  Widget build(BuildContext context) {
    final avatarRadius = heroRadius ?? radius;
    final avatarUrl = _safeUrl(user?.avatar?.url);
    
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: avatarRadius,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: avatarUrl != null
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: avatarUrl,
                    width: avatarRadius * 2,
                    height: avatarRadius * 2,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                    errorWidget: (context, url, error) =>
                        _buildFallbackAvatar(avatarRadius),
                  ),
                )
              : _buildFallbackAvatar(avatarRadius),
          ),
          if (showOnlineIndicator)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: avatarRadius * 0.4,
                height: avatarRadius * 0.4,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          if (isEditable)
            Positioned(
              bottom: -2,
              right: -2,
              child: CircleAvatar(
                radius: avatarRadius * 0.25,
                backgroundColor: AppColors.primary,
                child: Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: avatarRadius * 0.4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String? _safeUrl(String? value) {
    final url = value?.trim();
    if (url == null || url.isEmpty || url == 'default-avatar-url') return null;
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty)) {
      return null;
    }
    return url;
  }

  Widget _buildFallbackAvatar(double avatarRadius) {
    return ClipOval(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'score 11/Player Profile avatr circle page.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildInitials(),
          ),
          Center(child: _buildInitialsText()),
        ],
      ),
    );
  }

  Widget _buildInitials() {
    return Center(child: _buildInitialsText());
  }

  Widget _buildInitialsText() {
    final name = user?.name ?? 'U';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    
    return Text(
      initial,
      style: TextStyle(
        fontSize: radius * 0.6,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }
}
