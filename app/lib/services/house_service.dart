import 'package:flutter/material.dart';
import '../models/house_model.dart';
import 'api_service.dart';

class HouseService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<House> _houses = [];
  bool _isLoading = false;
  String? _error;

  List<House> get houses => _houses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Obtener casas por comunidad
  List<House> getHousesByCommunity(String communityId) {
    return _houses.where((house) => house.communityId == communityId).toList();
  }

  // Obtener casas activas por comunidad
  List<House> getActiveHousesByCommunity(String communityId) {
    return _houses.where((house) => house.communityId == communityId && house.isActive).toList();
  }

  // Obtener casa por ID
  House? getHouseById(String houseId) {
    try {
      return _houses.firstWhere((house) => house.id == houseId);
    } catch (e) {
      return null;
    }
  }

  // Cargar todas las casas
  Future<void> loadHouses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/houses/all');

      if (response.isSuccess && response.data != null) {
        // response.data is already the extracted data from ApiService
        final List<dynamic> housesData = response.data as List<dynamic>;
        _houses = housesData.map((data) => House.fromJson(data as Map<String, dynamic>)).toList();
      } else {
        _houses = [];
        _error = response.error ?? 'Error al cargar las casas';
      }
    } catch (e) {
      _houses = [];
      _error = 'Error inesperado: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cargar casas de una comunidad específica
  Future<void> loadHousesByCommunity(String communityId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    print('🔄 DEBUG HouseService.loadHousesByCommunity - Iniciando carga para comunidad: $communityId');

    try {
      print('🔍 DEBUG HouseService.loadHousesByCommunity - Haciendo llamada a API...');
      final response = await _apiService.get('/houses/community/$communityId');
      print(
          '🔍 DEBUG HouseService.loadHousesByCommunity - Respuesta recibida: success=${response.success}, error=${response.error}');

      if (response.isSuccess && response.data != null) {
        print('🔍 DEBUG HouseService.loadHousesByCommunity - Data recibida: ${response.data}');
        print('🔍 DEBUG HouseService.loadHousesByCommunity - Tipo de data: ${response.data.runtimeType}');

        // response.data is already the extracted data from ApiService
        final List<dynamic> housesData = response.data as List<dynamic>;
        print('🔍 DEBUG HouseService.loadHousesByCommunity - Data es List con ${housesData.length} elementos');
        _houses = housesData.map((data) => House.fromJson(data as Map<String, dynamic>)).toList();

        print('✅ DEBUG HouseService.loadHousesByCommunity - Casas cargadas: ${_houses.length}');
      } else {
        print('❌ DEBUG HouseService.loadHousesByCommunity - Error en respuesta: ${response.error}');
        _houses = [];
        _error = response.error ?? 'Error al cargar las casas de la comunidad';
      }
    } catch (e) {
      _houses = [];
      _error = 'Error inesperado: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Crear nueva casa
  Future<Map<String, dynamic>> createHouse(Map<String, dynamic> houseData) async {
    try {
      final response = await _apiService.post('/houses', body: houseData);

      if (response.isSuccess && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        // La respuesta ya viene con success: true desde la API
        // Recargar casas de la comunidad específica
        await loadHousesByCommunity(houseData['communityId']);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Casa creada exitosamente',
          'houseId': responseData['data']?['id'] ?? responseData['id']
        };
      } else {
        return {'success': false, 'message': response.error ?? 'Error al crear la casa'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error inesperado: $e'};
    }
  }

  // Actualizar casa
  Future<Map<String, dynamic>> updateHouse(String houseId, Map<String, dynamic> houseData) async {
    try {
      final response = await _apiService.put('/houses/$houseId', body: houseData);

      if (response.isSuccess && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        // La respuesta ya viene con success: true desde la API
        // Recargar casas de la comunidad específica
        await loadHousesByCommunity(houseData['communityId']);
        return {'success': true, 'message': responseData['message'] ?? 'Casa actualizada exitosamente'};
      } else {
        return {'success': false, 'message': response.error ?? 'Error al actualizar la casa'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error inesperado: $e'};
    }
  }

  // Eliminar casa
  Future<Map<String, dynamic>> deleteHouse(String houseId) async {
    try {
      // Obtener la casa antes de eliminarla para saber su communityId
      final house = getHouseById(houseId);
      final communityId = house?.communityId;

      final response = await _apiService.delete('/houses/$houseId');

      if (response.isSuccess && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        // La respuesta ya viene con success: true desde la API
        // Recargar casas de la comunidad específica si tenemos el communityId
        if (communityId != null) {
          await loadHousesByCommunity(communityId);
        }
        return {'success': true, 'message': responseData['message'] ?? 'Casa eliminada exitosamente'};
      } else {
        return {'success': false, 'message': response.error ?? 'Error al eliminar la casa'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error inesperado: $e'};
    }
  }

  // Limpiar datos
  void clear() {
    _houses = [];
    _error = null;
    notifyListeners();
  }
}
