import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import 'api_service.dart';
import '../config/api_config.dart';

class UserService {
  final ApiService _apiService = ApiService();

  List<User> _users = [];
  bool _isLoading = false;

  // Getters
  List<User> get users => _users;
  bool get isLoading => _isLoading;

  // Obtener usuario por ID
  User? getUserById(String id) {
    try {
      return _users.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }

  // Obtener usuarios por rol
  List<User> getUsersByRole(UserRole role) {
    return _users.where((user) => user.role == role).toList();
  }

  // Obtener usuarios por comunidad
  List<User> getUsersByCommunity(String communityId) {
    return _users.where((user) => user.communityId == communityId).toList();
  }

  // Obtener usuarios activos
  List<User> get activeUsers => _users.where((user) => user.isActive).toList();

  // Obtener usuarios inactivos
  List<User> get inactiveUsers => _users.where((user) => !user.isActive).toList();

  // Cargar todos los usuarios
  Future<void> loadUsers() async {
    _isLoading = true;

    try {
      print('=== DEBUG: UserService.loadUsers() ===');

      // Asegurarse de que el token de autenticación esté cargado
      await _apiService.loadAuthToken();
      print('Token de autenticación cargado');

      print('Haciendo llamada a API: /users');

      final response = await _apiService.get('/users');

      print('Respuesta de API recibida:');
      print('  - success: ${response.success}');
      print('  - statusCode: ${response.statusCode}');
      print('  - error: ${response.error}');
      print('  - data: ${response.data}');
      print('  - data type: ${response.data.runtimeType}');

      if (response.success) {
        if (response.data is Map<String, dynamic>) {
          // La API devuelve {success: true, count: X, data: [...]}
          final data = response.data as Map<String, dynamic>;
          if (data.containsKey('data') && data['data'] is List) {
            _users = (data['data'] as List).map((json) => User.fromJson(json)).toList();
            print('Usuarios cargados exitosamente desde data.data: ${_users.length}');

            // Mostrar detalles de cada usuario cargado
            for (var user in _users) {
              print('  Usuario: ${user.name} - ${user.email} - Role: ${user.role} - CommunityID: ${user.communityId}');
            }
          } else {
            print('ERROR: response.data es Map pero no contiene lista de usuarios en data.data');
            print('  - Keys disponibles: ${data.keys.toList()}');
            _users = [];
          }
        } else if (response.data is List) {
          // Fallback: si la API devuelve directamente la lista
          _users = (response.data as List).map((json) => User.fromJson(json)).toList();
          print('Usuarios cargados exitosamente desde lista directa: ${_users.length}');

          // Mostrar detalles de cada usuario cargado
          for (var user in _users) {
            print('  Usuario: ${user.name} - ${user.email} - Role: ${user.role} - CommunityID: ${user.communityId}');
          }
        } else {
          print('ERROR: response.data no es una List ni Map, es: ${response.data.runtimeType}');
          print('  - Contenido: $response.data');
          _users = [];
        }
      } else {
        print('ERROR: API no devolvió success: true');
        _users = [];
      }
    } catch (e) {
      print('Error loading users: $e');
      _users = [];
    } finally {
      _isLoading = false;
    }
  }

  // Crear nuevo usuario
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    try {
      // Hacer la llamada de forma directa para acceder a la estructura completa
      await _apiService.loadAuthToken();
      
      // Obtener el token de SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/users'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(userData),
      );

      final statusCode = response.statusCode;
      final responseBody = response.body;
      
      if (statusCode >= 200 && statusCode < 300) {
        // Éxito
        final responseData = jsonDecode(responseBody) as Map<String, dynamic>;
        
        if (responseData.containsKey('success') && responseData['success'] == true) {
          await loadUsers();
          return {
            'success': true,
            'message': responseData['message'] ?? 'Usuario creado exitosamente',
            'userId': responseData['userId']
          };
        } else {
          return {'success': false, 'message': responseData['error'] ?? 'Error desconocido al crear usuario'};
        }
      } else {
        // Error
        try {
          final errorData = jsonDecode(responseBody) as Map<String, dynamic>;
          String errorMessage = errorData['error'] ?? 'Error del servidor';
          
          // Mapear errores específicos a mensajes más amigables
          if (errorMessage.contains('email ya está registrado')) {
            errorMessage = 'El email ya está registrado en el sistema';
          } else if (errorMessage.contains('número de teléfono ya está registrado')) {
            errorMessage = 'El número de teléfono ya está registrado en el sistema';
          } else if (errorMessage.contains('Datos de entrada inválidos')) {
            errorMessage = 'Los datos ingresados no son válidos';
          }
          
          return {'success': false, 'message': errorMessage};
        } catch (e) {
          return {'success': false, 'message': 'Error del servidor ($statusCode)'};
        }
      }
    } catch (e) {
      print('Error creating user: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Actualizar usuario
  Future<Map<String, dynamic>> updateUser(String id, Map<String, dynamic> updates) async {
    try {
      final response = await _apiService.put<User>(
        '/users/$id',
        body: updates,
      );

      if (response.success) {
        await loadUsers();
        return {'success': true, 'message': 'Usuario actualizado exitosamente'};
      } else {
        return {'success': false, 'message': response.error ?? 'Error desconocido'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error al actualizar usuario: $e'};
    }
  }

  // Eliminar usuario
  Future<Map<String, dynamic>> deleteUser(String id) async {
    try {
      final response = await _apiService.delete<User>('/users/$id');

      if (response.success) {
        await loadUsers();
        return {'success': true, 'message': 'Usuario eliminado exitosamente'};
      } else {
        return {'success': false, 'message': response.error ?? 'Error desconocido'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error al eliminar usuario: $e'};
    }
  }

  // Activar/desactivar usuario
  Future<Map<String, dynamic>> toggleUserStatus(String id, bool isActive) async {
    return await updateUser(id, {
      'isActive': isActive,
    });
  }

  // Cambiar rol de usuario
  Future<Map<String, dynamic>> changeUserRole(String id, UserRole newRole) async {
    try {
      print('🔄 DEBUG UserService.changeUserRole - Iniciando cambio de rol');
      print('🔄 DEBUG UserService.changeUserRole - ID del usuario: $id');
      print('🔄 DEBUG UserService.changeUserRole - Nuevo rol: $newRole');
      print('🔄 DEBUG UserService.changeUserRole - Rol convertido: ${newRole.toString().split('.').last}');

      final response = await _apiService.patch<dynamic>(
        '/users/$id/role',
        body: {
          'role': newRole.toString().split('.').last,
        },
      );

      print('🔄 DEBUG UserService.changeUserRole - Respuesta de la API: $response');
      print('🔄 DEBUG UserService.changeUserRole - Success: ${response.success}');
      print('🔄 DEBUG UserService.changeUserRole - Error: ${response.error}');
      print('🔄 DEBUG UserService.changeUserRole - Status code: ${response.statusCode}');

      if (response.success) {
        print('🔄 DEBUG UserService.changeUserRole - Actualizando lista de usuarios...');
        await loadUsers();
        print('🔄 DEBUG UserService.changeUserRole - Lista de usuarios actualizada');
        return {'success': true, 'message': 'Rol de usuario actualizado exitosamente'};
      } else {
        print('🔄 DEBUG UserService.changeUserRole - Error en la respuesta: ${response.error}');
        return {'success': false, 'message': response.error ?? 'Error al cambiar rol de usuario'};
      }
    } catch (e) {
      print('🔄 DEBUG UserService.changeUserRole - Excepción capturada: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Asignar usuario a comunidad
  Future<Map<String, dynamic>> assignUserToCommunity(String userId, String communityId, String house) async {
    return await updateUser(userId, {
      'communityId': communityId,
      'house': house,
    });
  }

  // Remover usuario de comunidad
  Future<Map<String, dynamic>> removeUserFromCommunity(String userId) async {
    return await updateUser(userId, {
      'communityId': null,
      'house': null,
    });
  }

  // Cambiar contraseña de usuario (solo super admin)
  Future<Map<String, dynamic>> changeUserPassword(String userId, String newPassword) async {
    try {
      final response = await _apiService.patch('/users/$userId/password', 
        body: {
          'newPassword': newPassword,
        }
      );

      if (response.success) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Contraseña actualizada exitosamente',
        };
      } else {
        return {
          'success': false,
          'message': response.data['error'] ?? 'Error al cambiar contraseña',
        };
      }
    } catch (e) {
      // Error de conexión
      return {
        'success': false,
        'message': 'Error de conexión al cambiar contraseña',
      };
    }
  }

  // Refresh
  Future<void> refresh() async {
    await loadUsers();
  }
}
