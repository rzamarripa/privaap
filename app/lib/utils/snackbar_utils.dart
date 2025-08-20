import 'package:flutter/material.dart';

class SnackbarUtils {
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFF44336),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static void showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2196F3),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static void showWarningSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF9800),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static String createErrorTitle(String field) {
    switch (field.toLowerCase()) {
      case 'email':
        return 'Error en el email';
      case 'password':
        return 'Error en la contraseña';
      case 'phone':
        return 'Error en el teléfono';
      case 'name':
        return 'Error en el nombre';
      case 'validation':
        return 'Error de validación';
      case 'server':
        return 'Error del servidor';
      case 'connection':
        return 'Error de conexión';
      case 'default':
        return 'Error';
      default:
        return 'Error en el campo';
    }
  }

  static String createValidationErrorMessage(String field, String value) {
    switch (field.toLowerCase()) {
      case 'email':
        if (value.isEmpty) {
          return 'El email es obligatorio';
        }
        return 'El formato del email no es válido';
      case 'password':
        if (value.isEmpty) {
          return 'La contraseña es obligatoria';
        }
        if (value.length < 6) {
          return 'La contraseña debe tener al menos 6 caracteres';
        }
        return 'La contraseña no cumple con los requisitos';
      case 'phone':
        if (value.isEmpty) {
          return 'El teléfono es obligatorio';
        }
        return 'El formato del teléfono no es válido';
      case 'name':
        if (value.isEmpty) {
          return 'El nombre es obligatorio';
        }
        return 'El nombre debe tener al menos 2 caracteres';
      default:
        return 'El campo no es válido';
    }
  }
}
