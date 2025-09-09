import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'token_store.dart';

class AuthService {
  final TokenStore _store;
  final http.Client _http;

  AuthService(this._store, [http.Client? client]) : _http = client ?? http.Client();

  Uri _u(String path) => Uri.parse(AppConfig.apiBaseUrl + path);

  Future<AuthResult> signup(String email, String password) async {
    try {
      final resp = await _http.post(
        _u('/api/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        final access = data['accessToken'] as String? ?? (data['data'] is Map<String, dynamic> ? (data['data']['accessToken'] as String?) : null);
        final refresh = data['refreshToken'] as String? ?? (data['data'] is Map<String, dynamic> ? (data['data']['refreshToken'] as String?) : null);
        if (access != null && refresh != null) {
          await _store.saveTokens(access: access, refresh: refresh);
          return AuthResult.success(data['message'] as String? ?? 'Signup successful');
        }
      }
      
      final message = (data['message'] as String?) ?? (data['error'] as String?) ?? 'Signup failed';
      return AuthResult.error(message);
    } catch (e) {
      return AuthResult.error('Network error: ${e.toString()}');
    }
  }

  Future<AuthResult> login(String email, String password) async {
    try {
      final resp = await _http.post(
        _u('/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      
      if (resp.statusCode == 200) {
        final access = data['accessToken'] as String? ?? (data['data'] is Map<String, dynamic> ? (data['data']['accessToken'] as String?) : null);
        final refresh = data['refreshToken'] as String? ?? (data['data'] is Map<String, dynamic> ? (data['data']['refreshToken'] as String?) : null);
        if (access != null && refresh != null) {
          await _store.saveTokens(access: access, refresh: refresh);
          return AuthResult.success(data['message'] as String? ?? 'Login successful');
        }
      }
      
      final message = (data['message'] as String?) ?? (data['error'] as String?) ?? (resp.statusCode == 401 ? 'Invalid credentials' : 'Login failed');
      return AuthResult.error(message);
    } catch (e) {
      return AuthResult.error('Network error: ${e.toString()}');
    }
  }

  Future<AuthResult> logout() async {
    try {
      final refreshToken = await _store.getRefresh();
      if (refreshToken != null) {
        final resp = await _http.post(
          _u('/api/auth/logout'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refreshToken': refreshToken}),
        );
        
        if (resp.statusCode == 200) {
          await _store.clear();
          return AuthResult.success('Logout successful');
        }
      }
      
      await _store.clear();
      return AuthResult.success('Logout successful');
    } catch (e) {
      await _store.clear();
      return AuthResult.error('Logout error: ${e.toString()}');
    }
  }

  Future<AuthResult> refreshToken() async {
    try {
      final refreshToken = await _store.getRefresh();
      if (refreshToken == null) {
        return AuthResult.error('No refresh token available');
      }

      final resp = await _http.post(
        _u('/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      
      if (resp.statusCode == 200) {
        final access = data['accessToken'] as String? ?? (data['data'] is Map<String, dynamic> ? (data['data']['accessToken'] as String?) : null);
        final refresh = data['refreshToken'] as String? ?? (data['data'] is Map<String, dynamic> ? (data['data']['refreshToken'] as String?) : null);
        if (access != null && refresh != null) {
          await _store.saveTokens(access: access, refresh: refresh);
          return AuthResult.success('Token refreshed');
        }
      }
      
      final message = (data['message'] as String?) ?? (data['error'] as String?) ?? 'Token refresh failed';
      return AuthResult.error(message);
    } catch (e) {
      return AuthResult.error('Token refresh error: ${e.toString()}');
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _store.getAccess();
    return token != null;
  }
}

class AuthResult {
  final bool success;
  final String message;
  final String? error;

  AuthResult._({required this.success, required this.message, this.error});

  factory AuthResult.success(String message) {
    return AuthResult._(success: true, message: message);
  }

  factory AuthResult.error(String error) {
    return AuthResult._(success: false, message: error, error: error);
  }
}