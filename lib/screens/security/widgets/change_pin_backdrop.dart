import 'dart:ui';
import 'package:flutter/material.dart';

class ChangePinBackdrop extends StatelessWidget {
  const ChangePinBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          left: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.shade200.withValues(alpha: 0.4),
            ),
          ),
        ),
        Positioned(
          top: 200,
          left: -150,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.cyan.shade100.withValues(alpha: 0.5),
            ),
          ),
        ),
        Positioned(
          top: 300,
          right: -100,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.shade100.withValues(alpha: 0.6),
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          right: 50,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.indigo.shade50.withValues(alpha: 0.7),
            ),
          ),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
          child: Container(color: Colors.transparent),
        ),
      ],
    );
  }
}
