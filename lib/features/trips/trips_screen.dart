// PL-15 My Trips (Completed) / PL-16 My Trips (Cancelled)
import 'package:flutter/material.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PL-15 / PL-16 My Trips')),
      body: const Center(
        child: Text('PL-15 Completed / PL-16 Cancelled Trips Screen'),
      ),
    );
  }
}
