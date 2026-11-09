import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:path/path.dart' as p;
import 'package:nira/helpers/models/model.visitor.dart';
import 'package:nira/services/service.config.dart';
import 'package:nira/services/service.diagnostics.dart';
import 'package:nira/services/service.logger.dart';
import 'package:nira/services/service.storage.dart';

enum ChimeType { step, nudge, success, tap }

class VisitorService {
  static final VisitorService _instance = VisitorService._internal();
  factory VisitorService() => _instance;
  VisitorService._internal();

  final Map<String, ReturningVisitorProfile> _profilesByPhone = {};
  bool _isInitialized = false;
  Process? _ttsProcess;
  bool _isMuted = false;

  Function(VisitorRecord)? onVisitorRecorded;

  bool get isMuted => _isMuted;

  static String formatDateKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String formatCompactDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    _isMuted = !ConfigService().visitorAudioPromptsEnabled;
    await _loadProfiles();
    _initTtsWorker();
  }

  void setMuted(bool muted) {
    _isMuted = muted;
    if (_isMuted) {
      stopSpeech();
    }
  }

  Future<File> _getProfilesFile() async {
    final dir = await AppStorageService().getVisitorsDirectory();
    return File(p.join(dir.path, 'visitor_profiles.json'));
  }

  Future<File> _getCounterFile() async {
    final dir = await AppStorageService().getVisitorsDirectory();
    return File(p.join(dir.path, 'token_counter.json'));
  }

  Future<File> _getDailyLogFile(String dateKey) async {
    final dir = await AppStorageService().getVisitorsDirectory();
    return File(p.join(dir.path, 'visitors_$dateKey.jsonl'));
  }

  Future<void> _loadProfiles() async {
    try {
      final file = await _getProfilesFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content);
        if (data is Map) {
          _profilesByPhone.clear();
          data.forEach((key, value) {
            if (value is Map) {
              _profilesByPhone[key.toString()] =
                  ReturningVisitorProfile.fromJson(
                    Map<String, dynamic>.from(value),
                  );
            }
          });
        }
      }
    } catch (e) {
      logger.w("Failed to load returning visitor profiles: $e");
    }
  }

  Future<void> _saveProfiles() async {
    try {
      final file = await _getProfilesFile();
      final map = <String, dynamic>{};
      _profilesByPhone.forEach((key, value) {
        map[key] = value.toJson();
      });
      await file.writeAsString(jsonEncode(map), flush: true);
    } catch (e) {
      logger.w("Failed to save returning visitor profiles: $e");
    }
  }

  ReturningVisitorProfile? lookupByPhone(String rawPhone) {
    final normalized = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (normalized.length < 10) return null;
    final key = normalized.substring(normalized.length - 10);
    return _profilesByPhone[key];
  }

  Future<(String tokenId, String shortToken)> _nextToken(DateTime now) async {
    final dateKey = formatDateKey(now);
    final compactDate = formatCompactDate(now);
    int nextSeq = 1;

    try {
      final file = await _getCounterFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content);
        if (data is Map && data['date'] == dateKey) {
          final lastSeq = (data['seq'] as num?)?.toInt() ?? 0;
          nextSeq = lastSeq + 1;
        }
      }
      // Also cross-check against existing records for today so sequence never collides
      final existingToday = await getVisitorsForDate(dateKey);
      if (existingToday.length >= nextSeq) {
        nextSeq = existingToday.length + 1;
      }

      await file.writeAsString(
        jsonEncode({'date': dateKey, 'seq': nextSeq}),
        flush: true,
      );
    } catch (e) {
      logger.e("Error updating token counter: $e");
    }

    final seqStr = nextSeq.toString().padLeft(3, '0');
    final tokenId = 'NBS-$compactDate-$seqStr';
    final shortToken = 'V-$seqStr';
    return (tokenId, shortToken);
  }

  Future<VisitorRecord> registerVisitor({
    required String visitorName,
    required String phoneNumber,
    required String categoryId,
    required String categoryLabel,
    required String purposeId,
    required String purposeLabel,
    required String personToMeet,
    String? studentName,
    String? studentClass,
    String? studentDiv,
    String languageUsed = 'en',
  }) async {
    final now = DateTime.now();
    final (tokenId, shortToken) = await _nextToken(now);

    final cleanName = visitorName.trim().isEmpty
        ? 'Visitor'
        : visitorName.trim();
    final cleanPhone = phoneNumber.trim().isEmpty
        ? 'Not Provided'
        : phoneNumber.trim();

    final record = VisitorRecord(
      tokenId: tokenId,
      shortToken: shortToken,
      timestamp: now,
      visitorName: cleanName,
      phoneNumber: cleanPhone,
      categoryId: categoryId,
      categoryLabel: categoryLabel,
      purposeId: purposeId,
      purposeLabel: purposeLabel,
      personToMeet: personToMeet,
      studentName: (studentName != null && studentName.trim().isNotEmpty)
          ? studentName.trim()
          : null,
      studentClass: (studentClass != null && studentClass.trim().isNotEmpty)
          ? studentClass.trim()
          : null,
      studentDiv: (studentDiv != null && studentDiv.trim().isNotEmpty)
          ? studentDiv.trim()
          : null,
      languageUsed: languageUsed,
    );

    final dateKey = formatDateKey(now);
    final logFile = await _getDailyLogFile(dateKey);
    await logFile.writeAsString(
      '${jsonEncode(record.toJson())}\n',
      mode: FileMode.append,
      flush: true,
    );

    // Update returning visitor profile cache if 10-digit phone is provided
    final digits = cleanPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 10) {
      final phoneKey = digits.substring(digits.length - 10);
      final prev = _profilesByPhone[phoneKey];
      _profilesByPhone[phoneKey] = ReturningVisitorProfile(
        phoneNumber: phoneKey,
        visitorName: cleanName,
        lastCategoryId: categoryId,
        studentName: record.studentName ?? prev?.studentName,
        studentClass: record.studentClass ?? prev?.studentClass,
        studentDiv: record.studentDiv ?? prev?.studentDiv,
        visitCount: (prev?.visitCount ?? 0) + 1,
        lastVisitedAt: now,
      );
      unawaited(_saveProfiles());
    }

    DiagnosticLogger().log(
      type: LogType.success,
      event: 'VISITOR_TOKEN_ISSUED',
      message:
          'Issued token $shortToken ($tokenId) to $cleanName [$categoryLabel - $purposeLabel]',
      details: {
        'tokenId': tokenId,
        'shortToken': shortToken,
        'category': categoryLabel,
        'purpose': purposeLabel,
      },
    );

    onVisitorRecorded?.call(record);
    return record;
  }

  Future<List<VisitorRecord>> getVisitorsForDate(String dateKey) async {
    try {
      final file = await _getDailyLogFile(dateKey);
      if (!await file.exists()) return [];
      final lines = await file.readAsLines();
      final records = <VisitorRecord>[];
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        try {
          final map = jsonDecode(trimmed);
          if (map is Map) {
            records.add(
              VisitorRecord.fromJson(Map<String, dynamic>.from(map)),
            );
          }
        } catch (_) {}
      }
      return records;
    } catch (e) {
      logger.e("Failed to read visitors for $dateKey: $e");
      return [];
    }
  }

  Future<List<String>> getAvailableDates() async {
    final now = DateTime.now();
    final dates = <String>{
      for (int i = 0; i < 7; i++)
        formatDateKey(now.subtract(Duration(days: i))),
    };
    try {
      final dir = await AppStorageService().getVisitorsDirectory();
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File) {
            final name = p.basename(entity.path);
            final match = RegExp(
              r'^visitors_(\d{4}-\d{2}-\d{2})\.jsonl$',
            ).firstMatch(name);
            if (match != null) {
              dates.add(match.group(1)!);
            }
          }
        }
      }
    } catch (_) {}
    final sorted = dates.toList()..sort((a, b) => b.compareTo(a));
    return sorted;
  }

  String generateCsvContent(List<VisitorRecord> records) {
    final sb = StringBuffer();
    // UTF-8 BOM for Microsoft Excel compatibility with Malayalam/Unicode text
    sb.write('\uFEFF');
    sb.writeln(VisitorRecord.csvHeader());
    for (final r in records) {
      sb.writeln(r.toCsvRow());
    }
    return sb.toString();
  }

  Future<File> exportCsvFileForDate(String dateKey) async {
    final records = await getVisitorsForDate(dateKey);
    final csv = generateCsvContent(records);
    final dir = await AppStorageService().getVisitorsDirectory();
    final exportDir = Directory(p.join(dir.path, 'exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    final file = File(
      p.join(exportDir.path, 'Nirmala_Bhavan_Visitors_$dateKey.csv'),
    );
    await file.writeAsString(csv, flush: true);
    return file;
  }

  // --- Predefined Audio Guidance & Acoustic Chime Synthesis ---

  Future<void> _initTtsWorker() async {
    if (!Platform.isWindows || _ttsProcess != null) return;
    try {
      final proc = await Process.start('powershell.exe', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        r'''
Add-Type -AssemblyName System.Speech
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
$synth.Rate = 0
$synth.Volume = 95
try {
  $synth.SelectVoiceByHints([System.Speech.Synthesis.VoiceGender]::Female)
} catch {}
while ($true) {
  $line = [Console]::In.ReadLine()
  if ($null -eq $line -or $line -eq 'QUIT') { break }
  if ($line -eq 'STOP') {
    $synth.SpeakAsyncCancelAll()
    continue
  }
  if ($line.StartsWith('SAY:')) {
    $text = $line.Substring(4)
    $synth.SpeakAsyncCancelAll()
    [void]$synth.SpeakAsync($text)
  }
}
''',
      ], mode: ProcessStartMode.normal);
      _ttsProcess = proc;
      unawaited(proc.stdout.drain());
      unawaited(proc.stderr.drain());
    } catch (_) {}
  }

  void speakPrompt(String text) {
    if (_isMuted || !ConfigService().visitorAudioPromptsEnabled) return;
    if (!Platform.isWindows) return;
    if (_ttsProcess == null) {
      unawaited(_initTtsWorker());
    }
    try {
      final sanitized = text.replaceAll('\n', ' ').replaceAll('\r', ' ').trim();
      _ttsProcess?.stdin.writeln('SAY:$sanitized');
    } catch (_) {}
  }

  void stopSpeech() {
    try {
      _ttsProcess?.stdin.writeln('STOP');
    } catch (_) {}
  }

  Future<void> playChime(ChimeType type) async {
    if (_isMuted) return;
    try {
      final soloud = SoLoud.instance;
      final pcmBytes = _buildSynthesizedPcm16(type);
      final stream = soloud.setBufferStream(
        sampleRate: 24000,
        channels: Channels.mono,
        format: BufferType.s16le,
        bufferingType: BufferingType.released,
      );
      soloud.addAudioDataStream(stream, pcmBytes);
      soloud.setDataIsEnded(stream);
      final handle = soloud.play(stream);
      Future.delayed(const Duration(milliseconds: 700), () {
        try {
          soloud.stop(handle);
          soloud.disposeSource(stream);
        } catch (_) {}
      });
    } catch (_) {}
  }

  Uint8List _buildSynthesizedPcm16(ChimeType type) {
    const int sampleRate = 24000;
    final List<double> freqs;
    final double durationSec;

    switch (type) {
      case ChimeType.tap:
        freqs = [587.33]; // D5 short soft click
        durationSec = 0.06;
        break;
      case ChimeType.step:
        freqs = [523.25, 659.25]; // C5 -> E5 gentle two-note chime
        durationSec = 0.24;
        break;
      case ChimeType.nudge:
        freqs = [440.0, 554.37]; // A4 -> C#5 warm attention chime
        durationSec = 0.32;
        break;
      case ChimeType.success:
        freqs = [523.25, 659.25, 783.99, 1046.50]; // C5-E5-G5-C6 chord arpeggio
        durationSec = 0.48;
        break;
    }

    final int numSamples = (sampleRate * durationSec).toInt();
    final ByteData buffer = ByteData(numSamples * 2);

    final int segmentSamples = (numSamples / freqs.length).floor();
    for (int i = 0; i < numSamples; i++) {
      final int noteIdx = (i ~/ segmentSamples).clamp(0, freqs.length - 1);
      final double freq = freqs[noteIdx];
      final double localT = (i - noteIdx * segmentSamples) / sampleRate;
      final double segDur = segmentSamples / sampleRate;
      final double attack = (localT / 0.010).clamp(0.0, 1.0);
      final double decay = math.exp(-3.8 * (localT / segDur));
      final double env = attack * decay;
      final double sample =
          math.sin(2.0 * math.pi * freq * localT) * 0.75 +
          math.sin(4.0 * math.pi * freq * localT) * 0.25;
      final int pcmVal = (sample * env * 9000).round().clamp(-32767, 32767);
      buffer.setInt16(i * 2, pcmVal, Endian.little);
    }

    return buffer.buffer.asUint8List();
  }
}

