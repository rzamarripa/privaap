import 'package:flutter/foundation.dart';
import '../../models/monthly_fee_model.dart';
import '../../models/community_model.dart';
import 'api_service.dart';

class MonthlyFeeService extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<MonthlyFee> _monthlyFees = [];
  List<Community> _communities = [];
  bool _isLoading = false;

  // Getters
  List<MonthlyFee> get monthlyFees => _monthlyFees;
  List<Community> get communities => _communities;
  bool get isLoading => _isLoading;

  // Mensualidades por estado
  List<MonthlyFee> get pendingFees => _monthlyFees.where((fee) => fee.status == MonthlyFeeStatus.pendiente).toList();
  List<MonthlyFee> get paidFees => _monthlyFees.where((fee) => fee.status == MonthlyFeeStatus.pagado).toList();
  List<MonthlyFee> get overdueFees => _monthlyFees.where((fee) => fee.isOverdue).toList();
  List<MonthlyFee> get partialFees => _monthlyFees.where((fee) => fee.status == MonthlyFeeStatus.parcial).toList();

  // Totales
  double get totalPendingAmount => pendingFees.fold(0, (sum, fee) => sum + fee.remainingAmount);
  double get totalPaidAmount => paidFees.fold(0, (sum, fee) => sum + fee.amountPaid);
  double get totalOverdueAmount => overdueFees.fold(0, (sum, fee) => sum + fee.remainingAmount);

  // Cargar mensualidades
  Future<void> loadMonthlyFees({String? communityId, String? userId}) async {
    _isLoading = true;
    try {
      Map<String, String> queryParams = {};
      if (communityId != null) queryParams['communityId'] = communityId;
      if (userId != null) queryParams['userId'] = userId;

      final response = await _apiService.get('/monthly-fees', queryParams: queryParams);

      if (response.isSuccess && response.data != null) {
        // response.data is already the extracted data from ApiService
        final responseData = response.data as Map<String, dynamic>;
        if (responseData['monthlyFees'] != null) {
          final List<dynamic> monthlyFeesData = responseData['monthlyFees'] as List<dynamic>;
          _monthlyFees = monthlyFeesData.map((json) => MonthlyFee.fromJson(json)).toList();
        }
      }
    } catch (e) {
      print('Error loading monthly fees: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cargar comunidades
  Future<void> loadCommunities() async {
    try {
      final response = await _apiService.get<dynamic>('/communities');

      if (response.success) {
        _communities = (response.data as List).map((json) => Community.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error loading communities: $e');
    } finally {
      notifyListeners();
    }
  }

  // Crear nueva mensualidad
  Future<Map<String, dynamic>> createMonthlyFee(MonthlyFee monthlyFee) async {
    try {
      // Crear el body manualmente para asegurar que userId y houseId se envían correctamente
      final body = {
        'communityId': monthlyFee.communityId,
        'userId': monthlyFee.houseId, // En el frontend usamos houseId como userId
        'houseId': monthlyFee.id.isNotEmpty ? monthlyFee.id : monthlyFee.houseId, // Usar un ID de casa válido
        'month': monthlyFee.month,
        'amount': monthlyFee.amount,
        'dueDate': monthlyFee.dueDate.toIso8601String(),
        'status': monthlyFee.status.toString().split('.').last,
        if (monthlyFee.amountPaid > 0) 'amountPaid': monthlyFee.amountPaid,
        if (monthlyFee.paymentMethod != null) 'paymentMethod': monthlyFee.paymentMethod,
        if (monthlyFee.receiptNumber != null) 'receiptNumber': monthlyFee.receiptNumber,
        if (monthlyFee.notes != null) 'notes': monthlyFee.notes,
        if (monthlyFee.paidDate != null) 'paidDate': monthlyFee.paidDate!.toIso8601String(),
      };
      
      final response = await _apiService.post<dynamic>(
        '/monthly-fees',
        body: body,
      );

      if (response.success) {
        await loadMonthlyFees();
        return {'success': true, 'message': 'Mensualidad creada exitosamente'};
      } else {
        return {'success': false, 'message': response.error ?? 'Error desconocido'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error al crear mensualidad: $e'};
    }
  }

  // Actualizar mensualidad
  Future<Map<String, dynamic>> updateMonthlyFee(String id, Map<String, dynamic> updates) async {
    try {
      final response = await _apiService.put<MonthlyFee>(
        '/monthly-fees/$id',
        body: updates,
      );

      if (response.success) {
        await loadMonthlyFees();
        return {'success': true, 'message': 'Mensualidad actualizada exitosamente'};
      } else {
        return {'success': false, 'message': response.error ?? 'Error desconocido'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error al actualizar mensualidad: $e'};
    }
  }

  /// Obtiene el historial de tickets del usuario
  Future<List<MonthlyFee>> getUserTickets() async {
    try {
      final response = await _apiService.get('/monthly-fees/user');

      if (response.isSuccess && response.data != null) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => MonthlyFee.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener mensualidades: ${response.error}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtiene todas las mensualidades (para administradores)
  Future<List<MonthlyFee>> getAllMonthlyFees(
      {String? communityId, String? userId, String? status, String? month}) async {
    try {
      Map<String, String> queryParams = {};
      if (communityId != null) queryParams['communityId'] = communityId;
      if (userId != null) queryParams['userId'] = userId;
      if (status != null) queryParams['status'] = status;
      if (month != null) queryParams['month'] = month;

      final response = await _apiService.get('/monthly-fees', queryParams: queryParams);

      if (response.isSuccess && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        if (responseData['monthlyFees'] != null) {
          final List<dynamic> monthlyFeesData = responseData['monthlyFees'] as List<dynamic>;
          return monthlyFeesData.map((data) => MonthlyFee.fromJson(data as Map<String, dynamic>)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting all monthly fees: $e');
      return [];
    }
  }

  /// Obtiene mensualidades por comunidad
  Future<List<MonthlyFee>> getMonthlyFeesByCommunity(String communityId,
      {String? status, String? month, String? userId}) async {
    try {
      Map<String, String> queryParams = {};
      if (status != null) queryParams['status'] = status;
      if (month != null) queryParams['month'] = month;
      if (userId != null) queryParams['userId'] = userId;

      final response = await _apiService.get('/monthly-fees/community/$communityId', queryParams: queryParams);

      if (response.isSuccess && response.data != null) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => MonthlyFee.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener mensualidades de la comunidad: ${response.error}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtiene mensualidades por mes
  Future<List<MonthlyFee>> getMonthlyFeesByMonth(String month, {String? communityId}) async {
    try {
      Map<String, String> queryParams = {'month': month};
      if (communityId != null) queryParams['communityId'] = communityId;

      final response = await _apiService.get('/monthly-fees', queryParams: queryParams);

      if (response.isSuccess && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        if (responseData['monthlyFees'] != null) {
          final List<dynamic> monthlyFeesData = responseData['monthlyFees'] as List<dynamic>;
          return monthlyFeesData.map((data) => MonthlyFee.fromJson(data as Map<String, dynamic>)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting monthly fees by month: $e');
      return [];
    }
  }

  /// Obtiene resumen financiero
  Future<Map<String, dynamic>> getFinancialSummary({String? communityId, String? month}) async {
    try {
      Map<String, String> queryParams = {};
      if (communityId != null) queryParams['communityId'] = communityId;
      if (month != null) queryParams['month'] = month;

      final response = await _apiService.get('/monthly-fees/summary', queryParams: queryParams);

      if (response.isSuccess && response.data != null) {
        return response.data;
      } else {
        throw Exception('Error al obtener resumen financiero: ${response.error}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Registra un pago
  Future<Map<String, dynamic>> recordPayment(String monthlyFeeId, double amount, String paymentMethod,
      {String? receiptNumber, String? notes}) async {
    try {
      final body = {
        'amount': amount,
        'paymentMethod': paymentMethod,
      };

      if (receiptNumber != null) body['receiptNumber'] = receiptNumber;
      if (notes != null) body['notes'] = notes;

      final response = await _apiService.post('/monthly-fees/$monthlyFeeId/payment', body: body);

      if (response.isSuccess) {
        await loadMonthlyFees();
        return {'success': true, 'message': 'Pago registrado exitosamente'};
      } else {
        return {'success': false, 'message': response.error ?? 'Error desconocido'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error al registrar pago: $e'};
    }
  }

  /// Genera mensualidades para un mes específico
  Future<Map<String, dynamic>> generateMonthlyFeesForMonth(String communityId, String month) async {
    try {
      final response = await _apiService.post('/monthly-fees/generate', body: {
        'communityId': communityId,
        'month': month,
      });

      if (response.isSuccess) {
        await loadMonthlyFees();
        return {'success': true, 'message': 'Mensualidades generadas exitosamente'};
      } else {
        return {'success': false, 'message': response.error ?? 'Error desconocido'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error al generar mensualidades: $e'};
    }
  }

  // Refresh
  Future<void> refresh() async {
    print('🔄 MonthlyFeeService: Refreshing data...');
    await Future.wait([
      loadMonthlyFees(),
      loadCommunities(),
    ]);
    print('✅ MonthlyFeeService: Data refreshed. Monthly fees count: ${_monthlyFees.length}');
  }
}
