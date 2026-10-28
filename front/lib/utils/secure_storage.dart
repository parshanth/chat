import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:universal_html/html.dart' as html;

import '../models/auth_user.dart';

class SecureStorage {
  SecureStorage._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  static Future<void> saveToken(String token) async {
    if (kIsWeb) {
      html.window.localStorage[_tokenKey] = token;
      html.window.sessionStorage.remove(_tokenKey);
      return;
    }

    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    if (kIsWeb) {
      return _readWebValue(_tokenKey);
    }

    return _storage.read(key: _tokenKey);
  }

  static Future<void> saveUser(AuthUser user) async {
    final value = jsonEncode(user.toJson());

    if (kIsWeb) {
      html.window.localStorage[_userKey] = value;
      html.window.sessionStorage.remove(_userKey);
      return;
    }

    await _storage.write(key: _userKey, value: value);
  }

  static Future<AuthUser?> getUser() async {
    final value = kIsWeb
        ? _readWebValue(_userKey)
        : await _storage.read(key: _userKey);
    if (value == null || value.isEmpty) return null;

    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) {
        return AuthUser.fromJson(decoded);
      }
    } on FormatException {
      await deleteUser();
      return null;
    }

    await deleteUser();
    return null;
  }

  static Future<void> deleteUser() async {
    if (kIsWeb) {
      html.window.localStorage.remove(_userKey);
      html.window.sessionStorage.remove(_userKey);
      return;
    }

    await _storage.delete(key: _userKey);
  }

  static Future<void> deleteToken() async {
    if (kIsWeb) {
      html.window.localStorage.remove(_tokenKey);
      html.window.localStorage.remove(_userKey);
      html.window.sessionStorage.remove(_tokenKey);
      html.window.sessionStorage.remove(_userKey);
      return;
    }

    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  static Future<void> clearAll() async {
    if (kIsWeb) {
      html.window.localStorage.remove(_tokenKey);
      html.window.localStorage.remove(_userKey);
      html.window.sessionStorage.remove(_tokenKey);
      html.window.sessionStorage.remove(_userKey);
      return;
    }

    await _storage.deleteAll();
  }

  static String? _readWebValue(String key) {
    final value = html.window.localStorage[key];
    if (value != null) return value;

    final legacyValue = html.window.sessionStorage[key];
    if (legacyValue == null) return null;

    html.window.localStorage[key] = legacyValue;
    html.window.sessionStorage.remove(key);
    return legacyValue;
  }
}
