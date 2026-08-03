// PL-10 Booking Form (Walled)
// TEMP: client pricing, server re-price lands in Phase 7
import 'package:flutter/material.dart';

class BookingScreen extends StatelessWidget {
  final String experienceId;
  const BookingScreen({super.key, required this.experienceId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PL-10 Booking Form ($experienceId)')),
      body: Center(
        child: Text('PL-10 Booking Form Screen ($experienceId)'),
      ),
    );
  }
}
