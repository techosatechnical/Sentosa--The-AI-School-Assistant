import 'package:nira/helpers/models/model.map_data.dart';

class DefaultMaps {
  static final List<MapCorridor> _baseCorridors = [
    MapCorridor(id: 'c1', x: 80, y: 60, w: 940, h: 70),
    MapCorridor(id: 'c2', x: 480, y: 205, w: 460, h: 70),
    MapCorridor(id: 'c3', x: 80, y: 460, w: 940, h: 70),
    MapCorridor(id: 'c4', x: 80, y: 770, w: 940, h: 80),
    MapCorridor(id: 'c5', x: 290, y: 60, w: 70, h: 790),
    MapCorridor(id: 'c6', x: 480, y: 60, w: 100, h: 860),
    MapCorridor(id: 'c7', x: 700, y: 60, w: 70, h: 790),
  ];

  static final List<MapRoom> _baseRooms = [
    MapRoom(
      id: "r1",
      x: 80,
      y: 150,
      w: 210,
      h: 290,
      title: 'CONFERENCE HALL 1',
      subtitle: 'Auditorium & Boardroom',
      tag: 'ROOM A-110 • WING 1',
    ),
    MapRoom(
      id: "r2",
      x: 80,
      y: 550,
      w: 210,
      h: 200,
      title: 'MEDIA HUB & LIBRARY',
      subtitle: 'Digital Archive & Silent Study',
      tag: 'ROOM A-108',
    ),
    MapRoom(
      id: "r3",
      x: 80,
      y: 830,
      w: 210,
      h: 110,
      title: 'COURTYARD TERRACE',
      subtitle: 'Nira Garden Cafe',
    ),
    MapRoom(
      id: "r4",
      x: 360,
      y: 150,
      w: 120,
      h: 290,
      title: 'CENTRAL\nATRIUM',
      subtitle: '',
      type: RoomType.atrium,
    ),
    MapRoom(
      id: "r5",
      x: 580,
      y: 290,
      w: 120,
      h: 140,
      title: 'VICE PRINCIPAL',
      subtitle: 'Student Affairs',
      tag: 'SUITE A-104',
    ),
    MapRoom(
      id: "r6",
      x: 770,
      y: 150,
      w: 250,
      h: 290,
      title: "PRINCIPAL'S OFFICE",
      subtitle: "Administration & Governance",
      tag: 'EXECUTIVE SUITE A-102',
    ),
    MapRoom(
      id: "r7",
      x: 770,
      y: 550,
      w: 250,
      h: 200,
      title: 'ELEVATOR CORE A',
      subtitle: 'Vertical Transit: L1 to L4',
      tag: 'CAMPUS AMENITIES',
    ),
    MapRoom(
      id: "r8",
      x: 770,
      y: 830,
      w: 250,
      h: 110,
      title: 'SERVICE DESK',
      subtitle: 'Visitor Reception Desk',
    ),
    MapRoom(
      id: "r9",
      x: 410,
      y: 840,
      w: 240,
      h: 100,
      title: 'ENTRANCE FOYER & TURNSTILES',
      subtitle: 'Main South Security Gate & Station #01',
      type: RoomType.foyer,
    ),
  ];

  static MapData get principalMap {
    final rooms = List<MapRoom>.from(
      _baseRooms.map(
        (e) => MapRoom(
          id: e.id,
          x: e.x,
          y: e.y,
          w: e.w,
          h: e.h,
          title: e.title,
          subtitle: e.subtitle,
          tag: e.tag,
          type: e.id == 'r6' ? RoomType.target : e.type,
        ),
      ),
    );

    return MapData(
      id: 'principal',
      title: "Principal's Office",
      subtitle: "Suite Door A-102 Entrance",
      rooms: rooms,
      corridors: _baseCorridors,
      pathNodes: [
        MapPathNode(id: 'p1', x: 530, y: 890, isStart: true),
        MapPathNode(id: 'p2', x: 530, y: 770, isCheckpoint: true),
        MapPathNode(id: 'p3', x: 530, y: 495, isCheckpoint: true),
        MapPathNode(id: 'p4', x: 530, y: 240, isCheckpoint: true),
        MapPathNode(id: 'p5', x: 760, y: 240, isTarget: true),
      ],
    );
  }

  static MapData get libraryMap {
    final rooms = List<MapRoom>.from(
      _baseRooms.map(
        (e) => MapRoom(
          id: e.id,
          x: e.x,
          y: e.y,
          w: e.w,
          h: e.h,
          title: e.title,
          subtitle: e.subtitle,
          tag: e.tag,
          type: e.id == 'r2' ? RoomType.target : e.type,
        ),
      ),
    );

    return MapData(
      id: 'library',
      title: "Media Hub & Library",
      subtitle: "Room A-108 Entrance",
      rooms: rooms,
      corridors: _baseCorridors,
      pathNodes: [
        MapPathNode(id: 'p1', x: 530, y: 890, isStart: true),
        MapPathNode(id: 'p2', x: 530, y: 770, isCheckpoint: true),
        MapPathNode(id: 'p3', x: 530, y: 495, isCheckpoint: true),
        MapPathNode(id: 'p4', x: 325, y: 495, isCheckpoint: true),
        MapPathNode(id: 'p5', x: 325, y: 650, isCheckpoint: true),
        MapPathNode(id: 'p6', x: 290, y: 650, isTarget: true),
      ],
    );
  }

  static MapData get cafeteriaMap {
    final rooms = List<MapRoom>.from(
      _baseRooms.map(
        (e) => MapRoom(
          id: e.id,
          x: e.x,
          y: e.y,
          w: e.w,
          h: e.h,
          title: e.title,
          subtitle: e.subtitle,
          tag: e.tag,
          type: e.id == 'r3' ? RoomType.target : e.type,
        ),
      ),
    );

    return MapData(
      id: 'cafeteria',
      title: "Nira Garden Cafe",
      subtitle: "Courtyard Terrace Entrance",
      rooms: rooms,
      corridors: _baseCorridors,
      pathNodes: [
        MapPathNode(id: 'p1', x: 530, y: 890, isStart: true),
        MapPathNode(id: 'p2', x: 530, y: 810, isCheckpoint: true),
        MapPathNode(id: 'p3', x: 325, y: 810, isCheckpoint: true),
        MapPathNode(id: 'p4', x: 325, y: 885, isCheckpoint: true),
        MapPathNode(id: 'p5', x: 290, y: 885, isTarget: true),
      ],
    );
  }
}
