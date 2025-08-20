class ApiConfig {
  // Base configuration
  static const String host = '192.168.68.101';
  static const int port = 3004;
  static const String apiPath = '/api';

  // Full base URL
  static const String baseUrl = 'http://192.168.68.101:3004/api';

  // Alternative URLs for different environments
  static const String localhostUrl = 'http://localhost:3004/api';
  static const String localhostUrlAlt = 'http://127.0.0.1:3004/api';

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
}
