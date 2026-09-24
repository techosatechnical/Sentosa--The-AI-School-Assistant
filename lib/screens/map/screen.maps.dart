import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:sentosa/helpers/models/model.map_data.dart';
import 'package:sentosa/services/service.storage.dart';
import 'package:sentosa/helpers/data/data.default_maps.dart';

class MapScreen extends StatefulWidget {
  final String? mapId;
  const MapScreen({super.key, this.mapId});

  @override
  State<MapScreen> createState() => _MapScreenState();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: Stack(
        children: [
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

          FutureBuilder<MapData>(
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
                  _buildNavHeader(mapData),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Column(
                        children: [
                          _buildNextManeuver(mapData),
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
        ],
      ),
    );
  }

  Widget _buildNavHeader(MapData mapData) {
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
              child: const Icon(Icons.arrow_back, color: Colors.black),
            ),
          ),
          Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    mapData.title,
                    style: const TextStyle(
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

  Widget _buildNextManeuver(MapData mapData) {
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
                  const Row(
                    children: [
                      Text(
                        'DIRECTIONS',
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
                  Text(
                    'Follow the highlighted path to ${mapData.title}',
                    style: const TextStyle(
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

    // Since we simplified the rendering for dynamically loaded corridors,
    // the seamless junction overlaps are automatically drawn without borders 
    // by filling intersections, but we'll stick to a simpler render method for the dynamic version.
    // Ideally we would compute intersections and draw them with `fillPaint`, 
    // but for the sake of the builder, the default borders will be visible.
    // If seamless overlaps are strictly needed, we can re-implement them by computing Rect intersections.
    
    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
      
    // Naive O(N^2) intersection fill to restore seamless corridors
    for (int i = 0; i < corridors.length; i++) {
      for (int j = i + 1; j < corridors.length; j++) {
        final r1 = Rect.fromLTWH(corridors[i].x, corridors[i].y, corridors[i].w, corridors[i].h);
        final r2 = Rect.fromLTWH(corridors[j].x, corridors[j].y, corridors[j].w, corridors[j].h);
        final intersection = r1.intersect(r2);
        if (intersection.width > 0 && intersection.height > 0) {
          // Fill the intersection, slightly deflated to overwrite borders
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
      // Very basic pathing: just connect the dots with straight lines for now, 
      // or you can implement bezier logic if you have control points.
      path.lineTo(nodes[i].x, nodes[i].y);
    }

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
