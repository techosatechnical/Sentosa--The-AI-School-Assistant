import 'dart:math' as math;
import 'package:flutter/material.dart';

class HomeSpeechBubble extends StatelessWidget {
  final String aiResponse;
  final Map<String, String> currentGreeting;
  final bool isSpeaking;
  final Animation<double> waveAnimation;
  final VoidCallback onTap;

  const HomeSpeechBubble({
    super.key,
    required this.aiResponse,
    required this.currentGreeting,
    required this.isSpeaking,
    required this.waveAnimation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasResponse = aiResponse.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -6,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.98),
                  border: const Border(
                    top: BorderSide(color: Color(0xFFE0F2FE)),
                    left: BorderSide(color: Color(0xFFE0F2FE)),
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F2942).withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: hasResponse
                    ? (isSpeaking
                          ? const Color(0xFFA855F7).withValues(alpha: 0.4)
                          : const Color(0xFF38BDF8).withValues(alpha: 0.4))
                    : const Color(0xFFE0F2FE),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!hasResponse) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        currentGreeting['hi'] ?? 'Hi!',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F2942),
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedBuilder(
                        animation: waveAnimation,
                        builder: (context, child) {
                          final waveAngle =
                              math.sin(waveAnimation.value * math.pi * 2) *
                              0.25;
                          return Transform.rotate(
                            angle: waveAngle,
                            child: const Text(
                              "👋",
                              style: TextStyle(fontSize: 24),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentGreeting['text'] ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                      height: 1.35,
                    ),
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isSpeaking ? "Sentosa Speaking..." : "Sentosa",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isSpeaking
                              ? const Color(0xFFA855F7)
                              : const Color(0xFF0F2942),
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.auto_awesome,
                        size: 18,
                        color: isSpeaking
                            ? const Color(0xFFA855F7)
                            : const Color(0xFF38BDF8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 160),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        aiResponse,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F2942),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
