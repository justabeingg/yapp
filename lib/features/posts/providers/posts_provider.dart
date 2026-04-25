import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/posts_repository.dart';
import '../models/post.dart';

final postsRepositoryProvider = Provider((ref) {
  return PostsRepository(Supabase.instance.client);
});

// Legacy provider — kept for create-post flow compatibility
final createPostRepositoryProvider = Provider((ref) {
  return PostsRepository(Supabase.instance.client);
});
