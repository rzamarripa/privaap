#!/bin/bash

# 🚀 Script de inicio rápido para Privaap API con Docker
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

# Función para verificar Docker
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker no está instalado. Por favor instala Docker primero."
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose no está instalado. Por favor instala Docker Compose primero."
        exit 1
    fi

    if ! docker info &> /dev/null; then
        print_error "Docker no está ejecutándose. Por favor inicia Docker primero."
        exit 1
    fi

    print_success "Docker está disponible y ejecutándose"
}

# Función para verificar archivos necesarios
check_files() {
    local missing_files=()

    if [[ ! -f "docker-compose.yml" ]]; then
        missing_files+=("docker-compose.yml")
    fi

    if [[ ! -f "Dockerfile" ]]; then
        missing_files+=("Dockerfile")
    fi

    if [[ ! -f ".env" ]]; then
        missing_files+=(".env")
    fi

    if [[ ${#missing_files[@]} -gt 0 ]]; then
        print_error "Faltan los siguientes archivos: ${missing_files[*]}"
        print_message "Por favor asegúrate de que todos los archivos estén presentes"
        exit 1
    fi

    print_success "Todos los archivos necesarios están presentes"
}

# Función para crear archivo .env si no existe
create_env_if_missing() {
    if [[ ! -f ".env" ]]; then
        print_warning "Archivo .env no encontrado"
        
        if [[ -f "env.example" ]]; then
            print_message "Copiando env.example a .env"
            cp env.example .env
            print_warning "Por favor edita el archivo .env con tus credenciales antes de continuar"
            print_message "Presiona Enter cuando hayas configurado las variables de entorno..."
            read -r
        else
            print_error "No se encontró env.example. Por favor crea el archivo .env manualmente"
            exit 1
        fi
    fi
}

# Función para crear directorios necesarios
create_directories() {
    print_message "Creando directorios necesarios..."
    
    mkdir -p uploads
    mkdir -p logs
    
    print_success "Directorios creados"
}

# Función para iniciar servicios
start_services() {
    local compose_file="docker-compose.yml"
    
    if [[ "$1" == "prod" ]]; then
        compose_file="docker-compose.prod.yml"
        print_message "Iniciando servicios en modo PRODUCCIÓN"
    else
        print_message "Iniciando servicios en modo DESARROLLO"
    fi

    print_message "Construyendo e iniciando servicios con $compose_file..."
    
    if docker-compose -f "$compose_file" up -d --build; then
        print_success "Servicios iniciados correctamente"
    else
        print_error "Error al iniciar los servicios"
        exit 1
    fi
}

# Función para mostrar estado de servicios
show_status() {
    print_message "Estado de los servicios:"
    docker-compose ps
    
    echo ""
    print_message "Logs recientes:"
    docker-compose logs --tail=20
}

# Función para mostrar información de acceso
show_access_info() {
    echo ""
    print_success "🎉 ¡Privaap API está ejecutándose!"
    echo ""
    echo "📱 Servicios disponibles:"
echo "   • API: http://localhost:3004"
echo "   • Health Check: http://localhost:3004/api/health"
echo "   • MongoDB: localhost:27017 (instalación local)"
echo "   • Mongo Express: http://localhost:8081 (admin/privaap123)"
echo "   • Redis: localhost:6379"
    echo ""
    echo "🔧 Comandos útiles:"
    echo "   • Ver logs: docker-compose logs -f"
    echo "   • Parar servicios: docker-compose down"
    echo "   • Reiniciar: docker-compose restart"
    echo "   • Estado: docker-compose ps"
    echo ""
}

# Función principal
main() {
    echo "🐳 Privaap API - Docker Compose Starter"
    echo "========================================"
    echo ""

    # Verificar Docker
    check_docker
    
    # Crear directorios
    create_directories
    
    # Verificar archivos
    check_files
    
    # Crear .env si es necesario
    create_env_if_missing
    
    # Iniciar servicios
    start_services "$1"
    
    # Esperar un momento para que los servicios se estabilicen
    print_message "Esperando que los servicios se estabilicen..."
    sleep 10
    
    # Mostrar estado
    show_status
    
    # Mostrar información de acceso
    show_access_info
}

# Función de ayuda
show_help() {
    echo "Uso: $0 [OPCIÓN]"
    echo ""
    echo "Opciones:"
    echo "  dev     Iniciar en modo desarrollo (por defecto)"
    echo "  prod    Iniciar en modo producción"
    echo "  help    Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0          # Modo desarrollo"
    echo "  $0 prod     # Modo producción"
    echo "  $0 help     # Mostrar ayuda"
}

# Manejo de argumentos
case "${1:-dev}" in
    "dev"|"development")
        main "dev"
        ;;
    "prod"|"production")
        main "prod"
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        print_error "Opción desconocida: $1"
        show_help
        exit 1
        ;;
esac
