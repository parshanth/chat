import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/auth_user.dart';
import '../utils/secure_storage.dart';

class AuthService {
  Future<AuthUser> register({
    required String number,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse(ApiConfig.registerUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'number': number.trim(),
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 20));

    final data = _decodeResponse(response);

    if (response.statusCode == 201) {
      return AuthUser.fromJson(
        Map<String, dynamic>.from(data['user'] as Map),
      );
    }

    throw AuthException(
      data['message']?.toString() ?? 'Unable to create account.',
      statusCode: response.statusCode,
    );
  }

  Future<AuthUser> login({
    required String number,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse(ApiConfig.loginUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'number': number.trim(),
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 20));

    final data = _decodeResponse(response);

    if (response.statusCode == 403) {
      throw PendingApprovalException(
        data['message']?.toString() ?? 'Your account is awaiting approval.',
      );
    }

    if (response.statusCode != 200 || data['token'] == null) {
      throw AuthException(
        data['message']?.toString() ?? 'Login failed.',
        statusCode: response.statusCode,
      );
    }

    final userJson = data['user'];
    if (userJson is! Map) {
      throw AuthException('Invalid user data received from the server.');
    }

    final user = AuthUser.fromJson(
      Map<String, dynamic>.from(userJson),
    );

    await SecureStorage.saveUser(user);
    await SecureStorage.saveToken(data['token'].toString());
    return user;
  }

  Future<AuthUser> getCurrentUser() async {
    final token = await SecureStorage.getToken();

    if (token == null || token.isEmpty) {
      throw AuthException('No saved login session.');
    }

    final response = await _fetchCurrentUserResponse(token);

    if (response.statusCode == 401 || response.statusCode == 403) {
      await SecureStorage.deleteToken();
      final data = _decodeResponse(response);
      throw AuthException(
        data['message']?.toString() ??
            'Your login session has expired. Please log in again.',
        statusCode: response.statusCode,
      );
    }

    final data = _decodeResponse(response);
    if (response.statusCode != 200 || data['user'] is! Map) {
      throw AuthException(
        data['message']?.toString() ??
            'Unable to verify your login session.',
        statusCode: response.statusCode,
      );
    }

    final serverUser = AuthUser.fromJson(
      Map<String, dynamic>.from(data['user'] as Map),
    );
    final cachedUser = await SecureStorage.getUser();
    final user = AuthUser(
      id: serverUser.id,
      number: serverUser.number,
      allowed: data['user']['allowed'] is bool
          ? serverUser.allowed
          : cachedUser?.allowed ?? serverUser.allowed,
    );
    await SecureStorage.saveUser(user);
    return user;
  }

  Future<http.Response> _fetchCurrentUserResponse(String token) async {
    try {
      return await http
          .get(
            Uri.parse(ApiConfig.meUrl),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw AuthNetworkException(
        'Unable to reach the server. Your saved session is still available.',
      );
    } on http.ClientException {
      throw AuthNetworkException(
        'Unable to reach the server. Your saved session is still available.',
      );
    }
  }

  Future<void> logout() async {
    await SecureStorage.deleteToken();
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw const FormatException('Expected a JSON object.');
    } on FormatException {
      throw AuthException(
        'The server returned an invalid response.',
        statusCode: response.statusCode,
      );
    }
  }
}

class AuthException implements Exception {
  final String message;
  final int? statusCode;

  AuthException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class PendingApprovalException extends AuthException {
  PendingApprovalException(super.message);
}

class AuthNetworkException extends AuthException {
  AuthNetworkException(super.message);
}
