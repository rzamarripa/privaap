enum MonthlyFeeStatus { pendiente, abonado, pagado, vencido, parcial, exento }

class MonthlyFee {
  final String id;
  final String communityId; // ID de la privada
  final String houseId; // ID de la casa/propiedad
  final String month; // Mes en formato YYYY-MM
  final double amount; // Monto de la mensualidad
  final double amountPaid; // Monto pagado
  final MonthlyFeeStatus status;
  final DateTime dueDate; // Fecha de vencimiento
  final DateTime? paidDate; // Fecha de pago
  final String? paymentMethod; // Método de pago
  final String? receiptNumber; // Número de recibo
  final String? notes; // Notas adicionales
  final DateTime createdAt;
  final DateTime? updatedAt;

  MonthlyFee({
    required this.id,
    required this.communityId,
    required this.houseId,
    required this.month,
    required this.amount,
    required this.amountPaid,
    required this.status,
    required this.dueDate,
    this.paidDate,
    this.paymentMethod,
    this.receiptNumber,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory MonthlyFee.fromJson(Map<String, dynamic> json) {
    // Manejar houseId - priorizar houseId del backend, sino usar userId
    String houseId = '';
    if (json['houseId'] != null) {
      // Si viene del backend con houseId expandido
      if (json['houseId'] is Map) {
        houseId = json['houseId']['_id'] ?? json['houseId']['id'] ?? '';
      } else {
        houseId = json['houseId'] ?? '';
      }
    } else if (json['userId'] != null) {
      // Fallback: usar userId si no hay houseId
      if (json['userId'] is Map) {
        houseId = json['userId']['_id'] ?? json['userId']['id'] ?? '';
      } else {
        houseId = json['userId'] ?? '';
      }
    }
    
    String communityId = '';
    if (json['communityId'] != null) {
      // Si viene del backend con communityId expandido
      if (json['communityId'] is Map) {
        communityId = json['communityId']['_id'] ?? json['communityId']['id'] ?? '';
      } else {
        communityId = json['communityId'] ?? '';
      }
    }
    
    return MonthlyFee(
      id: json['_id'] ?? json['id'] ?? '',
      communityId: communityId,
      houseId: houseId, // Usar houseId del backend
      month: json['month'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      amountPaid: (json['amountPaid'] ?? 0.0).toDouble(),
      status: MonthlyFeeStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => MonthlyFeeStatus.pendiente,
      ),
      dueDate: DateTime.parse(json['dueDate'] ?? DateTime.now().toIso8601String()),
      paidDate: json['paidDate'] != null ? DateTime.parse(json['paidDate']) : null,
      paymentMethod: json['paymentMethod'],
      receiptNumber: json['receiptNumber'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'communityId': communityId,
      'houseId': houseId,
      'month': month,
      'amount': amount,
      'amountPaid': amountPaid,
      'status': status.toString().split('.').last,
      'dueDate': dueDate.toIso8601String(),
      'paidDate': paidDate?.toIso8601String(),
      'paymentMethod': paymentMethod,
      'receiptNumber': receiptNumber,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  MonthlyFee copyWith({
    String? id,
    String? communityId,
    String? houseId,
    String? month,
    double? amount,
    double? amountPaid,
    MonthlyFeeStatus? status,
    DateTime? dueDate,
    DateTime? paidDate,
    String? paymentMethod,
    String? receiptNumber,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MonthlyFee(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      houseId: houseId ?? this.houseId,
      month: month ?? this.month,
      amount: amount ?? this.amount,
      amountPaid: amountPaid ?? this.amountPaid,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Getters útiles
  double get remainingAmount => amount - amountPaid;
  bool get isFullyPaid => amountPaid >= amount;
  bool get isOverdue => DateTime.now().isAfter(dueDate) && !isFullyPaid;
  bool get isPartialPayment => amountPaid > 0 && amountPaid < amount;

  // Nota: Este modelo ahora maneja mensualidades por CASA en lugar de por USUARIO
  // Esto permite:
  // - Historial completo por propiedad
  // - Cambios de inquilinos sin perder historial
  // - Múltiples usuarios por casa
  // - Auditoría clara por propiedad
}
