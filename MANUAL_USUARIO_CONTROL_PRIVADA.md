# 📚 MANUAL DE USUARIO - SISTEMA CONTROL PRIVADA

## 📋 TABLA DE CONTENIDOS

1. [Introducción](#introducción)
2. [Requisitos del Sistema](#requisitos-del-sistema)
3. [Roles y Permisos](#roles-y-permisos)
4. [Módulos del Sistema](#módulos-del-sistema)
5. [Guía de Uso por Rol](#guía-de-uso-por-rol)
6. [Preguntas Frecuentes](#preguntas-frecuentes)
7. [Soporte Técnico](#soporte-técnico)

---

## 1. INTRODUCCIÓN

### 📱 ¿Qué es Control Privada?

**Control Privada** es un sistema integral de gestión para comunidades residenciales y privadas que permite administrar de manera eficiente:

- 🏠 **Registro y control de casas/unidades habitacionales**
- 💰 **Gestión de mensualidades y pagos**
- 👥 **Administración de residentes**
- 📊 **Control de gastos comunitarios**
- 📝 **Encuestas y comunicación**
- 📰 **Blog de noticias y avisos**
- 🎯 **Propuestas de mejora**
- 🔐 **Autenticación biométrica**

### 🎯 Objetivo del Sistema

Facilitar la administración transparente y eficiente de comunidades residenciales, mejorando la comunicación entre administradores y residentes, y automatizando procesos de cobro y control financiero.

---

## 2. REQUISITOS DEL SISTEMA

### 📱 Dispositivos Móviles

#### Android
- **Versión mínima**: Android 5.0 (API 21)
- **Versión recomendada**: Android 8.0 o superior
- **RAM mínima**: 2 GB
- **Almacenamiento**: 100 MB disponibles
- **Conexión a Internet**: Requerida

#### iOS
- **Versión mínima**: iOS 11.0
- **Dispositivos compatibles**: iPhone 6s o superior
- **Almacenamiento**: 100 MB disponibles
- **Conexión a Internet**: Requerida

### 🌐 Navegador Web (Panel Administrativo)
- Chrome 90+
- Safari 14+
- Firefox 88+
- Edge 90+

---

## 3. ROLES Y PERMISOS

### 👑 Super Administrador

**Descripción**: Control total del sistema multi-privada

**Permisos exclusivos**:
- ✅ Crear nuevas privadas/comunidades
- ✅ Asignar administradores a privadas
- ✅ Ver estadísticas globales del sistema
- ✅ Gestionar tickets de soporte de todas las privadas
- ✅ Acceso completo a todas las funcionalidades
- ✅ Configuración global del sistema
- ✅ Respaldo y restauración de datos

### 🏢 Administrador de Privada

**Descripción**: Gestión completa de una privada específica

**Permisos**:
- ✅ Registrar y gestionar casas
- ✅ Crear y gestionar mensualidades
- ✅ Registrar pagos y cancelaciones
- ✅ Administrar residentes de su privada
- ✅ Gestionar gastos comunitarios
- ✅ Crear encuestas y publicaciones
- ✅ Ver reportes financieros
- ✅ Aprobar propuestas de mejora
- ❌ No puede crear nuevas privadas
- ❌ No puede modificar configuración global

### 🏠 Residente

**Descripción**: Usuario final del sistema

**Permisos**:
- ✅ Ver estado de sus mensualidades
- ✅ Ver historial de pagos
- ✅ Participar en encuestas
- ✅ Leer publicaciones del blog
- ✅ Enviar propuestas de mejora
- ✅ Contactar soporte
- ✅ Ver gastos comunitarios
- ❌ No puede registrar pagos
- ❌ No puede crear contenido administrativo
- ❌ No puede ver información de otros residentes

---

## 4. MÓDULOS DEL SISTEMA

### 🔐 4.1 AUTENTICACIÓN Y SEGURIDAD

#### Registro de Usuario
1. **Ingreso de datos**:
   - 📱 Número de teléfono (10 dígitos)
   - 👤 Nombre completo
   - 📧 Correo electrónico
   - 🔑 Contraseña (mínimo 6 caracteres)
   - 🏠 Selección de privada (si aplica)

2. **Verificación**:
   - Validación de número único
   - Confirmación por correo electrónico

#### Inicio de Sesión
- **Métodos disponibles**:
  - 📱 Teléfono + Contraseña
  - 📧 Correo + Contraseña
  - 🔐 Autenticación biométrica (huella/Face ID)

#### Seguridad Adicional
- 🔄 Recuperación de contraseña por correo
- 🔐 Encriptación de datos sensibles
- ⏰ Sesiones con tiempo de expiración
- 📝 Registro de actividad

### 🏘️ 4.2 GESTIÓN DE PRIVADAS

#### Crear Privada (Solo Super Admin)
**Datos requeridos**:
- 📝 Nombre de la privada
- 📍 Dirección completa
- 📱 Teléfono de contacto
- 💰 Cuota mensual base
- 🏠 Número de casas/unidades
- 👤 Administrador asignado

#### Panel de Control de Privada
**Información visible**:
- 📊 Total de casas registradas
- 👥 Número de residentes activos
- 💰 Estado financiero general
- 📈 Gráficas de ingresos/egresos
- 🔔 Notificaciones pendientes

### 🏠 4.3 GESTIÓN DE CASAS

#### Registro de Casa
**Información requerida**:
- 🏠 Número/Identificador de casa
- 👤 Propietario/Inquilino asignado
- 💰 Cuota mensual específica
- 📱 Teléfono de contacto
- 📝 Notas adicionales

#### Estados de Casa
- ✅ **Activa**: Con residente asignado
- ⏸️ **Vacante**: Sin residente
- 🔧 **En mantenimiento**: Temporalmente inhabitable
- ❌ **Inactiva**: No disponible

### 💰 4.4 SISTEMA DE MENSUALIDADES Y PAGOS

#### Creación de Mensualidades

##### Mensualidad Individual
1. Seleccionar casa específica
2. Definir mes y año
3. Establecer monto
4. Fecha límite de pago
5. Agregar notas (opcional)

##### Mensualidades Masivas
1. Seleccionar múltiples casas o todas
2. Definir periodo (mes/año)
3. Aplicar cuota base o personalizada
4. Generar todas simultáneamente

#### Estados de Mensualidad
- 🔴 **Pendiente**: Sin pagos registrados
- 🟡 **Abonado**: Pagos parciales realizados
- 🟢 **Pagado**: Totalidad cubierta
- ⚫ **Cancelado**: Anulado por administrador

#### Registro de Pagos

##### Proceso de Pago
1. **Selección de mensualidad**
2. **Ingreso de datos**:
   - 💵 Monto del pago
   - 💳 Método de pago:
     - Efectivo
     - Transferencia bancaria
     - Tarjeta de débito/crédito
     - Cheque
     - Otro
   - 📄 Número de recibo (opcional)
   - 📝 Notas adicionales (opcional)
3. **Confirmación y registro**

##### Pagos Parciales
- ✅ Sistema permite múltiples abonos
- 📊 Seguimiento automático del saldo
- 🔄 Actualización de estado automática
- 📜 Historial detallado de cada abono

#### Cancelación de Pagos
**Requisitos**:
- Solo administradores pueden cancelar
- Razón obligatoria de cancelación
- Registro de auditoría automático
- Recálculo automático de totales

#### Visualización de Pagos

##### Vista de Administrador
- 📋 Lista completa de mensualidades
- 🔍 Filtros por:
  - Estado (pendiente/abonado/pagado)
  - Casa
  - Mes/Año
  - Rango de fechas
- 📊 Resumen financiero global
- 💾 Exportación a Excel/PDF

##### Vista de Residente
- 🏠 Solo sus mensualidades
- 📜 Historial de pagos realizados
- 💰 Saldo pendiente actual
- 📅 Próximos vencimientos

### 📊 4.5 GESTIÓN DE GASTOS

#### Registro de Gastos
**Campos requeridos**:
- 📝 Descripción del gasto
- 💰 Monto
- 📅 Fecha del gasto
- 📂 Categoría:
  - Mantenimiento
  - Servicios
  - Seguridad
  - Jardinería
  - Administración
  - Otros
- 👤 Proveedor/Beneficiario
- 📄 Número de factura
- 📎 Adjuntar comprobantes (fotos/PDF)

#### Categorías de Gastos
- 🔧 **Mantenimiento**: Reparaciones y mejoras
- 💡 **Servicios**: Luz, agua, gas comunes
- 👮 **Seguridad**: Vigilancia y sistemas
- 🌳 **Jardinería**: Áreas verdes
- 📋 **Administración**: Papelería, software
- 🏗️ **Obras**: Construcciones y remodelaciones
- 🎉 **Eventos**: Festividades comunitarias
- ➕ **Otros**: Gastos no categorizados

#### Reportes de Gastos
- 📊 Gráficas por categoría
- 📈 Tendencias mensuales
- 💹 Comparativas anuales
- 📑 Detalle por proveedor

### 📝 4.6 ENCUESTAS Y VOTACIONES

#### Crear Encuesta
**Configuración**:
- 📋 Título y descripción
- ❓ Tipo de preguntas:
  - Opción múltiple
  - Sí/No
  - Escala de satisfacción
  - Respuesta abierta
- 📅 Periodo de vigencia
- 👥 Audiencia (todos/específicos)
- 🔒 Votación anónima/identificada

#### Participación
- 📱 Notificación automática
- ✅ Una respuesta por residente
- 📊 Resultados en tiempo real
- 📈 Gráficas automáticas

### 📰 4.7 BLOG Y COMUNICADOS

#### Publicaciones
**Tipos de contenido**:
- 📢 **Avisos importantes**: Urgentes, destacados
- 📅 **Eventos**: Reuniones, festividades
- 🔧 **Mantenimiento**: Trabajos programados
- 📋 **Normativas**: Reglamentos, políticas
- 🎉 **Sociales**: Celebraciones, logros

#### Características
- 📸 Soporte multimedia (imágenes)
- 💬 Comentarios de residentes
- 👍 Reacciones (me gusta)
- 🔔 Notificaciones push
- 📌 Publicaciones fijadas

### 🎯 4.8 PROPUESTAS DE MEJORA

#### Envío de Propuestas
**Proceso**:
1. Descripción detallada
2. Categoría de mejora
3. Presupuesto estimado
4. Beneficios esperados
5. Archivos adjuntos

#### Estados de Propuesta
- 📝 **Enviada**: Pendiente de revisión
- 👀 **En revisión**: Siendo evaluada
- ✅ **Aprobada**: Aceptada para implementación
- ❌ **Rechazada**: No procede
- 🚧 **En proceso**: En implementación

### 🆘 4.9 SOPORTE Y AYUDA

#### Sistema de Tickets
**Creación de ticket**:
- 📝 Asunto claro y específico
- 📂 Categoría del problema
- 🔴 Prioridad (baja/media/alta)
- 📎 Capturas de pantalla
- 📱 Información de contacto

#### Categorías de Soporte
- 🐛 Errores técnicos
- ❓ Dudas de uso
- 💡 Sugerencias
- 💰 Problemas de pago
- 🔐 Acceso y seguridad

---

## 5. GUÍA DE USO POR ROL

### 👑 SUPER ADMINISTRADOR - FLUJO DE TRABAJO

#### Configuración Inicial
1. **Acceder al sistema**
   - Iniciar sesión con credenciales de super admin
   - Configurar perfil y preferencias

2. **Crear primera privada**
   - Ir a "Gestión de Privadas"
   - Clic en "Nueva Privada"
   - Completar formulario
   - Asignar administrador

3. **Gestión de administradores**
   - Revisar solicitudes de registro
   - Aprobar/rechazar administradores
   - Asignar permisos específicos

4. **Monitoreo del sistema**
   - Dashboard global
   - Métricas de todas las privadas
   - Alertas y notificaciones

#### Tareas Diarias
- ✅ Revisar tickets de soporte
- ✅ Aprobar nuevos administradores
- ✅ Monitorear actividad del sistema
- ✅ Generar reportes ejecutivos

### 🏢 ADMINISTRADOR - FLUJO DE TRABAJO

#### Configuración de Privada

1. **Registro de casas**
   ```
   Menú → Casas → Agregar Casa
   - Ingresar número de casa
   - Asignar residente (opcional)
   - Definir cuota mensual
   - Guardar
   ```

2. **Creación de mensualidades**
   ```
   Menú → Mensualidades → Crear Mensualidad
   - Opción 1: Individual
     • Seleccionar casa
     • Definir mes y monto
   - Opción 2: Masiva
     • Seleccionar todas las casas
     • Aplicar cuota base
   ```

3. **Registro de pagos**
   ```
   Mensualidades → Seleccionar casa → Registrar Pago
   - Ingresar monto
   - Método de pago
   - Número de recibo
   - Confirmar
   ```

#### Gestión Financiera Diaria

##### Mañana (9:00 - 12:00)
1. **Revisar pagos pendientes**
   - Filtrar mensualidades vencidas
   - Enviar recordatorios

2. **Procesar nuevos pagos**
   - Verificar transferencias
   - Registrar pagos en efectivo
   - Actualizar estados

##### Tarde (14:00 - 18:00)
1. **Gestión de gastos**
   - Registrar gastos del día
   - Adjuntar comprobantes
   - Categorizar correctamente

2. **Comunicación**
   - Publicar avisos importantes
   - Responder consultas
   - Crear encuestas si es necesario

#### Cierre Mensual
1. **Generar reportes**
   - Balance de ingresos/egresos
   - Lista de morosos
   - Estadísticas de pago

2. **Crear mensualidades siguiente mes**
   - Generación masiva
   - Ajustes por inflación si aplica
   - Notificar a residentes

### 🏠 RESIDENTE - GUÍA DE USO

#### Primer Acceso

1. **Registro en la app**
   ```
   1. Descargar app "Control Privada"
   2. Tap en "Registrarse"
   3. Ingresar datos personales
   4. Seleccionar su privada
   5. Esperar aprobación del administrador
   ```

2. **Configuración de perfil**
   - Agregar foto (opcional)
   - Verificar datos de contacto
   - Activar notificaciones
   - Configurar biometría

#### Consulta de Mensualidades

1. **Ver estado de cuenta**
   ```
   Menú → Mensualidades
   - Verde ✅: Pagado
   - Amarillo 🟡: Pago parcial
   - Rojo 🔴: Pendiente
   ```

2. **Ver detalles de pago**
   - Tap en mensualidad
   - Ver historial de abonos
   - Descargar recibos

#### Funciones Disponibles

##### Comunicación
- **Ver avisos**: Panel principal
- **Participar en encuestas**: Notificación → Responder
- **Enviar propuestas**: Menú → Propuestas → Nueva

##### Consultas
- **Gastos comunitarios**: Menú → Gastos
- **Eventos próximos**: Blog → Categoría Eventos
- **Reglamento**: Menú → Documentos

##### Soporte
- **Reportar problema**: Menú → Soporte → Nuevo Ticket
- **Ver tickets**: Menú → Mis Tickets
- **FAQ**: Menú → Ayuda

---

## 6. PREGUNTAS FRECUENTES

### 🔐 Acceso y Seguridad

**P: Olvidé mi contraseña, ¿qué hago?**
R: En la pantalla de inicio, toca "¿Olvidaste tu contraseña?", ingresa tu correo y recibirás instrucciones.

**P: ¿Cómo activo la autenticación biométrica?**
R: Menú → Configuración → Seguridad → Activar Biometría

**P: ¿Puedo tener múltiples cuentas?**
R: No, cada número de teléfono está asociado a una única cuenta.

### 💰 Pagos y Mensualidades

**P: ¿Puedo hacer pagos parciales?**
R: Sí, el sistema permite múltiples abonos hasta completar el total.

**P: ¿Cómo obtengo un recibo de pago?**
R: Mensualidades → Seleccionar pago → Descargar recibo

**P: Mi pago no se refleja, ¿qué hago?**
R: Contacta al administrador con tu comprobante de pago.

**P: ¿Puedo pagar meses adelantados?**
R: Sí, consulta con tu administrador para generar las mensualidades futuras.

### 📱 Problemas Técnicos

**P: La app no abre/se cierra sola**
R: 
1. Reinicia tu dispositivo
2. Verifica conexión a internet
3. Actualiza la app
4. Reinstala si persiste

**P: No recibo notificaciones**
R: Configuración del teléfono → Notificaciones → Control Privada → Activar

**P: Las imágenes no cargan**
R: Verifica tu conexión a internet y espacio disponible en el dispositivo.

### 👥 Gestión de Usuarios

**P: ¿Cómo cambio de casa dentro de la privada?**
R: Solicita al administrador actualizar tu información.

**P: ¿Puedo ver información de otros residentes?**
R: No, por privacidad solo puedes ver tu propia información.

**P: ¿Cómo actualizo mis datos de contacto?**
R: Menú → Perfil → Editar → Guardar cambios

### 📊 Reportes y Consultas

**P: ¿Dónde veo los gastos de la privada?**
R: Menú → Gastos → Puedes filtrar por mes y categoría

**P: ¿Cómo descargo mi historial de pagos?**
R: Mensualidades → Opciones → Exportar historial

**P: ¿Puedo ver estados de cuenta anteriores?**
R: Sí, en Mensualidades puedes navegar por meses anteriores.

---

## 7. SOPORTE TÉCNICO

### 📞 Canales de Atención

#### Soporte en la App
- **Horario**: 24/7 mediante tickets
- **Respuesta**: 24-48 horas hábiles
- **Proceso**: Menú → Soporte → Crear Ticket

#### Contacto Directo
- 📧 **Email**: soporte@controlprivada.com
- 📱 **WhatsApp**: +52 XXX XXX XXXX
- 🕐 **Horario**: Lunes a Viernes 9:00 - 18:00

#### Soporte de Emergencia
Para problemas críticos que afecten la operación:
- 🆘 **Línea directa**: +52 XXX XXX XXXX
- ⏰ **Disponible**: 24/7
- 🔴 **Solo para**: Fallas masivas del sistema

### 🐛 Reporte de Errores

#### Información necesaria:
1. **Descripción del problema**
   - ¿Qué intentabas hacer?
   - ¿Qué mensaje de error apareció?
   - ¿Cuándo ocurrió?

2. **Datos del dispositivo**
   - Modelo del teléfono
   - Sistema operativo y versión
   - Versión de la app

3. **Evidencia**
   - Capturas de pantalla
   - Videos del error (si aplica)
   - Pasos para reproducir

### 💡 Sugerencias y Mejoras

Valoramos tu retroalimentación para mejorar el sistema:

**Enviar sugerencia**:
1. Menú → Soporte
2. Categoría: Sugerencia
3. Describe tu idea detalladamente
4. Explica los beneficios esperados

### 📚 Recursos Adicionales

#### Tutoriales en Video
- 🎥 YouTube: Canal Control Privada
- 📺 Playlist por rol de usuario
- 🆕 Actualizaciones semanales

#### Documentación
- 📖 Manual PDF descargable
- 🌐 Wiki en línea
- 📝 Guías rápidas por función

#### Comunidad
- 💬 Grupo de Facebook
- 📱 Canal de Telegram
- 🐦 Twitter: @ControlPrivada

---

## 📋 ANEXOS

### A. Glosario de Términos

- **Mensualidad**: Cuota mensual que cada casa debe pagar
- **Abono**: Pago parcial de una mensualidad
- **Privada**: Comunidad residencial cerrada
- **Dashboard**: Panel de control principal
- **Ticket**: Solicitud de soporte
- **Biometría**: Huella digital o reconocimiento facial

### B. Códigos de Error Comunes

| Código | Descripción | Solución |
|--------|-------------|----------|
| E001 | Sin conexión | Verificar internet |
| E002 | Sesión expirada | Iniciar sesión nuevamente |
| E003 | Permisos insuficientes | Contactar administrador |
| E004 | Datos inválidos | Revisar información ingresada |
| E005 | Servidor no disponible | Intentar más tarde |

### C. Atajos de Teclado (Web)

- `Ctrl + N`: Nueva mensualidad
- `Ctrl + P`: Registrar pago
- `Ctrl + E`: Exportar reporte
- `Ctrl + F`: Buscar
- `Ctrl + R`: Refrescar datos

---

## 📝 NOTAS DE VERSIÓN

### Versión 2.0.0 (Actual)
- ✅ Sistema de pagos parciales
- ✅ Cancelación de pagos con auditoría
- ✅ Autenticación biométrica
- ✅ Exportación de reportes
- ✅ Notificaciones push mejoradas
- ✅ Interfaz rediseñada

### Próximas Funcionalidades
- 🔄 Pagos en línea integrados
- 📊 Dashboard personalizable
- 📱 Widget para escritorio
- 🌍 Soporte multi-idioma
- 🤖 Chatbot de soporte

---

## ✍️ CONTROL DE CAMBIOS

| Fecha | Versión | Descripción | Autor |
|-------|---------|-------------|-------|
| 2024-01-20 | 1.0 | Creación inicial del manual | Sistema |
| 2024-01-20 | 1.1 | Agregadas FAQ y soporte | Sistema |
| 2024-01-20 | 2.0 | Manual completo actualizado | Sistema |

---

## 📄 LICENCIA Y TÉRMINOS

© 2024 Control Privada. Todos los derechos reservados.

Este manual es propiedad intelectual de Control Privada y está protegido por las leyes de derechos de autor. Su reproducción total o parcial sin autorización está prohibida.

---

**Última actualización**: Enero 2024  
**Versión del manual**: 2.0  
**Compatible con app versión**: 2.0.0+

---

## 🙏 AGRADECIMIENTOS

Agradecemos a todos los usuarios, administradores y desarrolladores que han contribuido a mejorar Control Privada con sus sugerencias y retroalimentación.

Para más información, visita: [www.controlprivada.com](https://www.controlprivada.com)

---

**FIN DEL MANUAL**