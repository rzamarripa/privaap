import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';

class FirebaseStorageService {
  static final FirebaseStorageService _instance = FirebaseStorageService._internal();
  factory FirebaseStorageService() => _instance;
  FirebaseStorageService._internal();

  FirebaseStorage? _storage;
  final FirebaseService _firebaseService = FirebaseService();

  FirebaseStorage get storage {
    if (_storage == null) {
      if (!_firebaseService.isAvailable) {
        throw Exception('Firebase no está inicializado. Llama a FirebaseService.initialize() primero.');
      }
      _storage = FirebaseStorage.instance;
    }
    return _storage!;
  }

  /// Sube una imagen a Firebase Storage y retorna la URL de descarga
  Future<String> uploadImage(File imageFile, String folder, String fileName) async {
    try {
      // Intentar inicializar Firebase si no está disponible
      if (!_firebaseService.isAvailable) {
        debugPrint('🔄 Intentando inicializar Firebase...');
        final initialized = await _firebaseService.initialize();
        if (!initialized) {
          debugPrint('❌ Firebase no se pudo inicializar. No hay fallback disponible.');
          throw Exception('Firebase no está disponible. No se pueden subir imágenes en este momento.');
        }
        debugPrint('✅ Firebase inicializado correctamente');
      }

      debugPrint('🔍 DEBUG FirebaseStorage - Subiendo imagen: $fileName a carpeta: $folder');
      debugPrint('🔍 DEBUG FirebaseStorage - Firebase disponible: ${_firebaseService.isAvailable}');

      // Crear referencia al archivo en Firebase Storage
      final storageRef = storage.ref().child('$folder/$fileName');
      debugPrint('🔍 DEBUG FirebaseStorage - Referencia creada: $folder/$fileName');

      // Subir el archivo
      debugPrint('🔍 DEBUG FirebaseStorage - Iniciando subida...');
      final uploadTask = storageRef.putFile(imageFile);

      // Esperar a que termine la subida
      debugPrint('🔍 DEBUG FirebaseStorage - Esperando finalización...');
      final snapshot = await uploadTask;
      debugPrint('🔍 DEBUG FirebaseStorage - Subida completada, obteniendo URL...');

      // Obtener la URL de descarga
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('✅ DEBUG FirebaseStorage - Imagen subida exitosamente: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      debugPrint('❌ ERROR FirebaseStorage - Error al subir imagen: $e');
      debugPrint('❌ No hay fallback disponible. Firebase es requerido.');
      // Lanzar excepción clara para que el usuario sepa que no se pudo subir
      throw Exception('Error al subir imagen a Firebase: $e');
    }
  }

  /// Sube múltiples imágenes y retorna las URLs
  Future<List<String>> uploadMultipleImages(List<File> imageFiles, String folder) async {
    try {
      debugPrint('🔍 DEBUG FirebaseStorage - Subiendo ${imageFiles.length} imágenes a carpeta: $folder');

      final List<String> urls = [];

      for (int i = 0; i < imageFiles.length; i++) {
        try {
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          final url = await uploadImage(imageFiles[i], folder, fileName);
          urls.add(url);
          debugPrint('✅ DEBUG FirebaseStorage - Imagen $i subida: $url');
        } catch (e) {
          debugPrint('❌ ERROR FirebaseStorage - Error al subir imagen $i: $e');
          // Si una imagen falla, lanzar excepción para que el usuario sepa
          throw Exception('Error al subir imagen ${i + 1}: $e');
        }
      }

      debugPrint('✅ DEBUG FirebaseStorage - ${urls.length} imágenes procesadas exitosamente');

      return urls;
    } catch (e) {
      debugPrint('❌ ERROR FirebaseStorage - Error al procesar múltiples imágenes: $e');
      // Lanzar excepción clara
      throw Exception('Error al subir imágenes a Firebase: $e');
    }
  }

  /// Elimina una imagen de Firebase Storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      // Si es una URL temporal local, no hacer nada
      if (imageUrl.startsWith('local://temp/')) {
        debugPrint('⚠️ DEBUG FirebaseStorage - URL temporal detectada, no se puede eliminar: $imageUrl');
        return;
      }

      // Verificar que Firebase esté inicializado
      if (!_firebaseService.isAvailable) {
        debugPrint('⚠️ Firebase no está disponible. No se puede eliminar imagen.');
        return;
      }

      debugPrint('🔍 DEBUG FirebaseStorage - Eliminando imagen: $imageUrl');

      // Extraer la ruta del archivo de la URL
      final uri = Uri.parse(imageUrl);
      final path = uri.path.split('/o/').last.split('?').first;
      final decodedPath = Uri.decodeComponent(path);

      // Crear referencia y eliminar
      final storageRef = storage.ref().child(decodedPath);
      await storageRef.delete();

      debugPrint('✅ DEBUG FirebaseStorage - Imagen eliminada exitosamente');
    } catch (e) {
      debugPrint('❌ ERROR FirebaseStorage - Error al eliminar imagen: $e');
      // No lanzar excepción, solo registrar el error
      debugPrint('⚠️ Continuando sin eliminar la imagen.');
    }
  }

  /// Genera un nombre único para el archivo
  String generateUniqueFileName(String originalName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${timestamp}_${originalName.split('/').last}';
  }
}
