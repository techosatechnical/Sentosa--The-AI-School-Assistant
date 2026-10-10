import 'package:flutter/material.dart';
import 'package:nira/widgets/widgets.dart';

class HomeSentosaMicSection extends StatelessWidget {
  final bool isListening;
  final bool isSpeaking;
  final bool isThinking;
  final double currentAmplitude;
  final String statusText;
  final AnimationController pulseAnimation;
  final AnimationController waveAnimation;
  final VoidCallback onMicTap;

  const HomeSentosaMicSection({
    super.key,
    required this.isListening,
    required this.isSpeaking,
    this.isThinking = false,
    this.currentAmplitude = -50.0,
    required this.statusText,
    required this.pulseAnimation,
    required this.waveAnimation,
    required this.onMicTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isSpeaking
        ? const Color(0xFFA855F7)
        : isThinking
        ? const Color(0xFFF59E0B)
        : (isListening ? const Color(0xFF38BDF8) : const Color(0xFF10B981));

    return Container(
      key: const ValueKey('MicSection'),
      constraints: const BoxConstraints(minHeight: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 75),
          StatusBadge(
            isListening: isListening,
            isSpeaking: isSpeaking,
            isThinking: isThinking,
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
