# 🐳 Docker Compose para Privaap API

Este directorio contiene la configuración completa de Docker para ejecutar la API de Privaap en contenedores.

## 📋 Servicios Incluidos

- **API Node.js** - Servidor principal en puerto 3004
- **MongoDB** - Base de datos local (puerto 27017)
- **Mongo Express** - Interfaz web para MongoDB en puerto 8081
- **Redis** - Cache y rate limiting en puerto 6379

## 🚀 Inicio Rápido

### 1. Configurar MongoDB Local

**Importante**: Este Docker Compose está configurado para usar MongoDB local. Asegúrate de tener MongoDB instalado y ejecutándose en tu máquina.

```bash
# Verificar que MongoDB esté ejecutándose
brew services list | grep mongodb  # macOS
# o
sudo systemctl status mongod       # Linux

# Si no está ejecutándose, iniciarlo:
brew services start mongodb-community  # macOS
# o
sudo systemctl start mongod           # Linux
```

### 2. Configurar Variables de Entorno

```bash
# Copiar el archivo de ejemplo
cp env.example .env

# Editar las variables según tu configuración
nano .env
```

**Variables importantes a configurar:**

- `MONGODB_URI` - URI de tu MongoDB local (por defecto: mongodb://localhost:27017/privaap)
- `JWT_SECRET` - Clave secreta para JWT (¡cambiar en producción!)
- `CLOUDINARY_*` - Credenciales de Cloudinary para imágenes
- `SMTP_*` - Configuración de email

### 2. Ejecutar con Docker Compose

```bash
# Construir e iniciar todos los servicios
docker-compose up -d

# Ver logs en tiempo real
docker-compose logs -f

# Ver logs de un servicio específico
docker-compose logs -f api
```

### 3. Verificar Servicios

```bash
# Estado de los contenedores
docker-compose ps

# Health checks
docker-compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
```

## 🌐 Acceso a los Servicios

- **API**: http://localhost:3004
- **Health Check**: http://localhost:3004/api/health
- **MongoDB**: localhost:27017 (instalación local)
- **Mongo Express**: http://localhost:8081 (admin/privaap123)
- **Redis**: localhost:6379

## 📁 Estructura de Volúmenes

```
api/
├── uploads/          # Archivos subidos por usuarios
├── logs/            # Logs de la aplicación
└── mongo-init/      # Scripts de inicialización de MongoDB
```

## 🔧 Comandos Útiles

### Desarrollo

```bash
# Ejecutar solo la API en modo desarrollo
docker-compose up api

# Reconstruir la API después de cambios
docker-compose build api
docker-compose up -d api
```

### Base de Datos

```bash
# Acceder a MongoDB local
mongosh localhost:27017/privaap

# Ejecutar script de seed
docker-compose exec api npm run seed

# Backup de la base de datos
mongodump --out ./backup --db privaap
```

### Mantenimiento

```bash
# Parar todos los servicios
docker-compose down

# Parar y eliminar volúmenes (¡cuidado, elimina datos!)
docker-compose down -v

# Limpiar imágenes no utilizadas
docker system prune -f

# Ver uso de recursos
docker stats
```

## 🚨 Solución de Problemas

### Puerto ya en uso

```bash
# Ver qué proceso usa el puerto
lsof -i :3004

# Cambiar puerto en docker-compose.yml
ports:
  - "3005:3004"  # Puerto externo:interno
```

### Problemas de permisos

```bash
# Corregir permisos de uploads
sudo chown -R $USER:$USER uploads/
chmod 755 uploads/
```

### Base de datos no conecta

```bash
# Verificar que MongoDB esté ejecutándose
brew services list | grep mongodb
# o
sudo systemctl status mongod

# Reiniciar MongoDB local
brew services restart mongodb-community
# o
sudo systemctl restart mongod
```

### API no responde

```bash
# Ver logs de la API
docker-compose logs api

# Verificar health check
curl http://localhost:3004/api/health

# Reconstruir la API
docker-compose build --no-cache api
docker-compose up -d api
```

## 🔒 Seguridad

### Cambiar Contraseñas por Defecto

```bash
# Editar docker-compose.yml y cambiar:
MONGO_INITDB_ROOT_PASSWORD=tu_password_seguro
ME_CONFIG_BASICAUTH_PASSWORD=tu_password_seguro
```

### Variables de Entorno Sensibles

- Nunca committear archivos `.env` al repositorio
- Usar secretos de Docker en producción
- Rotar JWT_SECRET regularmente

## 📊 Monitoreo

### Logs Centralizados

```bash
# Ver todos los logs juntos
docker-compose logs -f --tail=100

# Filtrar por nivel
docker-compose logs -f api | grep ERROR
```

### Métricas de Recursos

```bash
# Uso de CPU y memoria
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Espacio en disco
docker system df
```

## 🚀 Producción

### Optimizaciones Recomendadas

1. Usar `docker-compose.prod.yml` con configuraciones específicas
2. Configurar logs rotativos
3. Implementar backup automático de MongoDB
4. Configurar monitoreo con Prometheus/Grafana
5. Usar secrets de Docker para credenciales

### Escalabilidad

```bash
# Escalar la API
docker-compose up -d --scale api=3

# Load balancer (requiere configuración adicional)
# Usar nginx o traefik para distribuir carga
```

## 📚 Recursos Adicionales

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [MongoDB Docker Image](https://hub.docker.com/_/mongo)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)
- [MongoDB Security Checklist](https://docs.mongodb.com/manual/security-checklist/)

## 🤝 Contribuir

Para mejorar esta configuración de Docker:

1. Fork el repositorio
2. Crear una rama para tu feature
3. Commit tus cambios
4. Push a la rama
5. Crear un Pull Request

---

**¡Disfruta usando Privaap con Docker! 🎉**
