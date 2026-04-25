import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';

final mediaUploadServiceProvider = Provider((ref) => MediaUploadService());

class MediaUploadResult {
  final String mediaFileId;
  final String fileKey;
  final String playbackUrl;

  MediaUploadResult({
    required this.mediaFileId,
    required this.fileKey,
    required this.playbackUrl,
  });
}

class MediaUploadService {
  final _picker = ImagePicker();

  Future<File?> pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;
    return File(picked.path);
  }

  Future<File?> compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.path}/${DateTime.now().millisecondsSinceEpoch}_c.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 85,
        minWidth: 1080,
        minHeight: 1080,
        keepExif: false,
      );

      if (result == null) {
        debugPrint('Compression returned null, using original');
        return null;
      }

      debugPrint('Compressed: ${await File(result.path).length()} bytes');
      return File(result.path);
    } catch (error) {
      debugPrint('Compression failed: $error; using original');
      return null;
    }
  }

  Future<MediaUploadResult?> uploadImage(File file) async {
    try {
      debugPrint('Starting image upload...');

      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        debugPrint('No active session');
        return null;
      }

      final compressed = await compressImage(file) ?? file;
      final fileSize = await compressed.length();

      final response = await http.post(
        Uri.parse(AppConstants.generateUploadUrlEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
          'apikey': AppConstants.supabaseAnonKey,
        },
        body: jsonEncode({
          'fileExtension': 'jpg',
          'contentType': 'image/jpeg',
          'mediaType': 'image',
        }),
      );

      if (response.statusCode != 200) {
        debugPrint(
          'Edge function failed: ${response.statusCode} - ${response.body}',
        );
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final uploadUrl = data['uploadUrl'] as String;
      final playbackUrl = data['playbackUrl'] as String;
      final mediaFileId = data['mediaFileId'] as String;
      final fileKey = data['fileKey'] as String;

      final uploadResponse = await http.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': 'image/jpeg'},
        body: await compressed.readAsBytes(),
      );

      if (uploadResponse.statusCode != 200) {
        debugPrint(
          'S3 upload failed: ${uploadResponse.statusCode} - '
          '${uploadResponse.body}',
        );
        return null;
      }

      await Supabase.instance.client.from('media_files').update({
        'file_size_bytes': fileSize,
        'processing_status': 'completed',
      }).eq('id', mediaFileId);

      return MediaUploadResult(
        mediaFileId: mediaFileId,
        fileKey: fileKey,
        playbackUrl: playbackUrl,
      );
    } catch (error, stackTrace) {
      debugPrint('Image upload error: $error');
      debugPrint('Stack: $stackTrace');
      return null;
    }
  }
}
