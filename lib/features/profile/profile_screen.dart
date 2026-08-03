// PL-17 Profile Screen
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PL-17 Profile')),
      body: const Center(
        child: Text('PL-17 Profile Screen'),
      ),
    );
  }
}
