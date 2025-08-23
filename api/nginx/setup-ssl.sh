#!/bin/bash

echo "🔒 Configurando SSL para privaap.masoft.mx..."

# 1. Verificar que Nginx esté funcionando
echo "Verificando Nginx..."
sudo systemctl status nginx --no-pager

# 2. Crear directorio para Let's Encrypt
sudo mkdir -p /var/www/html/.well-known/acme-challenge

# 3. Copiar configuración SSL
sudo cp privaap.masoft.mx-ssl.conf /etc/nginx/sites-available/privaap.masoft.mx

# 4. Habilitar sitio
sudo ln -sf /etc/nginx/sites-available/privaap.masoft.mx /etc/nginx/sites-enabled/

# 5. Verificar configuración
sudo nginx -t

# 6. Reiniciar Nginx
sudo systemctl reload nginx

# 7. Verificar que el dominio responda
echo "Verificando dominio..."
curl -I http://privaap.masoft.mx/health

# 8. Configurar SSL con Certbot
echo "Configurando SSL..."
sudo certbot --nginx -d privaap.masoft.mx --non-interactive --agree-tos --email admin@masoft.mx

# 9. Verificar estado final
echo "Verificando configuración final..."
sudo systemctl status nginx
sudo nginx -t

echo ""
echo "✅ SSL configurado correctamente!"
echo "🌐 Tu API estará disponible en: https://privaap.masoft.mx/api"
echo "🔍 Health check: https://privaap.masoft.mx/health"
