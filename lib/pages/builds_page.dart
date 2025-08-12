import 'package:flutter/material.dart';

class BuildsPage extends StatelessWidget {
  const BuildsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text('Cloud Build (Step 1 — Demo)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Text(
          'After pushing to GitHub, go to Actions → Android Debug APK → latest run → Download artifact.\\n'
          'In Step 2, this tab will list builds and let you download APK/AAB directly.',
        ),
      ],
    );
  }
}
