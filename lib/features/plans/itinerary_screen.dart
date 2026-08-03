// RM-10 Interactive Itinerary
import 'package:flutter/material.dart';

class ItineraryScreen extends StatelessWidget {
  final String bookingId;
  const ItineraryScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('RM-10 Interactive Itinerary ($bookingId)')),
      body: Center(
        child: Text('RM-10 Interactive Itinerary Screen ($bookingId)'),
      ),
    );
  }
}
