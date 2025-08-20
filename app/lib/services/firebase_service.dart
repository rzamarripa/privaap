import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Inicializa Firebase con configuración oficial de FlutterFire CLI
  Future<bool> initialize() async {
    if (_isInitialized) {
      debugPrint('✅ Firebase ya está inicializado');
      return true;
    }

    debugPrint('🔄 Iniciando inicialización de Firebase...');

    try {
      // Intentar inicialización simple primero
      debugPrint('🔄 Intentando inicialización simple...');
      await Firebase.initializeApp();
      _isInitialized = true;
      debugPrint('✅ Firebase inicializado correctamente');
      return true;
    } catch (e) {
      debugPrint('❌ Error en inicialización simple: $e');

      try {
        // Intentar con configuración específica
        debugPrint('🔄 Intentando con configuración específica...');
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        _isInitialized = true;
        debugPrint('✅ Firebase inicializado con configuración específica');
        return true;
      } catch (e2) {
        debugPrint('❌ Error en inicialización con configuración: $e2');
        _isInitialized = false;
        return false;
      }
    }
  }

  /// Verifica si Firebase está disponible
  bool get isAvailable => _isInitialized;

  /// Reinicia Firebase (útil para testing)
  Future<void> reset() async {
    try {
      await Firebase.app().delete();
      _isInitialized = false;
      debugPrint('🔄 Firebase reiniciado');
    } catch (e) {
      debugPrint('❌ Error al reiniciar Firebase: $e');
    }
  }
}
