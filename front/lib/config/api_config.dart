
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'http://172.20.10.2:5000/api/v1';

  static const String authUrl = '$baseUrl/auth';
  static const String registerUrl = '$authUrl/register';
  static const String loginUrl = '$authUrl/login';
  static const String meUrl = '$authUrl/me';
}
