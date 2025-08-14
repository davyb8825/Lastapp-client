import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lastapp_client/services/demo_api.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class BuildsPage extends StatefulWidget {
  const BuildsPage({super.key});
  @override
  State<BuildsPage> createState() => _BuildsPageState();
}

class _BuildsPageState extends State<BuildsPage> {
  String _log = 'Ready.';
  bool _busy = false;
  List<Map<String, dynamic>> _jobs = [];
  List<Map<String, dynamic>> _builds = [];

  void _append(String line) {
    setState(() => _log = (_log.isEmpty ? line : '$_log\n$line'));
  }

  Future<void> _refresh() async {
    try {
      final jobs = await _get('/jobs', 'jobs');
      final builds = await _get('/builds', 'builds');
      setState(() {
        _jobs = jobs;
        _builds = builds;
      });
    } catch (e) {
      _append('Refresh error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _get(String path, String key) async {
    final resp = await http.get(Uri.parse('${DemoApi.base}$path'));
    if (resp.statusCode != 200) return [];
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final list = (data[key] as List? ?? []);
    return list.map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  Future<void> _scaffold() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      _append('Scaffolding "Demo Notes App"...');
      final res = await DemoApi.scaffold('Demo Notes App', template: 'starter');
      _append('Scaffold result: $res');
      await _refresh();
    } catch (e) {
      _append('Error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _buildAndroid() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      _append('Triggering Android build...');
      final res = await DemoApi.buildAndroid('Demo Notes App');
      _append('Build result: $res');
      await _refresh();
    } catch (e) {
      _append('Error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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

  Future<void> _copyLog() async {
    await Clipboard.setData(ClipboardData(text: _log));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Log copied to clipboard')),
    );
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: _busy ? null : _scaffold,
                icon: const Icon(Icons.view_timeline),
                label: const Text('Scaffold Project'),
              ),
              ElevatedButton.icon(
                onPressed: _busy ? null : _buildAndroid,
                icon: const Icon(Icons.android),
                label: const Text('Build Android'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Jobs', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_jobs.isEmpty)
            const Text('No jobs yet.')
          else
            ..._jobs.map((j) => _JobTile(job: j)).toList(),
          const SizedBox(height: 16),
          const Text('Builds', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_builds.isEmpty)
            const Text('No builds yet.')
          else
            ..._builds.map((b) {
              final artifact = (b['artifact_url'] ?? '') as String;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.build_circle),
                  title: Text('Build ${b['build_id'] ?? ''}'),
                  subtitle: Text('Status: ${b['status'] ?? 'unknown'} • Project: ${b['project'] ?? ''}'),
                  isThreeLine: artifact.isNotEmpty,
                  trailing: artifact.isNotEmpty
                      ? TextButton.icon(
                          onPressed: () => _openUrl(artifact),
                          icon: const Icon(Icons.download),
                          label: const Text('Download APK'),
                        )
                      : null,
                ),
              );
            }).toList(),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Log', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                tooltip: 'Copy log',
                icon: const Icon(Icons.copy_all),
                onPressed: _copyLog,
              ),
              IconButton(
                tooltip: 'Clear log',
                icon: const Icon(Icons.clear),
                onPressed: () => setState(() => _log = ''),
              ),
            ],
          ),
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
    );
  }
}

class _JobTile extends StatelessWidget {
  final Map<String, dynamic> job;
  const _JobTile({required this.job});

  @override
  Widget build(BuildContext context) {
    final status = job['status'] ?? 'unknown';
    final id = job['job_id'] ?? '';
    final type = job['type'] ?? '';
    final proj = job['project_name'] ?? '';
    return Card(
      child: ListTile(
        leading: Icon(
          status == 'done' ? Icons.check_circle : Icons.timelapse,
          color: status == 'done' ? Colors.green : null,
        ),
        title: Text('$type — $proj'),
        subtitle: Text('Job $id\nStatus: $status'),
        isThreeLine: true,
      ),
    );
  }
}
