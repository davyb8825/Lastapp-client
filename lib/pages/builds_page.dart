import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/demo_api.dart';

class BuildsPage extends StatefulWidget {
  const BuildsPage({super.key});
  @override
  State<BuildsPage> createState() => _BuildsPageState();
}

class _BuildsPageState extends State<BuildsPage> {
  String? _artifactId;
  bool _busy = false;
  bool _autoPolling = false;
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
    if (res['artifact_id'] != null) setState(() => _artifactId = res['artifact_id'].toString());
    if (res['artifact_id'] != null) setState(() => _artifactId = res['artifact_id'].toString());
      _runId = (res['run_id'] ?? '').toString();
    if (res['artifact_id'] != null) setState(() => _artifactId = res['artifact_id'].toString());
      _status = res;
      _append('Dispatch: ${jsonEncode(res)}');
      await _autoPollUntilDone();
    } catch (e) {
      _append('Error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _poll() async {
    if (_runId == null || _runId!.isEmpty) {
      _append('No runId yet. Trigger a cloud build first.');
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      _append('Polling status for runId=$_runId …');
      final res = await DemoApi.cloudStatus(_runId!);
    if (res['artifact_id'] != null) setState(() => _artifactId = res['artifact_id'].toString());
    if (res['artifact_id'] != null) setState(() => _artifactId = res['artifact_id'].toString());
      _status = res;
      _append('Status: ${jsonEncode(res)}');
    } catch (e) {
      _append('Error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _autoPollUntilDone() async {
    if (_runId == null || _runId!.isEmpty) return;
    _autoPolling = true;
    try {
      for (int i = 0; i < 120; i++) { // ~8 minutes max
        await _poll();
        if (!mounted) break;
        final s = (_status?["status"] ?? "").toString();
        if (s == "completed") break;
        await Future.delayed(const Duration(seconds: 4));
        if (!_autoPolling) break;
      }
    } finally {
      _autoPolling = false;
    }
  }

  Future<void> _unzip() async {
    final artId = (_status?['artifact_id'] ?? '').toString();
    if (artId.isEmpty) {
      _append('No artifact_id yet. Wait for build to complete.');
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      _append('Unzipping artifact $artId …');
      final res = await DemoApi.unzipArtifact(artId);
    if (res['artifact_id'] != null) setState(() => _artifactId = res['artifact_id'].toString());
    if (res['artifact_id'] != null) setState(() => _artifactId = res['artifact_id'].toString());
      // merge into status under "unzipped"
      _status = Map<String, dynamic>.from(_status ?? {});
      _status!['unzipped'] = res;
      _append('Unzipped: ${jsonEncode(res)}');
    } catch (e) {
      _append('Error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final artifactId = (_status?['artifact_id'] ?? '').toString();
    final downloadZip = (_status?['download_url'] ?? '').toString();
    final unzipInfo = _status?['unzipped'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Builds'),
        actions: [
          IconButton(
            tooltip: 'Copy log',
            onPressed: _copyLog,
            icon: const Icon(Icons.copy_all),
          ),
          IconButton(
            tooltip: 'Clear log',
            onPressed: () => setState(() => _log = ''),
            icon: const Icon(Icons.clear),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _poll,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _busy ? null : _triggerCloud,
                  icon: const Icon(Icons.cloud),
                  label: const Text('Build in Cloud'),
                ),
                ElevatedButton.icon(
                  onPressed: _busy ? null : _poll,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Poll Status'),
                ),
                ElevatedButton.icon(
                  onPressed: _busy
                      ? null
                      : () {
                          _autoPolling = false;
                          _append("Auto-poll stopped.");
                        },
                  icon: const Icon(Icons.stop),
                  label: const Text("Stop Poll"),
                ),
                if (downloadZip.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: _busy ? null : () => _openUrl(downloadZip),
                    icon: const Icon(Icons.archive),
                    label: const Text('Download ZIP'),
                  ),
                if (artifactId.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: _busy ? null : _unzip,
                    icon: const Icon(Icons.unarchive),
                    label: const Text('Unzip'),
                  ),
                if ((unzipInfo?['apk_url'] ?? '').toString().isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: _busy ? null : () => _openUrl(unzipInfo!['apk_url']),
                    icon: const Icon(Icons.download),
                    label: const Text('Download APK'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Latest status', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _status == null ? '—' : const JsonEncoder.withIndent('  ').convert(_status),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Log', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _log.isEmpty ? '—' : _log,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
