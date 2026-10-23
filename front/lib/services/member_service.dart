
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../utils/secure_storage.dart';

class MemberService {
  Future<List<Map<String, dynamic>>> getMembers() async {
    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/members'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 20));

    final data = _decode(response);

    if (response.statusCode != 200) {
      throw MemberException(
        data['message']?.toString() ?? 'Unable to load members.',
        response.statusCode,
      );
    }

    final members = data['members'];

    if (members is! List) {
      throw MemberException('Invalid member data received.', response.statusCode);
    }

    return members
        .whereType<Map>()
        .map((member) => Map<String, dynamic>.from(member))
        .toList();
  }

  Future<Map<String, dynamic>> createMember({
    required String name,
    String? dob,
    String? phoneNumber,
    String? baptismDate,
  }) async {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/members'),
          headers: await _headers(),
          body: jsonEncode({
            'name': name.trim(),
            'dob': _dateValue(dob),
            'phoneNumber': phoneNumber?.trim() ?? '',
            'baptismDate': _dateValue(baptismDate),
          }),
        )
        .timeout(const Duration(seconds: 20));

    final data = _decode(response);

    if (response.statusCode != 201) {
      throw MemberException(
        data['message']?.toString() ?? 'Unable to create member.',
        response.statusCode,
      );
    }

    return Map<String, dynamic>.from(data['member'] as Map);
  }

  Future<Map<String, dynamic>> updateMember({
    required String id,
    required String name,
    String? dob,
    String? phoneNumber,
    String? baptismDate,
  }) async {
    final response = await http
        .put(
          Uri.parse('${ApiConfig.baseUrl}/members/$id'),
          headers: await _headers(),
          body: jsonEncode({
            'name': name.trim(),
            'dob': _dateValue(dob),
            'phoneNumber': phoneNumber?.trim() ?? '',
            'baptismDate': _dateValue(baptismDate),
          }),
        )
        .timeout(const Duration(seconds: 20));

    final data = _decode(response);

    if (response.statusCode != 200) {
      throw MemberException(
        data['message']?.toString() ?? 'Unable to update member.',
        response.statusCode,
      );
    }

    return Map<String, dynamic>.from(data['member'] as Map);
  }

  Future<void> deleteMember(String id) async {
    final response = await http
        .delete(
          Uri.parse('${ApiConfig.baseUrl}/members/$id'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 20));

    final data = _decode(response);

    if (response.statusCode != 200) {
      throw MemberException(
        data['message']?.toString() ?? 'Unable to delete member.',
        response.statusCode,
      );
    }
  }

  Future<Map<String, String>> _headers() async {
    final token = await SecureStorage.getToken();

    if (token == null || token.isEmpty) {
      throw MemberException('Please log in again.', 401);
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  String? _dateValue(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw const FormatException();
    } on FormatException {
      throw MemberException(
        'The server returned an invalid response.',
        response.statusCode,
      );
    }
  }
}

class MemberException implements Exception {
  final String message;
  final int statusCode;

  MemberException(this.message, this.statusCode);

  @override
  String toString() => message;
}
