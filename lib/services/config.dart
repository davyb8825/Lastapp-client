class Config {
  // 👇 CHANGE THIS to your server's LAN IP (same IP you used in the phone browser)
  static const String baseUrl = "http://192.168.1.42:8000";
  // Must match what your backend checks in require_auth()
  static const String? token  = "super-secret-token";
}
