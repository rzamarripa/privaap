# 🔒 CONFIGURACIÓN DE SEGURIDAD - PRIVAAP

## ⚠️ IMPORTANTE: CONFIGURACIÓN DE CREDENCIALES

Este proyecto requiere configuración de credenciales que **NO** están incluidas en el repositorio por seguridad.

## 📋 ARCHIVOS REQUERIDOS

### 1. Variables de Entorno API (`api/.env`)
```bash
cp api/.env.example api/.env
```
Luego edita `api/.env` con tus credenciales reales.

### 2. Firebase Android (`app/android/app/google-services.json`)
- Ve a [Firebase Console](https://console.firebase.google.com/)
- Selecciona tu proyecto
- Ve a Configuración del proyecto > Aplicaciones
- Descarga `google-services.json` para Android
- Colócalo en `app/android/app/google-services.json`

### 3. Firebase iOS (`app/ios/Runner/GoogleService-Info.plist`)
- Ve a [Firebase Console](https://console.firebase.google.com/)
- Selecciona tu proyecto
- Ve a Configuración del proyecto > Aplicaciones
- Descarga `GoogleService-Info.plist` para iOS
- Colócalo en `app/ios/Runner/GoogleService-Info.plist`

## 🔐 ROTACIÓN DE CLAVES COMPROMETIDAS

Si tus claves fueron expuestas públicamente:

### Google API Keys
1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Ve a APIs y servicios > Credenciales
3. Encuentra las claves comprometidas
4. Haz clic en "Regenerar clave"
5. Actualiza tus archivos de configuración

### Email Password
1. Ve a tu configuración de Gmail
2. Genera una nueva contraseña de aplicación
3. Actualiza el archivo `.env`

### JWT Secret
1. Genera una nueva clave segura:
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```
2. Actualiza `JWT_SECRET` en `.env`

## ⚡ COMANDOS RÁPIDOS

```bash
# Verificar que los archivos están ignorados
git status

# Los siguientes archivos NO deben aparecer:
# - api/.env
# - app/android/app/google-services.json
# - app/ios/Runner/GoogleService-Info.plist
```

## 🚨 EN CASO DE EXPOSICIÓN

Si accidentalmente commiteaste credenciales:

1. **Cambiar todas las credenciales inmediatamente**
2. **Limpiar historial de Git:**
```bash
git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch api/.env' --prune-empty --tag-name-filter cat -- --all
```
3. **Forzar push:**
```bash
git push origin --force --all
```

## 📞 CONTACTO

En caso de emergencia de seguridad, contacta inmediatamente al administrador del proyecto.