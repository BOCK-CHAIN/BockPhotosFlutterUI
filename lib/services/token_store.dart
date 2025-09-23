import 'package:shared_preferences/shared_preferences.dart';

class TokenStore {
  static const _kRefresh = 'refresh_token';
  static const _kAccess = 'access_token';

  static String? _inMemoryAccessToken;

  /// Load access token from persistent storage into memory (call on app start)
  Future<void> init() async {
    if (_inMemoryAccessToken != null) return;
    final sp = await SharedPreferences.getInstance();
    _inMemoryAccessToken = sp.getString(_kAccess);
  }

  Future<void> saveTokens({required String access, required String refresh}) async {
    _inMemoryAccessToken = access;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kAccess, access);
    await sp.setString(_kRefresh, refresh);
  }

  Future<String?> getAccess() async {
    if (_inMemoryAccessToken != null) return _inMemoryAccessToken;
    final sp = await SharedPreferences.getInstance();
    final access = sp.getString(_kAccess);
    _inMemoryAccessToken = access;
    return access;
  }

  Future<String?> getRefresh() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kRefresh);
  }

  Future<void> updateAccess(String access) async {
    _inMemoryAccessToken = access;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kAccess, access);
  }

  Future<void> updateRefresh(String refresh) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kRefresh, refresh);
  }

  Future<void> clear() async {
    _inMemoryAccessToken = null;
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kAccess);
    await sp.remove(_kRefresh);
  }
}