import 'package:flutter/material.dart';
import 'dart:ui';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _radarAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _radarAnimation = Tween<double>(begin: 0.9, end: 2.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutCubic),
    );
    _opacityAnimation = Tween<double>(begin: 0.85, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: Stack(
        children: [
          // Background ambient glows
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 380,
              height: 380,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x4DCCE5FF),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height / 2,
            right: -150,
            child: Container(
              width: 380,
              height: 380,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x33ACEDFF),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(color: Colors.transparent),
          ),

          Column(
            children: [
              _buildNavHeader(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      _buildNextManeuver(),
                      const SizedBox(height: 16),
                      Expanded(child: _buildBlueprintMap()),
                    ],
                  ),
                ),
              ),
              _buildFooter(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavHeader() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xE6FFFFFF),
        border: Border(bottom: BorderSide(color: Color(0x66C3C6D7))),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A0B1C30),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Icon(Icons.arrow_back, color: Colors.black),
            ),
          ),
          Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text(
                    "Principal's Office",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B1C30),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x382563EB),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.corporate_fare,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextManeuver() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33004AC6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x142563EB),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF004AC6),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.directions_walk,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'MANEUVER',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF004AC6),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Walk straight along Main Concourse (45m), then turn right into East Executive Corridor to Suite A-102.',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0B1C30),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBlueprintMap() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x66C3C6D7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0B1C30),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFDBE8F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x4DC3C6D7)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: GridPainter())),
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 3.0,
                constrained: true,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: 1100,
                    height: 980,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(painter: CorridorPainter()),
                        ),
                        _buildRoom(
                          80,
                          150,
                          210,
                          290,
                          'CONFERENCE HALL 1',
                          'Auditorium & Boardroom',
                          tag: 'ROOM A-110 • WING 1',
                        ),
                        _buildRoom(
                          80,
                          550,
                          210,
                          200,
                          'MEDIA HUB & LIBRARY',
                          'Digital Archive & Silent Study',
                          tag: 'ROOM A-108',
                        ),
                        _buildRoom(
                          80,
                          830,
                          210,
                          110,
                          'COURTYARD TERRACE',
                          'Sentosa Garden Cafe',
                        ),

                        _buildAtrium(360, 150, 120, 290),

                        _buildRoom(
                          580,
                          290,
                          120,
                          140,
                          'VICE PRINCIPAL',
                          'Student Affairs',
                          tag: 'SUITE A-104',
                        ),

                        _buildTargetRoom(770, 150, 250, 290),

                        _buildRoom(
                          770,
                          550,
                          250,
                          200,
                          'ELEVATOR CORE A',
                          'Vertical Transit: L1 to L4',
                          tag: 'CAMPUS AMENITIES',
                        ),
                        _buildRoom(
                          770,
                          830,
                          250,
                          110,
                          'SERVICE DESK',
                          'Visitor Reception Desk',
                        ),

                        _buildFoyer(410, 840, 240, 100),

                        Positioned.fill(
                          child: CustomPaint(painter: RoutePainter()),
                        ),

                        Positioned(
                          left: 530 - 28,
                          top: 890 - 28,
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  Opacity(
                                    opacity: _opacityAnimation.value,
                                    child: Transform.scale(
                                      scale: _radarAnimation.value,
                                      child: Container(
                                        width: 56,
                                        height: 56,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0x592563EB),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        Positioned(
                          left: 530 - 90,
                          top: 890 - 45,
                          child: Container(
                            width: 180,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B1C30),
                              borderRadius: BorderRadius.circular(13),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 4),
                              ],
                            ),
                            child: const Text(
                              "📍 You Are Here",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          left: 768 - 24,
                          top: 240 - 24,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0x402563EB),
                                ),
                              ),
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF004AC6),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.5,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.flag,
                                color: Colors.white,
                                size: 14,
                              ),
                            ],
                          ),
                        ),

                        Positioned(
                          left: 768 + 14,
                          top: 240 - 46,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF004AC6),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 4),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "🎯 Principal's Office",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _buildFloorIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildRoom(
    double x,
    double y,
    double w,
    double h,
    String title,
    String subtitle, {
    String? tag,
  }) {
    return Positioned(
      left: x,
      top: y,
      width: w,
      height: h,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFC3C6D7), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F0B1C30),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (tag != null) ...[
              Text(
                tag,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF004AC6),
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B1C30),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Color(0xFF434655)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAtrium(double x, double y, double w, double h) {
    return Positioned(
      left: x,
      top: y,
      width: w,
      height: h,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF4F8FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF93CCFF), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              "CENTRAL\nATRIUM",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF004AC6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoyer(double x, double y, double w, double h) {
    return Positioned(
      left: x,
      top: y,
      width: w,
      height: h,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF93CCFF), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              "ENTRANCE FOYER & TURNSTILES",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0B1C30),
              ),
            ),
            SizedBox(height: 4),
            Text(
              "Main South Security Gate & Station #01",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: Color(0xFF434655)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetRoom(double x, double y, double w, double h) {
    return Positioned(
      left: x,
      top: y,
      width: w,
      height: h,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEFF4FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2563EB), width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F0B1C30),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFDBE1FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'EXECUTIVE SUITE A-102',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF00174B),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "PRINCIPAL'S OFFICE",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0B1C30),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Administration & Governance",
              style: TextStyle(fontSize: 12, color: Color(0xFF434655)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloorIndicator() {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xE6FFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x66C3C6D7)),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Row(
          children: [
            const Icon(Icons.layers, color: Color(0xFF004AC6), size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Ground Floor',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B1C30),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

 
  Widget _buildFooter() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xF2FFFFFF),
        border: Border(top: BorderSide(color: Color(0x66C3C6D7))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Text(
                'Sentosa 2.0',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0B1C30),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final subGridPaint = Paint()
      ..color = const Color(0x7393CCFF)
      ..strokeWidth = 0.5;

    final mainGridPaint = Paint()
      ..color = const Color(0xBF5BB8FE)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        i % 100 == 0 ? mainGridPaint : subGridPaint,
      );
    }
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        i % 100 == 0 ? mainGridPaint : subGridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CorridorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFB4C7DC)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw horizontal corridors
    canvas.drawRect(const Rect.fromLTWH(80, 60, 940, 70), paint);
    canvas.drawRect(const Rect.fromLTWH(80, 60, 940, 70), borderPaint);

    canvas.drawRect(const Rect.fromLTWH(480, 205, 460, 70), paint);
    canvas.drawRect(const Rect.fromLTWH(480, 205, 460, 70), borderPaint);

    canvas.drawRect(const Rect.fromLTWH(80, 460, 940, 70), paint);
    canvas.drawRect(const Rect.fromLTWH(80, 460, 940, 70), borderPaint);

    canvas.drawRect(const Rect.fromLTWH(80, 770, 940, 80), paint);
    canvas.drawRect(const Rect.fromLTWH(80, 770, 940, 80), borderPaint);

    // Draw vertical corridors
    canvas.drawRect(const Rect.fromLTWH(290, 60, 70, 790), paint);
    canvas.drawRect(const Rect.fromLTWH(290, 60, 70, 790), borderPaint);

    canvas.drawRect(const Rect.fromLTWH(480, 60, 100, 860), paint);
    canvas.drawRect(const Rect.fromLTWH(480, 60, 100, 860), borderPaint);

    canvas.drawRect(const Rect.fromLTWH(700, 60, 70, 790), paint);
    canvas.drawRect(const Rect.fromLTWH(700, 60, 70, 790), borderPaint);

    // Seamless junction overlaps
    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(const Rect.fromLTWH(481, 206, 98, 68), fillPaint);
    canvas.drawRect(const Rect.fromLTWH(701, 206, 68, 68), fillPaint);
    canvas.drawRect(const Rect.fromLTWH(481, 461, 98, 68), fillPaint);
    canvas.drawRect(const Rect.fromLTWH(291, 461, 68, 68), fillPaint);
    canvas.drawRect(const Rect.fromLTWH(701, 461, 68, 68), fillPaint);
    canvas.drawRect(const Rect.fromLTWH(481, 771, 98, 78), fillPaint);
    canvas.drawRect(const Rect.fromLTWH(291, 771, 68, 78), fillPaint);
    canvas.drawRect(const Rect.fromLTWH(701, 771, 68, 78), fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(530, 890)
      ..lineTo(530, 250)
      ..quadraticBezierTo(530, 240, 540, 240)
      ..lineTo(760, 240);

    // Glow
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xA62563EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Solid route line
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF2563EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Checkpoints
    final cpPaint = Paint()..color = Colors.white;
    final cpBorder = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    _drawCp(canvas, 530, 770, 4, cpPaint, cpBorder);
    _drawCp(canvas, 530, 495, 4.5, cpPaint, cpBorder);
    _drawCp(canvas, 530, 240, 5, cpPaint, cpBorder);
    _drawCp(canvas, 760, 240, 4.5, cpPaint, cpBorder);
  }

  void _drawCp(
    Canvas canvas,
    double x,
    double y,
    double r,
    Paint fill,
    Paint border,
  ) {
    canvas.drawCircle(Offset(x, y), r, fill);
    canvas.drawCircle(Offset(x, y), r, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
