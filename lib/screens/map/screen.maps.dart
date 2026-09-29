import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sentosa/helpers/models/model.map_data.dart';
import 'package:sentosa/services/service.storage.dart';
import 'package:sentosa/helpers/data/data.default_maps.dart';
import 'package:sentosa/widgets/widget.painters.dart';

class MapScreen extends StatefulWidget {
  final String? mapId;
  const MapScreen({super.key, this.mapId});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _DestinationVisual {
  final Color bg;
  final Color accent;
  final Color dash;
  final CustomPainter Function(Color) painterBuilder;
  const _DestinationVisual({
    required this.bg,
    required this.accent,
    required this.dash,
    required this.painterBuilder,
  });
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _radarAnimation;
  late Animation<double> _opacityAnimation;
  Future<MapData>? _mapDataFuture;

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

    _loadMapData();
  }

  void _loadMapData() {
    final id = widget.mapId ?? 'principal';
    _mapDataFuture = AppStorageService().loadMapData(id).then((jsonStr) {
      if (jsonStr != null) {
        try {
          return MapData.fromJson(jsonDecode(jsonStr));
        } catch (e) {
          debugPrint('Error parsing map data: $e');
        }
      }
      if (id == 'library') return DefaultMaps.libraryMap;
      if (id == 'cafeteria') return DefaultMaps.cafeteriaMap;
      return DefaultMaps.principalMap;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  _DestinationVisual _destinationVisual(String mapId) {
    switch (mapId) {
      case 'library':
        return _DestinationVisual(
          bg: const Color(0xFFEBF5FF),
          accent: const Color(0xFF38BDF8),
          dash: const Color(0xFF93C5FD),
          painterBuilder: (c) => MapGraphicPainter(c),
        );
      case 'cafeteria':
        return _DestinationVisual(
          bg: const Color(0xFFEDFAF3),
          accent: const Color(0xFF10B981),
          dash: const Color(0xFF86EFAC),
          painterBuilder: (c) => CafeteriaGraphicPainter(c),
        );
      case 'principal':
      default:
        return _DestinationVisual(
          bg: const Color(0xFFF3EFFF),
          accent: const Color(0xFF818CF8),
          dash: const Color(0xFFC4B5FD),
          painterBuilder: (c) => PrincipalGraphicPainter(c),
        );
    }
  }

  Widget _destinationBadge(String mapId, {double size = 52}) {
    final visual = _destinationVisual(mapId);
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.16),
      decoration: BoxDecoration(
        color: visual.bg,
        borderRadius: BorderRadius.circular(size * 0.34),
        border: Border.all(color: visual.accent.withValues(alpha: 0.35), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: visual.accent.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: CustomPaint(painter: visual.painterBuilder(visual.dash)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapId = widget.mapId ?? 'principal';
    final screenWidth = MediaQuery.sizeOf(context).width;
    final blobScale = (screenWidth / 430).clamp(1.0, 1.9);
    final visual = _destinationVisual(mapId);

    return Scaffold(
      backgroundColor: const Color(0xFFDBEAFC),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF2F8FE),
                Color(0xFFF7FBFF),
                Color(0xFFE7F1FB),
              ],
            ),
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F2942).withValues(alpha: 0.12),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
              width: 3,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -50,
                left: -50,
                child: Container(
                  width: 250 * blobScale,
                  height: 250 * blobScale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFBAE6FD).withValues(alpha: 0.6),
                  ),
                ),
              ),
              Positioned(
                top: 280,
                right: -60,
                child: Container(
                  width: 260 * blobScale,
                  height: 260 * blobScale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: visual.accent.withValues(alpha: 0.14),
                  ),
                ),
              ),
              Positioned(
                bottom: 120,
                left: -50,
                child: Container(
                  width: 240 * blobScale,
                  height: 240 * blobScale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFCCFBF1).withValues(alpha: 0.5),
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: FutureBuilder<MapData>(
                  future: _mapDataFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return const Center(child: Text("Error loading map"));
                    }

                    final mapData = snapshot.data!;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                          child: _buildNavHeader(mapData, mapId),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                const SizedBox(height: 16),
                                Expanded(child: _buildBlueprintMap(mapData)),
                              ],
                            ),
                          ),
                        ),
                        _buildFooter(),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavHeader(MapData mapData, String mapId) {
    return Row(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F2942).withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F2942)),
            ),
          ),
        ),
        const SizedBox(width: 14),
        _destinationBadge(mapId, size: 52),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NAVIGATING TO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: const Color(0xFF0F2942).withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                mapData.title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0B1C30),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBlueprintMap(MapData mapData) {
    MapPathNode? startNode;
    MapPathNode? targetNode;

    try {
      startNode = mapData.pathNodes.firstWhere((n) => n.isStart);
    } catch (_) {}
    try {
      targetNode = mapData.pathNodes.firstWhere((n) => n.isTarget);
    } catch (_) {}

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x66C3C6D7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0B1C30),
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFDBE8F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x4DC3C6D7)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: GridPainter())),
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: 1100,
                  height: 980,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: CorridorPainter(mapData.corridors)),
                      ),

                      ...mapData.rooms.map((room) {
                        if (room.type == RoomType.atrium) {
                          return _buildAtrium(room.x, room.y, room.w, room.h, room.title);
                        } else if (room.type == RoomType.foyer) {
                          return _buildFoyer(room.x, room.y, room.w, room.h, room.title, room.subtitle);
                        } else if (room.type == RoomType.target) {
                          return _buildTargetRoom(room.x, room.y, room.w, room.h, room.title, room.subtitle, room.tag ?? '');
                        }
                        return _buildRoom(room.x, room.y, room.w, room.h, room.title, room.subtitle, tag: room.tag);
                      }),

                      Positioned.fill(
                        child: CustomPaint(painter: RoutePainter(mapData.pathNodes)),
                      ),

                      if (startNode != null)
                        Positioned(
                          left: startNode.x - 28,
                          top: startNode.y - 28,
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

                      if (startNode != null)
                        Positioned(
                          left: startNode.x - 90,
                          top: startNode.y - 45,
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

                      if (targetNode != null)
                        Positioned(
                          left: targetNode.x - 24,
                          top: targetNode.y - 24,
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

                      if (targetNode != null)
                        Positioned(
                          left: targetNode.x + 14,
                          top: targetNode.y - 46,
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
                              children: [
                                Text(
                                  "🎯 ${mapData.title}",
                                  style: const TextStyle(
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
            _buildFloorIndicator(mapData),
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
            if (tag != null && tag.isNotEmpty) ...[
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
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: Color(0xFF434655)),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildAtrium(double x, double y, double w, double h, String title) {
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
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
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

  Widget _buildFoyer(double x, double y, double w, double h, String title, String subtitle) {
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
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0B1C30),
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: Color(0xFF434655)),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildTargetRoom(double x, double y, double w, double h, String title, String subtitle, String tag) {
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
            if (tag.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBE1FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF00174B),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0B1C30),
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF434655)),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildFloorIndicator(MapData mapData) {
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
              children: [
                Text(
                  mapData.floor,
                  style: const TextStyle(
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Sentosa 2.0',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F2942).withValues(alpha: 0.4),
            ),
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
  final List<MapCorridor> corridors;

  CorridorPainter(this.corridors);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFB4C7DC)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final corridor in corridors) {
      final rect = Rect.fromLTWH(corridor.x, corridor.y, corridor.w, corridor.h);
      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, borderPaint);
    }

    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < corridors.length; i++) {
      for (int j = i + 1; j < corridors.length; j++) {
        final r1 = Rect.fromLTWH(corridors[i].x, corridors[i].y, corridors[i].w, corridors[i].h);
        final r2 = Rect.fromLTWH(corridors[j].x, corridors[j].y, corridors[j].w, corridors[j].h);
        final intersection = r1.intersect(r2);
        if (intersection.width > 0 && intersection.height > 0) {
          canvas.drawRect(intersection.deflate(-1.0), fillPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CorridorPainter oldDelegate) => true;
}

class RoutePainter extends CustomPainter {
  final List<MapPathNode> nodes;

  RoutePainter(this.nodes);

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty) return;

    final path = Path();
    path.moveTo(nodes.first.x, nodes.first.y);

    for (int i = 1; i < nodes.length; i++) {
      path.lineTo(nodes[i].x, nodes[i].y);
    }

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

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF2563EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final cpPaint = Paint()..color = Colors.white;
    final cpBorder = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (final node in nodes) {
      if (node.isCheckpoint || node.isStart || node.isTarget) {
        _drawCp(canvas, node.x, node.y, 4.5, cpPaint, cpBorder);
      }
    }
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
  bool shouldRepaint(covariant RoutePainter oldDelegate) => true;
}