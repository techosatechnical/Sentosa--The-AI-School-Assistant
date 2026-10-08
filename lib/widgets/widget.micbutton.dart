import 'dart:math' as math;
import 'package:flutter/material.dart';

class MicButton extends StatelessWidget {
  final Animation<double> pulseAnimation;
  final Animation<double>? waveAnimation;
  final bool isListening;
  final bool isSpeaking;
  final Color activeColor;
  final VoidCallback onTap;
  final double size;

  const MicButton({
    super.key,
    required this.pulseAnimation,
    this.waveAnimation,
    required this.isListening,
    required this.isSpeaking,
    required this.activeColor,
    required this.onTap,
    this.size = 340.0,
  });

  @override
  Widget build(BuildContext context) {
    final scale = size / 340.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([pulseAnimation, ?waveAnimation]),
        builder: (context, child) {
          final pulse = pulseAnimation.value;
          final wave = waveAnimation?.value ?? pulse;

          return SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isListening || isSpeaking)
                  Container(
                    width: (270 + (pulse * 64)) * scale,
                    height: (270 + (pulse * 64)) * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: activeColor.withValues(
                          alpha: 0.35 * (1.0 - pulse),
                        ),
                        width: 2.8 * scale,
                      ),
                    ),
                  ),

                if (isListening || isSpeaking)
                  Container(
                    width: (230 + (pulse * 42)) * scale,
                    height: (230 + (pulse * 42)) * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: activeColor.withValues(
                        alpha: 0.16 * (1.0 - (pulse * 0.4)),
                      ),
                    ),
                  ),

                if (isListening || isSpeaking)
                  ...List.generate(24, (index) {
                    final angle = (index * 2 * math.pi) / 24;
                    final barHeight =
                        (10.0 +
                            (math
                                    .sin((wave * 2 * math.pi) + (index * 0.65))
                                    .abs() *
                                22.0)) *
                        scale;
                    final distance = (128.0 + (pulse * 12.0)) * scale;
                    final x = math.cos(angle) * distance;
                    final y = math.sin(angle) * distance;

                    return Transform.translate(
                      offset: Offset(x, y),
                      child: Transform.rotate(
                        angle: angle + (math.pi / 2),
                        child: Container(
                          width: (4.5 * scale).clamp(2.5, 4.5),
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: activeColor.withValues(
                              alpha: 0.7 + (wave * 0.3),
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    );
                  }),

                Container(
                  width: 206 * scale,
                  height: 206 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.25, -0.35),
                      radius: 0.95,
                      colors: isListening || isSpeaking
                          ? [
                              activeColor.withValues(alpha: 0.5),
                              activeColor.withValues(alpha: 0.22),
                              const Color(0xFF0F172A),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.16),
                              Colors.white.withValues(alpha: 0.05),
                              const Color(0xFF0F172A),
                            ],
                    ),
                    border: Border.all(
                      color: isListening || isSpeaking
                          ? activeColor.withValues(alpha: 0.92)
                          : Colors.white.withValues(alpha: 0.28),
                      width: 4.0 * scale,
                    ),
                    boxShadow: isListening || isSpeaking
                        ? [
                            BoxShadow(
                              color: activeColor.withValues(
                                alpha: 0.55 * (0.65 + pulse * 0.35),
                              ),
                              blurRadius: 70 * scale,
                              spreadRadius: 10 * scale,
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 32 * scale,
                              offset: Offset(0, 8 * scale),
                            ),
                          ],
                  ),
                  child: Icon(
                    isSpeaking
                        ? Icons.volume_up_rounded
                        : (isListening
                              ? Icons.graphic_eq_rounded
                              : Icons.mic_rounded),
                    size: 92 * scale,
                    color: isListening || isSpeaking
                        ? activeColor
                        : Colors.white.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
