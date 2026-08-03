// RM-06 Collection / See All
import 'package:flutter/material.dart';

class CollectionScreen extends StatelessWidget {
  final String slug;
  const CollectionScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('RM-06 Collection: $slug')),
      body: Center(
        child: Text('RM-06 Collection Screen: $slug'),
      ),
    );
  }
}
