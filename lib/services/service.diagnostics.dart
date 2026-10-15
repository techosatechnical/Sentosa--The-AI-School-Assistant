import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:nira/services/service.storage.dart';

enum LogType { info, warning, error, success }

class DiagnosticLogEntry {
  final DateTime timestamp;
  final LogType type;
  final String event;
  final String message;
  final Map<String, dynamic>? details;

  DiagnosticLogEntry({
    required this.timestamp,
    required this.type,
    required this.event,
    required this.message,
    this.details,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'type': type.name,
    'event': event,
    'message': message,
    if (details != null) 'details': details,
  };

  factory DiagnosticLogEntry.fromJson(Map<String, dynamic> json) {
    return DiagnosticLogEntry(
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      type: LogType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => LogType.info,
      ),
      event: json['event'] ?? 'UNKNOWN',
      message: json['message'] ?? '',
      details: json['details'] != null
          ? Map<String, dynamic>.from(json['details'] as Map)
          : null,
    );
  }
}

class DiagnosticLogger {
  static final DiagnosticLogger _instance = DiagnosticLogger._internal();
  factory DiagnosticLogger() => _instance;

  final List<DiagnosticLogEntry> _memoryCache = [];
  final StreamController<String> _writeQueue = StreamController<String>();
  bool _isQueueInitialized = false;
  static const int _maxInMemory = 250;
  static const int _maxFileLines = 600;

  DiagnosticLogger._internal() {
    _initQueue();
  }

  void _initQueue() {
    if (_isQueueInitialized) return;
    _isQueueInitialized = true;

    _writeQueue.stream.asyncMap((line) async {
      try {
        final file = await _getLogFile();
        await file.writeAsString('$line\n', mode: FileMode.append, flush: false);
      } catch (_) {}
    }).drain();
  }

  Future<File> _getLogFile() async {
    final appDir = await AppStorageService().getAppDirectory();
    final file = File(p.join(appDir.path, 'nira_logs.jsonl'));
    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    return file;
  }
  void log({
    required LogType type,
    required String event,
    required String message,
    Map<String, dynamic>? details,
  }) {
    final entry = DiagnosticLogEntry(
      timestamp: DateTime.now(),
      type: type,
      event: event,
      message: message,
      details: details,
    );

    _memoryCache.insert(0, entry);
    if (_memoryCache.length > _maxInMemory) {
      _memoryCache.removeLast();
    }

    try {
      final jsonLine = jsonEncode(entry.toJson());
      _writeQueue.add(jsonLine);
    } catch (_) {}
  }

  Future<List<DiagnosticLogEntry>> readLogs({bool forceDisk = false}) async {
    try {
      final file = await _getLogFile();
      if (!await file.exists()) return [];

      final lines = await file.readAsLines();
      if (lines.isEmpty) return [];
      if (lines.length > _maxFileLines) {
        final trimmed = lines.sublist(lines.length - _maxFileLines);
        unawaited(file.writeAsString('${trimmed.join('\n')}\n', mode: FileMode.write));
      }

      final List<DiagnosticLogEntry> entries = [];
      for (int i = lines.length - 1; i >= 0; i--) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        try {
          final Map<String, dynamic> data = jsonDecode(line);
          entries.add(DiagnosticLogEntry.fromJson(data));
        } catch (_) {}
      }
      return entries;
    } catch (_) {
      return List.unmodifiable(_memoryCache);
    }
  }

  Future<void> clearLogs() async {
    _memoryCache.clear();
    try {
      final file = await _getLogFile();
      if (await file.exists()) {
        await file.writeAsString('', mode: FileMode.write);
      }
    } catch (_) {}
  }
}
