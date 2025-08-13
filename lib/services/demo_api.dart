import 'dart:convert';
import 'package:http/http.dart' as http;

class DemoApi {
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

  static Future<Map<String, dynamic>> scaffold(String name, {String template = 'starter'}) async {
    final resp = await http.post(
      Uri.parse('$_base/scaffold'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'project_name': name, 'template': template}),
    );
    return (resp.statusCode == 200)
        ? jsonDecode(resp.body) as Map<String, dynamic>
        : {'error': 'HTTP ${resp.statusCode}'};
  }

  static Future<Map<String, dynamic>> status(String jobId) async {
    final resp = await http.get(Uri.parse('$_base/status/$jobId'));
    return (resp.statusCode == 200)
        ? jsonDecode(resp.body) as Map<String, dynamic>
        : {'error': 'HTTP ${resp.statusCode}'};
  }

  static Future<Map<String, dynamic>> buildAndroid(String projectName) async {
    final resp = await http.post(
      Uri.parse('$_base/build/android'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'project': projectName}),
    );
    return (resp.statusCode == 200)
        ? jsonDecode(resp.body) as Map<String, dynamic>
        : {'error': 'HTTP ${resp.statusCode}'};
  }
}
