class SupportTicket {
  final String? id;
  final String userName;
  final String userEmail;
  final String? userPhone;
  final String communityName;
  final String subject;
  final String category;
  final String description;
  final String? reproductionSteps;
  final List<String>? attachments;
  final String deviceType;
  final String appVersion;
  final DateTime createdAt;
  final String status;
  final String? assignedTo;
  final DateTime? updatedAt;
  final String? response;
  final DateTime? respondedAt;

  SupportTicket({
    this.id,
    required this.userName,
    required this.userEmail,
    this.userPhone,
    required this.communityName,
    required this.subject,
    required this.category,
    required this.description,
    this.reproductionSteps,
    this.attachments,
    required this.deviceType,
    required this.appVersion,
    required this.createdAt,
    this.status = 'pending',
    this.assignedTo,
    this.updatedAt,
    this.response,
    this.respondedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['_id'],
      userName: json['userName'],
      userEmail: json['userEmail'],
      userPhone: json['userPhone'],
      communityName: json['communityName'],
      subject: json['subject'],
      category: json['category'],
      description: json['description'],
      reproductionSteps: json['reproductionSteps'],
      attachments: json['attachments'] != null ? List<String>.from(json['attachments']) : null,
      deviceType: json['deviceType'],
      appVersion: json['appVersion'],
      createdAt: DateTime.parse(json['createdAt']),
      status: json['status'] ?? 'pending',
      assignedTo: json['assignedTo'],
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      response: json['response'],
      respondedAt: json['respondedAt'] != null ? DateTime.parse(json['respondedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'communityName': communityName,
      'subject': subject,
      'category': category,
      'description': description,
      'reproductionSteps': reproductionSteps,
      'attachments': attachments,
      'deviceType': deviceType,
      'appVersion': appVersion,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'assignedTo': assignedTo,
      'updatedAt': updatedAt?.toIso8601String(),
      'response': response,
      'respondedAt': respondedAt?.toIso8601String(),
    };
  }

  SupportTicket copyWith({
    String? id,
    String? userName,
    String? userEmail,
    String? userPhone,
    String? communityName,
    String? subject,
    String? category,
    String? description,
    String? reproductionSteps,
    List<String>? attachments,
    String? deviceType,
    String? appVersion,
    DateTime? createdAt,
    String? status,
    String? assignedTo,
    DateTime? updatedAt,
    String? response,
    DateTime? respondedAt,
  }) {
    return SupportTicket(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      communityName: communityName ?? this.communityName,
      subject: subject ?? this.subject,
      category: category ?? this.category,
      description: description ?? this.description,
      reproductionSteps: reproductionSteps ?? this.reproductionSteps,
      attachments: attachments ?? this.attachments,
      deviceType: deviceType ?? this.deviceType,
      appVersion: appVersion ?? this.appVersion,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      updatedAt: updatedAt ?? this.updatedAt,
      response: response ?? this.response,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}

enum SupportCategory {
  technical('Técnico', '🔧'),
  bug('Error/Bug', '🐛'),
  feature('Nueva Funcionalidad', '✨'),
  account('Cuenta/Acceso', '👤'),
  billing('Facturación', '💰'),
  other('Otro', '❓');

  const SupportCategory(this.label, this.icon);
  final String label;
  final String icon;
}
