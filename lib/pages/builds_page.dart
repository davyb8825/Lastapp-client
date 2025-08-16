import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../services/demo_api.dart';

class BuildsPage extends StatefulWidget {
  const BuildsPage({super.key});
  @override
  State<BuildsPage> createState() => _BuildsPageState();
}

class _BuildsPageState extends State<BuildsPage> {
  bool _busy = false;
  String _log = 'Ready.';
  String? _runId;
  Map<String, dynamic>? _status; // last cloud status payload

  void _append(String line) {
    setState(() => _log = _log.isEmpty ? line : '$_log\n$line');
  }

  Future<void> _copyLog() async {
    await Clipboard.setData(ClipboardData(text: _log));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Log copied to clipboard')),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      _append('Cannot open URL: $url');
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) _append('Failed to launch: $url');
  }

  Future<void> _triggerCloud() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      _append('Triggering cloud build…');
      final res = await DemoApi.buildCloud();
      _runId = (res['run_id'] ?? '').toString();
      _status = res;
      _append("Dispatch: " + jsonEncode(res));
      await _autoPollUntilDone();
  }
}
