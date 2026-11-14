import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:nira/helpers/models/model.visitor.dart';
import 'package:nira/services/service.config.dart';
import 'package:nira/services/service.diagnostics.dart';
import 'package:nira/services/service.logger.dart';
import 'package:nira/services/service.storage.dart';
import 'package:nira/services/service.visitor.dart';

// --- Win32 winspool.drv FFI Bindings for Direct RAW ESC/POS USB Printing ---

base class _DocInfo1 extends Struct {
  external Pointer<Utf16> pDocName;
  external Pointer<Utf16> pOutputFile;
  external Pointer<Utf16> pDatatype;
}

typedef _OpenPrinterWNative = Int32 Function(
  Pointer<Utf16> pPrinterName,
  Pointer<IntPtr> phPrinter,
  Pointer<Void> pDefault,
);
typedef _OpenPrinterWDart = int Function(
  Pointer<Utf16> pPrinterName,
  Pointer<IntPtr> phPrinter,
  Pointer<Void> pDefault,
);

typedef _ClosePrinterNative = Int32 Function(IntPtr hPrinter);
typedef _ClosePrinterDart = int Function(int hPrinter);

typedef _StartDocPrinterWNative = Uint32 Function(
  IntPtr hPrinter,
  Uint32 level,
  Pointer<_DocInfo1> pDocInfo,
);
typedef _StartDocPrinterWDart = int Function(
  int hPrinter,
  int level,
  Pointer<_DocInfo1> pDocInfo,
);

typedef _EndDocPrinterNative = Int32 Function(IntPtr hPrinter);
typedef _EndDocPrinterDart = int Function(int hPrinter);

typedef _StartPagePrinterNative = Int32 Function(IntPtr hPrinter);
typedef _StartPagePrinterDart = int Function(int hPrinter);

typedef _EndPagePrinterNative = Int32 Function(IntPtr hPrinter);
typedef _EndPagePrinterDart = int Function(int hPrinter);

typedef _WritePrinterNative = Int32 Function(
  IntPtr hPrinter,
  Pointer<Uint8> pBuf,
  Uint32 cbBuf,
  Pointer<Uint32> pcWritten,
);
typedef _WritePrinterDart = int Function(
  int hPrinter,
  Pointer<Uint8> pBuf,
  int cbBuf,
  Pointer<Uint32> pcWritten,
);

typedef _GetDefaultPrinterWNative = Int32 Function(
  Pointer<Utf16> pszBuffer,
  Pointer<Uint32> pcchBuffer,
);
typedef _GetDefaultPrinterWDart = int Function(
  Pointer<Utf16> pszBuffer,
  Pointer<Uint32> pcchBuffer,
);

typedef _GetLastErrorNative = Uint32 Function();
typedef _GetLastErrorDart = int Function();

// --- Data Models for Print Jobs & Printer Status ---

enum PrintJobState { pending, printing, printed, failed }

class PrintJobEntry {
  final String tokenId;
  final String shortToken;
  final VisitorRecord record;
  final String instructionEn;
  final PrintJobState state;
  final int attempts;
  final DateTime createdAt;
  final DateTime? printedAt;
  final DateTime? lastAttemptAt;
  final String? lastError;
  final String? printerUsed;

  const PrintJobEntry({
    required this.tokenId,
    required this.shortToken,
    required this.record,
    required this.instructionEn,
    required this.state,
    this.attempts = 0,
    required this.createdAt,
    this.printedAt,
    this.lastAttemptAt,
    this.lastError,
    this.printerUsed,
  });

  PrintJobEntry copyWith({
    PrintJobState? state,
    int? attempts,
    DateTime? printedAt,
    DateTime? lastAttemptAt,
    String? lastError,
    bool clearError = false,
    String? printerUsed,
  }) {
    return PrintJobEntry(
      tokenId: tokenId,
      shortToken: shortToken,
      record: record,
      instructionEn: instructionEn,
      state: state ?? this.state,
      attempts: attempts ?? this.attempts,
      createdAt: createdAt,
      printedAt: printedAt ?? this.printedAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      lastError: clearError ? null : (lastError ?? this.lastError),
      printerUsed: printerUsed ?? this.printerUsed,
    );
  }

  Map<String, dynamic> toJson() => {
    'tokenId': tokenId,
    'shortToken': shortToken,
    'record': record.toJson(),
    'instructionEn': instructionEn,
    'state': state.name,
    'attempts': attempts,
    'createdAt': createdAt.toIso8601String(),
    'printedAt': printedAt?.toIso8601String(),
    'lastAttemptAt': lastAttemptAt?.toIso8601String(),
    'lastError': lastError,
    'printerUsed': printerUsed,
  };

  factory PrintJobEntry.fromJson(Map<String, dynamic> json) {
    final recMap = json['record'] is Map
        ? Map<String, dynamic>.from(json['record'] as Map)
        : <String, dynamic>{};
    final rec = VisitorRecord.fromJson(recMap);
    final rawState = json['state']?.toString() ?? 'pending';
    final parsedState = PrintJobState.values.firstWhere(
      (s) => s.name == rawState,
      orElse: () => PrintJobState.pending,
    );
    return PrintJobEntry(
      tokenId: json['tokenId']?.toString() ?? rec.tokenId,
      shortToken: json['shortToken']?.toString() ?? rec.shortToken,
      record: rec,
      instructionEn:
          json['instructionEn']?.toString() ??
          'Please present this printed token pass at the Reception Desk.',
      state: parsedState == PrintJobState.printing
          ? PrintJobState.failed
          : parsedState,
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          rec.timestamp,
      printedAt: DateTime.tryParse(json['printedAt']?.toString() ?? ''),
      lastAttemptAt: DateTime.tryParse(json['lastAttemptAt']?.toString() ?? ''),
      lastError: json['lastError']?.toString(),
      printerUsed: json['printerUsed']?.toString(),
    );
  }
}

class DiscoveredPrinter {
  final String name;
  final String portName;
  final String driverName;
  final bool isOnline;
  final bool isDefault;
  final bool isThermalCandidate;

  const DiscoveredPrinter({
    required this.name,
    required this.portName,
    required this.driverName,
    required this.isOnline,
    required this.isDefault,
    required this.isThermalCandidate,
  });
}

class PrintOutcome {
  final bool success;
  final String message;
  final String? printerName;
  final int attemptsMade;

  const PrintOutcome({
    required this.success,
    required this.message,
    this.printerName,
    this.attemptsMade = 1,
  });
}

/// Production ESC/POS 80mm Receipt Builder for PBX1 3-inch Thermal Printer (48 chars/line Font A).
class EscPos80mmReceiptBuilder {
  static const int lineWidth = 48; // 80mm thermal paper standard Font A width

  final List<int> _bytes = [];

  /// Initialize printer (`ESC @`), select standard character table (`ESC t 0`), normal line spacing (`ESC 2`).
  void initPrinter() {
    _bytes.addAll([0x1B, 0x40]); // ESC @ (Initialize printer)
    _bytes.addAll([0x1B, 0x74, 0x00]); // ESC t 0 (PC437 USA Standard Europe)
    _bytes.addAll([0x1B, 0x32]); // ESC 2 (Default line spacing)
  }

  /// Align: 0 = Left, 1 = Center, 2 = Right (`ESC a n`)
  void setAlign(int align) {
    _bytes.addAll([0x1B, 0x61, align.clamp(0, 2)]);
  }

  /// Bold on/off (`ESC E n`)
  void setBold(bool enabled) {
    _bytes.addAll([0x1B, 0x45, enabled ? 0x01 : 0x00]);
  }

  /// Character size (`GS ! n`): widthMultiplier (1..4), heightMultiplier (1..4)
  void setTextSize({int width = 1, int height = 1}) {
    final w = (width.clamp(1, 8) - 1) << 4;
    final h = (height.clamp(1, 8) - 1);
    _bytes.addAll([0x1D, 0x21, w | h]);
  }

  /// Reverse black/white printing mode (`GS B n`) for prominent badges
  void setReverseMode(bool enabled) {
    _bytes.addAll([0x1D, 0x42, enabled ? 0x01 : 0x00]);
  }

  void writeLine([String text = '']) {
    final clean = sanitizeAscii(text);
    _bytes.addAll(ascii.encode(clean));
    _bytes.add(0x0A); // LF
  }

  void writeWrapped(String text, {int width = lineWidth, String indent = ''}) {
    final lines = wrapText(sanitizeAscii(text), width: width, indent: indent);
    for (final line in lines) {
      writeLine(line);
    }
  }

  void writeKeyValue(String label, String value) {
    final cleanLabel = sanitizeAscii(label).trim();
    final cleanVal = sanitizeAscii(value).trim();
    final prefix = '$cleanLabel: ';
    final firstLineCap = lineWidth - prefix.length;

    if (cleanVal.length <= firstLineCap) {
      final padCount = (lineWidth - prefix.length - cleanVal.length).clamp(1, lineWidth);
      writeLine('$prefix${' ' * padCount}$cleanVal');
      return;
    }

    // Multi-line wrapped value aligned neatly
    final words = cleanVal.split(RegExp(r'\s+'));
    final lines = <String>[];
    String current = '';

    for (final w in words) {
      final cap = lines.isEmpty ? firstLineCap : (lineWidth - 4);
      if (current.isEmpty) {
        current = w;
      } else if (current.length + 1 + w.length <= cap) {
        current = '$current $w';
      } else {
        lines.add(current);
        current = w;
      }
    }
    if (current.isNotEmpty) {
      lines.add(current);
    }

    if (lines.isEmpty) {
      writeLine(prefix);
      return;
    }

    final firstVal = lines.first;
    final firstPad = (lineWidth - prefix.length - firstVal.length).clamp(1, lineWidth);
    writeLine('$prefix${' ' * firstPad}$firstVal');

    for (int i = 1; i < lines.length; i++) {
      final cont = lines[i];
      final contPad = (lineWidth - cont.length).clamp(2, lineWidth);
      writeLine('${' ' * contPad}$cont');
    }
  }

  void drawDoubleDivider() {
    writeLine('=' * lineWidth);
  }

  void drawSingleDivider() {
    writeLine('-' * lineWidth);
  }

  void feedLines(int count) {
    _bytes.addAll([0x1B, 0x64, count.clamp(1, 20)]); // ESC d n
  }

  /// Partial cut with feed (`GS V 66 n`) supported by PBX1 3-inch Auto Cutter
  void feedAndAutoCut({int feedUnits = 3}) {
    _bytes.addAll([0x1D, 0x56, 0x42, feedUnits.clamp(0, 10)]);
  }

  Uint8List toBytes() => Uint8List.fromList(_bytes);

  static String sanitizeAscii(String input) {
    return input
        .replaceAll('•', '-')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll(RegExp(r'[^\x20-\x7E]'), '')
        .trim();
  }

  static List<String> wrapText(
    String text, {
    int width = lineWidth,
    String indent = '',
  }) {
    final clean = sanitizeAscii(text);
    if (clean.isEmpty) return [''];
    final words = clean.split(RegExp(r'\s+'));
    final lines = <String>[];
    String current = indent;

    for (final word in words) {
      if (word.isEmpty) continue;
      if (current == indent) {
        if (current.length + word.length <= width) {
          current = '$current$word';
        } else {
          lines.add(word.substring(0, width.clamp(1, word.length)));
        }
      } else if (current.length + 1 + word.length <= width) {
        current = '$current $word';
      } else {
        lines.add(current);
        current = '$indent$word';
      }
    }
    if (current.trim().isNotEmpty) {
      lines.add(current);
    }
    return lines;
  }

  /// Builds a complete, attractive 80mm school-branded ESC/POS receipt for a VisitorRecord.
  static Uint8List buildVisitorPassReceipt({
    required VisitorRecord record,
    required String instructionEn,
    bool autoCut = true,
  }) {
    final b = EscPos80mmReceiptBuilder();
    b.initPrinter();

    // 1. School Header
    b.setAlign(1); // Center
    b.setBold(true);
    b.setTextSize(width: 1, height: 2);
    b.writeLine('NIRMALA BHAVAN HSS');
    b.setTextSize(width: 1, height: 1);
    b.writeLine('HIGHER SECONDARY SCHOOL');
    b.setBold(false);
    b.writeLine('Kowdiar, Trivandrum, Kerala - 695003');
    b.writeLine('Ph: +91-471-231-7772 / 272-7246');
    b.drawDoubleDivider();

    // 2. Pass Title Banner
    b.setBold(true);
    b.setReverseMode(true);
    b.writeLine('        OFFICIAL VISITOR TOKEN PASS         ');
    b.setReverseMode(false);
    b.writeLine();

    // 3. Prominent Token Number Block
    b.setAlign(1);
    b.setBold(false);
    b.writeLine('TOKEN NUMBER');
    b.setBold(true);
    b.setTextSize(width: 3, height: 3);
    b.writeLine(record.shortToken);
    b.setTextSize(width: 1, height: 1);
    b.setBold(false);
    b.writeLine('Pass ID: ${record.tokenId}');
    b.drawDoubleDivider();

    // 4. Visitor & Appointment Details
    b.setAlign(0); // Left align
    b.setBold(false);
    b.writeKeyValue('DATE', record.formattedDate);
    b.writeKeyValue('CHECK-IN TIME', record.formattedTime);
    b.drawSingleDivider();

    b.setBold(true);
    b.writeKeyValue('VISITOR NAME', record.visitorName.toUpperCase());
    b.setBold(false);
    b.writeKeyValue('MOBILE NO.', record.phoneNumber);
    b.writeKeyValue('CATEGORY', record.categoryLabel);
    b.drawSingleDivider();

    b.setBold(true);
    b.writeKeyValue('PURPOSE', record.purposeLabel);
    b.writeKeyValue('TO MEET', record.personToMeet);
    b.setBold(false);

    if (record.studentSummary != 'N/A') {
      b.writeKeyValue('STUDENT', record.studentSummary);
    }
    b.drawSingleDivider();

    // 5. Reception Guidance / Instructions
    b.setBold(true);
    b.writeLine('VISITOR INSTRUCTIONS:');
    b.setBold(false);
    final cleanInstruction = instructionEn.trim().isNotEmpty
        ? instructionEn.trim()
        : 'Please present this printed token pass at the Reception Desk before entering campus corridors.';
    b.writeWrapped(cleanInstruction, width: lineWidth);
    b.drawSingleDivider();

    // 6. Official Verification Box (For Staff / Security Sign-off)
    b.writeLine('OFFICE / RECEPTION VERIFICATION:');
    b.writeLine();
    b.writeLine('Met With / Staff Sign : ________________________');
    b.writeLine('Check-Out Time        : ________________________');
    b.drawDoubleDivider();

    // 7. Footer
    b.setAlign(1);
    b.setBold(true);
    b.writeLine('"Where there is love, there is God!"');
    b.setBold(false);
    b.writeLine('Issued by NIRA AI Reception Kiosk');
    b.writeLine('Valid only for the date of issue.');

    // Feed and Auto-Cut
    b.feedLines(3);
    if (autoCut) {
      b.feedAndAutoCut(feedUnits: 3);
    } else {
      b.feedLines(3);
    }

    return b.toBytes();
  }

  /// Builds a self-test diagnostic receipt for the PBX1 80mm thermal printer.
  static Uint8List buildDiagnosticTestReceipt({
    required String printerName,
    bool autoCut = true,
  }) {
    final now = DateTime.now();
    final dateStr = VisitorService.formatDateKey(now);
    final hour12 = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final min = now.minute.toString().padLeft(2, '0');
    final sec = now.second.toString().padLeft(2, '0');
    final amPm = now.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hour12:$min:$sec $amPm';

    final b = EscPos80mmReceiptBuilder();
    b.initPrinter();

    b.setAlign(1);
    b.setBold(true);
    b.setTextSize(width: 1, height: 2);
    b.writeLine('NIRMALA BHAVAN HSS');
    b.setTextSize(width: 1, height: 1);
    b.writeLine('PBX1 80MM THERMAL PRINTER TEST');
    b.setBold(false);
    b.drawDoubleDivider();

    b.setAlign(1);
    b.setBold(true);
    b.setTextSize(width: 2, height: 2);
    b.writeLine('TEST PASS: V-000');
    b.setTextSize(width: 1, height: 1);
    b.setBold(false);
    b.drawSingleDivider();

    b.setAlign(0);
    b.writeKeyValue('PRINTER QUEUE', printerName);
    b.writeKeyValue('PAPER WIDTH', '80mm (48 Columns Font A)');
    b.writeKeyValue('PROTOCOL', 'Win32 RAW ESC/POS + Auto Cut');
    b.writeKeyValue('DATE & TIME', '$dateStr $timeStr');
    b.drawDoubleDivider();

    b.setAlign(1);
    b.setBold(true);
    b.writeLine('PRINTER STATUS: READY & VERIFIED');
    b.setBold(false);
    b.writeLine('NIRA AI Reception Kiosk');

    b.feedLines(3);
    if (autoCut) {
      b.feedAndAutoCut(feedUnits: 3);
    } else {
      b.feedLines(3);
    }
    return b.toBytes();
  }
}

/// Singleton Thermal Printer Service managing Win32 RAW USB printing, auto-discovery,
/// persistent print queue, automatic retry, and recovery for failed print jobs.
class ThermalPrinterService extends ChangeNotifier {
  static final ThermalPrinterService _instance =
      ThermalPrinterService._internal();
  factory ThermalPrinterService() => _instance;
  ThermalPrinterService._internal();

  final Map<String, PrintJobEntry> _jobsByTokenId = {};
  List<DiscoveredPrinter> _discoveredPrinters = [];
  bool _isInitialized = false;
  bool _isPrinting = false;
  String? _activePrinterName;
  String _statusSummary = 'Checking printer...';
  bool _isPrinterReady = false;
  Timer? _retryWorkerTimer;

  // Win32 FFI function pointers
  DynamicLibrary? _winspool;
  DynamicLibrary? _kernel32;
  _OpenPrinterWDart? _openPrinterW;
  _ClosePrinterDart? _closePrinter;
  _StartDocPrinterWDart? _startDocPrinterW;
  _EndDocPrinterDart? _endDocPrinter;
  _StartPagePrinterDart? _startPagePrinter;
  _EndPagePrinterDart? _endPagePrinter;
  _WritePrinterDart? _writePrinter;
  _GetDefaultPrinterWDart? _getDefaultPrinterW;
  _GetLastErrorDart? _getLastError;

  bool get isPrinting => _isPrinting;
  bool get isPrinterReady => _isPrinterReady;
  String get statusSummary => _statusSummary;
  String? get activePrinterName => _activePrinterName;
  List<DiscoveredPrinter> get discoveredPrinters =>
      List.unmodifiable(_discoveredPrinters);

  List<PrintJobEntry> get allJobs {
    final list = _jobsByTokenId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<PrintJobEntry> get pendingOrFailedJobs {
    final list = _jobsByTokenId.values
        .where(
          (j) =>
              j.state == PrintJobState.failed ||
              j.state == PrintJobState.pending,
        )
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  PrintJobEntry? getJobForToken(String tokenId) => _jobsByTokenId[tokenId];

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    _bindWin32Spooler();
    await _loadPrintQueue();
    await refreshPrinters();

    // Background worker checks every 30 seconds to auto-recover pending jobs if printer reconnects
    _retryWorkerTimer?.cancel();
    _retryWorkerTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      unawaited(_autoRecoverIfPrinterOnline());
    });
  }

  void _bindWin32Spooler() {
    if (!Platform.isWindows) return;
    try {
      _winspool = DynamicLibrary.open('winspool.drv');
      _kernel32 = DynamicLibrary.open('kernel32.dll');

      _openPrinterW = _winspool!
          .lookupFunction<_OpenPrinterWNative, _OpenPrinterWDart>(
            'OpenPrinterW',
          );
      _closePrinter = _winspool!
          .lookupFunction<_ClosePrinterNative, _ClosePrinterDart>(
            'ClosePrinter',
          );
      _startDocPrinterW = _winspool!
          .lookupFunction<_StartDocPrinterWNative, _StartDocPrinterWDart>(
            'StartDocPrinterW',
          );
      _endDocPrinter = _winspool!
          .lookupFunction<_EndDocPrinterNative, _EndDocPrinterDart>(
            'EndDocPrinter',
          );
      _startPagePrinter = _winspool!
          .lookupFunction<_StartPagePrinterNative, _StartPagePrinterDart>(
            'StartPagePrinter',
          );
      _endPagePrinter = _winspool!
          .lookupFunction<_EndPagePrinterNative, _EndPagePrinterDart>(
            'EndPagePrinter',
          );
      _writePrinter = _winspool!
          .lookupFunction<_WritePrinterNative, _WritePrinterDart>(
            'WritePrinter',
          );
      _getDefaultPrinterW = _winspool!
          .lookupFunction<_GetDefaultPrinterWNative, _GetDefaultPrinterWDart>(
            'GetDefaultPrinterW',
          );
      _getLastError = _kernel32!
          .lookupFunction<_GetLastErrorNative, _GetLastErrorDart>(
            'GetLastError',
          );
    } catch (e) {
      logger.e('Failed to bind winspool.drv FFI: $e');
    }
  }

  Future<File> _getQueueFile() async {
    final dir = await AppStorageService().getVisitorsDirectory();
    return File(p.join(dir.path, 'thermal_print_queue.json'));
  }

  Future<void> _loadPrintQueue() async {
    try {
      final file = await _getQueueFile();
      if (!await file.exists()) return;
      final content = await file.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is Map) {
        _jobsByTokenId.clear();
        decoded.forEach((key, value) {
          if (value is Map) {
            final job = PrintJobEntry.fromJson(
              Map<String, dynamic>.from(value),
            );
            _jobsByTokenId[job.tokenId] = job;
          }
        });
      }
      notifyListeners();
    } catch (e) {
      logger.w('Failed to load thermal print queue: $e');
    }
  }

  Future<void> _savePrintQueue() async {
    try {
      final file = await _getQueueFile();
      // Keep last 300 jobs so storage stays bounded while preserving all failed/pending jobs
      final entries = _jobsByTokenId.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final map = <String, dynamic>{};
      int printedKept = 0;
      for (final job in entries) {
        if (job.state == PrintJobState.printed) {
          if (printedKept >= 250) continue;
          printedKept++;
        }
        map[job.tokenId] = job.toJson();
      }
      await file.writeAsString(jsonEncode(map), flush: true);
    } catch (e) {
      logger.w('Failed to save thermal print queue: $e');
    }
  }

  String? _getWindowsDefaultPrinterName() {
    if (!Platform.isWindows || _getDefaultPrinterW == null) return null;
    final pcchBuffer = calloc<Uint32>();
    try {
      pcchBuffer.value = 0;
      _getDefaultPrinterW!(nullptr, pcchBuffer);
      final needed = pcchBuffer.value;
      if (needed <= 1) return null;
      final buffer = calloc<Uint16>(needed).cast<Utf16>();
      try {
        final ok = _getDefaultPrinterW!(buffer, pcchBuffer);
        if (ok != 0) {
          final name = buffer.toDartString().trim();
          return name.isNotEmpty ? name : null;
        }
      } finally {
        calloc.free(buffer);
      }
    } catch (_) {
    } finally {
      calloc.free(pcchBuffer);
    }
    return null;
  }

  bool _canOpenPrinterHandle(String printerName) {
    if (!Platform.isWindows || _openPrinterW == null || _closePrinter == null) {
      return false;
    }
    final namePtr = printerName.toNativeUtf16();
    final phPrinter = calloc<IntPtr>();
    try {
      final ok = _openPrinterW!(namePtr, phPrinter, nullptr);
      if (ok != 0 && phPrinter.value != 0) {
        _closePrinter!(phPrinter.value);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      calloc.free(namePtr);
      calloc.free(phPrinter);
    }
  }

  static bool _isVirtualDocumentPrinter(String name, String port) {
    final lower = '$name $port'.toLowerCase();
    return lower.contains('microsoft print to pdf') ||
        lower.contains('microsoft xps') ||
        lower.contains('onenote') ||
        lower.contains('fax') ||
        lower.contains('nul:') ||
        lower.contains('portal');
  }

  static bool _matchesThermalKeywords(String name, String driver, String port) {
    final lower = '$name $driver $port'.toLowerCase();
    return lower.contains('pbx') ||
        lower.contains('80mm') ||
        lower.contains('pos') ||
        lower.contains('thermal') ||
        lower.contains('receipt') ||
        lower.contains('esc') ||
        lower.contains('epson') ||
        lower.contains('tm-t') ||
        lower.contains('xprinter') ||
        lower.contains('rp80') ||
        lower.contains('3-inch') ||
        lower.contains('usb0');
  }

  /// Queries Windows print queues and identifies the PBX1 80mm USB thermal printer.
  Future<List<DiscoveredPrinter>> refreshPrinters() async {
    if (!Platform.isWindows) {
      _isPrinterReady = false;
      _statusSummary = 'Windows required for USB printing';
      notifyListeners();
      return [];
    }

    final defaultPrinter = _getWindowsDefaultPrinterName();
    final discovered = <DiscoveredPrinter>[];

    try {
      final res = await Process.run(
        'powershell.exe',
        [
          '-NoProfile',
          '-ExecutionPolicy',
          'Bypass',
          '-Command',
          r'Get-CimInstance Win32_Printer | Select-Object Name, PortName, DriverName, WorkOffline, PrinterStatus, Default | ConvertTo-Json -Compress',
        ],
      ).timeout(const Duration(seconds: 6));

      final stdoutStr = res.stdout?.toString().trim() ?? '';
      if (stdoutStr.isNotEmpty) {
        final parsed = jsonDecode(stdoutStr);
        final rawList = parsed is List ? parsed : [parsed];
        for (final item in rawList) {
          if (item is! Map) continue;
          final name = item['Name']?.toString().trim() ?? '';
          if (name.isEmpty) continue;
          final port = item['PortName']?.toString().trim() ?? '';
          final driver = item['DriverName']?.toString().trim() ?? '';
          final workOffline = item['WorkOffline'] == true;
          final isDef = item['Default'] == true || name == defaultPrinter;
          final isVirtual = _isVirtualDocumentPrinter(name, port);
          final isThermal =
              !isVirtual && _matchesThermalKeywords(name, driver, port);

          discovered.add(
            DiscoveredPrinter(
              name: name,
              portName: port,
              driverName: driver,
              isOnline: !workOffline,
              isDefault: isDef,
              isThermalCandidate: isThermal,
            ),
          );
        }
      }
    } catch (e) {
      logger.w('PowerShell printer enumeration fallback triggered: $e');
    }

    // Sort thermal candidates first, then default printer, then online printers
    discovered.sort((a, b) {
      if (a.isThermalCandidate != b.isThermalCandidate) {
        return a.isThermalCandidate ? -1 : 1;
      }
      if (a.isDefault != b.isDefault) {
        return a.isDefault ? -1 : 1;
      }
      if (a.isOnline != b.isOnline) {
        return a.isOnline ? -1 : 1;
      }
      return a.name.compareTo(b.name);
    });

    _discoveredPrinters = discovered;
    _resolveTargetPrinter(defaultPrinter);
    notifyListeners();
    return discovered;
  }

  void _resolveTargetPrinter(String? defaultPrinter) {
    final configured = ConfigService().thermalPrinterName.trim();

    if (configured.isNotEmpty) {
      final matched = _discoveredPrinters
          .where((p) => p.name.toLowerCase() == configured.toLowerCase())
          .firstOrNull;
      if (matched != null) {
        _activePrinterName = matched.name;
        _isPrinterReady =
            matched.isOnline && _canOpenPrinterHandle(matched.name);
        _statusSummary = _isPrinterReady
            ? 'Ready: ${matched.name} (${matched.portName})'
            : 'Offline: ${matched.name}';
        return;
      }
      // Even if not in WMI list yet, check direct Win32 spooler handle
      if (_canOpenPrinterHandle(configured)) {
        _activePrinterName = configured;
        _isPrinterReady = true;
        _statusSummary = 'Ready: $configured';
        return;
      }
    }

    // Auto-select best thermal candidate (e.g., PBX1 / 80mm / POS / USB001)
    final thermal = _discoveredPrinters
        .where((p) => p.isThermalCandidate && p.isOnline)
        .firstOrNull;
    if (thermal != null && _canOpenPrinterHandle(thermal.name)) {
      _activePrinterName = thermal.name;
      _isPrinterReady = true;
      _statusSummary = 'Auto-detected: ${thermal.name} (${thermal.portName})';
      return;
    }

    // Fallback to any non-virtual online printer
    final nonVirtual = _discoveredPrinters
        .where(
          (p) => !_isVirtualDocumentPrinter(p.name, p.portName) && p.isOnline,
        )
        .firstOrNull;
    if (nonVirtual != null && _canOpenPrinterHandle(nonVirtual.name)) {
      _activePrinterName = nonVirtual.name;
      _isPrinterReady = true;
      _statusSummary = 'Ready: ${nonVirtual.name} (${nonVirtual.portName})';
      return;
    }

    // If a thermal printer is installed but currently offline/unplugged
    final offlineThermal = _discoveredPrinters
        .where((p) => p.isThermalCandidate)
        .firstOrNull;
    if (offlineThermal != null) {
      _activePrinterName = offlineThermal.name;
      _isPrinterReady = false;
      _statusSummary = 'USB Disconnected / Offline: ${offlineThermal.name}';
      return;
    }

    _activePrinterName = configured.isNotEmpty ? configured : null;
    _isPrinterReady = false;
    _statusSummary =
        'PBX1 80mm USB Thermal Printer not detected (Connect USB to print)';
  }

  /// Sends raw ESC/POS bytes directly to the Windows print spooler via Win32 FFI.
  (bool ok, String message) _sendRawEscPosBytesWin32({
    required String printerName,
    required Uint8List bytes,
    required String docTitle,
  }) {
    if (!Platform.isWindows) {
      return (false, 'RAW ESC/POS printing is only supported on Windows.');
    }
    if (_openPrinterW == null ||
        _closePrinter == null ||
        _startDocPrinterW == null ||
        _endDocPrinter == null ||
        _startPagePrinter == null ||
        _endPagePrinter == null ||
        _writePrinter == null) {
      return (false, 'Windows Print Spooler (winspool.drv) FFI unavailable.');
    }

    final pPrinterName = printerName.toNativeUtf16();
    final phPrinter = calloc<IntPtr>();
    final pDocName = docTitle.toNativeUtf16();
    final pDatatype = 'RAW'.toNativeUtf16();
    final pDocInfo = calloc<_DocInfo1>();
    final pData = calloc<Uint8>(bytes.length);
    final pcWritten = calloc<Uint32>();

    try {
      final opened = _openPrinterW!(pPrinterName, phPrinter, nullptr);
      if (opened == 0 || phPrinter.value == 0) {
        final err = _getLastError?.call() ?? 0;
        return (
          false,
          'Cannot open printer "$printerName" (Win32 Error $err). Check USB connection.',
        );
      }

      final hPrinter = phPrinter.value;
      try {
        pDocInfo.ref.pDocName = pDocName;
        pDocInfo.ref.pOutputFile = nullptr;
        pDocInfo.ref.pDatatype = pDatatype;

        final jobId = _startDocPrinterW!(hPrinter, 1, pDocInfo);
        if (jobId == 0) {
          final err = _getLastError?.call() ?? 0;
          return (
            false,
            'StartDocPrinter failed on "$printerName" (Win32 Error $err).',
          );
        }

        try {
          final pageStarted = _startPagePrinter!(hPrinter);
          if (pageStarted == 0) {
            final err = _getLastError?.call() ?? 0;
            return (
              false,
              'StartPagePrinter failed on "$printerName" (Win32 Error $err).',
            );
          }

          try {
            final nativeBuf = pData.asTypedList(bytes.length);
            nativeBuf.setAll(0, bytes);

            final writtenOk = _writePrinter!(
              hPrinter,
              pData,
              bytes.length,
              pcWritten,
            );
            final bytesWritten = pcWritten.value;

            if (writtenOk == 0 || bytesWritten != bytes.length) {
              final err = _getLastError?.call() ?? 0;
              return (
                false,
                'WritePrinter incomplete ($bytesWritten/${bytes.length} bytes, Error $err).',
              );
            }
          } finally {
            _endPagePrinter!(hPrinter);
          }
        } finally {
          _endDocPrinter!(hPrinter);
        }
      } finally {
        _closePrinter!(hPrinter);
      }

      return (
        true,
        'Printed ${bytes.length} ESC/POS bytes to "$printerName".',
      );
    } catch (e) {
      return (false, 'Win32 Spooler exception: $e');
    } finally {
      calloc.free(pPrinterName);
      calloc.free(phPrinter);
      calloc.free(pDocName);
      calloc.free(pDatatype);
      calloc.free(pDocInfo);
      calloc.free(pData);
      calloc.free(pcWritten);
    }
  }

  /// Automatically enqueues and prints a newly generated VisitorRecord with up to [maxAttempts] retries.
  /// Never loses or duplicates the visitor token if printing fails; retains the job for later recovery.
  Future<PrintOutcome> printVisitorToken(
    VisitorRecord record, {
    String? instructionEn,
    int maxAttempts = 3,
  }) async {
    final resolvedInstruction =
        instructionEn ??
        VisitorCatalog.purposes
            .where((p) => p.id == record.purposeId)
            .map((p) => p.instructionEn)
            .firstOrNull ??
        'Please present this printed token pass at the Reception Desk.';

    final existing = _jobsByTokenId[record.tokenId];
    final baseJob = existing ??
        PrintJobEntry(
          tokenId: record.tokenId,
          shortToken: record.shortToken,
          record: record,
          instructionEn: resolvedInstruction,
          state: PrintJobState.pending,
          attempts: 0,
          createdAt: DateTime.now(),
        );

    _jobsByTokenId[record.tokenId] = baseJob.copyWith(
      state: PrintJobState.printing,
      lastAttemptAt: DateTime.now(),
    );
    await _savePrintQueue();
    notifyListeners();

    _isPrinting = true;
    notifyListeners();

    try {
      await refreshPrinters();
      final targetPrinter = _activePrinterName;

      if (targetPrinter == null || !_isPrinterReady) {
        final errMsg =
            targetPrinter == null
                ? 'PBX1 80mm USB Thermal Printer not detected. Token saved to recovery queue.'
                : 'Printer "$targetPrinter" is offline or unplugged. Token saved to recovery queue.';

        _jobsByTokenId[record.tokenId] = baseJob.copyWith(
          state: PrintJobState.failed,
          attempts: baseJob.attempts + 1,
          lastAttemptAt: DateTime.now(),
          lastError: errMsg,
          printerUsed: targetPrinter,
        );
        await _savePrintQueue();

        DiagnosticLogger().log(
          type: LogType.warning,
          event: 'TOKEN_PRINT_QUEUED',
          message:
              'Token ${record.shortToken} (${record.tokenId}) queued for recovery: $errMsg',
          details: {
            'tokenId': record.tokenId,
            'shortToken': record.shortToken,
            'printer': targetPrinter ?? 'None',
          },
        );

        return PrintOutcome(
          success: false,
          message: errMsg,
          printerName: targetPrinter,
          attemptsMade: 1,
        );
      }

      final payload = EscPos80mmReceiptBuilder.buildVisitorPassReceipt(
        record: record,
        instructionEn: resolvedInstruction,
        autoCut: ConfigService().thermalAutoCutEnabled,
      );

      String lastErr = 'Unknown print error';
      int attemptsUsed = 0;

      for (int attempt = 1; attempt <= maxAttempts; attempt++) {
        attemptsUsed = attempt;
        final (ok, msg) = _sendRawEscPosBytesWin32(
          printerName: targetPrinter,
          bytes: payload,
          docTitle: 'NIRA Visitor Token ${record.shortToken} (${record.tokenId})',
        );

        if (ok) {
          final now = DateTime.now();
          _jobsByTokenId[record.tokenId] = baseJob.copyWith(
            state: PrintJobState.printed,
            attempts: baseJob.attempts + attempt,
            printedAt: now,
            lastAttemptAt: now,
            clearError: true,
            printerUsed: targetPrinter,
          );
          await _savePrintQueue();

          DiagnosticLogger().log(
            type: LogType.success,
            event: 'TOKEN_PRINTED',
            message:
                'Printed token ${record.shortToken} (${record.tokenId}) on "$targetPrinter" (attempt $attempt).',
            details: {
              'tokenId': record.tokenId,
              'shortToken': record.shortToken,
              'printer': targetPrinter,
              'bytes': payload.length,
            },
          );

          return PrintOutcome(
            success: true,
            message: 'Receipt printed on $targetPrinter',
            printerName: targetPrinter,
            attemptsMade: attempt,
          );
        }

        lastErr = msg;
        if (attempt < maxAttempts) {
          await Future.delayed(Duration(milliseconds: 450 * attempt));
          await refreshPrinters();
        }
      }

      // All attempts failed -> retain job in failed state for recovery
      _jobsByTokenId[record.tokenId] = baseJob.copyWith(
        state: PrintJobState.failed,
        attempts: baseJob.attempts + attemptsUsed,
        lastAttemptAt: DateTime.now(),
        lastError: lastErr,
        printerUsed: targetPrinter,
      );
      await _savePrintQueue();

      DiagnosticLogger().log(
        type: LogType.error,
        event: 'TOKEN_PRINT_FAILED',
        message:
            'Failed to print token ${record.shortToken} (${record.tokenId}) after $attemptsUsed attempts: $lastErr',
        details: {
          'tokenId': record.tokenId,
          'shortToken': record.shortToken,
          'printer': targetPrinter,
          'error': lastErr,
        },
      );

      return PrintOutcome(
        success: false,
        message: lastErr,
        printerName: targetPrinter,
        attemptsMade: attemptsUsed,
      );
    } finally {
      _isPrinting = false;
      notifyListeners();
    }
  }

  /// Prints a diagnostic test slip to verify the PBX1 80mm thermal printer and auto-cutter.
  Future<PrintOutcome> printTestReceipt() async {
    _isPrinting = true;
    notifyListeners();
    try {
      await refreshPrinters();
      final targetPrinter = _activePrinterName;
      if (targetPrinter == null || !_isPrinterReady) {
        return PrintOutcome(
          success: false,
          message:
              'PBX1 80mm USB Thermal Printer is not connected or online. Select an active printer first.',
          printerName: targetPrinter,
        );
      }

      final payload = EscPos80mmReceiptBuilder.buildDiagnosticTestReceipt(
        printerName: targetPrinter,
        autoCut: ConfigService().thermalAutoCutEnabled,
      );

      final (ok, msg) = _sendRawEscPosBytesWin32(
        printerName: targetPrinter,
        bytes: payload,
        docTitle: 'NIRA PBX1 80mm Diagnostic Test Slip',
      );

      DiagnosticLogger().log(
        type: ok ? LogType.success : LogType.error,
        event: ok ? 'PRINTER_TEST_SUCCESS' : 'PRINTER_TEST_FAILED',
        message: msg,
        details: {'printer': targetPrinter, 'bytes': payload.length},
      );

      return PrintOutcome(
        success: ok,
        message: ok ? 'Test receipt printed on $targetPrinter!' : msg,
        printerName: targetPrinter,
      );
    } finally {
      _isPrinting = false;
      notifyListeners();
    }
  }

  /// Retries all failed/pending print jobs in chronological order.
  Future<(int printedCount, int remainingCount)> retryAllFailedJobs() async {
    final queue = pendingOrFailedJobs;
    if (queue.isEmpty) return (0, 0);

    int successCount = 0;
    for (final job in queue) {
      final outcome = await printVisitorToken(
        job.record,
        instructionEn: job.instructionEn,
        maxAttempts: 2,
      );
      if (outcome.success) {
        successCount++;
      } else {
        // Stop batch if printer is still offline
        break;
      }
    }
    return (successCount, pendingOrFailedJobs.length);
  }

  Future<void> dismissFailedJob(String tokenId) async {
    final existing = _jobsByTokenId[tokenId];
    if (existing == null) return;
    _jobsByTokenId.remove(tokenId);
    await _savePrintQueue();
    notifyListeners();
  }

  Future<void> _autoRecoverIfPrinterOnline() async {
    if (_isPrinting || !ConfigService().thermalAutoPrintEnabled) return;
    final pending = pendingOrFailedJobs;
    if (pending.isEmpty) return;

    await refreshPrinters();
    if (_isPrinterReady && _activePrinterName != null) {
      logger.i(
        'Printer $_activePrinterName is online. Auto-recovering ${pending.length} queued visitor token(s)...',
      );
      await retryAllFailedJobs();
    }
  }
}

