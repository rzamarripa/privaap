import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/support_ticket_model.dart';
import 'api_service.dart';
import 'firebase_storage_service.dart';

class SupportService {
  final ApiService _apiService = ApiService();
  final FirebaseStorageService _firebaseStorage = FirebaseStorageService();

  /// Envía un ticket de soporte al servidor
  Future<bool> submitSupportTicket(SupportTicket ticket) async {
    try {
      debugPrint('🔍 DEBUG SupportService - Iniciando envío de ticket...');

      // Crear un mapa limpio con solo los campos requeridos por el backend
      final ticketData = {
        'userName': ticket.userName,
        'userEmail': ticket.userEmail,
        'userPhone': ticket.userPhone,
        'communityName': ticket.communityName,
        'subject': ticket.subject,
        'category': ticket.category,
        'description': ticket.description,
        'reproductionSteps': ticket.reproductionSteps,
        'attachments': ticket.attachments ?? [],
        'deviceType': ticket.deviceType,
        'appVersion': ticket.appVersion,
      };

      debugPrint('🔍 DEBUG SupportService - Datos del ticket a enviar:');
      debugPrint('  - userName: ${ticketData['userName']}');
      debugPrint('  - userEmail: ${ticketData['userEmail']}');
      debugPrint('  - userPhone: ${ticketData['userPhone']}');
      debugPrint('  - communityName: ${ticketData['communityName']}');
      debugPrint('  - subject: ${ticketData['subject']}');
      debugPrint('  - category: ${ticketData['category']}');
      debugPrint('  - description: ${ticketData['description']}');
      debugPrint('  - attachments: ${ticketData['attachments']}');
      debugPrint('  - deviceType: ${ticketData['deviceType']}');
      debugPrint('  - appVersion: ${ticketData['appVersion']}');

      // Cargar token antes de hacer la petición
      debugPrint('🔍 DEBUG SupportService - Cargando token de autenticación...');
      await _apiService.loadAuthToken();
      debugPrint('✅ DEBUG SupportService - Token cargado exitosamente');

      debugPrint('🔍 DEBUG SupportService - Enviando POST a /support/tickets...');
      final response = await _apiService.post(
        '/support/tickets',
        body: ticketData,
      );

      debugPrint('🔍 DEBUG SupportService - Respuesta recibida:');
      debugPrint('  - isSuccess: ${response.isSuccess}');
      debugPrint('  - error: ${response.error}');
      debugPrint('  - data: ${response.data}');

      if (!response.isSuccess && response.data != null) {
        debugPrint('🔍 DEBUG SupportService - Detalles del error: ${response.data}');
      }

      if (response.isSuccess) {
        debugPrint('✅ DEBUG SupportService - Ticket enviado exitosamente');
        return true;
      } else {
        debugPrint('❌ DEBUG SupportService - Error en la respuesta: ${response.error}');
        throw Exception('Error al enviar ticket: ${response.error}');
      }
    } catch (e) {
      debugPrint('❌ ERROR SupportService: $e');
      debugPrint('❌ ERROR SupportService - Stack trace: ${StackTrace.current}');
      throw Exception('Error de conexión: $e');
    }
  }

  /// Sube una imagen adjunta a Firebase Storage
  Future<String?> uploadAttachment(File imageFile) async {
    try {
      debugPrint('🔍 DEBUG SupportService - Subiendo imagen a Firebase Storage');

      // Generar nombre único para el archivo
      final fileName = _firebaseStorage.generateUniqueFileName(imageFile.path);

      // Subir imagen a Firebase Storage en la carpeta 'support-tickets'
      final downloadUrl = await _firebaseStorage.uploadImage(imageFile, 'support-tickets', fileName);

      debugPrint('✅ DEBUG SupportService - Imagen subida a Firebase: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      debugPrint('❌ ERROR SupportService - Error al subir imagen a Firebase: $e');
      throw Exception('Error al subir imagen: $e');
    }
  }

  /// Obtiene el historial de tickets del usuario
  Future<List<SupportTicket>> getUserTickets() async {
    try {
      print('🚀 DEBUG SupportService.getUserTickets - Iniciando llamada a API...');

      // Cargar el token de autenticación antes de hacer la llamada
      await _apiService.loadAuthToken();
      print('🔍 DEBUG SupportService.getUserTickets - Token cargado antes de la llamada');

      final response = await _apiService.get('/support/tickets/user');
      print(
          '🚀 DEBUG SupportService.getUserTickets - Respuesta recibida: success=${response.isSuccess}, data=${response.data != null ? 'SÍ' : 'NO'}');

      if (response.isSuccess && response.data != null) {
        print('🔍 DEBUG SupportService.getUserTickets - Response data: $response.data');
        print('🔍 DEBUG SupportService.getUserTickets - Tipo de response.data: ${response.data.runtimeType}');

        final List<dynamic> data = response.data['data'] ?? [];
        print('🔍 DEBUG SupportService.getUserTickets - Tickets encontrados en data: ${data.length}');

        if (data.isNotEmpty) {
          print('🔍 DEBUG SupportService.getUserTickets - Primer ticket: ${data.first}');
        }

        final tickets = data.map((json) => SupportTicket.fromJson(json)).toList();
        print('🔍 DEBUG SupportService.getUserTickets - Tickets parseados exitosamente: ${tickets.length}');
        return tickets;
      } else {
        print('❌ DEBUG SupportService.getUserTickets - Response no exitosa o data es NULL');
        print('❌ DEBUG SupportService.getUserTickets - isSuccess: ${response.isSuccess}, error: ${response.error}');
        throw Exception('Error al obtener tickets: ${response.error}');
      }
    } catch (e) {
      print('❌ ERROR SupportService.getUserTickets - Excepción capturada: $e');
      print('❌ ERROR SupportService.getUserTickets - Stack trace: ${StackTrace.current}');
      throw Exception('Error de conexión: $e');
    }
  }

  /// Sube múltiples imágenes adjuntas a Firebase Storage
  Future<List<String>> uploadMultipleAttachments(List<File> imageFiles) async {
    try {
      debugPrint('🔍 DEBUG SupportService - Subiendo ${imageFiles.length} imágenes a Firebase Storage');

      // Subir múltiples imágenes a Firebase Storage
      final downloadUrls = await _firebaseStorage.uploadMultipleImages(imageFiles, 'support-tickets');

      debugPrint('✅ DEBUG SupportService - ${downloadUrls.length} imágenes subidas a Firebase');

      return downloadUrls;
    } catch (e) {
      debugPrint('❌ ERROR SupportService - Error al subir múltiples imágenes a Firebase: $e');
      throw Exception('Error al subir imágenes: $e');
    }
  }

  // Refresh data from API
  Future<void> refresh() async {
    // Este método se mantiene para compatibilidad
    // Los tickets se recargan individualmente según sea necesario
  }

  // Métodos para gestión de tickets por super admin
  Future<List<SupportTicket>> getAllTickets() async {
    try {
      print('🚀 DEBUG SupportService.getAllTickets - Iniciando llamada a API...');

      // Cargar el token de autenticación antes de hacer la llamada
      await _apiService.loadAuthToken();
      print('🔍 DEBUG SupportService.getAllTickets - Token cargado antes de la llamada');

      final response = await _apiService.get('/support/tickets');
      print(
          '🚀 DEBUG SupportService.getAllTickets - Respuesta recibida: success=${response.isSuccess}, data=${response.data != null ? 'SÍ' : 'NO'}');

      if (response.isSuccess && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        print('🔍 DEBUG SupportService.getAllTickets - Response data completo: $responseData');
        print('🔍 DEBUG SupportService.getAllTickets - Keys en response.data: ${responseData.keys.toList()}');

        // La API devuelve los tickets directamente en response.data.tickets
        if (responseData['tickets'] != null) {
          print('🔍 DEBUG SupportService.getAllTickets - tickets encontrado directamente en response.data');
          final List<dynamic> ticketsData = responseData['tickets'] as List<dynamic>;
          print('🔍 DEBUG SupportService.getAllTickets - Tickets encontrados: ${ticketsData.length}');
          print(
              '🔍 DEBUG SupportService.getAllTickets - Primer ticket: ${ticketsData.isNotEmpty ? ticketsData.first : 'No hay tickets'}');

          final tickets = ticketsData.map((data) => SupportTicket.fromJson(data as Map<String, dynamic>)).toList();
          print('🔍 DEBUG SupportService.getAllTickets - Tickets parseados exitosamente: ${tickets.length}');
          return tickets;
        } else {
          print('❌ DEBUG SupportService.getAllTickets - response.data.tickets es NULL');
        }
      } else {
        print('❌ DEBUG SupportService.getAllTickets - Response no exitosa o data es NULL');
        print('❌ DEBUG SupportService.getAllTickets - isSuccess: ${response.isSuccess}, error: ${response.error}');
      }

      print('🔍 DEBUG SupportService.getAllTickets - Retornando lista vacía');
      return [];
    } catch (e) {
      print('❌ ERROR SupportService.getAllTickets - Excepción capturada: $e');
      print('❌ ERROR SupportService.getAllTickets - Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  Future<bool> updateTicketStatus(String ticketId, String newStatus) async {
    try {
      // Cargar el token de autenticación antes de hacer la llamada
      await _apiService.loadAuthToken();

      final response = await _apiService.put('/support/tickets/$ticketId', body: {
        'status': newStatus,
      });

      return response.isSuccess;
    } catch (e) {
      print('Error updating ticket status: $e');
      return false;
    }
  }

  Future<bool> respondToTicket(String ticketId, String response) async {
    try {
      // Cargar el token de autenticación antes de hacer la llamada
      await _apiService.loadAuthToken();

      final apiResponse = await _apiService.post('/support/tickets/$ticketId/respond', body: {
        'response': response,
      });

      return apiResponse.isSuccess;
    } catch (e) {
      print('Error responding to ticket: $e');
      return false;
    }
  }

  Future<SupportTicket?> getTicketById(String ticketId) async {
    try {
      // Cargar el token de autenticación antes de hacer la llamada
      await _apiService.loadAuthToken();

      final response = await _apiService.get('/support/tickets/$ticketId');

      if (response.isSuccess && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        if (responseData['data'] != null) {
          return SupportTicket.fromJson(responseData['data'] as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      print('Error getting ticket by ID: $e');
      return null;
    }
  }
}
