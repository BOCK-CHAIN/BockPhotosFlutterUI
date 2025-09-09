import 'package:shared_preferences/shared_preferences.dart';

class TokenStore {
  static const _kRefresh = 'refresh_token';

  static String? _inMemoryAccessToken;

  Future<void> saveTokens({required String access, required String refresh}) async {
    _inMemoryAccessToken = access;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kRefresh, refresh);
  }

  Future<String?> getAccess() async {
    return _inMemoryAccessToken;
  }

  Future<String?> getRefresh() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kRefresh);
  }

  Future<void> updateAccess(String access) async {
    _inMemoryAccessToken = access;
  }

  Future<void> updateRefresh(String refresh) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kRefresh, refresh);
  }

  Future<void> clear() async {
    _inMemoryAccessToken = null;
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kRefresh);
  }
}