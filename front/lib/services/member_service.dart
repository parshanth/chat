import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/member.dart';
import '../utils/secure_storage.dart';

class MemberService {
  Future<List<Member>> getMembers() async {
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
      throw MemberException(
        'Invalid member data received.',
        response.statusCode,
      );
    }

    return members
        .whereType<Map>()
        .map((member) => Member.fromJson(Map<String, dynamic>.from(member)))
        .toList();
  }

  Future<Member> createMember({
    required String name,
    DateTime? dob,
    String? phoneNumber,
    DateTime? baptismDate,
    DateTime? marriageDate,
  }) async {
    final request = Member(
      id: '',
      name: name.trim(),
      dob: dob,
      phoneNumber: phoneNumber?.trim() ?? '',
      baptismDate: baptismDate,
      marriageDate: marriageDate,
    );
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/members'),
          headers: await _headers(),
          body: jsonEncode(request.toJson()),
        )
        .timeout(const Duration(seconds: 20));

    final data = _decode(response);

    if (response.statusCode != 201) {
      throw MemberException(
        data['message']?.toString() ?? 'Unable to create member.',
        response.statusCode,
      );
    }

    return Member.fromJson(Map<String, dynamic>.from(data['member'] as Map));
  }

  Future<Member> updateMember({
    required String id,
    required String name,
    DateTime? dob,
    String? phoneNumber,
    DateTime? baptismDate,
    DateTime? marriageDate,
  }) async {
    final request = Member(
      id: '',
      name: name.trim(),
      dob: dob,
      phoneNumber: phoneNumber?.trim() ?? '',
      baptismDate: baptismDate,
      marriageDate: marriageDate,
    );
    final response = await http
        .put(
          Uri.parse('${ApiConfig.baseUrl}/members/$id'),
          headers: await _headers(),
          body: jsonEncode(request.toJson()),
        )
        .timeout(const Duration(seconds: 20));

    final data = _decode(response);

    if (response.statusCode != 200) {
      throw MemberException(
        data['message']?.toString() ?? 'Unable to update member.',
        response.statusCode,
      );
    }

    return Member.fromJson(Map<String, dynamic>.from(data['member'] as Map));
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
