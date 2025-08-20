class Survey {
  final String id;
  final String question;
  final List<SurveyOption> options;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String createdBy;
  final bool allowMultipleAnswers;
  final bool isAnonymous;
  final List<SurveyVote> votes;
  final bool isActive;

  Survey({
    required this.id,
    required this.question,
    required this.options,
    required this.createdAt,
    this.expiresAt,
    required this.createdBy,
    this.allowMultipleAnswers = false,
    this.isAnonymous = false,
    this.votes = const [],
    this.isActive = true,
  });

  factory Survey.fromJson(Map<String, dynamic> json) {
    return Survey(
      id: json['id'] ?? json['_id']?.toString() ?? '',
      question: json['question'] ?? '',
      options: (json['options'] as List? ?? []).map((e) => SurveyOption.fromJson(e)).toList(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      createdBy: json['createdBy'] is String ? json['createdBy'] : json['createdBy']?['_id']?.toString() ?? 'unknown',
      allowMultipleAnswers: json['allowMultipleAnswers'] ?? false,
      isAnonymous: json['isAnonymous'] ?? false,
      votes: (json['votes'] as List? ?? []).map((e) => SurveyVote.fromJson(e)).toList(),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'createdBy': createdBy,
      'allowMultipleAnswers': allowMultipleAnswers,
      'isAnonymous': isAnonymous,
      'votes': votes.map((e) => e.toJson()).toList(),
      'isActive': isActive,
    };
  }

  // For creating new surveys - doesn't include id, createdAt, votes, or createdBy
  Map<String, dynamic> toCreateJson() {
    return {
      'question': question,
      'options': options.map((e) => e.toCreateJson()).toList(),
      'expiresAt': expiresAt?.toIso8601String(),
      'allowMultipleAnswers': allowMultipleAnswers,
      'isAnonymous': isAnonymous,
    };
  }

  // For updating existing surveys - includes id and preserves existing data
  Map<String, dynamic> toUpdateJson() {
    return {
      'question': question,
      'options': options.map((e) => e.toUpdateJson()).toList(),
      'expiresAt': expiresAt?.toIso8601String(),
      'allowMultipleAnswers': allowMultipleAnswers,
      'isAnonymous': isAnonymous,
    };
  }

  int getTotalVotes() {
    return votes.length;
  }

  Map<String, int> getVotesByOption() {
    final voteCount = <String, int>{};
    for (var option in options) {
      voteCount[option.id] = votes.where((vote) => vote.selectedOptions.contains(option.id)).length;
    }
    return voteCount;
  }

  double getOptionPercentage(String optionId) {
    final total = getTotalVotes();
    if (total == 0) return 0;
    final optionVotes = votes.where((vote) => vote.selectedOptions.contains(optionId)).length;
    return (optionVotes / total) * 100;
  }

  bool hasUserVoted(String userId) {
    return votes.any((vote) => vote.userId == userId);
  }
}

class SurveyOption {
  final String id;
  final String text;
  final String? emoji;

  SurveyOption({
    required this.id,
    required this.text,
    this.emoji,
  });

  factory SurveyOption.fromJson(Map<String, dynamic> json) {
    return SurveyOption(
      id: json['id'] ?? json['_id']?.toString(),
      text: json['text'],
      emoji: json['emoji'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'emoji': emoji,
    };
  }

  // For creating new options - doesn't include id
  Map<String, dynamic> toCreateJson() {
    return {
      'text': text,
      'emoji': emoji,
    };
  }

  // For updating existing options - includes id and preserves existing data
  Map<String, dynamic> toUpdateJson() {
    return {
      'id': id, // Incluir el ID para la actualización
      'text': text,
      'emoji': emoji,
    };
  }
}

class SurveyVote {
  final String id;
  final String userId;
  final List<String> selectedOptions;
  final DateTime votedAt;

  SurveyVote({
    required this.id,
    required this.userId,
    required this.selectedOptions,
    required this.votedAt,
  });

  factory SurveyVote.fromJson(Map<String, dynamic> json) {
    return SurveyVote(
      id: json['id'] ?? json['_id']?.toString(),
      userId: json['userId'] ?? json['user']?.toString(),
      selectedOptions: List<String>.from(json['selectedOptions'] ?? []),
      votedAt: DateTime.parse(json['votedAt'] ?? json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'selectedOptions': selectedOptions,
      'votedAt': votedAt.toIso8601String(),
    };
  }
}
