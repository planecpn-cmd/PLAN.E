// RM-13 Budget Tracker
import 'package:flutter/material.dart';

class BudgetTrackerScreen extends StatelessWidget {
  final String bookingId;
  const BudgetTrackerScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('RM-13 Budget Tracker ($bookingId)')),
      body: Center(
        child: Text('RM-13 Budget Tracker Screen ($bookingId)'),
      ),
    );
  }
}
