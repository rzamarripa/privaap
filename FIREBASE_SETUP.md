# 🔥 Configuración de Firebase Storage

## 📋 Pasos para configurar Firebase Storage

### 1. 🚀 Crear proyecto en Firebase Console

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Crea un nuevo proyecto o usa uno existente
3. Habilita **Firebase Storage** en el proyecto

### 2. 📱 Configurar la aplicación

#### Para Android:

1. Ve a **Project Settings** > **Your apps** > **Add app** > **Android**
2. Usa el package name: `com.example.privapp`
3. Descarga el archivo `google-services.json`
4. Reemplaza el archivo en `app/android/app/google-services.json`

#### Para iOS:

1. Ve a **Project Settings** > **Your apps** > **Add app** > **iOS**
2. Usa el bundle ID: `com.example.privadaControl`
3. Descarga el archivo `GoogleService-Info.plist`
4. Reemplaza el archivo en `app/ios/Runner/GoogleService-Info.plist`

### 3. ⚙️ Actualizar configuración

#### Actualizar `app/lib/config/firebase_config.dart`:

```dart
static const FirebaseOptions androidOptions = FirebaseOptions(
  apiKey: 'TU_API_KEY_REAL',
  appId: 'TU_APP_ID_REAL',
  messagingSenderId: 'TU_SENDER_ID_REAL',
  projectId: 'TU_PROJECT_ID_REAL',
  storageBucket: 'TU_STORAGE_BUCKET_REAL',
);
```

### 4. 🔒 Configurar reglas de Storage

En Firebase Console > Storage > Rules, usa estas reglas:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Permitir lectura de archivos de soporte
    match /support-tickets/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }

    // Denegar todo lo demás
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

### 5. 🧪 Probar la integración

1. Ejecuta `flutter pub get`
2. Ejecuta `flutter run`
3. Ve a **Contactar Soporte** en la app
4. Adjunta una imagen y envía el ticket
5. Verifica que la imagen aparezca en Firebase Storage

## 📁 Estructura de archivos

```
app/
├── android/app/google-services.json          # Config Android
├── ios/Runner/GoogleService-Info.plist       # Config iOS
├── lib/
│   ├── config/
│   │   └── firebase_config.dart              # Config Flutter
│   └── services/
│       ├── firebase_storage_service.dart     # Servicio Storage
│       └── support_service.dart              # Servicio Soporte
```

## 🔧 Funcionalidades implementadas

- ✅ **Subida de imágenes individuales** a Firebase Storage
- ✅ **Subida de múltiples imágenes** en paralelo
- ✅ **Eliminación de imágenes** de Firebase Storage
- ✅ **Nombres únicos** para evitar conflictos
- ✅ **Manejo de errores** robusto
- ✅ **Logs de debug** para desarrollo

## 🎯 Uso en la aplicación

```dart
// Subir una imagen
final url = await _firebaseStorage.uploadImage(
  imageFile,
  'support-tickets',
  fileName
);

// Subir múltiples imágenes
final urls = await _firebaseStorage.uploadMultipleImages(
  imageFiles,
  'support-tickets'
);

// Eliminar imagen
await _firebaseStorage.deleteImage(imageUrl);
```

## ⚠️ Notas importantes

1. **Reemplaza las claves de ejemplo** con las reales de tu proyecto Firebase
2. **Configura las reglas de Storage** para seguridad
3. **Prueba en dispositivos reales** para verificar funcionamiento
4. **Mantén las claves seguras** y no las subas a repositorios públicos

## 🚀 Próximos pasos

- [ ] Configurar Firebase Auth para autenticación
- [ ] Implementar notificaciones push con Firebase Messaging
- [ ] Agregar analytics con Firebase Analytics
- [ ] Configurar Crashlytics para reportes de errores
