import '../../models/community_model.dart';
import '../../models/user_model.dart';
import 'api_service.dart';

class CommunityService {
  final ApiService _apiService = ApiService();

  List<Community> _communities = [];
  bool _isLoading = false;

  // Getters
  List<Community> get communities => _communities;
  bool get isLoading => _isLoading;

  // Obtener comunidad por ID
  Community? getCommunityById(String id) {
    try {
      return _communities.firstWhere((community) => community.id == id);
    } catch (e) {
      return null;
    }
  }

  // Obtener comunidades del super admin
  List<Community> getCommunitiesBySuperAdmin(String superAdminId) {
    return _communities.where((community) => community.superAdminId == superAdminId).toList();
  }

  // Obtener comunidades donde el usuario es admin
  List<Community> getCommunitiesByAdmin(String adminId) {
    return _communities.where((community) => community.adminIds.contains(adminId)).toList();
  }

  // Cargar todas las comunidades
  Future<void> loadCommunities() async {
    _isLoading = true;

    try {
      print('🔄 DEBUG CommunityService.loadCommunities - Iniciando carga...');

      // Cargar el token de autenticación antes de hacer la llamada
      await _apiService.loadAuthToken();
      print('🔍 DEBUG CommunityService.loadCommunities - Token cargado');

      print('🔍 DEBUG CommunityService.loadCommunities - Haciendo llamada a /communities...');
      final response = await _apiService.get<dynamic>('/communities');
      print(
          '🔍 DEBUG CommunityService.loadCommunities - Respuesta recibida: success=${response.success}, error=${response.error}');

      if (response.success && response.data != null) {
        // response.data is already the extracted data from ApiService
        final List<dynamic> communitiesList = response.data as List<dynamic>;
        
        print('🔍 DEBUG CommunityService.loadCommunities - Data recibida: ${communitiesList.length} comunidades');

        print(
            '🔍 DEBUG CommunityService.loadCommunities - Iniciando parsing de ${communitiesList.length} comunidades...');

        _communities = communitiesList.map((json) {
          try {
            print('🔍 DEBUG CommunityService.loadCommunities - Parseando comunidad: ${json['name']}');
            return Community.fromJson(json);
          } catch (e) {
            print('❌ ERROR CommunityService.loadCommunities - Error parseando comunidad ${json['name']}: $e');
            print('❌ ERROR CommunityService.loadCommunities - JSON: $json');
            rethrow;
          }
        }).toList();

        print('✅ Comunidades cargadas exitosamente: ${_communities.length}');
        print(
            '🔍 DEBUG CommunityService.loadCommunities - Comunidades parseadas: ${_communities.map((c) => c.name).toList()}');
      } else {
        print('❌ DEBUG CommunityService.loadCommunities - Error en respuesta: ${response.error}');
        _communities = [];
      }
    } catch (e) {
      print('❌ ERROR CommunityService.loadCommunities - Excepción: $e');
      print('❌ ERROR CommunityService.loadCommunities - Stack trace: ${StackTrace.current}');
      _communities = [];
    } finally {
      _isLoading = false;
    }
  }

  // Crear nueva comunidad
  Future<Map<String, dynamic>> createCommunity(Community community) async {
    try {
      // Cargar el token de autenticación antes de hacer la llamada
      await _apiService.loadAuthToken();

      final response = await _apiService.post<Map<String, dynamic>>(
        '/communities',
        body: community.toJson(),
      );

      if (response.success && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;

        // La respuesta ya viene con success: true desde la API
        await loadCommunities();
        return {'success': true, 'message': responseData['message'] ?? 'Comunidad creada exitosamente'};
      } else {
        return {'success': false, 'message': response.error ?? 'Error desconocido'};
      }
    } catch (e) {
      print('Error creating community: $e');
      return {'success': false, 'message': 'Error al crear comunidad: $e'};
    }
  }

  // Actualizar comunidad
  Future<Map<String, dynamic>> updateCommunity(String id, Map<String, dynamic> updates) async {
    try {
      // Cargar el token de autenticación antes de hacer la llamada
      await _apiService.loadAuthToken();

      final response = await _apiService.put<Map<String, dynamic>>(
        '/communities/$id',
        body: updates,
      );

      if (response.success && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;

        // La respuesta ya viene con success: true desde la API
        await loadCommunities();
        return {'success': true, 'message': responseData['message'] ?? 'Comunidad actualizada exitosamente'};
      } else {
        return {'success': false, 'message': response.error ?? 'Error desconocido'};
      }
    } catch (e) {
      print('Error updating community: $e');
      return {'success': false, 'message': 'Error al actualizar comunidad: $e'};
    }
  }

  // Eliminar comunidad
  Future<Map<String, dynamic>> deleteCommunity(String id) async {
    try {
      // Cargar el token de autenticación antes de hacer la llamada
      await _apiService.loadAuthToken();

      final response = await _apiService.delete<Map<String, dynamic>>('/communities/$id');

      if (response.success && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;

        // La respuesta ya viene con success: true desde la API
        await loadCommunities();
        return {'success': true, 'message': responseData['message'] ?? 'Comunidad eliminada exitosamente'};
      } else {
        return {'success': false, 'message': response.error ?? 'Error desconocido'};
      }
    } catch (e) {
      print('Error deleting community: $e');
      return {'success': false, 'message': 'Error al eliminar comunidad: $e'};
    }
  }

  // Agregar administrador a una comunidad
  Future<Map<String, dynamic>> addAdminToCommunity(String communityId, String adminId) async {
    try {
      final community = getCommunityById(communityId);
      if (community == null) {
        return {'success': false, 'message': 'Comunidad no encontrada'};
      }

      final updatedAdminIds = List<String>.from(community.adminIds);
      if (!updatedAdminIds.contains(adminId)) {
        updatedAdminIds.add(adminId);
      }

      return await updateCommunity(communityId, {'adminIds': updatedAdminIds});
    } catch (e) {
      return {'success': false, 'message': 'Error al agregar administrador: $e'};
    }
  }

  // Remover administrador de una comunidad
  Future<Map<String, dynamic>> removeAdminFromCommunity(String communityId, String adminId) async {
    try {
      final community = getCommunityById(communityId);
      if (community == null) {
        return {'success': false, 'message': 'Comunidad no encontrada'};
      }

      final updatedAdminIds = List<String>.from(community.adminIds);
      updatedAdminIds.remove(adminId);

      return await updateCommunity(communityId, {'adminIds': updatedAdminIds});
    } catch (e) {
      return {'success': false, 'message': 'Error al remover administrador: $e'};
    }
  }

  // Activar/desactivar comunidad
  Future<Map<String, dynamic>> toggleCommunityStatus(String id, bool isActive) async {
    try {
      // Cargar el token de autenticación antes de hacer la llamada
      await _apiService.loadAuthToken();

      final response = await _apiService.put<Map<String, dynamic>>(
        '/communities/$id/status',
        body: {'isActive': isActive},
      );

      if (response.success && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData.containsKey('success') && responseData['success'] == true) {
          await loadCommunities();
          return {
            'success': true,
            'message': responseData['message'] ?? 'Estado de comunidad actualizado exitosamente'
          };
        } else {
          return {'success': false, 'message': responseData['error'] ?? 'Error desconocido al cambiar estado'};
        }
      } else {
        return {'success': false, 'message': response.error ?? 'Error desconocido'};
      }
    } catch (e) {
      print('Error toggling community status: $e');
      return {'success': false, 'message': 'Error al cambiar estado de comunidad: $e'};
    }
  }

  // Actualizar configuración de mensualidad
  Future<Map<String, dynamic>> updateMonthlyFeeConfig(String id, double monthlyFee, String currency) async {
    return await updateCommunity(id, {
      'monthlyFee': monthlyFee,
      'currency': currency,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Refresh
  Future<void> refresh() async {
    await loadCommunities();
  }
}
