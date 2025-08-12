import 'package:flutter/material.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});
  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final List<String> _projects = ['Demo Notes App'];

  void _addProject() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text('New Project'),
          content: TextField(controller: c, decoration: const InputDecoration(hintText: 'Project name')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text('Create')),
          ],
        );
      },
    );
    if (name != null && name.isNotEmpty) setState(() => _projects.add(name));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _projects.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final p = _projects[i];
          return ListTile(
            leading: const Icon(Icons.folder),
            title: Text(p),
            subtitle: const Text('Tap for details (coming soon)'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProject,
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
      ),
    );
  }
}
