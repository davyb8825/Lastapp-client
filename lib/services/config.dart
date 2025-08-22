import 'package:shared_preferences/shared_preferences.dart';

class Config {
  static const _kBaseUrl = 'base_url';
  static const _kToken = 'auth_token';

  static String _baseUrl = 'http://127.0.0.1:8000';
  static String? _token;

  static String get baseUrl => _baseUrl;
  static String? get token => _token;

  static Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    _baseUrl = sp.getString(_kBaseUrl) ?? _baseUrl;
    _token = sp.getString(_kToken);
  }

  static Future<void> save({String? baseUrl, String? token}) async {
    final sp = await SharedPreferences.getInstance();
    if (baseUrl != null) {
      _baseUrl = baseUrl;
      await sp.setString(_kBaseUrl, baseUrl);
    }
    if (token != null) {
      _token = token.isEmpty ? null : token;
      if (_token == null) {
        await sp.remove(_kToken);
      } else {
        await sp.setString(_kToken, _token!);
      }
    }
  }
}
