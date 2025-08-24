import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'token_store.dart';

class AuthService {
  final TokenStore _store;
  final http.Client _http;

  AuthService(this._store, [http.Client? client]) : _http = client ?? http.Client();

  Uri _u(String path) => Uri.parse(AppConfig.apiBaseUrl + path);

  Future<bool> signup(String email, String password) async {
    final resp = await _http.post(
      _u('/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final access = data['access_jwt'] as String?;
      final refresh = data['refresh_jwt'] as String?;
      if (access != null && refresh != null) {
        await _store.saveTokens(access: access, refresh: refresh);
        return true;
      }
    }
    return false;
  }

  Future<bool> login(String email, String password) async {
    final resp = await _http.post(
      _u('/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final access = data['access_jwt'] as String?;
      final refresh = data['refresh_jwt'] as String?;
      if (access != null && refresh != null) {
        await _store.saveTokens(access: access, refresh: refresh);
        return true;
      }
    }
    return false;
  }

  Future<void> logout() async {
    // Optional: call /auth/logout to revoke refresh; otherwise just clear
    await _store.clear();
  }
}