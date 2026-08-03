// PL-11 Booking Confirmation
import 'package:flutter/material.dart';

class ConfirmationScreen extends StatelessWidget {
  final String bookingId;
  const ConfirmationScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PL-11 Booking Confirmation ($bookingId)')),
      body: Center(
        child: Text('PL-11 Booking Confirmation Screen ($bookingId)'),
      ),
    );
  }
}
