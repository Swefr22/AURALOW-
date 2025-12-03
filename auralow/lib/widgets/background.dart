// lib/widgets/background.dart
import 'package:flutter/material.dart';

class CalmBackground extends StatelessWidget {
  final Widget? child;
  final Gradient? gradient;
  const CalmBackground({Key? key, this.child, this.gradient}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0F172A), Color(0xFF4C1D95)], // navy -> purple
    );

    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? defaultGradient,
      ),
      child: Stack(
        children: [
          // optional subtle overlay (comment out if no asset)
          // Positioned.fill(child: Opacity(opacity: 0.05, child: Image.asset('assets/particles.png', fit: BoxFit.cover))),
          if (child != null) child!,
        ],
      ),
    );
  }
}
