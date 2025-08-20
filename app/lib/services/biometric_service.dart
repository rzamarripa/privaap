import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static const String _biometricEnabledKey = 'biometric_auth_enabled';
  static const String _biometricTypeKey = 'biometric_type';

  /// Verifica si la autenticación biométrica está disponible en el dispositivo
  Future<bool> isBiometricAvailable() async {
    try {
      // Intentar obtener biometrías disponibles primero
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      print('🔍 DEBUG BiometricService:');
      print('  - Biometrías disponibles: $availableBiometrics');
      print('  - Cantidad de biometrías: ${availableBiometrics.length}');

      // Si hay biometrías disponibles, el dispositivo las soporta
      if (availableBiometrics.isNotEmpty) {
        print('  - Dispositivo soporta biometría: ✅');
        return true;
      }

      // Fallback a los métodos originales
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      print('  - canCheckBiometrics: $isAvailable');
      print('  - isDeviceSupported: $isDeviceSupported');
      print('  - Resultado final: ${isAvailable && isDeviceSupported}');

      return isAvailable && isDeviceSupported;
    } on PlatformException catch (e) {
      print('❌ Error checking biometric availability: $e');
      return false;
    }
  }

  /// Obtiene los tipos de autenticación biométrica disponibles
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      print('🔍 DEBUG getAvailableBiometrics:');
      print('  - Tipos disponibles: $availableBiometrics');
      print('  - Cantidad: ${availableBiometrics.length}');

      return availableBiometrics;
    } on PlatformException catch (e) {
      print('❌ Error getting available biometrics: $e');
      return [];
    }
  }

  /// Obtiene el tipo de autenticación biométrica más apropiado para el dispositivo
  Future<String> getBiometricType() async {
    try {
      final availableBiometrics = await getAvailableBiometrics();

      print('🔍 DEBUG getBiometricType:');
      print('  - Biometrics disponibles: $availableBiometrics');

      if (availableBiometrics.contains(BiometricType.face)) {
        print('  - Tipo detectado: Face ID');
        return 'Face ID';
      } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
        print('  - Tipo detectado: Touch ID');
        return 'Touch ID';
      } else if (availableBiometrics.contains(BiometricType.iris)) {
        print('  - Tipo detectado: Iris');
        return 'Iris';
      } else {
        print('  - Tipo detectado: Biométrica (genérico)');
        return 'Biométrica';
      }
    } on PlatformException catch (e) {
      print('❌ Error getting biometric type: $e');
      return 'Biométrica';
    }
  }

  /// Verifica si la autenticación biométrica está habilitada
  Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_biometricEnabledKey) ?? false;
    } catch (e) {
      print('Error checking if biometric is enabled: $e');
      return false;
    }
  }

  /// Habilita o deshabilita la autenticación biométrica
  Future<bool> setBiometricEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, enabled);

      if (enabled) {
        // Guardar el tipo de autenticación biométrica
        final biometricType = await getBiometricType();
        await prefs.setString(_biometricTypeKey, biometricType);
      }

      return true;
    } catch (e) {
      print('Error setting biometric enabled: $e');
      return false;
    }
  }

  /// Obtiene el tipo de autenticación biométrica guardado
  Future<String> getSavedBiometricType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_biometricTypeKey) ?? 'Biométrica';
    } catch (e) {
      print('Error getting saved biometric type: $e');
      return 'Biométrica';
    }
  }

  /// Autentica al usuario usando biometría
  Future<bool> authenticate() async {
    try {
      final result = await _localAuth.authenticate(
        localizedReason: 'Autentica tu identidad para acceder a la aplicación',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      return result;
    } on PlatformException catch (e) {
      print('Error during biometric authentication: $e');
      return false;
    }
  }

  /// Configura la autenticación biométrica inicial
  Future<bool> setupBiometric() async {
    try {
      // Verificar disponibilidad
      if (!await isBiometricAvailable()) {
        return false;
      }

      // Realizar autenticación de prueba
      final isAuthenticated = await authenticate();

      if (isAuthenticated) {
        // Habilitar la autenticación biométrica
        await setBiometricEnabled(true);
        return true;
      }

      return false;
    } catch (e) {
      print('Error setting up biometric: $e');
      return false;
    }
  }

  /// Desactiva la autenticación biométrica
  Future<bool> disableBiometric() async {
    try {
      await setBiometricEnabled(false);
      return true;
    } catch (e) {
      print('❌ Error disabling biometric: $e');
      return false;
    }
  }

  /// Método de diagnóstico completo para debug
  Future<Map<String, dynamic>> getDiagnosticInfo() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final availableBiometrics = await getAvailableBiometrics();
      final biometricType = await getBiometricType();

      return {
        'canCheckBiometrics': isAvailable,
        'isDeviceSupported': isDeviceSupported,
        'availableBiometrics': availableBiometrics.map((e) => e.toString()).toList(),
        'biometricType': biometricType,
        'isAvailable': isAvailable && isDeviceSupported,
      };
    } catch (e) {
      print('❌ Error getting diagnostic info: $e');
      return {
        'error': e.toString(),
        'isAvailable': false,
      };
    }
  }
}
