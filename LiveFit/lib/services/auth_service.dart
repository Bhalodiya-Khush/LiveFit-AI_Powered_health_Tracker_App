import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

class AuthService {
  static const String _tokenKey = 'livefit_jwt_token';
  static const String _userKey = 'livefit_user_data';

  static String get defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:5000/api';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:5000/api';
    } catch (_) {}
    return 'http://localhost:5000/api';
  }

  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String _baseUrl = defaultBaseUrl;
  String? _cachedToken;
  UserModel? _currentUser;

  String get baseUrl => _baseUrl;
  String? get token => _cachedToken;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _cachedToken != null && _cachedToken!.isNotEmpty;

  void setBaseUrl(String url) {
    _baseUrl = url;
  }

  /// Initialize and attempt auto-login from stored JWT token
  Future<UserModel?> autoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(_tokenKey);
      final savedUserJson = prefs.getString(_userKey);

      if (savedToken == null || savedToken.isEmpty) {
        return null;
      }

      _cachedToken = savedToken;

      if (savedUserJson != null && savedUserJson.isNotEmpty) {
        try {
          _currentUser = UserModel.fromJson(jsonDecode(savedUserJson));
        } catch (_) {}
      }

      // Verify token with backend
      try {
        final response = await http
            .get(
              Uri.parse('$_baseUrl/auth/me'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $_cachedToken',
              },
            )
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['user'] != null) {
            _currentUser = UserModel.fromJson(data['user']);
            await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
            return _currentUser;
          }
        } else if (response.statusCode == 401) {
          // Token expired or invalid
          await logout();
          return null;
        }
      } catch (_) {
        // Backend temporarily unreachable; return cached user if present
        return _currentUser;
      }

      return _currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Log in with email and password
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _cachedToken = data['token'] as String?;
        if (data['user'] != null) {
          _currentUser = UserModel.fromJson(data['user']);
        }

        final prefs = await SharedPreferences.getInstance();
        if (_cachedToken != null) {
          await prefs.setString(_tokenKey, _cachedToken!);
        }
        if (_currentUser != null) {
          await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
        }

        return _currentUser;
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['message'] ?? 'Login failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Register a new user account
  Future<UserModel?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name.trim(),
              'email': email.trim().toLowerCase(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _cachedToken = data['token'] as String?;
        if (data['user'] != null) {
          _currentUser = UserModel.fromJson(data['user']);
        }

        final prefs = await SharedPreferences.getInstance();
        if (_cachedToken != null) {
          await prefs.setString(_tokenKey, _cachedToken!);
        }
        if (_currentUser != null) {
          await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
        }

        return _currentUser;
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['message'] ?? 'Registration failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Logout and clear stored credentials
  Future<void> logout() async {
    _cachedToken = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  /// Update locally cached user
  Future<void> updateCachedUser(UserModel user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }
}
