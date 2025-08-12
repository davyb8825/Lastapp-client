import 'package:flutter/material.dart';
import 'pages/chat_page.dart';
import 'pages/projects_page.dart';
import 'pages/builds_page.dart';

void main() {
  runApp(const LastApp());
}

class LastApp extends StatelessWidget {
  const LastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LastApp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C63FF)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('LastApp'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Chat', icon: Icon(Icons.chat_bubble_outline)),
              Tab(text: 'Projects', icon: Icon(Icons.folder_open)),
              Tab(text: 'Builds', icon: Icon(Icons.build_circle_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ChatPage(),
            ProjectsPage(),
            BuildsPage(),
          ],
        ),
      ),
    );
  }
}
