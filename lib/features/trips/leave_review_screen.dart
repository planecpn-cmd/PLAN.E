// RM-14 Leave a Review
import 'package:flutter/material.dart';

class LeaveReviewScreen extends StatelessWidget {
  final String bookingId;
  const LeaveReviewScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('RM-14 Leave Review ($bookingId)')),
      body: Center(
        child: Text('RM-14 Leave a Review Screen ($bookingId)'),
      ),
    );
  }
}
