import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post.dart';

class PostsRepository {
  final SupabaseClient _supabase;

  PostsRepository(this._supabase);

  Future<Post?> createTextPost(String textContent) async {
    return _createPost(contentType: 'text', textContent: textContent);
  }

  Future<Post?> createImagePost(
      {String? textContent, required String mediaFileId}) async {
    final contentType =
        textContent != null && textContent.isNotEmpty ? 'text_image' : 'image';
    return _createPost(
      contentType: contentType,
      textContent: textContent,
      mediaFileId: mediaFileId,
    );
  }

  Future<Post?> _createPost({
    required String contentType,
    String? textContent,
    String? mediaFileId,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final response = await _supabase
          .from('posts')
          .insert({
            'user_id': user.id,
            'content_type': contentType,
            if (textContent != null && textContent.isNotEmpty)
              'text_content': textContent,
            if (mediaFileId != null) 'media_file_id': mediaFileId,
          })
          .select()
          .single();

      return Post.fromJson(response);
    } catch (e) {
      debugPrint('Error creating post: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getFeedRaw(
      {int limit = 20, int offset = 0}) async {
    try {
      // Step 1: fetch posts + media
      final posts = await _supabase
          .from('posts')
          .select('*, media_files(raw_file_key, media_type)')
          .eq('is_removed', false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final postList = List<Map<String, dynamic>>.from(posts as List);
      if (postList.isEmpty) return [];

      final postIds = postList.map((p) => p['id'] as String).toList();

      final yaps = await _supabase
          .from('yaps')
          .select(
            'id, user_id, post_id, media_file_id, selected_filter, '
            'play_count, reply_count, created_at, '
            'media_files(raw_file_key, duration_seconds, media_type)',
          )
          .inFilter('post_id', postIds)
          .eq('is_deleted', false)
          .order('created_at', ascending: true);

      final yapList = List<Map<String, dynamic>>.from(yaps as List);

      // Step 2: collect unique user_ids
      final userIds = <String>{
        ...postList.map((p) => p['user_id'] as String),
        ...yapList.map((y) => y['user_id'] as String),
      }.toList();

      // Step 3: fetch profiles for those user_ids
      final profiles = await _supabase
          .from('profiles')
          .select('id, username, avatar_emoji, avatar_color')
          .inFilter('id', userIds);

      final profileMap = <String, Map<String, dynamic>>{};
      for (final p in profiles as List) {
        profileMap[p['id'] as String] = Map<String, dynamic>.from(p as Map);
      }

      final yapsByPostId = <String, List<Map<String, dynamic>>>{};
      for (final yap in yapList) {
        final postId = yap['post_id'] as String;
        final userId = yap['user_id'] as String;
        yapsByPostId.putIfAbsent(postId, () => []).add({
          ...yap,
          'profile': profileMap[userId],
        });
      }

      // Step 4: attach profile and yaps to each post
      return postList.map((post) {
        final userId = post['user_id'] as String;
        return {
          ...post,
          'profile': profileMap[userId],
          'yaps': yapsByPostId[post['id'] as String] ?? [],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching feed: $e');
      return [];
    }
  }
}
