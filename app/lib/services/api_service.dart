import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  static const String baseUrl = ApiConfig.baseUrl;
  static const String _tokenKey = 'auth_token';

  // Singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _authToken;
  bool _tokenLoaded = false;

  // Headers básicos
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  // Configurar token de autenticación
  Future<void> setAuthToken(String token) async {
    _authToken = token;
    _tokenLoaded = true; // Marcar como cargado
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    print('🔍 DEBUG setAuthToken - Token guardado: ${token.substring(0, 20)}...');
  }

  // Cargar token guardado
  Future<void> loadAuthToken() async {
    // Evitar cargar el token múltiples veces
    if (_tokenLoaded) return;
    
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(_tokenKey);
    _tokenLoaded = true;
    print('🔍 DEBUG loadAuthToken - Token cargado: ${_authToken != null ? 'SÍ' : 'NO'}');
    if (_authToken != null) {
      print('🔍 DEBUG loadAuthToken - Token: ${_authToken!.substring(0, 20)}...');
    }
  }

  // Limpiar token
  Future<void> clearAuthToken() async {
    _authToken = null;
    _tokenLoaded = false; // Resetear flag
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // GET Request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    try {
      // Asegurar que el token esté cargado
      await loadAuthToken();
      final uri = Uri.parse('$baseUrl$endpoint');
      final uriWithParams = queryParams != null ? uri.replace(queryParameters: queryParams) : uri;

      final response = await http.get(uriWithParams, headers: _headers);
      return _handleResponse<T>(response);
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // POST Request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      // Asegurar que el token esté cargado
      await loadAuthToken();
      print('🔍 DEBUG ApiService.post - Endpoint: $endpoint');
      print('🔍 DEBUG ApiService.post - Headers: $_headers');
      print('🔍 DEBUG ApiService.post - Body: $body');

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );

      print('🔍 DEBUG ApiService.post - Status: ${response.statusCode}');
      print('🔍 DEBUG ApiService.post - Response: ${response.body}');

      return _handleResponse<T>(response);
    } catch (e) {
      print('❌ ERROR ApiService.post: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // PUT Request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      // Asegurar que el token esté cargado
      await loadAuthToken();
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse<T>(response);
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // PATCH Request
  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      print('🔄 DEBUG ApiService.patch - Iniciando petición PATCH');
      print('🔄 DEBUG ApiService.patch - Endpoint: $endpoint');
      print('🔄 DEBUG ApiService.patch - Body: $body');

      // Asegurar que el token esté actualizado
      await loadAuthToken();

      print('🔄 DEBUG ApiService.patch - URL completa: $baseUrl$endpoint');
      print('🔄 DEBUG ApiService.patch - Headers: $_headers');

      final response = await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );

      print('🔄 DEBUG ApiService.patch - Respuesta HTTP recibida');
      print('🔄 DEBUG ApiService.patch - Status code: ${response.statusCode}');
      print('🔄 DEBUG ApiService.patch - Response body: ${response.body}');

      return _handleResponse<T>(response);
    } catch (e) {
      print('🔄 DEBUG ApiService.patch - Excepción capturada: $e');
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // DELETE Request
  Future<ApiResponse<T>> delete<T>(String endpoint) async {
    try {
      // Asegurar que el token esté cargado
      await loadAuthToken();
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      );
      return _handleResponse<T>(response);
    } catch (e) {
      return ApiResponse.error('Error de conexión: $e');
    }
  }

  // Upload File Request
  Future<ApiResponse<T>> uploadFile<T>(
    String endpoint,
    File file,
    String fieldName,
  ) async {
    try {
      await loadAuthToken();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$endpoint'),
      );

      // Agregar headers de autorización
      request.headers.addAll(_headers);

      // Agregar el archivo
      final stream = http.ByteStream(file.openRead());
      final length = await file.length();
      final multipartFile = http.MultipartFile(
        fieldName,
        stream,
        length,
        filename: file.path.split('/').last,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse<T>(response);
    } catch (e) {
      return ApiResponse.error('Error al subir archivo: $e');
    }
  }

  // Manejar respuesta HTTP
  ApiResponse<T> _handleResponse<T>(http.Response response) {
    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      // Éxito
      try {
        if (response.body.isEmpty) {
          return ApiResponse.success(null);
        }

        final data = jsonDecode(response.body);
        print('=== DEBUG: ApiService._handleResponse ===');
        print('Status Code: $statusCode');
        print('Response Body: ${response.body}');
        print('Parsed Data: $data');
        print('Data Type: ${data.runtimeType}');
        print('Expected Type T: $T');

        // Extraer el campo 'data' si la respuesta tiene la estructura estándar de la API
        dynamic responseData;
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          responseData = data['data'];
          print('=== DEBUG: Extrayendo campo "data": $responseData');
        } else {
          responseData = data;
          print('=== DEBUG: Usando respuesta completa como data');
        }

        return ApiResponse.success(responseData);
      } catch (e) {
        print('ERROR en _handleResponse: $e');
        return ApiResponse.error('Error al parsear respuesta: $e');
      }
    } else {
      // Error
      try {
        final errorData = jsonDecode(response.body);
        String message = 'Error del servidor';

        // Priorizar mensajes específicos de la API
        if (errorData.containsKey('error')) {
          message = errorData['error'];
        } else if (errorData.containsKey('message')) {
          message = errorData['message'];
        } else if (errorData.containsKey('details')) {
          // Si hay detalles de validación, crear un mensaje más específico
          final details = errorData['details'];
          if (details is List && details.isNotEmpty) {
            message = 'Datos inválidos: ${details.first['msg'] ?? 'Campo requerido'}';
          }
        }

        // Para errores 400, preservar el mensaje específico de la API
        if (statusCode == 400) {
          // No sobrescribir el mensaje si ya es específico
          if (message == 'Error del servidor') {
            // Solo cambiar si es el mensaje genérico por defecto
            if (errorData.containsKey('error')) {
              message = errorData['error'];
            } else if (errorData.containsKey('message')) {
              message = errorData['message'];
            }
          }
        } else if (statusCode == 401) {
          message = 'No autorizado. Inicia sesión nuevamente.';
        } else if (statusCode == 403) {
          message = 'Acceso denegado. No tienes permisos para esta acción.';
        } else if (statusCode == 404) {
          message = 'Recurso no encontrado.';
        } else if (statusCode == 409) {
          message = 'Conflicto: El recurso ya existe.';
        } else if (statusCode == 422) {
          message = 'Datos de entrada inválidos.';
        } else if (statusCode == 500) {
          message = 'Error interno del servidor.';
        }

        return ApiResponse.error(message, statusCode: statusCode);
      } catch (e) {
        // Si no se puede parsear el JSON, usar mensajes genéricos por código de estado
        String message;
        switch (statusCode) {
          case 400:
            message = 'Solicitud incorrecta';
            break;
          case 401:
            message = 'No autorizado';
            break;
          case 403:
            message = 'Acceso denegado';
            break;
          case 404:
            message = 'Recurso no encontrado';
            break;
          case 409:
            message = 'Conflicto: El recurso ya existe';
            break;
          case 422:
            message = 'Datos de entrada inválidos';
            break;
          case 500:
            message = 'Error interno del servidor';
            break;
          default:
            message = 'Error del servidor ($statusCode)';
        }

        return ApiResponse.error(message, statusCode: statusCode);
      }
    }
  }
}

// Clase para manejar respuestas de la API
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int? statusCode;

  ApiResponse._({
    required this.success,
    this.data,
    this.error,
    this.statusCode,
  });

  factory ApiResponse.success(T? data) {
    return ApiResponse._(success: true, data: data);
  }

  factory ApiResponse.error(String error, {int? statusCode}) {
    return ApiResponse._(
      success: false,
      error: error,
      statusCode: statusCode,
    );
  }

  bool get isSuccess => success;
  bool get isError => !success;
}
