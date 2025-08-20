class BlogPost {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> images;
  final BlogCategory category;
  final List<String> tags;
  final int likes;
  final List<String> likedBy;
  final List<BlogComment> comments;
  final bool isPinned;
  final int views;

  BlogPost({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.updatedAt,
    this.images = const [],
    required this.category,
    this.tags = const [],
    this.likes = 0,
    this.likedBy = const [],
    this.comments = const [],
    this.isPinned = false,
    this.views = 0,
  });

  factory BlogPost.fromJson(Map<String, dynamic> json) {
    // Handle author field which might be an ObjectId or object
    String authorId = '';
    String authorName = '';

    if (json['author'] != null) {
      if (json['author'] is String) {
        authorId = json['author'];
        authorName = 'Usuario';
      } else if (json['author'] is Map) {
        authorId = json['author']['_id']?.toString() ?? '';
        authorName = json['author']['name'] ?? 'Usuario';
      } else {
        // Handle ObjectId case (convert to string)
        authorId = json['author'].toString();
        authorName = 'Usuario';
      }
    } else {
      authorId = json['authorId'] ?? '';
      authorName = json['authorName'] ?? 'Usuario';
    }

    return BlogPost(
      id: json['id'] ?? json['_id']?.toString() ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      authorId: authorId,
      authorName: authorName,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      images: List<String>.from(json['images'] ?? []),
      category: BlogCategory.values.firstWhere(
        (e) => e.toString() == 'BlogCategory.${json['category']}',
        orElse: () => BlogCategory.general,
      ),
      tags: List<String>.from(json['tags'] ?? []),
      likes: json['likes'] is List ? (json['likes'] as List).length : (json['likes'] ?? 0),
      likedBy: json['likes'] is List ? List<String>.from(json['likes']) : [],
      comments: (json['comments'] as List? ?? []).map((commentJson) {
        // Crear un comentario con userName temporal, se actualizará después si es necesario
        final comment = commentJson as Map<String, dynamic>;
        return BlogComment.fromJson(comment);
      }).toList(),
      isPinned: json['isPinned'] ?? false,
      views: json['views'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'category': category.toString().split('.').last,
      'tags': tags,
      'isPublished': true,
      'isPinned': isPinned,
      'views': views,
    };
  }

  BlogPost copyWith({
    String? id,
    String? title,
    String? content,
    String? authorId,
    String? authorName,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? images,
    BlogCategory? category,
    List<String>? tags,
    int? likes,
    List<String>? likedBy,
    List<BlogComment>? comments,
    bool? isPinned,
    int? views,
  }) {
    return BlogPost(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      images: images ?? this.images,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
      comments: comments ?? this.comments,
      isPinned: isPinned ?? this.isPinned,
      views: views ?? this.views,
    );
  }
}

class BlogComment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String content;
  final DateTime createdAt;

  BlogComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
  });

  factory BlogComment.fromJson(Map<String, dynamic> json) {
    // Handle user field which might be an ObjectId
    String userId = '';
    if (json['user'] != null) {
      if (json['user'] is String) {
        userId = json['user'];
      } else {
        // Handle ObjectId case (convert to string)
        userId = json['user'].toString();
      }
    } else {
      userId = json['userId'] ?? '';
    }

    return BlogComment(
      id: json['_id'] ?? json['id'] ?? '',
      postId: json['postId'] ?? '',
      userId: userId,
      userName: 'Usuario', // Por ahora usamos un nombre genérico
      content: json['content'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  BlogComment copyWith({
    String? id,
    String? postId,
    String? userId,
    String? userName,
    String? content,
    DateTime? createdAt,
  }) {
    return BlogComment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum BlogCategory {
  anuncio,
  mantenimiento,
  evento,
  mejora,
  seguridad,
  general,
}

extension BlogCategoryExtension on BlogCategory {
  String get displayName {
    switch (this) {
      case BlogCategory.anuncio:
        return 'Anuncio';
      case BlogCategory.mantenimiento:
        return 'Mantenimiento';
      case BlogCategory.evento:
        return 'Evento';
      case BlogCategory.mejora:
        return 'Mejora';
      case BlogCategory.seguridad:
        return 'Seguridad';
      case BlogCategory.general:
        return 'General';
    }
  }

  String get icon {
    switch (this) {
      case BlogCategory.anuncio:
        return '📢';
      case BlogCategory.mantenimiento:
        return '🔧';
      case BlogCategory.evento:
        return '🎉';
      case BlogCategory.mejora:
        return '⭐';
      case BlogCategory.seguridad:
        return '🔒';
      case BlogCategory.general:
        return '📝';
    }
  }
}
