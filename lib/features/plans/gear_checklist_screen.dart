// RM-12 Gear Checklist
import 'package:flutter/material.dart';

class GearChecklistScreen extends StatelessWidget {
  final String bookingId;
  const GearChecklistScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('RM-12 Gear Checklist ($bookingId)')),
      body: Center(
        child: Text('RM-12 Gear Checklist Screen ($bookingId)'),
      ),
    );
  }
}
