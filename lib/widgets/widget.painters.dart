import 'package:flutter/material.dart';
import 'dart:math' as math;

class SentosaLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 48.0;
    final scaleY = size.height / 48.0;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    final path1 = Path();
    path1.moveTo(14, 26);
    path1.cubicTo(14, 18, 20, 10, 28, 8);
    path1.cubicTo(26, 18, 20, 26, 14, 26);
    path1.close();
    canvas.drawPath(path1, Paint()..color = const Color(0xFF00A896));

    final path2 = Path();
    path2.moveTo(10, 24);
    path2.cubicTo(10, 32, 18, 38, 26, 36);
    path2.cubicTo(24, 28, 18, 24, 10, 24);
    path2.close();
    canvas.drawPath(path2, Paint()..color = const Color(0xFF0284C7));

    final path3 = Path();
    path3.moveTo(34, 22);
    path3.cubicTo(34, 14, 28, 8, 20, 10);
    path3.cubicTo(22, 18, 28, 22, 34, 22);
    path3.close();
    canvas.drawPath(path3, Paint()..color = const Color(0xFFF59E0B));

    canvas.drawCircle(
      const Offset(24, 24),
      3.0,
      Paint()..color = const Color(0xFF0F2942),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MapGraphicPainter extends CustomPainter {
  final Color dashColor;
  MapGraphicPainter(this.dashColor);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final dashPaint = Paint()
      ..color = dashColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(cx - 24, cy - 20),
      Offset(cx - 18, cy - 24),
      dashPaint,
    );
    canvas.drawLine(
      Offset(cx + 20, cy - 18),
      Offset(cx + 26, cy - 14),
      dashPaint,
    );

    final p1 = Path()
      ..moveTo(cx - 24, cy - 6)
      ..lineTo(cx - 8, cy - 14)
      ..lineTo(cx - 8, cy + 18)
      ..lineTo(cx - 24, cy + 10)
      ..close();
    canvas.drawPath(p1, Paint()..color = const Color(0xFF4ADE80));

    final p2 = Path()
      ..moveTo(cx - 8, cy - 14)
      ..lineTo(cx + 8, cy - 6)
      ..lineTo(cx + 8, cy + 26)
      ..lineTo(cx - 8, cy + 18)
      ..close();
    canvas.drawPath(p2, Paint()..color = const Color(0xFF22C55E));

    final p3 = Path()
      ..moveTo(cx + 8, cy - 6)
      ..lineTo(cx + 24, cy - 14)
      ..lineTo(cx + 24, cy + 18)
      ..lineTo(cx + 8, cy + 26)
      ..close();
    canvas.drawPath(p3, Paint()..color = const Color(0xFF38BDF8));

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 10), width: 14, height: 6),
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );

    final pinPath = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(cx, cy - 3), radius: 10),
        -math.pi * 0.8,
        math.pi * 1.6,
      )
      ..lineTo(cx, cy + 9)
      ..close();
    canvas.drawPath(pinPath, Paint()..color = const Color(0xFFEF4444));

    canvas.drawCircle(Offset(cx, cy - 3), 3.8, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PrincipalGraphicPainter extends CustomPainter {
  final Color dashColor;
  PrincipalGraphicPainter(this.dashColor);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final dashPaint = Paint()
      ..color = dashColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(cx - 24, cy - 16),
      Offset(cx - 18, cy - 22),
      dashPaint,
    );
    canvas.drawLine(
      Offset(cx + 18, cy - 20),
      Offset(cx + 24, cy - 15),
      dashPaint,
    );

    canvas.drawCircle(
      Offset(cx, cy - 12),
      12.5,
      Paint()..color = const Color(0xFF4F46E5),
    );

    final suitPath = Path()
      ..moveTo(cx - 22, cy + 24)
      ..cubicTo(cx - 22, cy + 5, cx - 12, cy + 1, cx, cy + 1)
      ..cubicTo(cx + 12, cy + 1, cx + 22, cy + 5, cx + 22, cy + 24)
      ..close();
    canvas.drawPath(suitPath, Paint()..color = const Color(0xFF3730A3));

    final collarPath = Path()
      ..moveTo(cx - 8, cy + 2)
      ..lineTo(cx + 8, cy + 2)
      ..lineTo(cx, cy + 14)
      ..close();
    canvas.drawPath(collarPath, Paint()..color = Colors.white);

    final tiePath = Path()
      ..moveTo(cx - 2.5, cy + 4)
      ..lineTo(cx + 2.5, cy + 4)
      ..lineTo(cx + 4, cy + 15)
      ..lineTo(cx, cy + 22)
      ..lineTo(cx - 4, cy + 15)
      ..close();
    canvas.drawPath(tiePath, Paint()..color = const Color(0xFF818CF8));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CafeteriaGraphicPainter extends CustomPainter {
  final Color dashColor;
  CafeteriaGraphicPainter(this.dashColor);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final dashPaint = Paint()
      ..color = dashColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(cx - 25, cy - 18),
      Offset(cx - 20, cy - 24),
      dashPaint,
    );
    canvas.drawLine(
      Offset(cx + 20, cy - 22),
      Offset(cx + 26, cy - 16),
      dashPaint,
    );

    canvas.drawCircle(
      Offset(cx, cy),
      25,
      Paint()..color = const Color(0xFF10B981),
    );

    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final fx = cx - 7;
    canvas.drawLine(Offset(fx, cy - 2), Offset(fx, cy + 14), strokePaint);
    final forkBase = Path()
      ..moveTo(fx - 4, cy - 6)
      ..cubicTo(fx - 4, cy, fx + 4, cy, fx + 4, cy - 6)
      ..close();
    canvas.drawPath(forkBase, whitePaint);
    canvas.drawLine(
      Offset(fx - 3.5, cy - 6),
      Offset(fx - 3.5, cy - 14),
      strokePaint,
    );
    canvas.drawLine(Offset(fx, cy - 6), Offset(fx, cy - 14), strokePaint);
    canvas.drawLine(
      Offset(fx + 3.5, cy - 6),
      Offset(fx + 3.5, cy - 14),
      strokePaint,
    );

    final sx = cx + 7;
    canvas.drawLine(Offset(sx, cy - 2), Offset(sx, cy + 14), strokePaint);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(sx, cy - 8), width: 8.5, height: 13),
      whitePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class EventsGraphicPainter extends CustomPainter {
  final Color dashColor;
  EventsGraphicPainter(this.dashColor);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final dashPaint = Paint()
      ..color = dashColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(cx - 24, cy - 20),
      Offset(cx - 18, cy - 24),
      dashPaint,
    );
    canvas.drawLine(
      Offset(cx + 20, cy - 22),
      Offset(cx + 26, cy - 18),
      dashPaint,
    );

    final calRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - 2, cy - 1), width: 44, height: 40),
      const Radius.circular(8),
    );
    canvas.drawRRect(calRect, Paint()..color = Colors.white);
    canvas.drawRRect(
      calRect,
      Paint()
        ..color = const Color(0xFFFB923C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    final headerClip = Path()..addRRect(calRect);
    canvas.save();
    canvas.clipPath(headerClip);
    canvas.drawRect(
      Rect.fromLTWH(cx - 25, cy - 22, 50, 11),
      Paint()..color = const Color(0xFFEA580C),
    );
    canvas.restore();

    final ringPaint = Paint()
      ..color = const Color(0xFF9A3412)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - 12, cy - 23),
      Offset(cx - 12, cy - 16),
      ringPaint,
    );
    canvas.drawLine(
      Offset(cx + 8, cy - 23),
      Offset(cx + 8, cy - 16),
      ringPaint,
    );

    final dotPaint = Paint()..color = const Color(0xFFFDBA74);
    for (int r = 0; r < 2; r++) {
      for (int c = 0; c < 3; c++) {
        final dx = cx - 14 + (c * 9.5);
        final dy = cy - 2 + (r * 8.5);
        canvas.drawCircle(Offset(dx, dy), 2.0, dotPaint);
      }
    }

    final clockCx = cx + 15;
    final clockCy = cy + 12;
    canvas.drawCircle(
      Offset(clockCx, clockCy),
      10.5,
      Paint()..color = const Color(0xFFF59E0B),
    );
    canvas.drawCircle(
      Offset(clockCx, clockCy),
      10.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final handPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(clockCx, clockCy),
      Offset(clockCx, clockCy - 5),
      handPaint,
    );
    canvas.drawLine(
      Offset(clockCx, clockCy),
      Offset(clockCx + 4, clockCy),
      handPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BusGraphicPainter extends CustomPainter {
  final Color dashColor;
  BusGraphicPainter(this.dashColor);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final dashPaint = Paint()
      ..color = dashColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(cx - 24, cy - 18),
      Offset(cx - 18, cy - 24),
      dashPaint,
    );
    canvas.drawLine(
      Offset(cx + 20, cy - 22),
      Offset(cx + 26, cy - 18),
      dashPaint,
    );

    final busRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 2), width: 44, height: 38),
      const Radius.circular(10),
    );
    canvas.drawRRect(busRect, Paint()..color = const Color(0xFFFBBF24));

    final mirrorPaint = Paint()..color = const Color(0xFFF59E0B);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 24, cy - 2), width: 4, height: 9),
        const Radius.circular(2),
      ),
      mirrorPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 24, cy - 2), width: 4, height: 9),
        const Radius.circular(2),
      ),
      mirrorPaint,
    );

    final windRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy - 5), width: 34, height: 16),
      const Radius.circular(4),
    );
    canvas.drawRRect(windRect, Paint()..color = const Color(0xFFE0F2FE));
    canvas.drawLine(
      Offset(cx, cy - 13),
      Offset(cx, cy + 3),
      Paint()
        ..color = const Color(0xFFFBBF24)
        ..strokeWidth = 2,
    );

    canvas.drawCircle(
      Offset(cx - 12, cy + 10),
      3.6,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(cx - 12, cy + 10),
      3.6,
      Paint()
        ..color = const Color(0xFFF59E0B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(
      Offset(cx + 12, cy + 10),
      3.6,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(cx + 12, cy + 10),
      3.6,
      Paint()
        ..color = const Color(0xFFF59E0B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + 17), width: 36, height: 5),
        const Radius.circular(2.5),
      ),
      Paint()..color = const Color(0xFF334155),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AdmissionGraphicPainter extends CustomPainter {
  final Color dashColor;
  AdmissionGraphicPainter(this.dashColor);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final dashPaint = Paint()
      ..color = dashColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(cx - 24, cy - 20),
      Offset(cx - 18, cy - 24),
      dashPaint,
    );
    canvas.drawLine(
      Offset(cx + 20, cy - 22),
      Offset(cx + 26, cy - 18),
      dashPaint,
    );

    final docRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - 3, cy - 1), width: 38, height: 44),
      const Radius.circular(8),
    );
    canvas.drawRRect(docRect, Paint()..color = const Color(0xFF06B6D4));

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - 14, cy - 11),
      Offset(cx + 2, cy - 11),
      linePaint,
    );
    canvas.drawLine(Offset(cx - 14, cy - 3), Offset(cx + 8, cy - 3), linePaint);
    canvas.drawLine(Offset(cx - 14, cy + 5), Offset(cx - 2, cy + 5), linePaint);

    final plusCx = cx + 13;
    final plusCy = cy + 13;
    canvas.drawCircle(
      Offset(plusCx, plusCy),
      11.5,
      Paint()..color = const Color(0xFF0891B2),
    );
    canvas.drawCircle(
      Offset(plusCx, plusCy),
      11.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final pPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(plusCx - 5, plusCy),
      Offset(plusCx + 5, plusCy),
      pPaint,
    );
    canvas.drawLine(
      Offset(plusCx, plusCy - 5),
      Offset(plusCx, plusCy + 5),
      pPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TalkGraphicPainter extends CustomPainter {
  final Color dashColor;
  TalkGraphicPainter(this.dashColor);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final dashPaint = Paint()
      ..color = dashColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(cx - 24, cy - 18),
      Offset(cx - 18, cy - 24),
      dashPaint,
    );
    canvas.drawLine(
      Offset(cx + 20, cy - 22),
      Offset(cx + 26, cy - 18),
      dashPaint,
    );

    final headCx = cx - 6;
    canvas.drawCircle(
      Offset(headCx, cy - 10),
      12.0,
      Paint()..color = const Color(0xFF6366F1),
    );

    final suitPath = Path()
      ..moveTo(headCx - 20, cy + 22)
      ..cubicTo(headCx - 20, cy + 5, headCx - 10, cy + 2, headCx, cy + 2)
      ..cubicTo(headCx + 10, cy + 2, headCx + 18, cy + 5, headCx + 18, cy + 22)
      ..close();
    canvas.drawPath(suitPath, Paint()..color = const Color(0xFF4F46E5));

    final textPainter = TextPainter(
      text: const TextSpan(
        text: '?',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: Color(0xFF312E81),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(cx + 9, cy - 14));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class QuestionsGraphicPainter extends CustomPainter {
  final Color dashColor;
  QuestionsGraphicPainter(this.dashColor);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final dashPaint = Paint()
      ..color = dashColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(cx - 24, cy - 18),
      Offset(cx - 18, cy - 24),
      dashPaint,
    );
    canvas.drawLine(
      Offset(cx + 20, cy - 22),
      Offset(cx + 26, cy - 18),
      dashPaint,
    );

    final backBubble = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx + 6, cy - 6), width: 34, height: 26),
      const Radius.circular(10),
    );
    canvas.drawRRect(backBubble, Paint()..color = const Color(0xFFA7F3D0));

    final frontBubble = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - 4, cy + 4), width: 38, height: 28),
      const Radius.circular(10),
    );
    canvas.drawRRect(frontBubble, Paint()..color = const Color(0xFF10B981));

    final tailPath = Path()
      ..moveTo(cx + 4, cy + 14)
      ..lineTo(cx + 12, cy + 24)
      ..lineTo(cx + 12, cy + 14)
      ..close();
    canvas.drawPath(tailPath, Paint()..color = const Color(0xFF10B981));

    final linePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 15, cy + 1), Offset(cx + 5, cy + 1), linePaint);
    canvas.drawLine(Offset(cx - 15, cy + 7), Offset(cx - 2, cy + 7), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
