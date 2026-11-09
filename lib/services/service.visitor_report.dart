import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:nira/helpers/models/model.visitor.dart';
import 'package:nira/services/service.config.dart';
import 'package:nira/services/service.diagnostics.dart';
import 'package:nira/services/service.logger.dart';
import 'package:nira/services/service.storage.dart';
import 'package:nira/services/service.visitor.dart';

class ReportDispatchEntry {
  final String dateKey;
  final bool sent;
  final DateTime? sentAt;
  final int visitorCount;
  final bool needsUpdate;
  final String? lastError;
  final List<String> recipients;

  const ReportDispatchEntry({
    required this.dateKey,
    required this.sent,
    this.sentAt,
    required this.visitorCount,
    this.needsUpdate = false,
    this.lastError,
    this.recipients = const [],
  });

  ReportDispatchEntry copyWith({
    bool? sent,
    DateTime? sentAt,
    int? visitorCount,
    bool? needsUpdate,
    String? lastError,
    List<String>? recipients,
  }) {
    return ReportDispatchEntry(
      dateKey: dateKey,
      sent: sent ?? this.sent,
      sentAt: sentAt ?? this.sentAt,
      visitorCount: visitorCount ?? this.visitorCount,
      needsUpdate: needsUpdate ?? this.needsUpdate,
      lastError: lastError,
      recipients: recipients ?? this.recipients,
    );
  }

  Map<String, dynamic> toJson() => {
    'dateKey': dateKey,
    'sent': sent,
    'sentAt': sentAt?.toIso8601String(),
    'visitorCount': visitorCount,
    'needsUpdate': needsUpdate,
    'lastError': lastError,
    'recipients': recipients,
  };

  factory ReportDispatchEntry.fromJson(Map<String, dynamic> json) {
    return ReportDispatchEntry(
      dateKey: json['dateKey']?.toString() ?? '',
      sent: json['sent'] == true,
      sentAt: DateTime.tryParse(json['sentAt']?.toString() ?? ''),
      visitorCount: (json['visitorCount'] as num?)?.toInt() ?? 0,
      needsUpdate: json['needsUpdate'] == true,
      lastError: json['lastError']?.toString(),
      recipients: (json['recipients'] is List)
          ? (json['recipients'] as List).map((e) => e.toString()).toList()
          : const [],
    );
  }
}

class VisitorReportService {
  static final VisitorReportService _instance =
      VisitorReportService._internal();
  factory VisitorReportService() => _instance;
  VisitorReportService._internal();

  final Map<String, ReportDispatchEntry> _ledger = {};
  Timer? _schedulerTimer;
  bool _isInitialized = false;
  bool _isSending = false;

  bool get isSending => _isSending;

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await _loadLedger();

    // Listen for newly issued visitor tokens so late check-ins after the daily report time
    // mark today's ledger entry for an updated dispatch.
    VisitorService().onVisitorRecorded = (record) {
      final dateKey = record.formattedDate;
      final existing = _ledger[dateKey];
      if (existing != null && existing.sent) {
        _ledger[dateKey] = existing.copyWith(
          visitorCount: existing.visitorCount + 1,
          needsUpdate: true,
        );
        unawaited(_saveLedger());
      }
    };

    // Start background scheduler (checks every 45 seconds)
    _schedulerTimer?.cancel();
    _schedulerTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      unawaited(_runScheduledCheck());
    });

    // Run an initial catch-up check 8 seconds after startup for any past unsent days
    Future.delayed(const Duration(seconds: 8), () {
      unawaited(_runScheduledCheck(includeCatchUp: true));
    });
  }

  Future<File> _getLedgerFile() async {
    final dir = await AppStorageService().getVisitorsDirectory();
    return File(p.join(dir.path, 'report_dispatch_log.json'));
  }

  Future<void> _loadLedger() async {
    try {
      final file = await _getLedgerFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content);
        if (data is Map) {
          _ledger.clear();
          data.forEach((key, value) {
            if (value is Map) {
              _ledger[key.toString()] = ReportDispatchEntry.fromJson(
                Map<String, dynamic>.from(value),
              );
            }
          });
        }
      }
    } catch (e) {
      logger.w("Failed to load visitor report ledger: $e");
    }
  }

  Future<void> _saveLedger() async {
    try {
      final file = await _getLedgerFile();
      final map = <String, dynamic>{};
      _ledger.forEach((k, v) => map[k] = v.toJson());
      await file.writeAsString(jsonEncode(map), flush: true);
    } catch (e) {
      logger.w("Failed to save visitor report ledger: $e");
    }
  }

  ReportDispatchEntry? getStatusForDate(String dateKey) => _ledger[dateKey];

  bool _isPastOrAtScheduledTime(DateTime now) {
    final raw = ConfigService().dailyReportTime;
    final parts = raw.split(':');
    int targetHour = 16;
    int targetMinute = 0;
    if (parts.length >= 2) {
      targetHour = int.tryParse(parts[0]) ?? 16;
      targetMinute = int.tryParse(parts[1]) ?? 0;
    }
    if (now.hour > targetHour) return true;
    if (now.hour == targetHour && now.minute >= targetMinute) return true;
    return false;
  }

  Future<void> _runScheduledCheck({bool includeCatchUp = false}) async {
    if (_isSending || !ConfigService().autoDailyReportEnabled) return;
    if (ConfigService().enabledRecipientEmails.isEmpty) return;
    if (ConfigService().smtpPassword.trim().isEmpty) return;

    final now = DateTime.now();
    final todayKey = VisitorService.formatDateKey(now);

    // 1. Check today's scheduled report
    if (_isPastOrAtScheduledTime(now)) {
      final todayRecords = await VisitorService().getVisitorsForDate(todayKey);
      if (todayRecords.isNotEmpty) {
        final status = _ledger[todayKey];
        if (status == null || !status.sent || status.needsUpdate) {
          await sendReportForDate(todayKey, isAutomated: true);
        }
      }
    }

    // 2. Startup / Periodic Catch-Up for any missed past dates
    if (includeCatchUp) {
      final dates = await VisitorService().getAvailableDates();
      for (final dateKey in dates) {
        if (dateKey == todayKey) continue;
        final status = _ledger[dateKey];
        if (status != null && status.sent && !status.needsUpdate) continue;

        final records = await VisitorService().getVisitorsForDate(dateKey);
        if (records.isNotEmpty) {
          await sendReportForDate(dateKey, isAutomated: true);
        }
      }
    }
  }

  /// Called by HomeTopHeader before shutting down or restarting the kiosk
  /// so today's visitor report is never missed if staff turn off the kiosk early.
  Future<void> flushBeforeShutdown() async {
    try {
      final todayKey = VisitorService.formatDateKey(DateTime.now());
      final records = await VisitorService().getVisitorsForDate(todayKey);
      if (records.isEmpty) return;

      // Always save local CSV & HTML exports before shutdown
      await saveLocalReportFiles(todayKey, records);

      final status = _ledger[todayKey];
      final alreadyUpToDate =
          status != null &&
          status.sent &&
          !status.needsUpdate &&
          status.visitorCount == records.length;

      if (!alreadyUpToDate &&
          ConfigService().enabledRecipientEmails.isNotEmpty &&
          ConfigService().smtpPassword.trim().isNotEmpty) {
        await sendReportForDate(
          todayKey,
          isAutomated: true,
        ).timeout(const Duration(seconds: 7), onTimeout: () => (false, 'Timeout'));
      }
    } catch (_) {}
  }

  Future<(File csvFile, File htmlFile)> saveLocalReportFiles(
    String dateKey,
    List<VisitorRecord> records,
  ) async {
    final csvFile = await VisitorService().exportCsvFileForDate(dateKey);
    final dir = await AppStorageService().getVisitorsDirectory();
    final exportDir = Directory(p.join(dir.path, 'exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    final htmlFile = File(
      p.join(exportDir.path, 'Nirmala_Bhavan_Visitors_$dateKey.html'),
    );
    final htmlContent = _buildHtmlReport(dateKey, records);
    await htmlFile.writeAsString(htmlContent, flush: true);
    return (csvFile, htmlFile);
  }

  Future<(bool success, String message)> sendReportForDate(
    String dateKey, {
    bool isAutomated = false,
  }) async {
    if (_isSending) {
      return (false, 'Another report dispatch is currently in progress.');
    }

    _isSending = true;
    try {
      final records = await VisitorService().getVisitorsForDate(dateKey);
      final (csvFile, _) = await saveLocalReportFiles(dateKey, records);

      final recipients = ConfigService().enabledRecipientEmails;
      if (recipients.isEmpty) {
        return (
          false,
          'No active email recipients configured. Local CSV saved.',
        );
      }

      final host = ConfigService().smtpHost.trim();
      final port = ConfigService().smtpPort;
      final sender = ConfigService().smtpSenderEmail.trim();
      final password = ConfigService().smtpPassword.trim();

      if (host.isEmpty || sender.isEmpty || password.isEmpty) {
        final msg =
            'SMTP App Password is not configured yet in Admin Settings. Local CSV exported.';
        _ledger[dateKey] = ReportDispatchEntry(
          dateKey: dateKey,
          sent: false,
          visitorCount: records.length,
          needsUpdate: true,
          lastError: 'SMTP credentials missing',
          recipients: recipients,
        );
        await _saveLedger();
        return (false, msg);
      }

      final subject =
          '[NIRA Kiosk] Nirmala Bhavan Visitor Report — $dateKey (${records.length} Visitors)';
      final htmlBody = _buildHtmlReport(dateKey, records);
      final csvBytes = await csvFile.readAsBytes();
      final csvFileName = 'Nirmala_Bhavan_Visitors_$dateKey.csv';

      await _sendSmtpEmail(
        host: host,
        port: port,
        senderEmail: sender,
        password: password,
        recipients: recipients,
        subject: subject,
        htmlBody: htmlBody,
        attachmentName: csvFileName,
        attachmentBytes: csvBytes,
      );

      final now = DateTime.now();
      _ledger[dateKey] = ReportDispatchEntry(
        dateKey: dateKey,
        sent: true,
        sentAt: now,
        visitorCount: records.length,
        needsUpdate: false,
        lastError: null,
        recipients: recipients,
      );
      await _saveLedger();

      DiagnosticLogger().log(
        type: LogType.success,
        event: isAutomated ? 'AUTO_REPORT_EMAILED' : 'MANUAL_REPORT_EMAILED',
        message:
            'Daily visitor report for $dateKey (${records.length} visitors) emailed to ${recipients.length} recipient(s).',
        details: {'date': dateKey, 'recipients': recipients},
      );

      return (
        true,
        'Report for $dateKey (${records.length} visitors) sent to ${recipients.join(", ")}',
      );
    } catch (e) {
      final errStr = e.toString();
      logger.e("Failed to send visitor email report for $dateKey: $errStr");
      DiagnosticLogger().log(
        type: LogType.error,
        event: 'VISITOR_REPORT_FAILED',
        message: 'Failed to email visitor report for $dateKey: $errStr',
      );
      final prev = _ledger[dateKey];
      _ledger[dateKey] = ReportDispatchEntry(
        dateKey: dateKey,
        sent: prev?.sent ?? false,
        sentAt: prev?.sentAt,
        visitorCount: prev?.visitorCount ?? 0,
        needsUpdate: true,
        lastError: errStr,
        recipients: ConfigService().enabledRecipientEmails,
      );
      await _saveLedger();
      return (false, 'Email failed: $errStr');
    } finally {
      _isSending = false;
    }
  }

  String _buildHtmlReport(String dateKey, List<VisitorRecord> records) {
    final parentCount = records.where((r) => r.categoryId == 'parent').length;
    final admissionCount = records
        .where((r) => r.categoryId == 'admission')
        .length;
    final otherCount = records.length - parentCount - admissionCount;

    String esc(String input) {
      return input
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;')
          .replaceAll('"', '&quot;');
    }

    final rowsHtml = StringBuffer();
    if (records.isEmpty) {
      rowsHtml.writeln('''
        <tr>
          <td colspan="7" style="padding:20px;text-align:center;color:#64748b;">
            No visitors recorded for $dateKey.
          </td>
        </tr>
      ''');
    } else {
      for (int i = 0; i < records.length; i++) {
        final r = records[i];
        final bg = i.isEven ? '#ffffff' : '#f8fafc';
        rowsHtml.writeln('''
          <tr style="background-color:$bg;">
            <td style="padding:10px 12px;border-bottom:1px solid #e2e8f0;font-weight:700;color:#0284c7;">
              ${esc(r.shortToken)}<br><span style="font-size:11px;color:#64748b;font-weight:500;">${esc(r.tokenId)}</span>
            </td>
            <td style="padding:10px 12px;border-bottom:1px solid #e2e8f0;color:#1e293b;white-space:nowrap;">
              ${esc(r.formattedTime)}
            </td>
            <td style="padding:10px 12px;border-bottom:1px solid #e2e8f0;font-weight:600;color:#0f2942;">
              ${esc(r.visitorName)}
            </td>
            <td style="padding:10px 12px;border-bottom:1px solid #e2e8f0;color:#334155;">
              ${esc(r.phoneNumber)}
            </td>
            <td style="padding:10px 12px;border-bottom:1px solid #e2e8f0;color:#334155;">
              ${esc(r.categoryLabel)}
            </td>
            <td style="padding:10px 12px;border-bottom:1px solid #e2e8f0;color:#334155;">
              <strong>${esc(r.purposeLabel)}</strong><br>
              <span style="font-size:12px;color:#64748b;">${esc(r.personToMeet)}</span>
            </td>
            <td style="padding:10px 12px;border-bottom:1px solid #e2e8f0;color:#334155;">
              ${esc(r.studentSummary)}
            </td>
          </tr>
        ''');
      }
    }

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Nirmala Bhavan Daily Visitor Report - $dateKey</title>
</head>
<body style="margin:0;padding:24px;font-family:'Segoe UI',Arial,sans-serif;background-color:#f1f5f9;color:#0f2942;">
  <div style="max-width:960px;margin:0 auto;background:#ffffff;border-radius:16px;overflow:hidden;border:1px solid #cbd5e1;">
    <div style="background:linear-gradient(135deg,#0f2942,#0284c7);padding:24px 28px;color:#ffffff;">
      <h1 style="margin:0;font-size:22px;font-weight:800;">Nirmala Bhavan Higher Secondary School</h1>
      <p style="margin:6px 0 0;font-size:14px;opacity:0.9;">NIRA AI Kiosk • Automated Daily Reception Visitor Report ($dateKey)</p>
    </div>
    <div style="padding:24px 28px;">
      <table width="100%" cellspacing="0" cellpadding="0" style="margin-bottom:24px;">
        <tr>
          <td width="25%" style="padding:14px;background:#f0f9ff;border-radius:12px;border:1px solid #bae6fd;text-align:center;">
            <div style="font-size:12px;color:#0369a1;font-weight:700;text-transform:uppercase;">Total Visitors</div>
            <div style="font-size:28px;font-weight:900;color:#0f2942;margin-top:4px;">${records.length}</div>
          </td>
          <td width="2%"></td>
          <td width="23%" style="padding:14px;background:#f0fdf4;border-radius:12px;border:1px solid #bbf7d0;text-align:center;">
            <div style="font-size:12px;color:#15803d;font-weight:700;text-transform:uppercase;">Parents</div>
            <div style="font-size:28px;font-weight:900;color:#0f2942;margin-top:4px;">$parentCount</div>
          </td>
          <td width="2%"></td>
          <td width="23%" style="padding:14px;background:#f0fdfa;border-radius:12px;border:1px solid #99f6e4;text-align:center;">
            <div style="font-size:12px;color:#0f766e;font-weight:700;text-transform:uppercase;">Admissions</div>
            <div style="font-size:28px;font-weight:900;color:#0f2942;margin-top:4px;">$admissionCount</div>
          </td>
          <td width="2%"></td>
          <td width="23%" style="padding:14px;background:#fffbeb;border-radius:12px;border:1px solid #fde68a;text-align:center;">
            <div style="font-size:12px;color:#b45309;font-weight:700;text-transform:uppercase;">Other Guests</div>
            <div style="font-size:28px;font-weight:900;color:#0f2942;margin-top:4px;">$otherCount</div>
          </td>
        </tr>
      </table>

      <table width="100%" cellspacing="0" cellpadding="0" style="border-collapse:collapse;font-size:13.5px;border:1px solid #e2e8f0;">
        <thead>
          <tr style="background-color:#f8fafc;text-align:left;color:#475569;font-size:12px;text-transform:uppercase;">
            <th style="padding:12px;border-bottom:2px solid #cbd5e1;">Token</th>
            <th style="padding:12px;border-bottom:2px solid #cbd5e1;">Time</th>
            <th style="padding:12px;border-bottom:2px solid #cbd5e1;">Visitor Name</th>
            <th style="padding:12px;border-bottom:2px solid #cbd5e1;">Mobile</th>
            <th style="padding:12px;border-bottom:2px solid #cbd5e1;">Category</th>
            <th style="padding:12px;border-bottom:2px solid #cbd5e1;">Purpose & Office</th>
            <th style="padding:12px;border-bottom:2px solid #cbd5e1;">Student Details</th>
          </tr>
        </thead>
        <tbody>
          ${rowsHtml.toString()}
        </tbody>
      </table>

      <p style="margin-top:20px;font-size:12px;color:#64748b;">
        Attached: <strong>Nirmala_Bhavan_Visitors_$dateKey.csv</strong> (Spreadsheet-ready CSV export).<br>
        Generated automatically by NIRA AI Reception Kiosk • Nirmala Bhavan Higher Secondary School, Kowdiar, Trivandrum.
      </p>
    </div>
  </div>
</body>
</html>
''';
  }

  /// Pure-Dart RFC-5321 SMTP Client supporting Implicit TLS (Port 465)
  /// and STARTTLS (Port 587) with AUTH LOGIN and MIME Multipart attachments.
  Future<void> _sendSmtpEmail({
    required String host,
    required int port,
    required String senderEmail,
    required String password,
    required List<String> recipients,
    required String subject,
    required String htmlBody,
    required String attachmentName,
    required List<int> attachmentBytes,
  }) async {
    final cleanPassword = password.replaceAll(' ', '').trim();
    final useImplicitTls =
        port == 465 || host.trim().toLowerCase() == 'smtp.gmail.com';
    final effectivePort =
        (host.trim().toLowerCase() == 'smtp.gmail.com' && port == 587)
        ? 465
        : port;

    logger.i(
      'Connecting to SMTP server $host:$effectivePort (Implicit TLS: $useImplicitTls) as $senderEmail...',
    );

    Socket socket;
    if (useImplicitTls) {
      socket = await SecureSocket.connect(
        host,
        effectivePort,
        timeout: const Duration(seconds: 12),
      );
    } else {
      socket = await Socket.connect(
        host,
        effectivePort,
        timeout: const Duration(seconds: 12),
      );
    }

    final List<String> lineBuffer = [];
    Completer<void>? lineWaiter;
    Object? socketError;
    bool socketClosed = false;
    StreamSubscription<List<int>>? sub;
    String partialLine = '';

    void attachSocketListener(Socket s) {
      sub?.cancel();
      final stream = s.asBroadcastStream();
      sub = stream.listen(
        (List<int> chunk) {
          partialLine += utf8.decode(chunk, allowMalformed: true);
          while (true) {
            final nlIdx = partialLine.indexOf('\n');
            if (nlIdx == -1) break;
            final line = partialLine.substring(0, nlIdx).replaceAll('\r', '');
            partialLine = partialLine.substring(nlIdx + 1);
            lineBuffer.add(line);
          }
          if (lineBuffer.isNotEmpty &&
              lineWaiter != null &&
              !lineWaiter!.isCompleted) {
            lineWaiter!.complete();
          }
        },
        onError: (Object e) {
          socketError = e;
          if (lineWaiter != null && !lineWaiter!.isCompleted) {
            lineWaiter!.completeError(e);
          }
        },
        onDone: () {
          socketClosed = true;
          if (lineWaiter != null && !lineWaiter!.isCompleted) {
            lineWaiter!.complete();
          }
        },
      );
    }

    attachSocketListener(socket);

    Future<String> nextLine() async {
      while (lineBuffer.isEmpty) {
        if (socketError != null) throw socketError!;
        if (socketClosed) {
          throw Exception('Connection closed by SMTP server $host:$effectivePort');
        }
        lineWaiter = Completer<void>();
        await lineWaiter!.future.timeout(
          const Duration(seconds: 12),
          onTimeout: () => throw Exception(
            'Timed out waiting for response from $host:$effectivePort',
          ),
        );
      }
      return lineBuffer.removeAt(0);
    }

    Future<String> readSmtpResponse() async {
      final buffer = StringBuffer();
      while (true) {
        final line = await nextLine();
        buffer.writeln(line);
        // SMTP multiline response ends when 4th char is space (e.g. "250 OK")
        if (line.length >= 3 &&
            int.tryParse(line.substring(0, 3)) != null &&
            (line.length == 3 || line[3] == ' ')) {
          final code = int.parse(line.substring(0, 3));
          if (code == 535 || code == 534) {
            throw Exception(
              'Gmail/SMTP Authentication Rejected ($code): Verify Sender Email ($senderEmail) and 16-char Google App Password.',
            );
          }
          if (code >= 400) {
            throw Exception('SMTP Error $code: $line');
          }
          return buffer.toString();
        }
      }
    }

    Future<String> sendCmd(String cmd, {bool maskLog = false}) async {
      if (!maskLog) {
        logger.d('SMTP >> $cmd');
      }
      socket.add(utf8.encode('$cmd\r\n'));
      await socket.flush();
      return await readSmtpResponse();
    }

    try {
      // 1. Read greeting
      await readSmtpResponse();

      // 2. EHLO
      await sendCmd('EHLO nira-kiosk.local');

      // 3. Upgrade via STARTTLS if not already using Implicit TLS
      if (!useImplicitTls) {
        await sendCmd('STARTTLS');
        await sub?.cancel();
        socket = await SecureSocket.secure(socket, host: host);
        attachSocketListener(socket);
        await sendCmd('EHLO nira-kiosk.local');
      }

      // 4. AUTH LOGIN
      await sendCmd('AUTH LOGIN');
      await sendCmd(
        base64Encode(utf8.encode(senderEmail)),
        maskLog: true,
      );
      await sendCmd(
        base64Encode(utf8.encode(cleanPassword)),
        maskLog: true,
      );

      // 5. Envelope
      await sendCmd('MAIL FROM:<$senderEmail>');
      for (final rcpt in recipients) {
        await sendCmd('RCPT TO:<${rcpt.trim()}>');
      }

      // 6. DATA
      await sendCmd('DATA');

      final boundary =
          '----=_NiraKioskBoundary_${DateTime.now().millisecondsSinceEpoch}';
      final encodedSubject =
          '=?utf-8?B?${base64Encode(utf8.encode(subject))}?=';
      final encodedHtml = _chunkBase64(base64Encode(utf8.encode(htmlBody)));
      final encodedCsv = _chunkBase64(base64Encode(attachmentBytes));

      final mime = StringBuffer()
        ..write('From: "NIRA AI Reception Kiosk" <$senderEmail>\r\n')
        ..write('To: ${recipients.join(", ")}\r\n')
        ..write('Subject: $encodedSubject\r\n')
        ..write('MIME-Version: 1.0\r\n')
        ..write('Content-Type: multipart/mixed; boundary="$boundary"\r\n\r\n')
        ..write('--$boundary\r\n')
        ..write('Content-Type: text/html; charset="utf-8"\r\n')
        ..write('Content-Transfer-Encoding: base64\r\n\r\n')
        ..write('$encodedHtml\r\n')
        ..write('--$boundary\r\n')
        ..write('Content-Type: text/csv; name="$attachmentName"\r\n')
        ..write(
          'Content-Disposition: attachment; filename="$attachmentName"\r\n',
        )
        ..write('Content-Transfer-Encoding: base64\r\n\r\n')
        ..write('$encodedCsv\r\n')
        ..write('--$boundary--\r\n.\r\n');

      socket.add(utf8.encode(mime.toString()));
      await socket.flush();
      await readSmtpResponse();

      logger.i(
        'SMTP report email delivered successfully to ${recipients.join(", ")}',
      );

      try {
        socket.add(utf8.encode('QUIT\r\n'));
      } catch (_) {}
    } finally {
      try {
        sub?.cancel();
      } catch (_) {}
      try {
        socket.destroy();
      } catch (_) {}
    }
  }

  String _chunkBase64(String b64) {
    final sb = StringBuffer();
    for (int i = 0; i < b64.length; i += 76) {
      final end = (i + 76 < b64.length) ? i + 76 : b64.length;
      sb.write(b64.substring(i, end));
      sb.write('\r\n');
    }
    return sb.toString();
  }
}

