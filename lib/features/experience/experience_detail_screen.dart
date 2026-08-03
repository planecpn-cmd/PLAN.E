// PL-09 Experience Details
import 'package:flutter/material.dart';

class ExperienceDetailScreen extends StatelessWidget {
  final String id;
  const ExperienceDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PL-09 Experience Details ($id)')),
      body: Center(
        child: Text('PL-09 Experience Details Screen ($id)'),
      ),
    );
  }
}
