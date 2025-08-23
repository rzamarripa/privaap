class Expense {
  final String id;
  final String title;
  final String description;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String createdBy;
  final String? communityId;
  final String? receipt;
  final ExpenseStatus status;
  final List<String> attachments;

  Expense({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.category,
    required this.date,
    required this.createdBy,
    this.communityId,
    this.receipt,
    this.status = ExpenseStatus.pendiente,
    this.attachments = const [],
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] ?? json['_id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      category: ExpenseCategory.values.firstWhere(
        (e) => e.toString() == 'ExpenseCategory.${json['category']}',
        orElse: () => ExpenseCategory.otros,
      ),
      date: json['date'] != null 
          ? DateTime.parse(json['date']) 
          : DateTime.now(),
      createdBy: json['createdBy'] is String 
          ? json['createdBy'] 
          : json['createdBy']?['_id']?.toString() ?? 'unknown',
      communityId: json['communityId']?.toString(),
      receipt: json['receipt'],
      status: ExpenseStatus.values.firstWhere(
        (e) => e.toString() == 'ExpenseStatus.${json['status']}',
        orElse: () => ExpenseStatus.pendiente,
      ),
      attachments: List<String>.from(json['attachments'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'amount': amount,
      'category': category.toString().split('.').last,
      'date': date.toIso8601String(),
      'createdBy': createdBy,
      'communityId': communityId,
      'receipt': receipt,
      'status': status.toString().split('.').last,
      'attachments': attachments,
    };
  }

  // For creating new expenses - doesn't include id or createdBy
  Map<String, dynamic> toCreateJson() {
    return {
      'title': title,
      'description': description,
      'amount': amount,
      'category': category.toString().split('.').last,
      'date': date.toIso8601String(),
      'receipt': receipt,
      'attachments': attachments,
    };
  }

  Expense copyWith({
    String? id,
    String? title,
    String? description,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    String? createdBy,
    String? communityId,
    String? receipt,
    ExpenseStatus? status,
    List<String>? attachments,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      createdBy: createdBy ?? this.createdBy,
      communityId: communityId ?? this.communityId,
      receipt: receipt ?? this.receipt,
      status: status ?? this.status,
      attachments: attachments ?? this.attachments,
    );
  }
}

enum ExpenseCategory {
  mantenimiento,
  seguridad,
  limpieza,
  servicios,
  mejoras,
  administrativos,
  otros,
}

enum ExpenseStatus {
  pendiente,
  aprobado,
  rechazado,
  pagado,
}

extension ExpenseCategoryExtension on ExpenseCategory {
  String get displayName {
    switch (this) {
      case ExpenseCategory.mantenimiento:
        return 'Mantenimiento';
      case ExpenseCategory.seguridad:
        return 'Seguridad';
      case ExpenseCategory.limpieza:
        return 'Limpieza';
      case ExpenseCategory.servicios:
        return 'Servicios';
      case ExpenseCategory.mejoras:
        return 'Mejoras';
      case ExpenseCategory.administrativos:
        return 'Administrativos';
      case ExpenseCategory.otros:
        return 'Otros';
    }
  }

  String get icon {
    switch (this) {
      case ExpenseCategory.mantenimiento:
        return '🔧';
      case ExpenseCategory.seguridad:
        return '🔒';
      case ExpenseCategory.limpieza:
        return '🧹';
      case ExpenseCategory.servicios:
        return '💡';
      case ExpenseCategory.mejoras:
        return '🏗️';
      case ExpenseCategory.administrativos:
        return '📋';
      case ExpenseCategory.otros:
        return '📦';
    }
  }
}
