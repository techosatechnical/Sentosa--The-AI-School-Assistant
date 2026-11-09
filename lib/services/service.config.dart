import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:nira/helpers/data/data.sentosa.dart';
import 'package:nira/helpers/models/model.visitor.dart';
import 'service.storage.dart';

class ConfigService {
  static const String _defaultPin = '313431';
  static const String _defaultAiPin = '000000';
  static const String _defaultVoice = 'Aoede';
  static const String _defaultModel = 'models/gemini-3.1-flash-live-preview';
  static const String _defaultSmtpHost = 'smtp.gmail.com';
  static const int _defaultSmtpPort = 587;
  static const String _defaultSmtpSender = 'sentosa.aitechosa@gmail.com';
  static const String _defaultSmtpPassword = String.fromEnvironment(
    'SMTP_PASSWORD',
    defaultValue: 'rtqi chqh heav ecvc',
  );
  static const String _defaultReportTime = '16:00';
  static const String _fileName = 'config.json';

  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  String _pin = _defaultPin;
  String _aiPin = _defaultAiPin;
  String _voice = _defaultVoice;
  String _model = _defaultModel;
  String _systemInstruction = SentosaData.systemInstruction;

  List<EmailRecipient> _visitorRecipients = const [
    EmailRecipient(
      email: 'nirmalabhavanschool@gmail.com',
      label: 'School General Office',
      enabled: true,
    ),
    EmailRecipient(
      email: 'nirmalabhavanadmission@gmail.com',
      label: 'Admissions Office',
      enabled: true,
    ),
  ];

  String _smtpHost = _defaultSmtpHost;
  int _smtpPort = _defaultSmtpPort;
  String _smtpSenderEmail = _defaultSmtpSender;
  String _smtpPassword = _defaultSmtpPassword;
  String _dailyReportTime = _defaultReportTime;
  bool _autoDailyReportEnabled = true;
  bool _visitorAudioPromptsEnabled = true;

  String get pin => _pin;
  String get aiPin => _aiPin;
  String get voice => _voice;
  String get model => _model;
  String get systemInstruction => _systemInstruction;

  List<EmailRecipient> get visitorRecipients =>
      List.unmodifiable(_visitorRecipients);
  List<String> get enabledRecipientEmails => _visitorRecipients
      .where((r) => r.enabled && r.email.trim().isNotEmpty)
      .map((r) => r.email.trim())
      .toList();

  String get smtpHost => _smtpHost;
  int get smtpPort => _smtpPort;
  String get smtpSenderEmail => _smtpSenderEmail;
  String get smtpPassword => _smtpPassword;
  String get dailyReportTime => _dailyReportTime;
  bool get autoDailyReportEnabled => _autoDailyReportEnabled;
  bool get visitorAudioPromptsEnabled => _visitorAudioPromptsEnabled;

  Future<File> get _configFile async {
    final docsDir = await AppStorageService().getDocumentsDirectory();
    return File(p.join(docsDir.path, _fileName));
  }

  Future<void> init() async {
    try {
      final file = await _configFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final data = jsonDecode(contents);
        _pin = data['pin']?.toString() ?? _defaultPin;
        _aiPin = data['aiPin']?.toString() ?? _defaultAiPin;
        _voice = data['voice']?.toString() ?? _defaultVoice;
        _model = data['model']?.toString() ?? _defaultModel;
        _systemInstruction =
            data['systemInstruction']?.toString() ??
            SentosaData.systemInstruction;

        if (data['visitorRecipients'] is List) {
          final rawList = data['visitorRecipients'] as List;
          _visitorRecipients = rawList
              .map((item) {
                if (item is Map<String, dynamic>) {
                  return EmailRecipient.fromJson(item);
                } else if (item is Map) {
                  return EmailRecipient.fromJson(
                    Map<String, dynamic>.from(item),
                  );
                } else if (item is String) {
                  return EmailRecipient(email: item);
                }
                return null;
              })
              .whereType<EmailRecipient>()
              .where((r) => r.email.isNotEmpty)
              .toList();
        }

        _smtpHost = data['smtpHost']?.toString() ?? _defaultSmtpHost;
        _smtpPort =
            int.tryParse(data['smtpPort']?.toString() ?? '') ??
            _defaultSmtpPort;
        final savedSender = data['smtpSenderEmail']?.toString().trim() ?? '';
        if (savedSender.isNotEmpty &&
            savedSender != 'nirmalabhavanschool@gmail.com') {
          _smtpSenderEmail = savedSender;
        } else {
          _smtpSenderEmail = _defaultSmtpSender;
        }
        final savedPwd = data['smtpPassword']?.toString().trim() ?? '';
        if (savedPwd.isNotEmpty) {
          _smtpPassword = savedPwd;
        } else {
          _smtpPassword = _defaultSmtpPassword;
        }
        _dailyReportTime =
            data['dailyReportTime']?.toString() ?? _defaultReportTime;
        _autoDailyReportEnabled = data['autoDailyReportEnabled'] != false;
        _visitorAudioPromptsEnabled =
            data['visitorAudioPromptsEnabled'] != false;
      }
    } catch (e) {
      // Ignore read errors, fall back to default
    }
  }

  Future<void> _save() async {
    try {
      final file = await _configFile;
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }
      final data = {
        'pin': _pin,
        'aiPin': _aiPin,
        'voice': _voice,
        'model': _model,
        'systemInstruction': _systemInstruction,
        'visitorRecipients': _visitorRecipients.map((r) => r.toJson()).toList(),
        'smtpHost': _smtpHost,
        'smtpPort': _smtpPort,
        'smtpSenderEmail': _smtpSenderEmail,
        'smtpPassword': _smtpPassword,
        'dailyReportTime': _dailyReportTime,
        'autoDailyReportEnabled': _autoDailyReportEnabled,
        'visitorAudioPromptsEnabled': _visitorAudioPromptsEnabled,
      };
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      rethrow;
    }
  }

  // Deprecated async getter to maintain backwards compatibility, though sync `pin` is available.
  Future<String> getPin() async => _pin;

  Future<void> setPin(String newPin) async {
    _pin = newPin;
    await _save();
  }

  Future<void> setAiPin(String newPin) async {
    _aiPin = newPin;
    await _save();
  }

  Future<void> setAiConfig({
    String? voice,
    String? model,
    String? systemInstruction,
  }) async {
    if (voice != null) _voice = voice;
    if (model != null) _model = model;
    if (systemInstruction != null) _systemInstruction = systemInstruction;
    await _save();
  }

  Future<void> addVisitorRecipient(EmailRecipient recipient) async {
    final normalized = recipient.email.trim().toLowerCase();
    final updated = List<EmailRecipient>.from(_visitorRecipients);
    final existingIdx = updated.indexWhere(
      (r) => r.email.trim().toLowerCase() == normalized,
    );
    if (existingIdx >= 0) {
      updated[existingIdx] = recipient.copyWith(email: recipient.email.trim());
    } else {
      updated.add(recipient.copyWith(email: recipient.email.trim()));
    }
    _visitorRecipients = updated;
    await _save();
  }

  Future<void> updateVisitorRecipient(
    int index,
    EmailRecipient updatedRecipient,
  ) async {
    if (index < 0 || index >= _visitorRecipients.length) return;
    final updated = List<EmailRecipient>.from(_visitorRecipients);
    updated[index] = updatedRecipient.copyWith(
      email: updatedRecipient.email.trim(),
    );
    _visitorRecipients = updated;
    await _save();
  }

  Future<void> removeVisitorRecipient(int index) async {
    if (index < 0 || index >= _visitorRecipients.length) return;
    final updated = List<EmailRecipient>.from(_visitorRecipients);
    updated.removeAt(index);
    _visitorRecipients = updated;
    await _save();
  }

  Future<void> setVisitorReportSettings({
    String? smtpHost,
    int? smtpPort,
    String? smtpSenderEmail,
    String? smtpPassword,
    String? dailyReportTime,
    bool? autoDailyReportEnabled,
    bool? visitorAudioPromptsEnabled,
  }) async {
    if (smtpHost != null) _smtpHost = smtpHost.trim();
    if (smtpPort != null) _smtpPort = smtpPort;
    if (smtpSenderEmail != null) _smtpSenderEmail = smtpSenderEmail.trim();
    if (smtpPassword != null) _smtpPassword = smtpPassword;
    if (dailyReportTime != null) _dailyReportTime = dailyReportTime.trim();
    if (autoDailyReportEnabled != null) {
      _autoDailyReportEnabled = autoDailyReportEnabled;
    }
    if (visitorAudioPromptsEnabled != null) {
      _visitorAudioPromptsEnabled = visitorAudioPromptsEnabled;
    }
    await _save();
  }
}
