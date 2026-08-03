// PL-06 Home Screen
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PL-06 Home')),
      body: const Center(
        child: Text('PL-06 Home Screen'),
      ),
    );
  }
}
