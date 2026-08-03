// RM-21 Settings
import 'package:flutter/material.dart';

class MoreSettingsScreen extends StatelessWidget {
  const MoreSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RM-21 Settings')),
      body: const Center(
        child: Text('RM-21 More Settings Screen'),
      ),
    );
  }
}
