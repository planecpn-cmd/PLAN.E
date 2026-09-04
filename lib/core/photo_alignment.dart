import 'package:flutter/material.dart';

/// Composition only: the database remains the sole source of the image URL.
Alignment photoAlignment(String? url) =>
    switch (Uri.tryParse(url ?? '')?.pathSegments.lastOrNull) {
      'photo_3059892.webp' => const Alignment(0, 0.65),
      'photo_5011236.webp' ||
      'photo_37358046.webp' ||
      'photo_11052970.webp' => Alignment.topCenter,
      'photo_34912011.webp' => const Alignment(0, -0.5),
      _ => Alignment.center,
    };
