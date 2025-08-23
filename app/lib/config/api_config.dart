class ApiConfig {
  // Base configuration
  static const String host = '167.114.174.230';
  static const int port = 3004;
  static const String apiPath = '/api';

  // Full base URL
  static const String baseUrl = 'http://167.114.174.230:3004/api';

  // Alternative URLs for different environments
  static const String localhostUrl = 'http://167.114.174.230:3004/api';
  static const String localhostUrlAlt = 'http://privaap.masoft.mx:3004/api';

  // Timeout configuration
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Rate limiting
  static const int maxRequestsPerMinute = 100;

  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Environment-based configuration
  static String getBaseUrl() {
    // Dominio de producción
    const String productionDomain = 'privaap.masoft.mx';

    // Para desarrollo local (emulador)
    if (productionDomain == 'localhost' || productionDomain == '127.0.0.1') {
      return 'http://10.0.2.2:3004/api'; // IP especial para emulador Android
    }

    // Para servidor remoto (con HTTPS)
    return 'https://$productionDomain/api';
  }

  // Health check URL
  static String getHealthCheckUrl() {
    return getBaseUrl().replaceAll('/api', '/api/health');
  }

  // Debug information
  static void printConfig() {
    print('🌐 API Configuration:');
    print('   Host: $host');
    print('   Port: $port');
    print('   Base URL: ${getBaseUrl()}');
    print('   Health Check: ${getHealthCheckUrl()}');
  }
}
