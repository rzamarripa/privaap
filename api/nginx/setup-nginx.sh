#!/bin/bash

# 🚀 Script de configuración de Nginx para Privaap
# Autor: Privaap Team
# Versión: 1.0.0

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir mensajes
print_message() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Variables de configuración
DOMAIN="privaap.masoft.mx"
API_PORT="3004"
NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"
NGINX_ENABLED="/etc/nginx/sites-enabled/$DOMAIN"

echo "🌐 Configuración de Nginx para $DOMAIN"
echo "========================================"

# 1. Verificar que Nginx esté instalado
print_message "Verificando instalación de Nginx..."
if ! command -v nginx &> /dev/null; then
    print_message "Instalando Nginx..."
    sudo apt update
    sudo apt install -y nginx
else
    print_success "Nginx ya está instalado"
fi

# 2. Verificar estado de Nginx
print_message "Verificando estado de Nginx..."
sudo systemctl status nginx --no-pager

# 3. Crear directorio de logs
print_message "Creando directorio de logs..."
sudo mkdir -p /var/log/nginx
sudo chown -R www-data:www-data /var/log/nginx

# 4. Copiar configuración
print_message "Copiando configuración de Nginx..."
sudo cp privaap.masoft.mx.conf $NGINX_CONF

# 5. Habilitar sitio
print_message "Habilitando sitio..."
if [ -L "$NGINX_ENABLED" ]; then
    sudo rm "$NGINX_ENABLED"
fi
sudo ln -s "$NGINX_CONF" "$NGINX_ENABLED"

# 6. Verificar configuración
print_message "Verificando configuración de Nginx..."
sudo nginx -t

# 7. Instalar Certbot para SSL
print_message "Instalando Certbot para SSL..."
if ! command -v certbot &> /dev/null; then
    sudo apt install -y certbot python3-certbot-nginx
else
    print_success "Certbot ya está instalado"
fi

# 8. Configurar SSL
print_message "Configurando SSL con Let's Encrypt..."
print_warning "Asegúrate de que el DNS apunte a este servidor antes de continuar"
print_warning "Presiona Enter cuando estés listo para configurar SSL..."
read -r

# Configurar SSL
sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@masoft.mx

# 9. Reiniciar Nginx
print_message "Reiniciando Nginx..."
sudo systemctl reload nginx

# 10. Verificar estado final
print_message "Verificando estado final..."
sudo systemctl status nginx --no-pager

# 11. Mostrar información de configuración
echo ""
print_success "🎉 Nginx configurado correctamente para $DOMAIN"
echo ""
echo "📱 Configuración final:"
echo "   • Dominio: https://$DOMAIN"
echo "   • API: https://$DOMAIN/api"
echo "   • Health Check: https://$DOMAIN/health"
echo "   • Uploads: https://$DOMAIN/uploads"
echo ""
echo "🔧 Comandos útiles:"
echo "   • Ver logs: sudo tail -f /var/log/nginx/$DOMAIN.access.log"
echo "   • Ver errores: sudo tail -f /var/log/nginx/$DOMAIN.error.log"
echo "   • Reiniciar Nginx: sudo systemctl reload nginx"
echo "   • Ver estado: sudo systemctl status nginx"
echo "   • Renovar SSL: sudo certbot renew"
echo ""
echo "⚠️  IMPORTANTE:"
echo "   • Asegúrate de que tu API esté ejecutándose en el puerto $API_PORT"
echo "   • Verifica que el firewall permita tráfico en puertos 80 y 443"
echo "   • El DNS debe apuntar a este servidor"
echo ""

# 12. Verificar conectividad
print_message "Verificando conectividad..."
if curl -s -o /dev/null -w "%{http_code}" "http://localhost/health" | grep -q "200"; then
    print_success "✅ Health check funcionando"
else
    print_warning "⚠️  Health check no responde (puede ser normal si la API no está ejecutándose)"
fi

print_success "¡Configuración completada!"
