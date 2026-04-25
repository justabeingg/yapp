class Post {
  final String id;
  final String userId;
  final String contentType;
  final String? textContent;
  final String? mediaFileId;
  final String? thumbnailFileKey;
  final int yapCount;
  final int viewCount;
  final double hotnessScore;
  final bool isFlagged;
  final bool isRemoved;
  final DateTime createdAt;
  final DateTime updatedAt;

  Post({
    required this.id,
    required this.userId,
    required this.contentType,
    this.textContent,
    this.mediaFileId,
    this.thumbnailFileKey,
    required this.yapCount,
    required this.viewCount,
    required this.hotnessScore,
    required this.isFlagged,
    required this.isRemoved,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      contentType: json['content_type'] as String,
      textContent: json['text_content'] as String?,
      mediaFileId: json['media_file_id'] as String?,
      thumbnailFileKey: json['thumbnail_file_key'] as String?,
      yapCount: json['yap_count'] as int,
      viewCount: json['view_count'] as int,
      hotnessScore: (json['hotness_score'] as num).toDouble(),
      isFlagged: json['is_flagged'] as bool,
      isRemoved: json['is_removed'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
