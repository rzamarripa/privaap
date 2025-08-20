# 📊 API de Mensualidades - Documentación Completa

## 🎯 **Descripción General**

La API de Mensualidades permite gestionar completamente el sistema de cobros mensuales de las comunidades privadas. Incluye funcionalidades para crear, actualizar, consultar y gestionar pagos de mensualidades.

---

## 🔐 **Autenticación**

Todas las rutas requieren autenticación mediante JWT Bearer Token:

```http
Authorization: Bearer <token>
```

---

## 📋 **Endpoints Disponibles**

### **1. Obtener Mensualidades**

#### **GET** `/api/monthly-fees`

Obtiene todas las mensualidades con filtros y paginación (solo administradores).

**Parámetros de consulta:**

- `page` (opcional): Número de página (default: 1)
- `limit` (opcional): Elementos por página (default: 20, max: 100)
- `status` (opcional): Estado de la mensualidad
- `month` (opcional): Mes en formato YYYY-MM
- `communityId` (opcional): ID de la comunidad
- `userId` (opcional): ID del usuario
- `sortBy` (opcional): Campo de ordenamiento
- `sortOrder` (opcional): Orden (asc/desc)

**Respuesta exitosa:**

```json
{
  "success": true,
  "data": {
    "monthlyFees": [...],
    "pagination": {
      "currentPage": 1,
      "totalPages": 5,
      "totalMonthlyFees": 100,
      "hasNext": true,
      "hasPrev": false
    }
  }
}
```

---

#### **GET** `/api/monthly-fees/user`

Obtiene las mensualidades del usuario autenticado.

**Parámetros de consulta:**

- `status` (opcional): Estado de la mensualidad
- `month` (opcional): Mes en formato YYYY-MM
- `communityId` (opcional): ID de la comunidad

**Respuesta exitosa:**

```json
{
  "success": true,
  "data": [...]
}
```

---

#### **GET** `/api/monthly-fees/community/:communityId`

Obtiene mensualidades de una comunidad específica (solo administradores).

**Parámetros de consulta:**

- `status` (opcional): Estado de la mensualidad
- `month` (opcional): Mes en formato YYYY-MM
- `userId` (opcional): ID del usuario

---

#### **GET** `/api/monthly-fees/:id`

Obtiene una mensualidad específica por ID.

---

### **2. Crear y Gestionar Mensualidades**

#### **POST** `/api/monthly-fees`

Crea una nueva mensualidad (solo administradores).

**Cuerpo de la petición:**

```json
{
  "communityId": "507f1f77bcf86cd799439011",
  "userId": "507f1f77bcf86cd799439012",
  "month": "2024-01",
  "amount": 1500.0,
  "dueDate": "2024-01-31T00:00:00.000Z",
  "status": "pendiente",
  "discountAmount": 0,
  "lateFeeAmount": 0
}
```

**Validaciones:**

- `communityId`: ID de MongoDB válido
- `userId`: ID de MongoDB válido
- `month`: Formato YYYY-MM
- `amount`: Número positivo
- `dueDate`: Fecha ISO válida
- `status`: Uno de: pendiente, pagado, vencido, parcial, exento

---

#### **PUT** `/api/monthly-fees/:id`

Actualiza una mensualidad existente (solo administradores).

**Campos actualizables:**

- `amount`: Monto total
- `amountPaid`: Monto pagado
- `status`: Estado
- `dueDate`: Fecha de vencimiento
- `paidDate`: Fecha de pago
- `paymentMethod`: Método de pago
- `receiptNumber`: Número de recibo
- `notes`: Notas adicionales
- `discountAmount`: Monto de descuento
- `lateFeeAmount`: Monto de penalización

---

#### **DELETE** `/api/monthly-fees/:id`

Elimina una mensualidad (solo super administradores).

**Restricciones:**

- Solo se pueden eliminar mensualidades sin pagos registrados

---

### **3. Gestión de Pagos**

#### **POST** `/api/monthly-fees/:id/payment`

Registra un pago en una mensualidad (solo administradores).

**Cuerpo de la petición:**

```json
{
  "amount": 500.0,
  "paymentMethod": "transferencia",
  "receiptNumber": "REC-001",
  "notes": "Pago parcial de enero"
}
```

**Validaciones:**

- `amount`: Número mayor a 0
- `paymentMethod`: Uno de: efectivo, transferencia, cheque, tarjeta, otro
- `receiptNumber`: Máximo 50 caracteres
- `notes`: Máximo 500 caracteres

---

### **4. Generación Masiva**

#### **POST** `/api/monthly-fees/generate`

Genera mensualidades para todos los usuarios de una comunidad en un mes específico (solo administradores).

**Cuerpo de la petición:**

```json
{
  "communityId": "507f1f77bcf86cd799439011",
  "month": "2024-02"
}
```

---

### **5. Reportes y Resúmenes**

#### **GET** `/api/monthly-fees/summary`

Obtiene resumen financiero de mensualidades (solo administradores).

**Parámetros de consulta:**

- `communityId` (opcional): ID de la comunidad
- `month` (opcional): Mes en formato YYYY-MM

**Respuesta:**

```json
{
  "success": true,
  "data": [
    {
      "_id": "pendiente",
      "count": 25,
      "totalAmount": 37500,
      "totalPaid": 0,
      "totalDiscounts": 0,
      "totalLateFees": 0
    },
    {
      "_id": "pagado",
      "count": 15,
      "totalAmount": 22500,
      "totalPaid": 22500,
      "totalDiscounts": 500,
      "totalLateFees": 0
    }
  ]
}
```

---

## 📊 **Modelo de Datos**

### **MonthlyFee Schema**

```javascript
{
  communityId: ObjectId,      // Referencia a Community
  userId: ObjectId,           // Referencia a User
  month: String,              // Formato: YYYY-MM
  amount: Number,             // Monto total
  amountPaid: Number,         // Monto pagado (default: 0)
  status: String,             // pendiente, pagado, vencido, parcial, exento
  dueDate: Date,              // Fecha de vencimiento
  paidDate: Date,             // Fecha de pago (opcional)
  paymentMethod: String,      // efectivo, transferencia, cheque, tarjeta, otro
  receiptNumber: String,      // Número de recibo (opcional)
  notes: String,              // Notas adicionales (opcional)
  isRecurring: Boolean,       // Es recurrente (default: true)
  discountAmount: Number,     // Monto de descuento (default: 0)
  lateFeeAmount: Number,      // Monto de penalización (default: 0)
  createdAt: Date,            // Fecha de creación
  updatedAt: Date             // Fecha de última actualización
}
```

---

## 🔒 **Control de Acceso**

### **Roles y Permisos**

| Endpoint            | Usuario | Administrador | Super Admin |
| ------------------- | ------- | ------------- | ----------- |
| `GET /user`         | ✅      | ✅            | ✅          |
| `GET /`             | ❌      | ✅            | ✅          |
| `GET /summary`      | ❌      | ✅            | ✅          |
| `POST /`            | ❌      | ✅            | ✅          |
| `PUT /:id`          | ❌      | ✅            | ✅          |
| `DELETE /:id`       | ❌      | ❌            | ✅          |
| `POST /:id/payment` | ❌      | ✅            | ✅          |
| `POST /generate`    | ❌      | ✅            | ✅          |

---

## ⚠️ **Validaciones y Restricciones**

### **Validaciones del Modelo**

- **Índice único**: No puede haber dos mensualidades para el mismo usuario, comunidad y mes
- **Formato de mes**: Debe ser YYYY-MM
- **Montos**: No pueden ser negativos
- **Fechas**: La fecha de pago no puede ser anterior a la fecha de vencimiento

### **Validaciones de Negocio**

- **Pagos**: El monto pagado no puede exceder el monto total
- **Eliminación**: Solo se pueden eliminar mensualidades sin pagos
- **Generación**: No se duplican mensualidades existentes

---

## 🚀 **Ejemplos de Uso**

### **Crear Mensualidad Individual**

```bash
curl -X POST http://localhost:3001/api/monthly-fees \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "communityId": "507f1f77bcf86cd799439011",
    "userId": "507f1f77bcf86cd799439012",
    "month": "2024-01",
    "amount": 1500.00,
    "dueDate": "2024-01-31T00:00:00.000Z"
  }'
```

### **Registrar Pago**

```bash
curl -X POST http://localhost:3001/api/monthly-fees/507f1f77bcf86cd799439013/payment \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 1500.00,
    "paymentMethod": "transferencia",
    "receiptNumber": "TRF-001-2024"
  }'
```

### **Generar Mensualidades Masivas**

```bash
curl -X POST http://localhost:3001/api/monthly-fees/generate \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "communityId": "507f1f77bcf86cd799439011",
    "month": "2024-02"
  }'
```

---

## 📝 **Códigos de Error Comunes**

| Código | Descripción                | Solución                           |
| ------ | -------------------------- | ---------------------------------- |
| `400`  | Datos de entrada inválidos | Verificar formato de datos         |
| `401`  | No autenticado             | Incluir token válido               |
| `403`  | No autorizado              | Verificar rol de usuario           |
| `404`  | Recurso no encontrado      | Verificar ID de mensualidad        |
| `409`  | Conflicto                  | Mensualidad ya existe para ese mes |
| `500`  | Error interno del servidor | Contactar administrador            |

---

## 🔧 **Configuración y Despliegue**

### **Variables de Entorno Requeridas**

```bash
MONGODB_URI=mongodb://localhost:27017/privapp
JWT_SECRET=tu_secreto_jwt
```

### **Dependencias del Backend**

```json
{
  "express": "^4.18.0",
  "mongoose": "^7.0.0",
  "express-validator": "^7.0.0",
  "jsonwebtoken": "^9.0.0"
}
```

---

## 📚 **Recursos Adicionales**

- **Modelo**: `api/src/models/MonthlyFee.model.js`
- **Controlador**: `api/src/controllers/monthly-fee.controller.js`
- **Rutas**: `api/src/routes/monthly-fee.routes.js`
- **Script de Prueba**: `api/test-monthly-fees.js`

---

## 🎉 **¡El módulo está listo para usar!**

Con esta implementación completa, ahora tienes un sistema robusto de gestión de mensualidades que incluye:

✅ **Backend completo** con MongoDB  
✅ **API REST** con validaciones  
✅ **Control de acceso** basado en roles  
✅ **Frontend integrado** en Flutter  
✅ **Documentación completa** de la API  
✅ **Scripts de prueba** para validación

¡El módulo de mensualidades está completamente funcional!
