import 'config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DemoApi {
  // Base URL for your local backend
  static const String base = 'http://127.0.0.1:8000';

  // -------- Local endpoints --------

  // POST /scaffold  {name or project_name, template}
  static Future<Map<String, dynamic>> scaffold(String name, {String template = 'starter'}) async {
    final uri = Uri.parse('$base/scaffold');
    final r = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'template': template}),
    );
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  // GET /status/{jobId}
  static Future<Map<String, dynamic>> status(String jobId) async {
    final uri = Uri.parse('$base/status/$jobId');
    final r = await http.get(uri);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  // POST /build/android {project or projectName}
  static Future<Map<String, dynamic>> buildAndroid(String projectName) async {
    final uri = Uri.parse('$base/build/android');
    final r = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'projectName': projectName}),
    );
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  // -------- Cloud build helpers (GitHub Actions) --------

  // POST /build/cloud
  static Future<Map<String, dynamic>> buildCloud() async {
    final uri = Uri.parse('$base/build/cloud');
    final r = await http.post(uri, headers: {'Content-Type': 'application/json'});
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  // GET /build/cloud/{runId}
  static Future<Map<String, dynamic>> cloudStatus(String runId) async {
    final uri = Uri.parse('$base/build/cloud/$runId');
    final r = await http.get(uri);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  // POST /artifacts/cloud/{artifactId}/unzip
  static Future<Map<String, dynamic>> unzipArtifact(String artifactId) async {
    final uri = Uri.parse('$base/artifacts/cloud/$artifactId/unzip');
    final r = await http.post(uri);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  // -------- Simple chat/echo helper --------
  // POST /echo { "message": "<text>" } -> { "reply": "..." }
  static Future<Map<String, dynamic>> chat(String text) async {
    final uri = Uri.parse('$base/echo');
    final r = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': text}),
    );
    return jsonDecode(r.body) as Map<String, dynamic>;
  }
}

// --- Cloud artifact helpers (added by sed) ---
static Map<String, String> _jsonHeaders() {
  final h = <String, String>{'Content-Type': 'application/json'};
  if (Config.token != null) h['Authorization'] = 'Bearer ${Config.token!}';
  return h;
}

static Future<Map<String, dynamic>> unzipArtifact(String artifactId) async {
  final uri = Uri.parse('${Config.baseUrl}/artifacts/cloud/$artifactId/unzip');
  final resp = await http.post(uri, headers: _jsonHeaders());
  if (resp.statusCode >= 400) {
    throw Exception('Unzip failed: ${resp.statusCode} ${resp.body}');
  }
  return jsonDecode(resp.body) as Map<String, dynamic>;
}

static Uri artifactApkUri(String artifactId) {
  return Uri.parse('${Config.baseUrl}/artifacts/cloud/$artifactId/apk');
}

static Uri artifactApkUriWithFlavor(String artifactId, String flavor) {
  return Uri.parse('${Config.baseUrl}/artifacts/cloud/$artifactId/apk/$flavor');
}
