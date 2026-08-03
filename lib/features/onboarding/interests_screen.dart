// PL-05 Select Interests
import 'package:flutter/material.dart';

class InterestsScreen extends StatelessWidget {
  const InterestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PL-05 Select Interests')),
      body: const Center(
        child: Text(
          'PL-05 Select Interests (min 3 selection rule)',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
