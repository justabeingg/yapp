import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/post.dart';
import '../providers/posts_provider.dart';
import '../../feed/providers/feed_provider.dart';
import '../services/media_upload_service.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _textController = TextEditingController();
  File? _selectedImage;
  bool _isPosting = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final service = ref.read(mediaUploadServiceProvider);
    final file = await service.pickImage();
    if (file != null) setState(() => _selectedImage = file);
  }

  void _removeImage() => setState(() => _selectedImage = null);

  Future<void> _submitPost() async {
    final text = _textController.text.trim();
    final hasText = text.isNotEmpty;
    final hasImage = _selectedImage != null;

    if (!hasText && !hasImage) return;

    setState(() => _isPosting = true);

    final repo = ref.read(postsRepositoryProvider);
    Post? post;

    if (hasImage) {
      final service = ref.read(mediaUploadServiceProvider);
      final uploadResult = await service.uploadImage(_selectedImage!);

      if (uploadResult == null) {
        if (mounted) {
          setState(() => _isPosting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image upload failed. Try again.')),
          );
        }
        return;
      }

      post = await repo.createImagePost(
        textContent: hasText ? text : null,
        mediaFileId: uploadResult.mediaFileId,
      );
    } else {
      post = await repo.createTextPost(text);
    }

    if (mounted) {
      if (post != null) {
        ref.invalidate(feedProvider);
        Navigator.pop(context);
      } else {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create post. Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Create Post', style: AppTextStyles.headlineLarge),
        actions: [
          TextButton(
            onPressed: _isPosting ? null : _submitPost,
            child: _isPosting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Post',
                    style: AppTextStyles.titleMedium
                        .copyWith(color: AppColors.primary),
                  ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _textController,
              maxLength: 280,
              maxLines: null,
              autofocus: _selectedImage == null,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: 'What\'s on your mind?',
                hintStyle: AppTextStyles.bodyLarge
                    .copyWith(color: AppColors.textMuted),
                border: InputBorder.none,
                counterStyle: const TextStyle(color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedImage != null) ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage!,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _removeImage,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (_selectedImage == null)
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image_outlined),
                label: const Text('Add Image'),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}
