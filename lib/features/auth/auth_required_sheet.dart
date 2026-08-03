// RM-05 Authentication Required Sheet
import 'package:flutter/material.dart';

class AuthRequiredSheet extends StatelessWidget {
  const AuthRequiredSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RM-05 Auth Required')),
      body: const Center(
        child: Text('RM-05 Authentication Required Sheet'),
      ),
    );
  }
}
