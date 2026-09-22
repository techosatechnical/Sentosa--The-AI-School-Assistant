import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class ConfigService {
  static const String _defaultPin = '313431';
  static const String _fileName = 'config.json';

  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  Future<File> get _configFile async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, _fileName);
    return File(path);
  }

  Future<String> getPin() async {
    try {
      final file = await _configFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final data = jsonDecode(contents);
        return data['pin']?.toString() ?? _defaultPin;
      }
    } catch (e) {
      // Ignore read errors, fall back to default
    }
    return _defaultPin;
  }

  Future<void> setPin(String newPin) async {
    try {
      final file = await _configFile;
      final Map<String, dynamic> data = {'pin': newPin};
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      // Ignore write errors
    }
  }
}
