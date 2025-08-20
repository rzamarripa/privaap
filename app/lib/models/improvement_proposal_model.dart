import 'package:flutter/material.dart';

class ImprovementProposal {
  final String id;
  final String title;
  final String description;
  final String proposedBy;
  final String proposedByName;
  final DateTime createdAt;
  final ProposalStatus status;
  final ProposalPriority priority;
  final List<String> attachments;
  final List<ProposalVote> votes;
  final List<ProposalComment> comments;
  final double? estimatedCost;
  final String? adminResponse;
  final DateTime? adminResponseDate;

  ImprovementProposal({
    required this.id,
    required this.title,
    required this.description,
    required this.proposedBy,
    required this.proposedByName,
    required this.createdAt,
    this.status = ProposalStatus.pendiente,
    this.priority = ProposalPriority.media,
    this.attachments = const [],
    this.votes = const [],
    this.comments = const [],
    this.estimatedCost,
    this.adminResponse,
    this.adminResponseDate,
  });

  factory ImprovementProposal.fromJson(Map<String, dynamic> json) {
    // Handle submittedBy/proposedBy field which might be an object or string
    String proposedById = '';
    String proposedByName = '';
    
    if (json['submittedBy'] != null) {
      if (json['submittedBy'] is String) {
        proposedById = json['submittedBy'];
        proposedByName = 'Usuario';
      } else if (json['submittedBy'] is Map) {
        proposedById = json['submittedBy']['_id']?.toString() ?? '';
        proposedByName = json['submittedBy']['name'] ?? 'Usuario';
      }
    } else if (json['proposedBy'] != null) {
      if (json['proposedBy'] is String) {
        proposedById = json['proposedBy'];
        proposedByName = json['proposedByName'] ?? 'Usuario';
      } else if (json['proposedBy'] is Map) {
        proposedById = json['proposedBy']['_id']?.toString() ?? '';
        proposedByName = json['proposedBy']['name'] ?? 'Usuario';
      }
    } else {
      proposedById = json['proposedBy'] ?? '';
      proposedByName = json['proposedByName'] ?? 'Usuario';
    }
    
    return ImprovementProposal(
      id: json['id'] ?? json['_id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      proposedBy: proposedById,
      proposedByName: proposedByName,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      status: ProposalStatus.values.firstWhere(
        (e) => e.toString() == 'ProposalStatus.${json['status']}',
        orElse: () => ProposalStatus.pendiente,
      ),
      priority: ProposalPriority.values.firstWhere(
        (e) => e.toString() == 'ProposalPriority.${json['priority']}',
        orElse: () => ProposalPriority.media,
      ),
      attachments: List<String>.from(json['attachments'] ?? []),
      votes: (json['votes'] as List? ?? [])
          .map((e) => ProposalVote.fromJson(e))
          .toList(),
      comments: (json['comments'] as List? ?? [])
          .map((e) => ProposalComment.fromJson(e))
          .toList(),
      estimatedCost: json['estimatedCost']?.toDouble(),
      adminResponse: json['adminResponse'],
      adminResponseDate: json['adminResponseDate'] != null
          ? DateTime.parse(json['adminResponseDate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'proposedBy': proposedBy,
      'proposedByName': proposedByName,
      'createdAt': createdAt.toIso8601String(),
      'status': status.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'attachments': attachments,
      'votes': votes.map((e) => e.toJson()).toList(),
      'comments': comments.map((e) => e.toJson()).toList(),
      'estimatedCost': estimatedCost,
      'adminResponse': adminResponse,
      'adminResponseDate': adminResponseDate?.toIso8601String(),
    };
  }

  int get upvotes => votes.where((v) => v.isUpvote).length;
  int get downvotes => votes.where((v) => !v.isUpvote).length;
  int get score => upvotes - downvotes;

  bool hasUserVoted(String userId) {
    return votes.any((vote) => vote.userId == userId);
  }

  ProposalVote? getUserVote(String userId) {
    try {
      return votes.firstWhere((vote) => vote.userId == userId);
    } catch (_) {
      return null;
    }
  }
}

class ProposalVote {
  final String id;
  final String userId;
  final bool isUpvote;
  final DateTime votedAt;

  ProposalVote({
    required this.id,
    required this.userId,
    required this.isUpvote,
    required this.votedAt,
  });

  factory ProposalVote.fromJson(Map<String, dynamic> json) {
    return ProposalVote(
      id: json['id'],
      userId: json['userId'],
      isUpvote: json['isUpvote'],
      votedAt: DateTime.parse(json['votedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'isUpvote': isUpvote,
      'votedAt': votedAt.toIso8601String(),
    };
  }
}

class ProposalComment {
  final String id;
  final String userId;
  final String userName;
  final String content;
  final DateTime createdAt;

  ProposalComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
  });

  factory ProposalComment.fromJson(Map<String, dynamic> json) {
    return ProposalComment(
      id: json['id'],
      userId: json['userId'],
      userName: json['userName'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

enum ProposalStatus {
  pendiente,
  enRevision,
  aprobada,
  rechazada,
  enProgreso,
  completada,
}

enum ProposalPriority {
  baja,
  media,
  alta,
  urgente,
}

extension ProposalStatusExtension on ProposalStatus {
  String get displayName {
    switch (this) {
      case ProposalStatus.pendiente:
        return 'Pendiente';
      case ProposalStatus.enRevision:
        return 'En Revisión';
      case ProposalStatus.aprobada:
        return 'Aprobada';
      case ProposalStatus.rechazada:
        return 'Rechazada';
      case ProposalStatus.enProgreso:
        return 'En Progreso';
      case ProposalStatus.completada:
        return 'Completada';
    }
  }

  Color get color {
    switch (this) {
      case ProposalStatus.pendiente:
        return const Color(0xFF757575);
      case ProposalStatus.enRevision:
        return const Color(0xFF2196F3);
      case ProposalStatus.aprobada:
        return const Color(0xFF4CAF50);
      case ProposalStatus.rechazada:
        return const Color(0xFFF44336);
      case ProposalStatus.enProgreso:
        return const Color(0xFFFF9800);
      case ProposalStatus.completada:
        return const Color(0xFF00BCD4);
    }
  }
}

extension ProposalPriorityExtension on ProposalPriority {
  String get displayName {
    switch (this) {
      case ProposalPriority.baja:
        return 'Baja';
      case ProposalPriority.media:
        return 'Media';
      case ProposalPriority.alta:
        return 'Alta';
      case ProposalPriority.urgente:
        return 'Urgente';
    }
  }

  Color get color {
    switch (this) {
      case ProposalPriority.baja:
        return const Color(0xFF4CAF50);
      case ProposalPriority.media:
        return const Color(0xFF2196F3);
      case ProposalPriority.alta:
        return const Color(0xFFFF9800);
      case ProposalPriority.urgente:
        return const Color(0xFFF44336);
    }
  }
}
