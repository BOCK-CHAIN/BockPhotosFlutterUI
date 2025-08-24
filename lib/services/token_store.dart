import 'package:shared_preferences/shared_preferences.dart';

class TokenStore {
  static const _kAccess = 'access_jwt';
  static const _kRefresh = 'refresh_jwt';

  Future<void> saveTokens({required String access, required String refresh}) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kAccess, access);
    await sp.setString(_kRefresh, refresh);
  }

  Future<String?> getAccess() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kAccess);
  }

  Future<String?> getRefresh() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kRefresh);
  }

  Future<void> updateAccess(String access) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kAccess, access);
  }

  Future<void> updateRefresh(String refresh) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kRefresh, refresh);
  }

  Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kAccess);
    await sp.remove(_kRefresh);
  }
}