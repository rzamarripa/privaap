class Community {
  final String id;
  final String name;
  final String address;
  final String description;
  final double monthlyFee; // Mensualidad base
  final String currency; // Moneda (MXN, USD, etc.)
  final int totalHouses; // Total de casas/habitaciones
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final Map<String, dynamic> settings; // Configuraciones específicas
  final List<String> adminIds; // IDs de administradores
  final String superAdminId; // ID del super administrador

  Community({
    required this.id,
    required this.name,
    required this.address,
    required this.description,
    required this.monthlyFee,
    required this.currency,
    required this.totalHouses,
    required this.createdAt,
    this.updatedAt,
    required this.isActive,
    required this.settings,
    required this.adminIds,
    required this.superAdminId,
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['_id'] ?? json['id'] ?? '', // MongoDB usa _id, pero también acepta id
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      description: json['description'] ?? '',
      monthlyFee: (json['monthlyFee'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'MXN',
      totalHouses: json['totalHouses'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'].toString()) : null,
      isActive: json['isActive'] ?? true,
      settings: json['settings'] is Map<String, dynamic> ? json['settings'] : {},
      adminIds: json['adminIds'] is List ? List<String>.from(json['adminIds'].map((id) => id.toString())) : [],
      superAdminId: json['superAdminId']?["_id"]?.toString() ?? json['superAdminId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'description': description,
      'monthlyFee': monthlyFee,
      'currency': currency,
      'totalHouses': totalHouses,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
      'settings': settings,
      'adminIds': adminIds,
      'superAdminId': superAdminId,
    };
  }

  Community copyWith({
    String? id,
    String? name,
    String? address,
    String? description,
    double? monthlyFee,
    String? currency,
    int? totalHouses,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    Map<String, dynamic>? settings,
    List<String>? adminIds,
    String? superAdminId,
  }) {
    return Community(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      description: description ?? this.description,
      monthlyFee: monthlyFee ?? this.monthlyFee,
      currency: currency ?? this.currency,
      totalHouses: totalHouses ?? this.totalHouses,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      settings: settings ?? this.settings,
      adminIds: adminIds ?? this.adminIds,
      superAdminId: superAdminId ?? this.superAdminId,
    );
  }

  @override
  String toString() {
    return 'Community(id: $id, name: $name, address: $address, totalHouses: $totalHouses, isActive: $isActive)';
  }
}
