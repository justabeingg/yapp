// =============================================================================
// DUMMY UI REFERENCE — DO NOT USE IN PRODUCTION
// This is the original dummy/mock feed screen with hardcoded data.
// Kept as a visual reference for the intended UI design.
// The real implementation is in feed_screen.dart
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

Map<String, dynamic> _yap(dynamic raw) =>
    Map<String, dynamic>.from(raw as Map);
List<Map<String, dynamic>> _replies(dynamic raw) {
  if (raw == null) return [];
  return (raw as List)
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
}

final _dummyPosts = [
  {
    'username': 'silent_gecko',
    'avatar_emoji': '🦊',
    'avatar_color': AppColors.primary,
    'time': '2m ago',
    'category': '🔥 Trending',
    'type': 'image',
    'image_url': 'https://picsum.photos/seed/yapp1/600/400',
    'content':
        'Bro they just replaced 200 software engineers with one AI model and called it "operational efficiency" 💀',
    'yap_count': 48,
    'yaps': [
      {
        'id': '1',
        'username': 'chaos_muffin',
        'emoji': '👾',
        'color': Color(0xFF7C4DFF),
        'duration': '0:12',
        'total_seconds': 12,
        'replies': [
          {
            'id': '1a',
            'username': 'neon_possum',
            'emoji': '🐺',
            'color': Color(0xFF00B4D8),
            'duration': '0:08',
            'total_seconds': 8,
            'replies': [
              {
                'id': '1a1',
                'username': 'void_panda',
                'emoji': '🔥',
                'color': Color(0xFFFF9800),
                'duration': '0:05',
                'total_seconds': 5,
                'replies': [],
              },
            ],
          },
          {
            'id': '1b',
            'username': 'ghost_taco',
            'emoji': '👻',
            'color': Color(0xFF00E676),
            'duration': '0:06',
            'total_seconds': 6,
            'replies': [],
          },
        ],
      },
      {
        'id': '2',
        'username': 'neon_possum',
        'emoji': '🐺',
        'color': Color(0xFF00B4D8),
        'duration': '0:08',
        'total_seconds': 8,
        'replies': [
          {
            'id': '2a',
            'username': 'rogue_pretzel',
            'emoji': '🗿',
            'color': Color(0xFFFFD60A),
            'duration': '0:15',
            'total_seconds': 15,
            'replies': [],
          },
        ],
      },
      {
        'id': '3',
        'username': 'void_panda',
        'emoji': '🔥',
        'color': Color(0xFFFF9800),
        'duration': '0:22',
        'total_seconds': 22,
        'replies': [],
      },
    ],
  },
  {
    'username': 'cosmic_pickle',
    'avatar_emoji': '🐲',
    'avatar_color': Color(0xFF00B4D8),
    'time': '15m ago',
    'category': '😂 Meme',
    'type': 'text',
    'image_url': null,
    'content':
        'My sleep schedule has entered its villain arc and I am not stopping it',
    'yap_count': 124,
    'yaps': [
      {
        'id': '4',
        'username': 'turbo_biscuit',
        'emoji': '💀',
        'color': Color(0xFFFF3C5F),
        'duration': '0:05',
        'total_seconds': 5,
        'replies': [
          {
            'id': '4a',
            'username': 'wild_noodle',
            'emoji': '🎭',
            'color': Color(0xFF7C4DFF),
            'duration': '0:11',
            'total_seconds': 11,
            'replies': [
              {
                'id': '4a1',
                'username': 'turbo_biscuit',
                'emoji': '💀',
                'color': Color(0xFFFF3C5F),
                'duration': '0:07',
                'total_seconds': 7,
                'replies': [],
              },
            ],
          },
        ],
      },
      {
        'id': '5',
        'username': 'blaze_penguin',
        'emoji': '⚡',
        'color': Color(0xFFFF9800),
        'duration': '0:18',
        'total_seconds': 18,
        'replies': [],
      },
    ],
  },
  {
    'username': 'ghost_taco',
    'avatar_emoji': '👻',
    'avatar_color': Color(0xFF00E676),
    'time': '1h ago',
    'category': '🌍 News',
    'type': 'image',
    'image_url': 'https://picsum.photos/seed/yapp3/600/400',
    'content':
        'The new iPhone costs more than my first car. We have collectively lost our minds as a society.',
    'yap_count': 312,
    'yaps': [
      {
        'id': '6',
        'username': 'rogue_pretzel',
        'emoji': '🗿',
        'color': Color(0xFFFFD60A),
        'duration': '0:30',
        'total_seconds': 30,
        'replies': [],
      },
      {
        'id': '7',
        'username': 'blaze_penguin',
        'emoji': '⚡',
        'color': Color(0xFFFF9800),
        'duration': '0:11',
        'total_seconds': 11,
        'replies': [
          {
            'id': '7a',
            'username': 'static_llama',
            'emoji': '🤖',
            'color': Color(0xFF00B4D8),
            'duration': '0:20',
            'total_seconds': 20,
            'replies': [],
          },
        ],
      },
      {
        'id': '8',
        'username': 'static_llama',
        'emoji': '🤖',
        'color': Color(0xFF00B4D8),
        'duration': '0:25',
        'total_seconds': 25,
        'replies': [],
      },
    ],
  },
];

class FeedScreenDummy extends StatelessWidget {
  const FeedScreenDummy({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('yapp',
            style: AppTextStyles.displayMedium
                .copyWith(color: AppColors.primary, letterSpacing: -2)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded,
                color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: _dummyPosts.length,
        separatorBuilder: (_, __) => const Gap(8),
        itemBuilder: (context, i) =>
            _PostCard(post: Map<String, dynamic>.from(_dummyPosts[i])),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final yaps = (post['yaps'] as List).map((e) => _yap(e)).toList();
    final previewYaps = yaps.take(3).toList();
    final imageUrl = post['image_url'] as String?;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                _Avatar(
                    emoji: post['avatar_emoji'] as String,
                    color: post['avatar_color'] as Color,
                    size: 36,
                    fontSize: 18),
                const Gap(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('@${post['username']}',
                          style: AppTextStyles.username),
                      Text(post['time'] as String,
                          style: AppTextStyles.labelSmall),
                    ],
                  ),
                ),
                _CategoryTag(label: post['category'] as String),
              ],
            ),
          ),
          if (imageUrl != null)
            Image.network(
              imageUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: 200,
                  color: AppColors.surfaceElevated,
                  child: const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2),
                  ),
                );
              },
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                14, imageUrl != null ? 10 : 0, 14, 14),
            child: Text(post['content'] as String,
                style: AppTextStyles.bodyLarge),
          ),
          Container(height: 1, color: AppColors.border),
          GestureDetector(
            onTap: () => _openYapChain(context, post, yaps),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              child: Row(
                children: [
                  const Icon(Icons.mic_rounded,
                      color: AppColors.primary, size: 14),
                  const Gap(6),
                  Text('${post['yap_count']} Yaps',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.primary)),
                  const Spacer(),
                  Text('See all →',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              children: previewYaps
                  .map((yap) => _YapBubble(
                        yap: yap,
                        onTap: () => _openYapChain(context, post, yaps),
                      ))
                  .toList(),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border))),
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.mic_none_rounded,
                  color: AppColors.textMuted, size: 18),
              label: Text('Yapp your reaction',
                  style: AppTextStyles.bodyMedium),
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12)),
            ),
          ),
        ],
      ),
    );
  }

  void _openYapChain(BuildContext context, Map<String, dynamic> post,
      List<Map<String, dynamic>> yaps) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _YapChainSheet(post: post, yaps: yaps),
    );
  }
}

class _YapChainSheet extends StatelessWidget {
  final Map<String, dynamic> post;
  final List<Map<String, dynamic>> yaps;
  const _YapChainSheet({required this.post, required this.yaps});

  @override
  Widget build(BuildContext context) {
    final imageUrl = post['image_url'] as String?;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.92,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2)),
          ),
          const Gap(4),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Gap(12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            _Avatar(
                                emoji: post['avatar_emoji'] as String,
                                color: post['avatar_color'] as Color,
                                size: 34,
                                fontSize: 17),
                            const Gap(10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('@${post['username']}',
                                    style: AppTextStyles.username),
                                Text(post['time'] as String,
                                    style: AppTextStyles.labelSmall),
                              ],
                            ),
                            const Spacer(),
                            _CategoryTag(label: post['category'] as String),
                          ],
                        ),
                      ),
                      const Gap(10),
                      if (imageUrl != null)
                        Image.network(imageUrl,
                            width: double.infinity, fit: BoxFit.cover),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                            16, imageUrl != null ? 12 : 0, 16, 16),
                        child: Text(post['content'] as String,
                            style: AppTextStyles.bodyLarge),
                      ),
                      Container(
                        color: AppColors.background,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.mic_rounded,
                                color: AppColors.primary, size: 16),
                            const Gap(8),
                            Text('${post['yap_count']} Yaps',
                                style: AppTextStyles.headlineMedium),
                          ],
                        ),
                      ),
                      Container(height: 1, color: AppColors.border),
                      const Gap(12),
                    ],
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _YapChainItem(yap: yaps[i], depth: 0),
                    ),
                    childCount: yaps.length,
                  ),
                ),
                const SliverToBoxAdapter(child: Gap(100)),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border))),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.mic_rounded, size: 18),
                label: const Text('Yapp your reaction'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _YapChainItem extends StatefulWidget {
  final Map<String, dynamic> yap;
  final int depth;
  const _YapChainItem({required this.yap, required this.depth});

  @override
  State<_YapChainItem> createState() => _YapChainItemState();
}

class _YapChainItemState extends State<_YapChainItem>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  bool _playing = false;
  double _seekPosition = 0.0;
  late AnimationController _playController;

  @override
  void initState() {
    super.initState();
    final total = widget.yap['total_seconds'] as int? ?? 10;
    _playController = AnimationController(
      vsync: this,
      duration: Duration(seconds: total),
    )
      ..addListener(() {
        if (mounted) setState(() => _seekPosition = _playController.value);
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _playing = false;
            _seekPosition = 0.0;
          });
          _playController.reset();
        }
      });
  }

  @override
  void dispose() {
    _playController.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() => _playing = !_playing);
    if (_playing) {
      _playController.forward(from: _seekPosition);
    } else {
      _playController.stop();
    }
  }

  String _formatTime(double position, int totalSeconds) {
    final current = (position * totalSeconds).round();
    final m = current ~/ 60;
    final s = current % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final replies = _replies(widget.yap['replies']);
    final hasReplies = replies.isNotEmpty;
    final color = widget.yap['color'] as Color;
    final totalSeconds = widget.yap['total_seconds'] as int? ?? 10;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.depth > 0)
            Row(
              children: [
                SizedBox(width: (widget.depth - 1) * 20.0),
                Container(
                  width: 2,
                  margin: const EdgeInsets.only(right: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: widget.depth == 0
                        ? AppColors.surfaceElevated
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        child: Row(
                          children: [
                            _Avatar(
                                emoji: widget.yap['emoji'] as String,
                                color: color,
                                size: 30,
                                fontSize: 15),
                            const Gap(10),
                            Expanded(
                              child: Text('@${widget.yap['username']}',
                                  style: AppTextStyles.labelLarge),
                            ),
                            GestureDetector(
                              onTap: _togglePlay,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: _playing
                                      ? AppColors.primary
                                      : AppColors.primaryGlow,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.primary, width: 1),
                                ),
                                child: Icon(
                                  _playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: _playing
                                      ? Colors.white
                                      : AppColors.primary,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6),
                                overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 12),
                                activeTrackColor: AppColors.primary,
                                inactiveTrackColor: AppColors.border,
                                thumbColor: AppColors.primary,
                                overlayColor: AppColors.primaryGlow,
                              ),
                              child: Slider(
                                value: _seekPosition,
                                onChanged: (val) {
                                  setState(() => _seekPosition = val);
                                  if (_playing) {
                                    _playController.forward(from: val);
                                  }
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatTime(_seekPosition, totalSeconds),
                                    style: AppTextStyles.labelSmall,
                                  ),
                                  Text(widget.yap['duration'] as String,
                                      style: AppTextStyles.labelSmall),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                            border: Border(
                                top: BorderSide(color: AppColors.border))),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: Row(
                          children: [
                            TextButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.reply_rounded,
                                  size: 13, color: AppColors.textMuted),
                              label: Text('Reply',
                                  style: AppTextStyles.labelSmall),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            if (hasReplies) ...[
                              const Gap(8),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _expanded = !_expanded),
                                child: Row(
                                  children: [
                                    Icon(
                                      _expanded
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      size: 14,
                                      color: AppColors.accent,
                                    ),
                                    const Gap(2),
                                    Text(
                                      '${replies.length} ${replies.length == 1 ? 'reply' : 'replies'}',
                                      style: AppTextStyles.labelSmall
                                          .copyWith(color: AppColors.accent),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_expanded)
                  ...replies.map((reply) =>
                      _YapChainItem(yap: reply, depth: widget.depth + 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _YapBubble extends StatelessWidget {
  final Map<String, dynamic> yap;
  final VoidCallback onTap;
  const _YapBubble({required this.yap, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final replies = _replies(yap['replies']);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _Avatar(
                emoji: yap['emoji'] as String,
                color: yap['color'] as Color,
                size: 28,
                fontSize: 14),
            const Gap(10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('@${yap['username']}', style: AppTextStyles.labelLarge),
                  Row(
                    children: [
                      Text(yap['duration'] as String,
                          style: AppTextStyles.labelSmall),
                      if (replies.isNotEmpty) ...[
                        const Gap(6),
                        Text(
                          '· ${replies.length} ${replies.length == 1 ? 'reply' : 'replies'}',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.accent),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryGlow,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 1),
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: AppColors.primary, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String emoji;
  final Color color;
  final double size;
  final double fontSize;
  const _Avatar(
      {required this.emoji,
      required this.color,
      required this.size,
      required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Center(child: Text(emoji, style: TextStyle(fontSize: fontSize))),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  final String label;
  const _CategoryTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label, style: AppTextStyles.labelSmall),
    );
  }
}
