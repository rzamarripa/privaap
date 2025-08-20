class House {
  final String id;
  final String communityId; // ID de la comunidad/privada
  final String houseNumber; // Número de casa (ej: "A1", "B5", "15")
  final String? description; // Descripción opcional (ej: "Casa principal", "Casa de invitados")
  final double monthlyFee; // Monto fijo de la mensualidad
  final String? currentUserId; // ID del usuario actual (inquilino)
  final String? currentUserName; // Nombre del inquilino actual
  final bool isActive; // Si la casa está activa
  final DateTime createdAt;
  final DateTime? updatedAt;

  House({
    required this.id,
    required this.communityId,
    required this.houseNumber,
    this.description,
    required this.monthlyFee,
    this.currentUserId,
    this.currentUserName,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory House.fromJson(Map<String, dynamic> json) {
    return House(
      id: json['_id'] ?? json['id'] ?? '',
      communityId: json['communityId'] ?? '',
      houseNumber: json['houseNumber'] ?? '',
      description: json['description'],
      monthlyFee: (json['monthlyFee'] ?? 0.0).toDouble(),
      currentUserId: json['currentUserId'],
      currentUserName: json['currentUserName'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'communityId': communityId,
      'houseNumber': houseNumber,
      'description': description,
      'monthlyFee': monthlyFee,
      'currentUserId': currentUserId,
      'currentUserName': currentUserName,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  House copyWith({
    String? id,
    String? communityId,
    String? houseNumber,
    String? description,
    double? monthlyFee,
    String? currentUserId,
    String? currentUserName,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return House(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      houseNumber: houseNumber ?? this.houseNumber,
      description: description ?? this.description,
      monthlyFee: monthlyFee ?? this.monthlyFee,
      currentUserId: currentUserId ?? this.currentUserId,
      currentUserName: currentUserName ?? this.currentUserName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Getters útiles
  String get displayName => description != null ? '$houseNumber - $description' : houseNumber;
  bool get hasCurrentUser => currentUserId != null && currentUserId!.isNotEmpty;
  String get statusText => isActive ? 'Activa' : 'Inactiva';
}
