import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../data/services/community_service.dart';
import '../../data/services/upload_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final CommunityService _communityService = CommunityService();
  final UploadService _uploadService = UploadService();
  final List<File> _selectedImages = [];
  bool _isPosting = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _uploadService.pickImageFromGallery();
    if (image == null || !mounted) return;
    setState(() => _selectedImages.add(image));
  }

  Future<void> _createPost() async {
    final content = _contentController.text.trim();
    if (content.isEmpty && _selectedImages.isEmpty) {
      _showSnack('Please write something or add an image.', Colors.grey.shade800);
      return;
    }

    setState(() => _isPosting = true);
    try {
      final uploadedImages = <Map<String, dynamic>>[];
      if (_selectedImages.isNotEmpty) {
        final uploadResult = _selectedImages.length == 1
            ? await _uploadService.uploadImage(_selectedImages.first, folder: 'scores11/community')
            : await _uploadService.uploadMultipleImages(_selectedImages, folder: 'scores11/community');

        if (uploadResult == null || uploadResult['success'] != true) {
          throw Exception(uploadResult?['message'] ?? 'Image upload failed');
        }

        final data = uploadResult['data'];
        if (data is List) {
          for (final item in data) {
            if (item is Map) uploadedImages.add(Map<String, dynamic>.from(item));
          }
        } else if (data is Map) {
          uploadedImages.add(Map<String, dynamic>.from(data));
        }
      }

      await _communityService.createPost({
        'content': content,
        'category': 'community',
        'tags': ['cricket'],
        if (uploadedImages.isNotEmpty) 'image': uploadedImages.first,
        if (uploadedImages.length > 1) 'images': uploadedImages,
      });

      if (!mounted) return;
      _showSnack('Post created successfully!', AppColors.success);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Unable to create post. Please try again.', AppColors.error);
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final maxWidth = width > 720 ? 680.0 : double.infinity;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Post',
              style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w900, fontSize: 18),
            ),
            Text(
              'Share a cricket moment',
              style: TextStyle(color: Color(0xFF667085), fontWeight: FontWeight.w600, fontSize: 11),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _isPosting ? null : _createPost,
              child: _isPosting
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  : Text(
                      'Post',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900),
                    ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _ComposerCard(
                controller: _contentController,
                selectedImages: _selectedImages,
                onPickImage: _pickImage,
                onRemoveImage: (index) => setState(() => _selectedImages.removeAt(index)),
              ),
              const SizedBox(height: 14),
              _PostTools(onPickImage: _pickImage),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Publish Post',
                onPressed: _createPost,
                isLoading: _isPosting,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposerCard extends StatelessWidget {
  final TextEditingController controller;
  final List<File> selectedImages;
  final VoidCallback onPickImage;
  final ValueChanged<int> onRemoveImage;

  const _ComposerCard({
    required this.controller,
    required this.selectedImages,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFECEFF5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.72)]),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Scores11', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                      SizedBox(height: 2),
                      Text('Public post', style: TextStyle(color: Color(0xFF667085), fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          TextField(
            controller: controller,
            minLines: 6,
            maxLines: null,
            decoration: const InputDecoration(
              hintText: 'Share match updates, photos, opinions, or cricket news...',
              hintStyle: TextStyle(color: Color(0xFF98A2B3), height: 1.45),
              border: InputBorder.none,
              contentPadding: EdgeInsets.fromLTRB(16, 0, 16, 14),
            ),
            style: const TextStyle(fontSize: 15, height: 1.55, color: Color(0xFF111827)),
          ),
          if (selectedImages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _ImagePreviewGrid(images: selectedImages, onRemove: onRemoveImage),
            ),
        ],
      ),
    );
  }
}

class _ImagePreviewGrid extends StatelessWidget {
  final List<File> images;
  final ValueChanged<int> onRemove;

  const _ImagePreviewGrid({required this.images, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: images.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: images.length == 1 ? 1 : 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: images.length == 1 ? 1.8 : 1,
      ),
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(images[index], fit: BoxFit.cover),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => onRemove(index),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PostTools extends StatelessWidget {
  final VoidCallback onPickImage;

  const _PostTools({required this.onPickImage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECEFF5)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Add to post',
              style: TextStyle(color: Color(0xFF475467), fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
          _ToolButton(icon: Icons.image_rounded, label: 'Photo', color: const Color(0xFF16A34A), onTap: onPickImage),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ToolButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
