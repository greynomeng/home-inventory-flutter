const String _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  // defaultValue: 'http://10.0.2.2:3000',
  defaultValue: 'http://192.168.1.104:3000',
);

class AppConfig {
  AppConfig._();

  static const String baseUrl = _apiBaseUrl;

  static const String itemsEndpoint = '/api/items';
  static const String categoriesEndpoint = '/api/categories';
  static const String locationsEndpoint = '/api/locations';
  static const String uploadEndpoint = '/api/upload';
}
