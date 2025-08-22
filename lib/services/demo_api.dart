import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class DemoApi {
  static String get base => Config.baseUrl;

  static Map<String, String> _jsonHeaders() {
    final h = <String, String>{'Content-Type': 'application/json'};
    final t = Config.token;
    if (t != null && t.isNotEmpty) h['Authorization'] = 'Bearer $t';
    return h;
  }

  // ---- Projects / Jobs (simple demo) ----
  static Future<Map<String, dynamic>> scaffold(String name, {String template = 'starter'}) async {
    final uri = Uri.parse('$base/scaffold');
    final resp = await http.post(uri, headers: _jsonHeaders(),
        body: jsonEncode({'name': name, 'template': template}));
    if (resp.statusCode != 200) {
      throw Exception('scaffold failed: ${resp.statusCode} ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> status(String jobId) async {
    final uri = Uri.parse('$base/status/$jobId');
    final resp = await http.get(uri, headers: _jsonHeaders());
    if (resp.statusCode != 200) {
      throw Exception('status failed: ${resp.statusCode} ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> buildAndroid(String projectName) async {
    final uri = Uri.parse('$base/build/android');
    final resp = await http.post(uri, headers: _jsonHeaders(),
        body: jsonEncode({'projectName': projectName}));
    if (resp.statusCode != 200) {
      throw Exception('build android failed: ${resp.statusCode} ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  // ---- Cloud build (GitHub Actions) ----
  static Future<Map<String, dynamic>> buildCloud() async {
    final uri = Uri.parse('$base/build/cloud');
    final resp = await http.post(uri, headers: _jsonHeaders(), body: jsonEncode({}));
    if (resp.statusCode != 200) {
      throw Exception('cloud dispatch failed: ${resp.statusCode} ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> cloudStatus(String runId) async {
    final uri = Uri.parse('$base/build/cloud/$runId');
    final resp = await http.get(uri, headers: _jsonHeaders());
    if (resp.statusCode != 200) {
      throw Exception('cloud status failed: ${resp.statusCode} ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> unzipArtifact(String artifactId) async {
    final uri = Uri.parse('$base/artifacts/cloud/$artifactId/unzip');
    final resp = await http.post(uri, headers: _jsonHeaders(), body: jsonEncode({}));
    if (resp.statusCode != 200) {
      throw Exception('unzip failed: ${resp.statusCode} ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  static Uri artifactApkUri(String artifactId) {
    return Uri.parse('$base/artifacts/cloud/$artifactId/apk');
  }

  static Uri artifactApkUriWithFlavor(String artifactId, String flavor) {
    return Uri.parse('$base/artifacts/cloud/$artifactId/apk/$flavor');
  }

  // ---- Chat (simple echo to your backend) ----
  static Future<String> chat(String text) async {
    final uri = Uri.parse('$base/echo');
    final resp = await http.post(uri, headers: _jsonHeaders(),
        body: jsonEncode({'message': text}));
    if (resp.statusCode != 200) {
      throw Exception('chat failed: ${resp.statusCode} ${resp.body}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return (data['reply'] as String?) ?? data.toString();
  }
}
