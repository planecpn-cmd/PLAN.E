// RM-02 Login
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RM-02 Login')),
      body: const Center(
        child: Text('RM-02 Login Screen'),
      ),
    );
  }
}
