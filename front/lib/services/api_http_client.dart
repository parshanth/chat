import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiHttpClient {
  ApiHttpClient._();

  static final http.Client _client = http.Client();

  static Future<http.Response> send({
    required String method,
    required Uri url,
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
  }) async {
    final requestTime = DateTime.now().toUtc();
    final stopwatch = Stopwatch()..start();
    final authorizationHeaderPresent =
        headers?.keys.any((key) => key.toLowerCase() == 'authorization') ??
        false;

    _log('[API REQUEST]', {
      'method': method.toUpperCase(),
      'url': _safeUrl(url),
      'timestamp': requestTime.toIso8601String(),
      'connectionTimeout': 'Not separately exposed by package:http',
      'receiveTimeout': 'Not separately exposed by package:http',
      'requestTimeout': timeout?.toString() ?? 'Not explicitly configured',
      'authorizationHeaderPresent': authorizationHeaderPresent,
    });

    try {
      final request = http.Request(method, url);
      headers?.forEach((key, value) {
        request.headers[key] = value;
      });
      if (body != null) {
        request.body = body.toString();
      }

      Future<http.Response> performRequest() async {
        final streamedResponse = await _client.send(request);
        return http.Response.fromStream(streamedResponse);
      }

      final response = timeout == null
          ? await performRequest()
          : await performRequest().timeout(timeout);
      stopwatch.stop();

      _log('[API RESPONSE]', {
        'method': method.toUpperCase(),
        'url': _safeUrl(url),
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'statusCode': response.statusCode,
        'statusCategory': response.statusCode >= 400
            ? 'HTTP error ${response.statusCode}'
            : 'HTTP success',
        'durationMs': stopwatch.elapsedMilliseconds,
        'body': _safeResponseBody(response.body),
      });

      return response;
    } catch (error, stackTrace) {
      stopwatch.stop();
      _log('[API ERROR]', {
        'method': method.toUpperCase(),
        'url': _safeUrl(url),
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'durationMs': stopwatch.elapsedMilliseconds,
        'exceptionType': error.runtimeType.toString(),
        'category': _classifyError(error),
        'details': _sanitizeText(error.toString()),
        'stackTrace': _sanitizeText(stackTrace.toString()),
      });
      rethrow;
    }
  }

  static String _classifyError(Object error) {
    final type = error.runtimeType.toString().toLowerCase();
    final details = error.toString().toLowerCase();

    if (error is TimeoutException || type.contains('timeout')) {
      return 'Connection/receive timeout';
    }
    if (type.contains('handshake') ||
        type.contains('tls') ||
        details.contains('certificate') ||
        details.contains('ssl')) {
      return 'Certificate/SSL error';
    }
    if (type.contains('socket') &&
        (details.contains('lookup') ||
            details.contains('resolve') ||
            details.contains('dns'))) {
      return 'DNS resolution error';
    }
    if (type.contains('socket')) {
      return 'SocketException / connection failure';
    }
    if (error is http.ClientException) {
      return 'HTTP client/network error';
    }
    return 'Unexpected client error';
  }

  static Object? _safeResponseBody(String body) {
    try {
      return _redactValue(jsonDecode(body));
    } on FormatException {
      return _sanitizeText(body);
    }
  }

  static Object? _redactValue(Object? value, [String? key]) {
    if (key != null && _isSensitiveKey(key)) {
      return '[REDACTED]';
    }
    if (value is Map) {
      return value.map(
        (dynamic childKey, dynamic childValue) => MapEntry(
          childKey.toString(),
          _redactValue(childValue, childKey.toString()),
        ),
      );
    }
    if (value is List) {
      return value.map(_redactValue).toList();
    }
    if (value is String) {
      return _sanitizeText(value);
    }
    return value;
  }

  static bool _isSensitiveKey(String key) {
    final normalized = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return normalized.contains('password') ||
        normalized.contains('token') ||
        normalized.contains('authorization') ||
        normalized.contains('secret') ||
        normalized.contains('email') ||
        normalized.contains('phone') ||
        normalized.contains('address') ||
        normalized.contains('birth') ||
        normalized.endsWith('name') ||
        normalized == 'number' ||
        normalized == 'id' ||
        normalized.endsWith('id');
  }

  static String _safeUrl(Uri url) {
    final queryParameters = Map<String, String>.from(url.queryParameters);
    for (final key in queryParameters.keys.toList()) {
      if (_isSensitiveKey(key)) {
        queryParameters[key] = '[REDACTED]';
      }
    }
    final safeUri = url.replace(
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    return _sanitizeText(
      safeUri.toString().replaceAll(
        RegExp(r'\b[0-9a-fA-F]{24}\b'),
        '[REDACTED_ID]',
      ),
    );
  }

  static String _sanitizeText(String value) {
    return value
        .replaceAll(
          RegExp(r'\beyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b'),
          '[REDACTED_TOKEN]',
        )
        .replaceAll(
          RegExp(
            r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b',
            caseSensitive: false,
          ),
          '[REDACTED_EMAIL]',
        )
        .replaceAll(
          RegExp(r'(?<!\w)\+?\d[\d\s().-]{5,}\d(?!\w)'),
          '[REDACTED_NUMBER]',
        );
  }

  static void _log(String prefix, Map<String, Object?> details) {
    if (!kDebugMode) return;
    debugPrint('$prefix ${jsonEncode(details)}');
  }
}
