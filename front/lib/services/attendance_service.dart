
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../utils/secure_storage.dart';

class AttendanceService {
  AttendanceService._();

  static final AttendanceService instance = AttendanceService._();

  Future<Map<String, String>> _headers() async {
    final token = await SecureStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Your session has expired. Please log in again.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception('The server returned an invalid response.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected response from the server.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        decoded['message']?.toString() ?? 'Attendance request failed.',
      );
    }

    if (decoded['success'] != true) {
      throw Exception(
        decoded['message']?.toString() ?? 'Attendance request failed.',
      );
    }

    return decoded;
  }

  /// Loads all members and their statuses for a selected Sunday.
  Future<Map<String, dynamic>> getAttendance(String date) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/attendance').replace(
      queryParameters: {'date': date},
    );

    final response = await http.get(
      uri,
      headers: await _headers(),
    );

    return _decodeResponse(response);
  }

  /// Saves one member immediately after Present or Absent is selected.
  Future<Map<String, dynamic>> updateMemberAttendance({
    required String date,
    required String memberId,
    required String status,
  }) async {
    if (!['present', 'absent', 'unmarked'].contains(status)) {
      throw ArgumentError('Invalid attendance status.');
    }

    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/attendance/member'),
      headers: await _headers(),
      body: jsonEncode({
        'date': date,
        'memberId': memberId,
        'status': status,
      }),
    );

    return _decodeResponse(response);
  }

  /// Saves the complete list. Omit unmarked members from entries.
  Future<Map<String, dynamic>> saveAttendance({
    required String date,
    required List<Map<String, String>> entries,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/attendance'),
      headers: await _headers(),
      body: jsonEncode({
        'date': date,
        'entries': entries,
      }),
    );

    return _decodeResponse(response);
  }


  /// Loads attendance summaries for a selected year.
  /// Optionally filters the history to a specific member.
  Future<Map<String, dynamic>> getAttendanceSummary({
    int? year,
    String? memberId,
    bool includeMemberStatus = false,
  }) async {
    final queryParameters = <String, String>{};

    if (year != null) {
      queryParameters['year'] = year.toString();
    }

    if (memberId != null && memberId.isNotEmpty) {
      queryParameters['memberId'] = memberId;
    }

    if (includeMemberStatus) {
      queryParameters['includeMemberStatus'] = 'true';
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/attendance/summary',
    ).replace(
      queryParameters:
          queryParameters.isEmpty ? null : queryParameters,
    );

    final response = await http.get(
      uri,
      headers: await _headers(),
    );

    return _decodeResponse(response);
  }


}
