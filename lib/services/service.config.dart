import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sentosa/helpers/data/data.sentosa.dart';
import 'service.storage.dart';

class ConfigService {
  static const String _defaultPin = '313431';
  static const String _defaultAiPin = '000000';
  static const String _defaultVoice = 'Aoede';
  static const String _defaultModel = 'models/gemini-3.1-flash-live-preview';
  static const String _fileName = 'config.json';

  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  String _pin = _defaultPin;
  String _aiPin = _defaultAiPin;
  String _voice = _defaultVoice;
  String _model = _defaultModel;
  String _systemInstruction = SentosaData.systemInstruction;

  String get pin => _pin;
  String get aiPin => _aiPin;
  String get voice => _voice;
  String get model => _model;
  String get systemInstruction => _systemInstruction;

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
        _systemInstruction = data['systemInstruction']?.toString() ?? SentosaData.systemInstruction;
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

  Future<void> setAiConfig({String? voice, String? model, String? systemInstruction}) async {
    if (voice != null) _voice = voice;
    if (model != null) _model = model;
    if (systemInstruction != null) _systemInstruction = systemInstruction;
    await _save();
  }
}
