import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExpenseService extends ChangeNotifier {
  List<Expense> _expenses = [];
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  List<Expense> get expenses => [..._expenses];
  bool get isLoading => _isLoading;

  List<Expense> get pendingExpenses => _expenses.where((e) => e.status == ExpenseStatus.pendiente).toList();

  List<Expense> get approvedExpenses => _expenses.where((e) => e.status == ExpenseStatus.aprobado).toList();

  List<Expense> get paidExpenses => _expenses.where((e) => e.status == ExpenseStatus.pagado).toList();

  List<Expense> get rejectedExpenses => _expenses.where((e) => e.status == ExpenseStatus.rechazado).toList();

  double get totalExpenses =>
      _expenses.where((e) => e.status != ExpenseStatus.rechazado).fold(0, (sum, expense) => sum + expense.amount);

  // Total de todos los gastos incluyendo rechazados (para estadísticas completas)
  double get totalAllExpenses => _expenses.fold(0, (sum, expense) => sum + expense.amount);

  // Gastos activos (no rechazados)
  List<Expense> get activeExpenses => _expenses.where((e) => e.status != ExpenseStatus.rechazado).toList();

  double get totalPaidExpenses => paidExpenses.fold(0, (sum, expense) => sum + expense.amount);

  double get totalPendingExpenses => pendingExpenses.fold(0, (sum, expense) => sum + expense.amount);

  double get totalRejectedExpenses => rejectedExpenses.fold(0, (sum, expense) => sum + expense.amount);

  Map<ExpenseCategory, double> getExpensesByCategory() {
    final Map<ExpenseCategory, double> categoryTotals = {};

    for (var expense in _expenses) {
      categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    return categoryTotals;
  }

  List<Expense> getExpensesByDateRange(DateTime start, DateTime end) {
    return _expenses.where((expense) => expense.date.isAfter(start) && expense.date.isBefore(end)).toList();
  }

  // Cargar gastos desde la API
  Future<void> loadExpenses() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Limpiar gastos anteriores para evitar mezcla de datos
      _expenses.clear();
      
      // Obtener el communityId del usuario logueado
      final prefs = await SharedPreferences.getInstance();
      final userCommunityId = prefs.getString('userCommunityId');
      
      print('🔍 Cargando gastos del backend');
      print('👤 CommunityId del usuario actual: $userCommunityId');
      
      // Enviar el communityId como parámetro para filtrar los gastos
      Map<String, String>? queryParams;
      if (userCommunityId != null && userCommunityId.isNotEmpty) {
        queryParams = {'community': userCommunityId};
        print('📤 Enviando parámetro community: $userCommunityId');
      } else {
        print('⚠️ Usuario sin communityId, cargando todos los gastos disponibles');
      }
      
      final response = await _apiService.get('/expenses', queryParams: queryParams);

      if (response.isSuccess && response.data != null) {
        // response.data is already the extracted data from ApiService
        final List<dynamic> expensesData = response.data as List<dynamic>;
        _expenses = expensesData.map((data) => Expense.fromJson(data as Map<String, dynamic>)).toList();
        
        print('✅ Gastos cargados: ${_expenses.length} gastos');
        
        // Log detallado de los primeros gastos para verificar
        if (_expenses.isNotEmpty) {
          print('📋 Primer gasto: ${_expenses.first.title}');
          print('📅 Fecha: ${_expenses.first.date}');
          print('💰 Monto: ${_expenses.first.amount}');
          print('👥 Creado por: ${_expenses.first.createdBy}');
          print('🏠 CommunityId del gasto: ${_expenses.first.communityId}');
          
          // Verificar que todos los gastos son de la comunidad correcta
          for (var expense in _expenses) {
            if (expense.communityId != userCommunityId) {
              print('⚠️ ALERTA: Gasto "${expense.title}" tiene communityId diferente: ${expense.communityId}');
            }
          }
        } else {
          print('⚠️ No hay gastos para la comunidad: $userCommunityId');
        }
      }
    } catch (e) {
      print('❌ Error loading expenses: $e');
      // Mantener datos locales en caso de error
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> addExpense(Expense expense) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('/expenses', body: expense.toCreateJson());

      if (response.isSuccess && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        final newExpense = Expense.fromJson(responseData['data'] ?? responseData);
        _expenses.insert(0, newExpense);

        _isLoading = false;
        notifyListeners();
        return {'success': true, 'message': 'Gasto creado exitosamente', 'data': newExpense};
      } else {
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'message': response.error ?? 'Error al crear el gasto'};
      }
    } catch (e) {
      print('Error adding expense: $e');
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> updateExpense(Expense updatedExpense) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.put(
        '/expenses/${updatedExpense.id}',
        body: updatedExpense.toJson(),
      );

      if (response.isSuccess && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        final updated = Expense.fromJson(responseData['data'] ?? responseData);
        final index = _expenses.indexWhere((e) => e.id == updatedExpense.id);

        if (index != -1) {
          _expenses[index] = updated;
        }

        _isLoading = false;
        notifyListeners();
        return {'success': true, 'message': 'Gasto actualizado exitosamente', 'data': updated};
      } else {
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'message': response.error ?? 'Error al actualizar el gasto'};
      }
    } catch (e) {
      print('Error updating expense: $e');
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> updateExpenseStatus(String expenseId, ExpenseStatus newStatus) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.put(
        '/expenses/$expenseId/status',
        body: {'status': newStatus.toString().split('.').last},
      );

      if (response.isSuccess) {
        final index = _expenses.indexWhere((e) => e.id == expenseId);
        if (index != -1) {
          _expenses[index] = _expenses[index].copyWith(status: newStatus);
        }

        _isLoading = false;
        notifyListeners();
        return {'success': true, 'message': 'Estado del gasto actualizado exitosamente'};
      } else {
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'message': response.error ?? 'Error al actualizar el estado'};
      }
    } catch (e) {
      print('Error updating expense status: $e');
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteExpense(String expenseId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.delete('/expenses/$expenseId');

      if (response.isSuccess) {
        _expenses.removeWhere((e) => e.id == expenseId);

        _isLoading = false;
        notifyListeners();
        return {'success': true, 'message': 'Gasto eliminado exitosamente'};
      } else {
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'message': response.error ?? 'Error al eliminar el gasto'};
      }
    } catch (e) {
      print('Error deleting expense: $e');
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Expense? getExpenseById(String id) {
    try {
      return _expenses.firstWhere((expense) => expense.id == id);
    } catch (_) {
      return null;
    }
  }

  // Refresh data from API
  Future<void> refresh() async {
    await loadExpenses();
  }
  
  // Limpiar todos los gastos (útil al cambiar de usuario o comunidad)
  void clearExpenses() {
    _expenses.clear();
    notifyListeners();
    print('🧹 Gastos limpiados');
  }
}
