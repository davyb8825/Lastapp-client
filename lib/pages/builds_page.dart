import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import '../services/demo_api.dart';

class BuildsPage extends StatefulWidget {
  const BuildsPage({super.key});
  @override
  State<BuildsPage> createState() => _BuildsPageState();
}

class _BuildsPageState extends State<BuildsPage> {
  bool _busy = false;

  String? _runId;
  String? _status;      // in_progress | completed
  String? _conclusion;  // success | failure | null
  String? _artifactId;
  String? _downloadUrl; // backend proxy to artifact zip

  Uri? _debugApk;
  Uri? _releaseApk;

  Timer? _poller;

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  Future<void> _startCloudBuild() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _runId = null;
      _status = null;
      _conclusion = null;
      _artifactId = null;
      _downloadUrl = null;
      _debugApk = null;
      _releaseApk = null;
    });

    try {
      // Kick off CI
      final res = await DemoApi.buildCloud(); // POST /build/cloud
      final runId = (res['run_id'] ?? '').toString();

      setState(() {
        _runId = runId.isNotEmpty ? runId : null;
        _status = res['status']?.toString();
      });

      if (_runId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start cloud build')),
        );
        return;
      }

      // Start polling
      _poller?.cancel();
      _poller = Timer.periodic(const Duration(seconds: 6), (_) => _pollOnce());
      // Immediate poll for faster UI update
      await _pollOnce();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start cloud build: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pollOnce() async {
    if (_runId == null) return;
    try {
      final res = await DemoApi.cloudStatus(_runId!); // GET /build/cloud/{run_id}
      final status = res['status']?.toString();
      final conclusion = res['conclusion']?.toString();
      final artifactId = res['artifact_id']?.toString();
      final downloadUrl = res['download_url']?.toString();

      setState(() {
        _status = status;
        _conclusion = conclusion;
        if ((artifactId ?? '').isNotEmpty) _artifactId = artifactId;
        if ((downloadUrl ?? '').isNotEmpty) _downloadUrl = downloadUrl;
      });

      if (status == 'completed') {
        _poller?.cancel();
        if (conclusion == 'success' && _artifactId != null) {
          await _prepareApks(); // download zip + unzip + locate APKs
        } else if (conclusion == 'failure' && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Build failed – check CI logs')),
          );
        }
      }
    } catch (_) {
      // non-fatal; keep polling until completed
    }
    if (mounted) setState(() {});
  }

  Future<void> _prepareApks() async {
    if (_artifactId == null) return;

    // 1) If backend gave a direct download_url proxy, hit it (backend writes zip to disk)
    if ((_downloadUrl ?? '').isNotEmpty) {
      try {
        await http.get(Uri.parse(_downloadUrl!));
      } catch (_) {/* ignore */}
    }

    // 2) Ask backend to unzip and return direct APK URLs
    try {
      final info = await DemoApi.unzipArtifact(_artifactId!); // POST /artifacts/cloud/{id}/unzip
      final debugUrl = info['debug_apk_url'] as String?;
      final releaseUrl = info['release_apk_url'] as String?;

      setState(() {
        _debugApk = (debugUrl != null && debugUrl.isNotEmpty) ? Uri.parse(debugUrl) : null;
        _releaseApk = (releaseUrl != null && releaseUrl.isNotEmpty) ? Uri.parse(releaseUrl) : null;
      });

      if (_debugApk == null && _releaseApk == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No APK found in artifact.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unzip failed: $e')),
      );
    }
  }

  Future<void> _open(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open ${url.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      _kv('Run ID', _runId),
      _kv('Status', _status),
      _kv('Conclusion', _conclusion),
      _kv('Artifact ID', _artifactId),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Builds (Cloud)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: _busy ? null : _startCloudBuild,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Start Cloud Build'),
                ),
                if (_runId != null && _status != 'completed')
                  OutlinedButton.icon(
                    onPressed: _pollOnce,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Poll Now'),
                  ),
                if (_artifactId != null)
                  OutlinedButton.icon(
                    onPressed: _prepareApks,
                    icon: const Icon(Icons.unarchive),
                    label: const Text('Unzip Artifact'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...rows,
            const Divider(height: 32),

            // APK download buttons
            if (_debugApk != null || _releaseApk != null) ...[
              const Text('APK Downloads', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (_debugApk != null)
                    OutlinedButton.icon(
                      onPressed: () => _open(_debugApk!),
                      icon: const Icon(Icons.download),
                      label: const Text('Download Debug APK'),
                    ),
                  if (_releaseApk != null)
                    OutlinedButton.icon(
                      onPressed: () => _open(_releaseApk!),
                      icon: const Icon(Icons.download),
                      label: const Text('Download Release APK'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            if (_status == 'in_progress') const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String? v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text('$k:', style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(v ?? '—')),
        ],
      ),
    );
  }
}
