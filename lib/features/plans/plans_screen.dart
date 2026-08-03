// PL-13 My Plans (Upcoming) / PL-14 My Plans (Drafts)
import 'package:flutter/material.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PL-13 / PL-14 My Plans')),
      body: const Center(
        child: Text('PL-13 Upcoming / PL-14 Drafts Screen'),
      ),
    );
  }
}
