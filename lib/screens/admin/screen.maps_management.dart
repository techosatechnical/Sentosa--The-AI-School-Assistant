import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:sentosa/helpers/models/model.map_data.dart';
import 'package:sentosa/services/service.storage.dart';
import 'package:sentosa/widgets/widget.toast.dart';
import 'package:sentosa/helpers/data/data.default_maps.dart';

class MapsManagementScreen extends StatefulWidget {
  final String? mapId;
  const MapsManagementScreen({super.key, this.mapId});

  @override
  State<MapsManagementScreen> createState() => _MapsManagementScreenState();
}

class _RouteHit {
  final Offset point;
  final int afterIndex;
  _RouteHit(this.point, this.afterIndex);
}

class _MapsManagementScreenState extends State<MapsManagementScreen> {
  MapData? _mapData;
  bool _isLoading = true;

  dynamic _selectedItem;
  bool _isDragging = false;

  double _scale = 0.6;
  double _baseScale = 0.6;
  Offset _canvasOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  Future<void> _loadMapData() async {
    final id = widget.mapId ?? 'principal';
    final jsonStr = await AppStorageService().loadMapData(id);
    if (jsonStr != null) {
      try {
        _mapData = MapData.fromJson(jsonDecode(jsonStr));
      } catch (e) {
        debugPrint('Error parsing map data: $e');
      }
    }

    if (_mapData == null) {
      if (id == 'library') {
        _mapData = DefaultMaps.libraryMap;
      } else if (id == 'cafeteria') {
        _mapData = DefaultMaps.cafeteriaMap;
      } else {
        _mapData = DefaultMaps.principalMap;
      }
      _mapData = MapData.fromJson(jsonDecode(jsonEncode(_mapData!.toJson())));
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveMapData() async {
    if (_mapData == null) return;
    final id = widget.mapId ?? 'principal';
    try {
      await AppStorageService().saveMapData(id, jsonEncode(_mapData!.toJson()));
      if (!mounted) return;
      SentosaToast.show(context: context, message: 'Map saved successfully!');
    } catch (e) {
      if (!mounted) return;
      SentosaToast.show(
        context: context,
        message: 'Error saving map: $e',
        isError: true,
      );
    }
  }

  void _addRoom() {
    setState(() {
      final newRoom = MapRoom(
        id: 'r_${DateTime.now().millisecondsSinceEpoch}',
        x: 200,
        y: 200,
        w: 150,
        h: 120,
        title: 'New Room',
        subtitle: '',
      );
      _mapData!.rooms.add(newRoom);
      _selectedItem = newRoom;
    });
  }

  void _addCorridor() {
    setState(() {
      final newCorridor = MapCorridor(
        id: 'c_${DateTime.now().millisecondsSinceEpoch}',
        x: 200,
        y: 200,
        w: 300,
        h: 80,
      );
      _mapData!.corridors.add(newCorridor);
      _selectedItem = newCorridor;
    });
  }

  void _addPathNode() {
    setState(() {
      final nodes = _mapData!.pathNodes;
      Offset pos;
      int insertIndex;
      if (nodes.length >= 2) {
        final a = nodes[nodes.length - 2];
        final b = nodes[nodes.length - 1];
        pos = Offset((a.x + b.x) / 2, (a.y + b.y) / 2);
        insertIndex = nodes.length - 1;
      } else {
        pos = const Offset(200, 200);
        insertIndex = nodes.length;
      }
      final newNode = MapPathNode(
        id: 'p_${DateTime.now().millisecondsSinceEpoch}',
        x: pos.dx,
        y: pos.dy,
        isCheckpoint: true,
      );
      nodes.insert(insertIndex, newNode);
      _selectedItem = newNode;
    });
  }

  void _deleteSelectedItem() {
    if (_selectedItem == null) return;
    setState(() {
      if (_selectedItem is MapRoom) {
        _mapData!.rooms.remove(_selectedItem);
      } else if (_selectedItem is MapCorridor) {
        _mapData!.corridors.remove(_selectedItem);
      } else if (_selectedItem is MapPathNode) {
        _mapData!.pathNodes.remove(_selectedItem);
      }
      _selectedItem = null;
    });
  }

  Offset _screenToCanvas(Offset screenPos) {
    return (screenPos - _canvasOffset) / _scale;
  }

  dynamic _hitTest(Offset canvasPos) {
    for (final node in _mapData!.pathNodes.reversed) {
      final rect = Rect.fromCenter(
        center: Offset(node.x, node.y),
        width: 28,
        height: 28,
      );
      if (rect.contains(canvasPos)) return node;
    }
    for (final room in _mapData!.rooms.reversed) {
      final rect = Rect.fromLTWH(room.x, room.y, room.w, room.h);
      if (rect.contains(canvasPos)) return room;
    }
    for (final corridor in _mapData!.corridors.reversed) {
      final rect = Rect.fromLTWH(
        corridor.x,
        corridor.y,
        corridor.w,
        corridor.h,
      );
      if (rect.contains(canvasPos)) return corridor;
    }
    return null;
  }

  Offset _closestPointOnSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final lenSq = ab.dx * ab.dx + ab.dy * ab.dy;
    if (lenSq == 0) return a;
    double t = ((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / lenSq;
    t = t.clamp(0.0, 1.0);
    return Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
  }

  _RouteHit? _nearestPointOnRoute(Offset pos, double maxDist) {
    final nodes = _mapData!.pathNodes;
    if (nodes.length < 2) return null;
    _RouteHit? best;
    double bestDist = maxDist;
    for (int i = 0; i < nodes.length - 1; i++) {
      final a = Offset(nodes[i].x, nodes[i].y);
      final b = Offset(nodes[i + 1].x, nodes[i + 1].y);
      final segs = <List<Offset>>[];
      if (a.dx == b.dx || a.dy == b.dy) {
        segs.add([a, b]);
      } else {
        final elbow = Offset(b.dx, a.dy);
        segs.add([a, elbow]);
        segs.add([elbow, b]);
      }
      for (final seg in segs) {
        final proj = _closestPointOnSegment(pos, seg[0], seg[1]);
        final dist = (proj - pos).distance;
        if (dist < bestDist) {
          bestDist = dist;
          best = _RouteHit(proj, i);
        }
      }
    }
    return best;
  }

  void _onCanvasTapDown(TapDownDetails details) {
    final canvasPos = _screenToCanvas(details.localPosition);
    final hit = _hitTest(canvasPos);
    setState(() => _selectedItem = hit);
  }

  void _onCanvasLongPressStart(LongPressStartDetails details) {
    final canvasPos = _screenToCanvas(details.localPosition);
    if (_hitTest(canvasPos) != null) return;
    final hit = _nearestPointOnRoute(canvasPos, 16 / _scale);
    if (hit == null) return;
    setState(() {
      final newNode = MapPathNode(
        id: 'p_${DateTime.now().millisecondsSinceEpoch}',
        x: hit.point.dx,
        y: hit.point.dy,
        isCheckpoint: true,
      );
      _mapData!.pathNodes.insert(hit.afterIndex + 1, newNode);
      _selectedItem = newNode;
    });
  }

  void _onScaleStart(ScaleStartDetails details) {
    _baseScale = _scale;
    if (details.pointerCount == 1) {
      final canvasPos = _screenToCanvas(details.localFocalPoint);
      final hit = _hitTest(canvasPos);
      if (hit != null) {
        setState(() {
          _selectedItem = hit;
          _isDragging = true;
        });
        return;
      }
    }
    setState(() => _isDragging = false);
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_isDragging && _selectedItem != null && details.pointerCount == 1) {
      final dx = details.focalPointDelta.dx / _scale;
      final dy = details.focalPointDelta.dy / _scale;
      setState(() {
        final item = _selectedItem;
        if (item is MapRoom) {
          item.x += dx;
          item.y += dy;
        } else if (item is MapCorridor) {
          item.x += dx;
          item.y += dy;
        } else if (item is MapPathNode) {
          item.x += dx;
          item.y += dy;
        }
      });
      return;
    }

    setState(() {
      if (details.pointerCount >= 2) {
        final newScale = (_baseScale * details.scale).clamp(0.2, 3.0);
        final focal = details.localFocalPoint;
        _canvasOffset = focal - (focal - _canvasOffset) * (newScale / _scale);
        _scale = newScale;
      } else {
        _canvasOffset += details.focalPointDelta;
      }
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    setState(() => _isDragging = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
          Column(
            children: [
              _buildNavHeader(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 280,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0x66C3C6D7)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0F0B1C30),
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Material(
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: _buildSidebarTools(),
                            ),
                          ),
                        ),
                      ),
                      Expanded(child: _buildCanvasArea()),
                    ],
                  ),
                ),
              ),
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
              child: const Icon(Icons.arrow_back, color: Colors.black),
            ),
          ),
          Row(
            children: [
              Text(
                "Map Builder — ${_mapData?.title ?? ''}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B1C30),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _saveMapData,
                icon: const Icon(Icons.save),
                label: const Text('Save Map'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarTools() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tools",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B1C30),
            ),
          ),
          const SizedBox(height: 12),
          _toolBtn('Add Room', Icons.add_box_outlined, _addRoom),
          const SizedBox(height: 8),
          _toolBtn('Add Corridor', Icons.add_road, _addCorridor),
          const SizedBox(height: 8),
          _toolBtn(
            'Add Path Node',
            Icons.add_location_alt_outlined,
            _addPathNode,
          ),
          const SizedBox(height: 8),
          const Text(
            "Long-press anywhere on the route line to drop a new bend node right there.",
            style: TextStyle(color: Colors.grey, fontSize: 11.5, height: 1.3),
          ),
          const Divider(height: 28),
          if (_selectedItem != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Properties",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B1C30),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  tooltip: 'Delete',
                  onPressed: _deleteSelectedItem,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_selectedItem is MapRoom) _roomProps(_selectedItem as MapRoom),
            if (_selectedItem is MapCorridor)
              _corridorProps(_selectedItem as MapCorridor),
            if (_selectedItem is MapPathNode)
              _nodeProps(_selectedItem as MapPathNode),
          ] else ...[
            const Text(
              "Tap any block, corridor or path node on the canvas to select it.",
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              "Map Properties",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B1C30),
              ),
            ),
            const SizedBox(height: 8),
            _textField(
              'Title',
              _mapData?.title ?? '',
              (v) => setState(() => _mapData?.title = v),
            ),
            const SizedBox(height: 8),
            _textField(
              'Subtitle',
              _mapData?.subtitle ?? '',
              (v) => setState(() => _mapData?.subtitle = v),
            ),
            const SizedBox(height: 8),
            _textField(
              'Floor',
              _mapData?.floor ?? '',
              (v) => setState(() => _mapData?.floor = v),
            ),
          ],
        ],
      ),
    );
  }

  Widget _toolBtn(String label, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _roomProps(MapRoom room) {
    return Column(
      key: ValueKey('room_${room.id}'),
      children: [
        _textField('Title', room.title, (v) => setState(() => room.title = v)),
        const SizedBox(height: 8),
        _textField(
          'Subtitle',
          room.subtitle,
          (v) => setState(() => room.subtitle = v),
        ),
        const SizedBox(height: 8),
        _textField(
          'Tag',
          room.tag ?? '',
          (v) => setState(() => room.tag = v.isEmpty ? null : v),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<RoomType>(
          initialValue: room.type,
          decoration: const InputDecoration(
            labelText: 'Type',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: RoomType.values
              .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => room.type = v);
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _numField('X', room.x, (v) => setState(() => room.x = v)),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _numField('Y', room.y, (v) => setState(() => room.y = v)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _numField('W', room.w, (v) => setState(() => room.w = v)),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _numField('H', room.h, (v) => setState(() => room.h = v)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _corridorProps(MapCorridor c) {
    return Column(
      key: ValueKey('corridor_${c.id}'),
      children: [
        Row(
          children: [
            Expanded(
              child: _numField('X', c.x, (v) => setState(() => c.x = v)),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _numField('Y', c.y, (v) => setState(() => c.y = v)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _numField('W', c.w, (v) => setState(() => c.w = v)),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _numField('H', c.h, (v) => setState(() => c.h = v)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _nodeProps(MapPathNode node) {
    return Column(
      key: ValueKey('node_${node.id}'),
      children: [
        Row(
          children: [
            Expanded(
              child: _numField('X', node.x, (v) => setState(() => node.x = v)),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _numField('Y', node.y, (v) => setState(() => node.y = v)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          dense: true,
          title: const Text('Start Node', style: TextStyle(fontSize: 13)),
          value: node.isStart,
          onChanged: (v) => setState(() => node.isStart = v ?? false),
        ),
        CheckboxListTile(
          dense: true,
          title: const Text('Target Node', style: TextStyle(fontSize: 13)),
          value: node.isTarget,
          onChanged: (v) => setState(() => node.isTarget = v ?? false),
        ),
        CheckboxListTile(
          dense: true,
          title: const Text('Checkpoint', style: TextStyle(fontSize: 13)),
          value: node.isCheckpoint,
          onChanged: (v) => setState(() => node.isCheckpoint = v ?? false),
        ),
      ],
    );
  }

  Widget _textField(String label, String val, ValueChanged<String> onChange) {
    return TextField(
      controller: TextEditingController(text: val)
        ..selection = TextSelection.collapsed(offset: val.length),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: onChange,
    );
  }

  Widget _numField(String label, double val, ValueChanged<double> onChange) {
    return TextField(
      controller: TextEditingController(text: val.toStringAsFixed(0))
        ..selection = TextSelection.collapsed(
          offset: val.toStringAsFixed(0).length,
        ),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onSubmitted: (s) {
        final d = double.tryParse(s);
        if (d != null) onChange(d);
      },
    );
  }

  Widget _buildCanvasArea() {
    return Container(
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
      padding: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _onCanvasTapDown,
          onLongPressStart: _onCanvasLongPressStart,
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onScaleEnd: _onScaleEnd,
          child: Container(
            color: const Color(0xFFDBE8F8),
            child: CustomPaint(
              painter: _MapBuilderPainter(
                mapData: _mapData!,
                selectedItem: _selectedItem,
                offset: _canvasOffset,
                scale: _scale,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapBuilderPainter extends CustomPainter {
  final MapData mapData;
  final dynamic selectedItem;
  final Offset offset;
  final double scale;

  _MapBuilderPainter({
    required this.mapData,
    required this.selectedItem,
    required this.offset,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    _drawGrid(canvas, size);
    _drawCorridors(canvas);
    _drawRooms(canvas);
    _drawRoute(canvas);
    _drawNodes(canvas);

    canvas.restore();
  }

  void _drawGrid(Canvas canvas, Size size) {
    final sub = Paint()
      ..color = const Color(0x7393CCFF)
      ..strokeWidth = 0.5;
    final main = Paint()
      ..color = const Color(0xBF5BB8FE)
      ..strokeWidth = 1;
    const total = 2000.0;
    for (double i = 0; i <= total; i += 20) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, total),
        i % 100 == 0 ? main : sub,
      );
      canvas.drawLine(
        Offset(0, i),
        Offset(total, i),
        i % 100 == 0 ? main : sub,
      );
    }
  }

  void _drawCorridors(Canvas canvas) {
    for (final c in mapData.corridors) {
      final isSelected = selectedItem == c;
      final rect = Rect.fromLTWH(c.x, c.y, c.w, c.h);
      canvas.drawRect(rect, Paint()..color = Colors.white);
      canvas.drawRect(
        rect,
        Paint()
          ..color = isSelected ? Colors.orange : const Color(0xFFB4C7DC)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 3 : 1.5,
      );
    }
  }

  void _drawRooms(Canvas canvas) {
    for (final r in mapData.rooms) {
      final isSelected = selectedItem == r;
      final rect = Rect.fromLTWH(r.x, r.y, r.w, r.h);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));

      Color fill;
      if (r.type == RoomType.atrium) {
        fill = const Color(0xFFF4F8FF);
      } else if (r.type == RoomType.foyer) {
        fill = const Color(0xFFF8FAFF);
      } else if (r.type == RoomType.target) {
        fill = const Color(0xFFEFF4FF);
      } else {
        fill = Colors.white;
      }

      canvas.drawRRect(rrect, Paint()..color = fill);
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = isSelected ? Colors.orange : const Color(0xFFC3C6D7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 3 : 1.5,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: r.title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? const Color(0xFF004AC6)
                : const Color(0xFF0B1C30),
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tp.layout(maxWidth: r.w - 8);
      tp.paint(
        canvas,
        Offset(r.x + (r.w - tp.width) / 2, r.y + (r.h - tp.height) / 2),
      );
    }
  }

  void _drawRoute(Canvas canvas) {
    final nodes = mapData.pathNodes;
    if (nodes.length < 2) return;
    final path = Path()..moveTo(nodes.first.x, nodes.first.y);
    for (int i = 0; i < nodes.length - 1; i++) {
      final a = Offset(nodes[i].x, nodes[i].y);
      final b = Offset(nodes[i + 1].x, nodes[i + 1].y);
      if (a.dx != b.dx && a.dy != b.dy) {
        path.lineTo(b.dx, a.dy);
      }
      path.lineTo(b.dx, b.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x802563EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _drawNodes(Canvas canvas) {
    for (final n in mapData.pathNodes) {
      final isSelected = selectedItem == n;
      Color fill;
      if (n.isStart) {
        fill = Colors.green;
      } else if (n.isTarget) {
        fill = Colors.red;
      } else {
        fill = Colors.white;
      }
      canvas.drawCircle(Offset(n.x, n.y), 12, Paint()..color = fill);
      canvas.drawCircle(
        Offset(n.x, n.y),
        12,
        Paint()
          ..color = isSelected ? Colors.orange : const Color(0xFF2563EB)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 4 : 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MapBuilderPainter old) => true;
}
