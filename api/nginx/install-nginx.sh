#!/bin/bash

echo "🌐 Instalando Nginx para privaap.masoft.mx..."

# 1. Instalar Nginx
sudo apt update
sudo apt install -y nginx

# 2. Crear directorio de logs
sudo mkdir -p /var/log/nginx

# 3. Copiar configuración
sudo cp privaap.masoft.mx.conf /etc/nginx/sites-available/privaap.masoft.mx

# 4. Habilitar sitio
sudo ln -sf /etc/nginx/sites-available/privaap.masoft.mx /etc/nginx/sites-enabled/

# 5. Verificar configuración
sudo nginx -t

# 6. Reiniciar Nginx
sudo systemctl restart nginx

# 7. Habilitar en boot
sudo systemctl enable nginx

# 8. Verificar estado
sudo systemctl status nginx

echo ""
echo "✅ Nginx instalado y configurado!"
echo "🌐 Tu API estará disponible en: http://privaap.masoft.mx/api"
echo "🔍 Health check: http://privaap.masoft.mx/health"
echo ""
echo "📝 Para ver logs:"
echo "   sudo tail -f /var/log/nginx/privaap.masoft.mx.access.log"
echo "   sudo tail -f /var/log/nginx/privaap.masoft.mx.error.log"
