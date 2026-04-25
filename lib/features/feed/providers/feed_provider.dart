import 'dart:convert';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../models/feed_models.dart';
import '../repositories/feed_repository.dart';
import '../services/media_url_service.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------
final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(Supabase.instance.client);
});

// ---------------------------------------------------------------------------
// Feed state
// ---------------------------------------------------------------------------
class FeedState {
  final List<FeedPost> posts;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  const FeedState({
    this.posts = const [],
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  FeedState copyWith({
    List<FeedPost>? posts,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// FeedNotifier
// ---------------------------------------------------------------------------
class FeedNotifier extends AsyncNotifier<FeedState> {
  static const int _pageSize = 20;

  FeedRepository get _repo => ref.read(feedRepositoryProvider);
  MediaUrlService get _mediaService => ref.read(mediaUrlServiceProvider);

  @override
  Future<FeedState> build() async {
    final posts = await _repo.getFeed(limit: _pageSize);
    await _prefetchUrls(posts);
    return FeedState(posts: posts, hasMore: posts.length == _pageSize);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final posts = await _repo.getFeed(limit: _pageSize);
      await _prefetchUrls(posts);
      return FeedState(posts: posts, hasMore: posts.length == _pageSize);
    });
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final cursor =
          current.posts.isNotEmpty ? current.posts.last.createdAt : null;
      final more = await _repo.getFeed(limit: _pageSize, before: cursor);
      await _prefetchUrls(more);

      state = AsyncData(current.copyWith(
        posts: [...current.posts, ...more],
        isLoadingMore: false,
        hasMore: more.length == _pageSize,
      ));
    } catch (e) {
      state = AsyncData(current.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // Optimistic yap management
  // ---------------------------------------------------------------------------

  /// Inserts a pending yap immediately into the in-memory tree.
  /// Returns the tempId so the caller can confirm/fail it later.
  String addOptimisticYap({
    required String postId,
    required String? parentYapId,
    required FeedProfile profile,
    required double durationSeconds,
    required String localAudioPath,
  }) {
    final current = state.valueOrNull;
    if (current == null) return '';

    final tempId = 'pending_${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = FeedYap(
      id: tempId,
      postId: postId,
      parentYapId: parentYapId,
      profile: profile,
      media: FeedMedia(
        rawFileKey: '',
        mediaType: 'audio',
        durationSeconds: durationSeconds,
      ),
      createdAt: DateTime.now(),
      status: YapStatus.pending,
      localAudioPath: localAudioPath,
    );

    final updatedPosts = current.posts.map((post) {
      if (post.id != postId) return post;
      final updatedYaps = _insertYapIntoTree(
        post.yaps,
        optimistic,
        parentYapId,
      );
      return post.copyWith(
        yaps: updatedYaps,
        yapCount: post.yapCount + 1,
      );
    }).toList();

    state = AsyncData(current.copyWith(posts: updatedPosts));
    return tempId;
  }

  /// Replaces the optimistic (pending) yap with the confirmed server yap.
  void confirmYap(String tempId, FeedYap serverYap) {
    final current = state.valueOrNull;
    if (current == null) return;

    final updatedPosts = current.posts.map((post) {
      if (post.id != serverYap.postId) return post;
      final updatedYaps = _replaceYapInTree(post.yaps, tempId, serverYap);
      return post.copyWith(yaps: updatedYaps);
    }).toList();

    state = AsyncData(current.copyWith(posts: updatedPosts));
  }

  /// Marks the optimistic yap as failed so the UI can show a retry.
  void failYap(String tempId, String postId) {
    final current = state.valueOrNull;
    if (current == null) return;

    final updatedPosts = current.posts.map((post) {
      if (post.id != postId) return post;
      final updatedYaps = _markYapFailed(post.yaps, tempId);
      return post.copyWith(
        yaps: updatedYaps,
        yapCount: (post.yapCount - 1).clamp(0, double.maxFinite.toInt()),
      );
    }).toList();

    state = AsyncData(current.copyWith(posts: updatedPosts));
  }

  // ---------------------------------------------------------------------------
  // Tree helpers
  // ---------------------------------------------------------------------------

  List<FeedYap> _insertYapIntoTree(
    List<FeedYap> yaps,
    FeedYap newYap,
    String? parentYapId,
  ) {
    if (parentYapId == null) {
      // Top-level yap — append at the end
      return [...yaps, newYap];
    }
    return yaps.map((yap) {
      if (yap.id == parentYapId) {
        return yap.copyWith(replies: [...yap.replies, newYap]);
      }
      if (yap.replies.isNotEmpty) {
        return yap.copyWith(
          replies: _insertYapIntoTree(yap.replies, newYap, parentYapId),
        );
      }
      return yap;
    }).toList();
  }

  List<FeedYap> _replaceYapInTree(
    List<FeedYap> yaps,
    String tempId,
    FeedYap serverYap,
  ) {
    return yaps.map((yap) {
      if (yap.id == tempId) return serverYap;
      if (yap.replies.isNotEmpty) {
        return yap.copyWith(
          replies: _replaceYapInTree(yap.replies, tempId, serverYap),
        );
      }
      return yap;
    }).toList();
  }

  List<FeedYap> _markYapFailed(List<FeedYap> yaps, String tempId) {
    return yaps.map((yap) {
      if (yap.id == tempId) return yap.copyWith(status: YapStatus.failed);
      if (yap.replies.isNotEmpty) {
        return yap.copyWith(replies: _markYapFailed(yap.replies, tempId));
      }
      return yap;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Delete operations
  // ---------------------------------------------------------------------------

  Future<bool> removePost(String postId) async {
    final current = state.valueOrNull;
    if (current == null) return false;

    // Call server FIRST, then remove optimistically on success
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return false;

      final response = await http.post(
        Uri.parse(AppConstants.deletePostEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
          'apikey': AppConstants.supabaseAnonKey,
        },
        body: jsonEncode({'postId': postId}),
      );

      if (response.statusCode != 200) return false;

      // Only remove from state after confirmed server success
      final latest = state.valueOrNull;
      if (latest != null) {
        state = AsyncData(latest.copyWith(
          posts: latest.posts.where((p) => p.id != postId).toList(),
        ));
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeYap(String yapId, String postId) async {
    final current = state.valueOrNull;
    if (current == null) return false;

    // Optimistic remove from tree
    final updatedPosts = current.posts.map((post) {
      if (post.id != postId) return post;
      final updatedYaps = _removeYapFromTree(post.yaps, yapId);
      final removedCount = _countYaps(post.yaps) - _countYaps(updatedYaps);
      return post.copyWith(
        yaps: updatedYaps,
        yapCount: (post.yapCount - removedCount).clamp(0, post.yapCount),
      );
    }).toList();

    state = AsyncData(current.copyWith(posts: updatedPosts));

    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) throw Exception('No session');

      final response = await http.post(
        Uri.parse(AppConstants.deleteYapEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
          'apikey': AppConstants.supabaseAnonKey,
        },
        body: jsonEncode({'yapId': yapId}),
      );

      if (response.statusCode != 200) {
        refresh();
        return false;
      }
      return true;
    } catch (e) {
      refresh();
      return false;
    }
  }

  List<FeedYap> _removeYapFromTree(List<FeedYap> yaps, String yapId) {
    return yaps
        .where((y) => y.id != yapId)
        .map((y) => y.copyWith(replies: _removeYapFromTree(y.replies, yapId)))
        .toList();
  }

  int _countYaps(List<FeedYap> yaps) {
    int count = 0;
    for (final y in yaps) {
      count += 1 + _countYaps(y.replies);
    }
    return count;
  }

  Future<void> _prefetchUrls(List<FeedPost> posts) async {
    final keys = <String>[];
    for (final post in posts) {
      if (post.media?.mediaType == 'image') {
        keys.add(post.media!.rawFileKey);
      }
    }
    if (keys.isNotEmpty) await _mediaService.getUrls(keys);
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------
final feedProvider =
    AsyncNotifierProvider<FeedNotifier, FeedState>(FeedNotifier.new);
