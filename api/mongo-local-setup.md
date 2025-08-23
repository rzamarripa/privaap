# 🍃 Configuración de MongoDB Local

Este documento explica cómo configurar MongoDB local para usar con la API de Privaap.

## 📋 Requisitos Previos

- MongoDB instalado localmente
- Puerto 27017 disponible
- Base de datos `privaap` creada

## 🚀 Instalación de MongoDB

### macOS (con Homebrew)

```bash
# Instalar MongoDB Community Edition
brew tap mongodb/brew
brew install mongodb-community

# Iniciar MongoDB como servicio
brew services start mongodb-community

# Verificar estado
brew services list | grep mongodb
```

### Ubuntu/Debian

```bash
# Importar clave pública
wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | sudo apt-key add -

# Agregar repositorio
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

# Instalar MongoDB
sudo apt-get update
sudo apt-get install -y mongodb-org

# Iniciar servicio
sudo systemctl start mongod
sudo systemctl enable mongod

# Verificar estado
sudo systemctl status mongod
```

### Windows

1. Descargar MongoDB Community Server desde [mongodb.com](https://www.mongodb.com/try/download/community)
2. Instalar siguiendo el wizard
3. MongoDB se ejecutará como servicio automáticamente

## 🔧 Configuración Inicial

### 1. Crear Base de Datos

```bash
# Conectar a MongoDB
mongosh

# Crear y usar base de datos
use privaap

# Crear usuario administrador (opcional)
db.createUser({
  user: "privaap_admin",
  pwd: "tu_password_seguro",
  roles: [
    { role: "readWrite", db: "privaap" },
    { role: "dbAdmin", db: "privaap" }
  ]
})

# Verificar
show dbs
```

### 2. Crear Colecciones Iniciales

```bash
# Usar base de datos
use privaap

# Crear colecciones
db.createCollection("users")
db.createCollection("communities")
db.createCollection("houses")
db.createCollection("monthlyfees")
db.createCollection("expenses")
db.createCollection("payments")
db.createCollection("surveys")
db.createCollection("blogposts")
db.createCollection("proposals")
db.createCollection("supporttickets")

# Verificar colecciones
show collections
```

### 3. Crear Índices Básicos

```bash
# Índices para usuarios
db.users.createIndex({ "email": 1 }, { unique: true })
db.users.createIndex({ "phone": 1 })

# Índices para comunidades
db.communities.createIndex({ "name": 1 })

# Índices para casas
db.houses.createIndex({ "communityId": 1 })
db.houses.createIndex({ "unitNumber": 1 })

# Índices para cuotas mensuales
db.monthlyfees.createIndex({ "communityId": 1, "month": 1, "year": 1 })

# Índices para gastos
db.expenses.createIndex({ "communityId": 1, "date": 1 })

# Índices para pagos
db.payments.createIndex({ "monthlyFeeId": 1 })

# Índices para encuestas
db.surveys.createIndex({ "communityId": 1, "status": 1 })
```

## 🔒 Configuración de Seguridad

### 1. Autenticación (Recomendado para producción)

```bash
# Editar archivo de configuración
sudo nano /etc/mongod.conf

# Agregar/modificar estas líneas:
security:
  authorization: enabled

# Reiniciar MongoDB
sudo systemctl restart mongod
# o en macOS:
brew services restart mongodb-community
```

### 2. Configurar Firewall

```bash
# Ubuntu/Debian
sudo ufw allow 27017

# macOS
# MongoDB solo acepta conexiones locales por defecto
```

## 📊 Monitoreo y Mantenimiento

### 1. Verificar Estado

```bash
# Verificar que MongoDB esté ejecutándose
ps aux | grep mongod

# Ver logs
tail -f /var/log/mongodb/mongod.log
# o en macOS:
tail -f /usr/local/var/log/mongodb/mongo.log
```

### 2. Backup y Restore

```bash
# Backup completo
mongodump --db privaap --out ./backup/$(date +%Y%m%d)

# Backup de colección específica
mongodump --db privaap --collection users --out ./backup/users

# Restore
mongorestore --db privaap ./backup/20241201/privaap/
```

### 3. Limpieza y Optimización

```bash
# Ver estadísticas de la base de datos
db.stats()

# Ver estadísticas de colecciones
db.users.stats()
db.communities.stats()

# Compactar colecciones (liberar espacio)
db.users.runCommand("compact")
```

## 🚨 Solución de Problemas

### Puerto 27017 en uso

```bash
# Ver qué proceso usa el puerto
lsof -i :27017

# Matar proceso si es necesario
sudo kill -9 <PID>
```

### Permisos de archivos

```bash
# Verificar permisos del directorio de datos
ls -la /var/lib/mongodb/
# o en macOS:
ls -la /usr/local/var/mongodb/

# Corregir permisos si es necesario
sudo chown -R mongodb:mongodb /var/lib/mongodb/
```

### Conexión rechazada

```bash
# Verificar que MongoDB esté escuchando
netstat -tlnp | grep 27017

# Verificar configuración de red
cat /etc/mongod.conf | grep bindIp
```

## 🔗 Conexión desde la API

### Variables de Entorno

```bash
# En tu archivo .env
MONGODB_URI=mongodb://localhost:27017/privaap

# Si tienes autenticación habilitada:
MONGODB_URI=mongodb://usuario:password@localhost:27017/privaap?authSource=privaap
```

### Verificar Conexión

```bash
# Desde la API, puedes probar:
curl http://localhost:3004/api/health
```

## 📚 Recursos Adicionales

- [MongoDB Documentation](https://docs.mongodb.com/)
- [MongoDB Community Server](https://www.mongodb.com/try/download/community)
- [MongoDB Security Checklist](https://docs.mongodb.com/manual/security-checklist/)
- [MongoDB Best Practices](https://docs.mongodb.com/manual/core/data-modeling-introduction/)

---

**¡MongoDB local configurado correctamente! 🎉**
