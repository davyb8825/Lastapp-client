import 'dart:convert';
import 'package:http/http.dart' as http;

class DemoApi {
  // Backend running on the same phone:
  static const String _base = 'http://127.0.0.1:8000';

  static Future<String> chat(String input) async {
    try {
      final resp = await http.post(
        Uri.parse('$_base/echo'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': input}),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return (data['reply'] as String?) ?? 'No reply';
      } else {
        return 'Backend error: HTTP ${resp.statusCode}';
      }
    } catch (e) {
      return 'Failed to reach backend: $e';
    }
  }
}
