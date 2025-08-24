import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'token_store.dart';

class ApiClient {
  final http.Client _http;
  final TokenStore _store;
  bool _isRefreshing = false;

  ApiClient(this._store, [http.Client? client]) : _http = client ?? http.Client();

  Uri _u(String path, [Map<String, dynamic>? query]) {
    final uri = Uri.parse(AppConfig.apiBaseUrl + path);
    if (query != null) {
      return uri.replace(queryParameters: query.map((key, value) => MapEntry(key, value.toString())));
    }
    return uri;
  }

  Future<http.Response> _authorizedRequest(
    Future<http.Response> Function(String? token) request,
  ) async {
    final token = await _store.getAccess();
    if (token != null) {
      try {
        final response = await request(token);
        if (response.statusCode != 401) return response;
      } catch (e) {
        // Continue to refresh token
      }
    }

    if (_isRefreshing) {
      // Wait for refresh to complete
      while (_isRefreshing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      final newToken = await _store.getAccess();
      return request(newToken);
    }

    final refreshed = await _refreshToken();
    if (refreshed) {
      final newToken = await _store.getAccess();
      return request(newToken);
    }

    return request(null);
  }

  Future<bool> _refreshToken() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;
    try {
      final refresh = await _store.getRefresh();
      if (refresh == null) return false;

      final resp = await _http.post(
        _u('/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_jwt': refresh}),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final access = data['access_jwt'] as String?;
        final newRefresh = data['refresh_jwt'] as String?;
        if (access != null && newRefresh != null) {
          await _store.saveTokens(access: access, refresh: newRefresh);
          return true;
        }
      }
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<http.Response> get(String path, {Map<String, dynamic>? query}) async {
    return _authorizedRequest((token) {
      return _http.get(
        _u(path, query),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
    });
  }

  Future<http.Response> post(String path, {Object? body}) async {
    return _authorizedRequest((token) {
      return _http.post(
        _u(path),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: body,
      );
    });
  }

  Future<http.Response> delete(String path) async {
    return _authorizedRequest((token) {
      return _http.delete(
        _u(path),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
    });
  }
}