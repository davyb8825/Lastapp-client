import 'package:flutter/material.dart';
import '../services/demo_api.dart';

class BuildsPage extends StatefulWidget {
  const BuildsPage({super.key});
  @override
  State<BuildsPage> createState() => _BuildsPageState();
}

class _BuildsPageState extends State<BuildsPage> {
  String _log = 'Ready.';
  String? _lastJobId;
  String? _lastBuildId;
  bool _busy = false;

  void _append(String line) {
    setState(() => _log = (_log.isEmpty ? line : '$_log\n$line'));
  }

  Future<void> _scaffold() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      _append('Scaffolding project "Demo Notes App"...');
      final result = await DemoApi.scaffold('Demo Notes App', template: 'starter');
      _append('Scaffold result: $result');
      _lastJobId = result['job_id'] as String?;
      if (_lastJobId != null) {
        _append('Status: ' + st.toString());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _buildAndroid() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      _append('Triggering Android build...');
      final result = await DemoApi.buildAndroid('Demo Notes App');
      _append('Build result: $result');
      _lastBuildId = result['build_id'] as String?;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            ],
          ),
          const SizedBox(height: 12),
          const Text('Log:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _log,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
