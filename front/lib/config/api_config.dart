
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'https://attendance-production-cccd.up.railway.app/api/v1';

  static const String authUrl = '$baseUrl/auth';
  static const String registerUrl = '$authUrl/register';
  static const String loginUrl = '$authUrl/login';
  static const String meUrl = '$authUrl/me';
}
