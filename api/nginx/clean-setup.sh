#!/bin/bash

echo "🧹 Limpiando y reconfigurando Nginx..."

# 1. Parar todos los servicios web
echo "Parando servicios web..."
sudo systemctl stop nginx 2>/dev/null || true
sudo systemctl stop apache2 2>/dev/null || true

# 2. Matar procesos huérfanos
echo "Limpiando procesos..."
sudo pkill -f nginx 2>/dev/null || true
sudo pkill -f apache 2>/dev/null || true

# 3. Verificar que los puertos estén libres
echo "Verificando puertos..."
sleep 2
if sudo netstat -tlnp | grep -E ':(80|443)' > /dev/null; then
    echo "❌ Los puertos 80/443 aún están en uso:"
    sudo netstat -tlnp | grep -E ':(80|443)'
    echo "Por favor, identifica qué proceso los está usando y deténlo manualmente."
    exit 1
else
    echo "✅ Puertos 80/443 están libres"
fi

# 4. Limpiar configuración de Nginx
echo "Limpiando configuración..."
sudo rm -f /etc/nginx/sites-enabled/*
sudo rm -f /etc/nginx/sites-available/privaap.masoft.mx*

# 5. Crear directorio de logs
sudo mkdir -p /var/log/nginx

# 6. Copiar configuración simple
echo "Copiando configuración simple..."
sudo cp privaap.masoft.mx-simple.conf /etc/nginx/sites-available/privaap.masoft.mx

# 7. Habilitar sitio
sudo ln -sf /etc/nginx/sites-available/privaap.masoft.mx /etc/nginx/sites-enabled/

# 8. Verificar configuración
echo "Verificando configuración..."
sudo nginx -t

# 9. Iniciar Nginx
echo "Iniciando Nginx..."
sudo systemctl start nginx

# 10. Verificar estado
echo "Verificando estado..."
sudo systemctl status nginx --no-pager

# 11. Verificar que responda
echo "Verificando respuesta..."
sleep 3
if curl -s -o /dev/null -w "%{http_code}" "http://localhost/health" | grep -q "200"; then
    echo "✅ Health check funcionando"
else
    echo "⚠️  Health check no responde (puede ser normal si la API no está ejecutándose)"
fi

echo ""
echo "✅ Nginx configurado correctamente!"
echo "🌐 Tu API estará disponible en: http://privaap.masoft.mx/api"
echo "🔍 Health check: http://privaap.masoft.mx/health"
echo ""
echo "📝 Para ver logs:"
echo "   sudo tail -f /var/log/nginx/privaap.masoft.mx.access.log"
echo "   sudo tail -f /var/log/nginx/privaap.masoft.mx.error.log"
echo ""
echo "⚠️  IMPORTANTE:"
echo "   • Asegúrate de que tu API esté ejecutándose en el puerto 3004"
echo "   • Verifica que el firewall permita tráfico en puerto 80"
echo "   • El DNS debe apuntar a este servidor"
