enum UserRole {
  superAdmin, // Super administrador (puede crear privadas)
  administrador, // Administrador de una privada específica
  residente, // Usuario normal/inquilino
}

class User {
  final String id;
  final String phoneNumber;
  final String name;
  final String email;
  final UserRole role;
  final String? profileImage;
  final String? communityId; // ID de la privada a la que pertenece
  final String? house; // Número de casa/habitación
  final DateTime createdAt;
  final bool isActive;
  final DateTime? lastLogin; // Último login del usuario
  final DateTime? updatedAt; // Última actualización del usuario

  User({
    required this.id,
    required this.phoneNumber,
    required this.name,
    required this.email,
    required this.role,
    this.profileImage,
    this.communityId,
    this.house,
    required this.createdAt,
    this.isActive = true,
    this.lastLogin,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'], // Usar _id primero, luego id como fallback
      phoneNumber: json['phoneNumber'].toString(),
      name: json['name'],
      email: json['email'],
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
        orElse: () => UserRole.residente,
      ),
      profileImage: json['profileImage'],
      communityId: json['communityId'],
      house: json['house'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      isActive: json['isActive'] ?? true,
      lastLogin: json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'name': name,
      'email': email,
      'role': role.toString().split('.').last,
      'profileImage': profileImage,
      'communityId': communityId,
      'house': house,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'lastLogin': lastLogin?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? phoneNumber,
    String? name,
    String? email,
    UserRole? role,
    String? profileImage,
    String? communityId,
    String? house,
    DateTime? createdAt,
    bool? isActive,
    DateTime? lastLogin,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      profileImage: profileImage ?? this.profileImage,
      communityId: communityId ?? this.communityId,
      house: house ?? this.house,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      lastLogin: lastLogin ?? this.lastLogin,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Getters útiles
  bool get isSuperAdmin => role == UserRole.superAdmin;
  bool get isAdmin => role == UserRole.administrador;
  bool get isResident => role == UserRole.residente;
  bool get hasCommunity => communityId != null && communityId!.isNotEmpty;
}
