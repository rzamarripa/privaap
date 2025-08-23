import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'expense_service.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _shouldRedirectToLogin = false;
  final ApiService _apiService = ApiService();

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isAdmin => _currentUser?.role == UserRole.administrador || _currentUser?.role == UserRole.superAdmin;
  bool get shouldRedirectToLogin => _shouldRedirectToLogin;

  void clearRedirectFlag() {
    _shouldRedirectToLogin = false;
  }

  // Método para forzar logout y redirección
  Future<void> forceLogout() async {
    await logout();
    // Asegurar que la bandera esté activa
    _shouldRedirectToLogin = true;
    notifyListeners();
  }

  Future<bool> login(String phoneNumber, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('/auth/login', body: {
        'phoneNumber': phoneNumber,
        'password': password,
      });

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final token = data['token'] as String;
        final userData = data['user'] as Map<String, dynamic>;

        _currentUser = User.fromJson(userData);
        _isAuthenticated = true;

        // Configurar token en ApiService
        await _apiService.setAuthToken(token);

        // Guardar sesión completa
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', _currentUser!.id);
        await prefs.setString('userPhone', _currentUser!.phoneNumber);
        await prefs.setString('userName', _currentUser!.name);
        await prefs.setString('userEmail', _currentUser!.email);
        await prefs.setString('userRole', _currentUser!.role.toString());
        if (_currentUser!.house != null) {
          await prefs.setString('userHouse', _currentUser!.house!);
        }
        if (_currentUser!.communityId != null) {
          await prefs.setString('userCommunityId', _currentUser!.communityId!);
          print('🔐 CommunityId guardado: ${_currentUser!.communityId}');
        }
        await prefs.setBool('isAuthenticated', true);

        // Guardar credenciales para login biométrico
        await saveCredentialsForBiometric(phoneNumber, password);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Obtiene las credenciales guardadas para login biométrico
  Future<Map<String, String>?> getSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('userPhone');
      final password = prefs.getString('userPassword');

      if (phoneNumber != null && password != null) {
        return {
          'phoneNumber': phoneNumber,
          'password': password,
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Guarda las credenciales para login biométrico
  Future<bool> saveCredentialsForBiometric(String phoneNumber, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userPhone', phoneNumber);
      await prefs.setString('userPassword', password);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Llamar endpoint de logout si existe
      await _apiService.post('/auth/logout');
    } catch (e) {
      // Continuar con logout local aunque falle la API
      print('⚠️ Error en logout de API: $e');
    }

    try {
      // Limpiar solo la sesión actual, NO las credenciales biométricas
      final prefs = await SharedPreferences.getInstance();

      // Eliminar solo las claves de sesión, mantener las biométricas
      await prefs.remove('userId');
      await prefs.remove('userName');
      await prefs.remove('userEmail');
      await prefs.remove('userRole');
      await prefs.remove('userHouse');
      await prefs.remove('userCommunityId');
      await prefs.remove('isAuthenticated');
      await prefs.remove('auth_token');

      // NO eliminar: userPhone, userPassword, biometric_auth_enabled, biometric_type

      await _apiService.clearAuthToken();

      // Limpiar estado local
      _currentUser = null;
      _isAuthenticated = false;
      _isLoading = false;

      // Notificar que se debe redirigir al login
      _shouldRedirectToLogin = true;

      notifyListeners();
    } catch (e) {
      // Asegurar que el estado se limpie aunque falle
      _currentUser = null;
      _isAuthenticated = false;
      _isLoading = false;
      _shouldRedirectToLogin = true;
      notifyListeners();
    }
  }

  Future<void> checkAuthStatus() async {
    if (_isLoading) return; // Evitar múltiples llamadas simultáneas

    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final isAuthenticated = prefs.getBool('isAuthenticated') ?? false;
      final userId = prefs.getString('userId');

      if (isAuthenticated && userId != null) {
        // Restaurar datos del usuario desde SharedPreferences

        final userName = prefs.getString('userName');
        final userPhone = prefs.getString('userPhone');
        final userEmail = prefs.getString('userEmail');
        final userRoleString = prefs.getString('userRole');
        final userHouse = prefs.getString('userHouse');
        final userCommunityId = prefs.getString('userCommunityId');

        if (userName != null && userPhone != null && userEmail != null && userRoleString != null) {
          // Recrear objeto User desde datos locales
          UserRole userRole;
          if (userRoleString.contains('superAdmin')) {
            userRole = UserRole.superAdmin;
          } else if (userRoleString.contains('administrador')) {
            userRole = UserRole.administrador;
          } else {
            userRole = UserRole.residente;
          }

          _currentUser = User(
            id: userId,
            phoneNumber: userPhone,
            name: userName,
            email: userEmail,
            role: userRole,
            house: userHouse,
            communityId: userCommunityId,
            createdAt: DateTime.now(),
            isActive: true,
          );

          _isAuthenticated = true;

          // Cargar token y validar con API en segundo plano
          await _apiService.loadAuthToken();

          // Opcional: Verificar token con la API (sin bloquear la UI)
          try {
            final response = await _apiService.get('/auth/me');
            if (response.isSuccess && response.data != null) {
              // response.data is already the extracted user data from ApiService
              final userData = response.data as Map<String, dynamic>;
              _currentUser = User.fromJson(userData);

              // Guardar la casa y comunidad actualizadas en SharedPreferences
              if (_currentUser!.house != null) {
                await prefs.setString('userHouse', _currentUser!.house!);
              }
              if (_currentUser!.communityId != null) {
                await prefs.setString('userCommunityId', _currentUser!.communityId!);
              }

              notifyListeners();
            }
          } catch (e) {
            // No se pudo validar con API, pero sesión local válida
          }
        } else {
          await _clearLocalData();
        }
      } else {
        _isAuthenticated = false;
      }
    } catch (e) {
      _isAuthenticated = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _clearLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _apiService.clearAuthToken();
    _currentUser = null;
    _isAuthenticated = false;
  }

  Future<bool> register({
    required String phoneNumber,
    required String password,
    required String name,
    required String email,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('/auth/register', body: {
        'phoneNumber': phoneNumber,
        'password': password,
        'name': name,
        'email': email,
      });

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final token = data['token'] as String;
        final userData = data['user'] as Map<String, dynamic>;

        _currentUser = User.fromJson(userData);
        _isAuthenticated = true;

        // Configurar token en ApiService
        await _apiService.setAuthToken(token);

        // Guardar sesión completa
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', _currentUser!.id);
        await prefs.setString('userPhone', _currentUser!.phoneNumber);
        await prefs.setString('userName', _currentUser!.name);
        await prefs.setString('userEmail', _currentUser!.email);
        await prefs.setString('userRole', _currentUser!.role.toString());
        await prefs.setBool('isAuthenticated', true);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String email,
    String? phoneNumber,
    String? house,
    String? profileImage,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.put('/users/${_currentUser!.id}', body: {
        'name': name,
        'email': email,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (house != null) 'house': house,
        if (profileImage != null) 'profileImage': profileImage,
      });

      if (response.isSuccess && response.data != null) {
        // response.data is already the extracted user data from ApiService
        final userData = response.data as Map<String, dynamic>;
        _currentUser = User.fromJson(userData);

        // Actualizar SharedPreferences con los nuevos datos
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userName', _currentUser!.name);
        await prefs.setString('userEmail', _currentUser!.email);
        await prefs.setString('userPhone', _currentUser!.phoneNumber);

        // Manejar campo house que puede ser null
        if (_currentUser!.house != null && _currentUser!.house!.isNotEmpty) {
          await prefs.setString('userHouse', _currentUser!.house!);
        } else {
          await prefs.remove('userHouse');
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> refreshCurrentUser() async {
    if (_currentUser == null) return false;

    try {
      final response = await _apiService.get('/auth/me');

      if (response.isSuccess && response.data != null) {
        // response.data is already the extracted user data from ApiService
        final userData = response.data as Map<String, dynamic>;
        _currentUser = User.fromJson(userData);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
