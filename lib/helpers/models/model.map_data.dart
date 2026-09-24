class MapData {
  final String id;
  final String title;
  final String subtitle;
  final List<MapRoom> rooms;
  final List<MapCorridor> corridors;
  final List<MapPathNode> pathNodes;

  MapData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.rooms,
    required this.corridors,
    required this.pathNodes,
  });

  factory MapData.fromJson(Map<String, dynamic> json) {
    return MapData(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      rooms: (json['rooms'] as List<dynamic>?)
              ?.map((e) => MapRoom.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      corridors: (json['corridors'] as List<dynamic>?)
              ?.map((e) => MapCorridor.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pathNodes: (json['pathNodes'] as List<dynamic>?)
              ?.map((e) => MapPathNode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'rooms': rooms.map((e) => e.toJson()).toList(),
      'corridors': corridors.map((e) => e.toJson()).toList(),
      'pathNodes': pathNodes.map((e) => e.toJson()).toList(),
    };
  }
}

enum RoomType {
  standard,
  atrium,
  foyer,
  target,
}

class MapRoom {
  final String id;
  double x;
  double y;
  double w;
  double h;
  String title;
  String subtitle;
  String? tag;
  RoomType type;

  MapRoom({
    required this.id,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.title,
    required this.subtitle,
    this.tag,
    this.type = RoomType.standard,
  });

  factory MapRoom.fromJson(Map<String, dynamic> json) {
    return MapRoom(
      id: json['id'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      w: (json['w'] as num).toDouble(),
      h: (json['h'] as num).toDouble(),
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      tag: json['tag'] as String?,
      type: RoomType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => RoomType.standard,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'x': x,
      'y': y,
      'w': w,
      'h': h,
      'title': title,
      'subtitle': subtitle,
      'tag': tag,
      'type': type.toString(),
    };
  }
}

class MapCorridor {
  final String id;
  double x;
  double y;
  double w;
  double h;

  MapCorridor({
    required this.id,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });

  factory MapCorridor.fromJson(Map<String, dynamic> json) {
    return MapCorridor(
      id: json['id'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      w: (json['w'] as num).toDouble(),
      h: (json['h'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'x': x,
      'y': y,
      'w': w,
      'h': h,
    };
  }
}

class MapPathNode {
  final String id;
  double x;
  double y;
  bool isCheckpoint;
  bool isStart;
  bool isTarget;

  MapPathNode({
    required this.id,
    required this.x,
    required this.y,
    this.isCheckpoint = false,
    this.isStart = false,
    this.isTarget = false,
  });

  factory MapPathNode.fromJson(Map<String, dynamic> json) {
    return MapPathNode(
      id: json['id'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      isCheckpoint: json['isCheckpoint'] as bool? ?? false,
      isStart: json['isStart'] as bool? ?? false,
      isTarget: json['isTarget'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'x': x,
      'y': y,
      'isCheckpoint': isCheckpoint,
      'isStart': isStart,
      'isTarget': isTarget,
    };
  }
}
