class Payment {
  final String id;
  final String monthlyFeeId;
  final double amount;
  final DateTime paidDate;
  final String paymentMethod; // efectivo, transferencia, cheque, tarjeta, otro
  final String? receiptNumber;
  final String? notes;
  final bool isCancelled;
  final DateTime? cancelledAt;
  final String? cancelledBy;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Payment({
    required this.id,
    required this.monthlyFeeId,
    required this.amount,
    required this.paidDate,
    required this.paymentMethod,
    this.receiptNumber,
    this.notes,
    this.isCancelled = false,
    this.cancelledAt,
    this.cancelledBy,
    this.cancellationReason,
    required this.createdAt,
    this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    // Helper function to extract user ID from populated or string field
    String? extractUserId(dynamic field) {
      if (field == null) return null;
      if (field is String) return field;
      if (field is Map<String, dynamic>) return field['_id'] as String?;
      return null;
    }

    return Payment(
      id: json['_id'] ?? json['id'] ?? '',
      monthlyFeeId: json['monthlyFeeId'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      paidDate: DateTime.parse(json['paidDate'] ?? DateTime.now().toIso8601String()),
      paymentMethod: json['paymentMethod'] ?? 'efectivo',
      receiptNumber: json['receiptNumber'],
      notes: json['notes'],
      isCancelled: json['isCancelled'] ?? false,
      cancelledAt: json['cancelledAt'] != null ? DateTime.parse(json['cancelledAt']) : null,
      cancelledBy: extractUserId(json['cancelledBy']),
      cancellationReason: json['cancellationReason'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'monthlyFeeId': monthlyFeeId,
      'amount': amount,
      'paidDate': paidDate.toIso8601String(),
      'paymentMethod': paymentMethod,
      'receiptNumber': receiptNumber,
      'notes': notes,
      'isCancelled': isCancelled,
      'cancelledAt': cancelledAt?.toIso8601String(),
      'cancelledBy': cancelledBy,
      'cancellationReason': cancellationReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Payment copyWith({
    String? id,
    String? monthlyFeeId,
    double? amount,
    DateTime? paidDate,
    String? paymentMethod,
    String? receiptNumber,
    String? notes,
    bool? isCancelled,
    DateTime? cancelledAt,
    String? cancelledBy,
    String? cancellationReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      monthlyFeeId: monthlyFeeId ?? this.monthlyFeeId,
      amount: amount ?? this.amount,
      paidDate: paidDate ?? this.paidDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      notes: notes ?? this.notes,
      isCancelled: isCancelled ?? this.isCancelled,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Getters útiles
  bool get isActive => !isCancelled;
  String get statusText => isCancelled ? 'Cancelado' : 'Activo';
}