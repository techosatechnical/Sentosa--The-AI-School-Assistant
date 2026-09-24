import 'package:flutter/material.dart';
import 'package:sentosa/widgets/widgets.dart';

class HomeSentosaMicSection extends StatelessWidget {
  final bool isListening;
  final bool isSpeaking;
  final String statusText;
  final AnimationController pulseAnimation;
  final AnimationController waveAnimation;
  final VoidCallback onBackTap;
  final VoidCallback onMicTap;

  const HomeSentosaMicSection({
    super.key,
    required this.isListening,
    required this.isSpeaking,
    required this.statusText,
    required this.pulseAnimation,
    required this.waveAnimation,
    required this.onBackTap,
    required this.onMicTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isSpeaking
        ? const Color(0xFFA855F7)
        : (isListening ? const Color(0xFF38BDF8) : const Color(0xFF10B981));

    return Container(
      key: const ValueKey('MicSection'),
      constraints: const BoxConstraints(minHeight: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.keyboard_backspace_rounded,
                  color: Color(0xFF0F2942),
                  size: 28,
                ),
                onPressed: onBackTap,
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "TALK TO SENTOSA",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F2942),
                      letterSpacing: -0.6,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    "Your School's AI assistant.",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 75),
          StatusBadge(
            isListening: isListening,
            isSpeaking: isSpeaking,
            activeColor: activeColor,
          ),
          const SizedBox(height: 14),
          Text(
            statusText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              color: const Color(0xFF0F2942).withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          MicButton(
            size: 400.0,
            pulseAnimation: pulseAnimation,
            waveAnimation: waveAnimation,
            isListening: isListening,
            isSpeaking: isSpeaking,
            activeColor: activeColor,
            onTap: onMicTap,
          ),
        ],
      ),
    );
  }
}
