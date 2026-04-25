import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';

// ---------------------------------------------------------------------------
// Cache entry
// ---------------------------------------------------------------------------
class _CacheEntry {
  final String url;
  final DateTime expiresAt;

  _CacheEntry({required this.url, required this.expiresAt});

  bool get isValid => DateTime.now().isBefore(
        expiresAt.subtract(const Duration(minutes: 5)), // 5-min safety buffer
      );
}

// ---------------------------------------------------------------------------
// MediaUrlService
// Batch-fetches presigned S3 URLs. In-memory TTL cache (24h expiry from server).
// ---------------------------------------------------------------------------
class MediaUrlService {
  final Map<String, _CacheEntry> _cache = {};

  /// Returns presigned URL for a single key (uses batch internally).
  Future<String?> getUrl(String fileKey) async {
    final results = await getUrls([fileKey]);
    return results[fileKey];
  }

  /// Batch-fetches presigned URLs. Returns only the ones that succeeded.
  /// Already-cached (and still valid) keys are served from cache — no HTTP call.
  Future<Map<String, String>> getUrls(List<String> fileKeys) async {
    if (fileKeys.isEmpty) return {};

    final result = <String, String>{};
    final missing = <String>[];

    for (final key in fileKeys) {
      final entry = _cache[key];
      if (entry != null && entry.isValid) {
        result[key] = entry.url;
      } else {
        missing.add(key);
      }
    }

    if (missing.isEmpty) return result;

    try {
      final fetched = await _fetchBatch(missing);
      result.addAll(fetched);
    } catch (e) {
      debugPrint('[MediaUrlService] batch fetch error: $e');
    }

    return result;
  }

  Future<Map<String, String>> _fetchBatch(List<String> keys) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return {};

    // Split into chunks of 50 (edge function cap)
    final chunks = <List<String>>[];
    for (var i = 0; i < keys.length; i += 50) {
      chunks.add(keys.sublist(i, i + 50 > keys.length ? keys.length : i + 50));
    }

    final result = <String, String>{};

    await Future.wait(chunks.map((chunk) async {
      final response = await http.post(
        Uri.parse(AppConstants.getPlaybackUrlEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
          'apikey': AppConstants.supabaseAnonKey,
        },
        body: jsonEncode({'fileKeys': chunk}),
      );

      if (response.statusCode != 200) {
        debugPrint('[MediaUrlService] HTTP ${response.statusCode}: ${response.body}');
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final urls = data['urls'] as Map<String, dynamic>?;
      if (urls == null) return;

      for (final entry in urls.entries) {
        final val = entry.value as Map<String, dynamic>;
        final url = val['url'] as String?;
        final expiresAtStr = val['expiresAt'] as String?;
        if (url == null) continue;

        final expiresAt = expiresAtStr != null
            ? DateTime.tryParse(expiresAtStr) ?? DateTime.now().add(const Duration(hours: 23))
            : DateTime.now().add(const Duration(hours: 23));

        _cache[entry.key] = _CacheEntry(url: url, expiresAt: expiresAt);
        result[entry.key] = url;
      }
    }));

    return result;
  }

  void invalidate(String fileKey) => _cache.remove(fileKey);
  void clear() => _cache.clear();
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------
final mediaUrlServiceProvider = Provider<MediaUrlService>((ref) {
  return MediaUrlService();
});
