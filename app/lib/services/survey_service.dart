import 'package:flutter/material.dart';
import '../models/survey_model.dart';
import 'api_service.dart';

class SurveyService extends ChangeNotifier {
  List<Survey> _surveys = [];
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  List<Survey> get surveys => [..._surveys];
  List<Survey> get activeSurveys =>
      _surveys.where((s) => s.isActive && (s.expiresAt == null || s.expiresAt!.isAfter(DateTime.now()))).toList();
  List<Survey> get expiredSurveys {
    final expired =
        _surveys.where((s) => !s.isActive || (s.expiresAt != null && s.expiresAt!.isBefore(DateTime.now()))).toList();
    print('DEBUG: Total encuestas: ${_surveys.length}');
    print('DEBUG: Encuestas activas: ${_surveys.where((s) => s.isActive).length}');
    print('DEBUG: Encuestas inactivas: ${_surveys.where((s) => !s.isActive).length}');
    print(
        'DEBUG: Encuestas expiradas por fecha: ${_surveys.where((s) => s.expiresAt != null && s.expiresAt!.isBefore(DateTime.now())).length}');
    print('DEBUG: Encuestas finalizadas: ${expired.length}');
    return expired;
  }

  bool get isLoading => _isLoading;

  List<Survey> votedSurveys(String userId) {
    return _surveys.where((s) => s.hasUserVoted(userId)).toList();
  }

  // Cargar encuestas desde la API
  Future<void> loadSurveys() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get('/surveys');

      if (response.isSuccess && response.data != null) {
        // response.data ya es la lista extraída por ApiService
        final List<dynamic> surveysData = response.data as List<dynamic>;
        _surveys = surveysData.map((data) => Survey.fromJson(data as Map<String, dynamic>)).toList();

        // Ordenar por fecha de creación (más recientes primero)
        _surveys.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else {
        print('Error loading surveys: ${response.error}');
      }
    } catch (e) {
      // Mantener datos locales en caso de error
      print('Error loading surveys: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Survey? getSurveyById(String id) {
    try {
      return _surveys.firstWhere((survey) => survey.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> createSurvey(Survey survey) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('/surveys', body: survey.toCreateJson());

      if (response.isSuccess && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        final surveyData = responseData['data'] ?? responseData;
        final newSurvey = Survey.fromJson(surveyData as Map<String, dynamic>);
        _surveys.insert(0, newSurvey);

        _isLoading = false;
        notifyListeners();
        return {'success': true, 'message': 'Encuesta creada exitosamente'};
      } else {
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'message': response.error ?? 'Error al crear la encuesta'};
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> updateSurvey(Survey survey) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.put('/surveys/${survey.id}', body: survey.toUpdateJson());

      if (response.isSuccess && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        final surveyData = responseData['data'] ?? responseData;
        final updatedSurvey = Survey.fromJson(surveyData as Map<String, dynamic>);

        // Actualizar la encuesta en la lista local
        final index = _surveys.indexWhere((s) => s.id == survey.id);
        if (index != -1) {
          _surveys[index] = updatedSurvey;
        }

        _isLoading = false;
        notifyListeners();
        return {'success': true, 'message': 'Encuesta actualizada exitosamente', 'data': updatedSurvey};
      } else {
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'message': response.error ?? 'Error al actualizar la encuesta'};
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<bool> voteSurvey({
    required String surveyId,
    required String userId,
    required List<String> selectedOptions,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post('/surveys/$surveyId/vote', body: {
        'userId': userId,
        'selectedOptions': selectedOptions,
      });

      if (response.isSuccess && response.data != null) {
        // No actualizar la encuesta local con la respuesta de voto
        // La API solo devuelve confirmación, no la encuesta actualizada
        // Recargar las encuestas para obtener los datos actualizados
        await loadSurveys();

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

  Future<bool> closeSurvey(String surveyId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.patch('/surveys/$surveyId/close');

      if (response.isSuccess) {
        final index = _surveys.indexWhere((s) => s.id == surveyId);
        if (index != -1) {
          _surveys[index] = Survey(
            id: _surveys[index].id,
            question: _surveys[index].question,
            options: _surveys[index].options,
            createdAt: _surveys[index].createdAt,
            expiresAt: _surveys[index].expiresAt,
            createdBy: _surveys[index].createdBy,
            allowMultipleAnswers: _surveys[index].allowMultipleAnswers,
            isAnonymous: _surveys[index].isAnonymous,
            votes: _surveys[index].votes,
            isActive: false,
          );
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

  Future<bool> deleteSurvey(String surveyId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.delete('/surveys/$surveyId');

      if (response.isSuccess) {
        _surveys.removeWhere((s) => s.id == surveyId);

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

  // Refresh data from API
  Future<void> refresh() async {
    try {
      await loadSurveys();
    } catch (e) {
      print('Error refreshing surveys: $e');
    }
  }
}
