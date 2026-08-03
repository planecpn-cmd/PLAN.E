// RM-11 Trip Chat
import 'package:flutter/material.dart';

class TripChatScreen extends StatelessWidget {
  final String bookingId;
  const TripChatScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('RM-11 Trip Chat ($bookingId)')),
      body: Center(
        child: Text('RM-11 Trip Chat Screen ($bookingId)'),
      ),
    );
  }
}
