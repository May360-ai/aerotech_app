class ApiConfig {
  static const String _configuredUrl = String.fromEnvironment('API_BASE_URL');
  static const String _productionUrl = 'https://aerotech-back.onrender.com/api';

  static String get baseUrl {
    return _configuredUrl.isEmpty ? _productionUrl : _configuredUrl;
  }
}
