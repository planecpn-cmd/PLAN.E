// PL-02 Onboarding Slide 1 / PL-03 Slide 2 / PL-04 Slide 3
import 'package:flutter/material.dart';

class OnboardingSlideScreen extends StatelessWidget {
  final int step;
  const OnboardingSlideScreen({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    final String id = step == 1 ? 'PL-02' : (step == 2 ? 'PL-03' : 'PL-04');
    return Scaffold(
      appBar: AppBar(title: Text('$id Onboarding Slide $step')),
      body: Center(
        child: Text(
          '$id Onboarding Slide $step',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
