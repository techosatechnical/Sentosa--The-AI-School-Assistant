import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AppStorageService {
  static final AppStorageService _instance = AppStorageService._internal();
  factory AppStorageService() => _instance;
  AppStorageService._internal();

  Directory? _appDir;

  Future<Directory> getAppDirectory() async {
    if (_appDir != null) return _appDir!;
    final baseDir = await getApplicationSupportDirectory();
    _appDir = baseDir;
    if (!await _appDir!.exists()) {
      await _appDir!.create(recursive: true);
    }
    return _appDir!;
  }

  Future<Directory> getDocumentsDirectory() async {
    final appDir = await getAppDirectory();
    final docsDir = Directory(p.join(appDir.path, 'documents'));
    if (!await docsDir.exists()) {
      await docsDir.create(recursive: true);
    }
    return docsDir;
  }

  Future<Directory> getMapsDirectory() async {
    final appDir = await getAppDirectory();
    final mapsDir = Directory(p.join(appDir.path, 'maps'));
    if (!await mapsDir.exists()) {
      await mapsDir.create(recursive: true);
    }
    return mapsDir;
  }

  Future<void> saveMapData(String id, String jsonString) async {
    final mapsDir = await getMapsDirectory();
    final file = File(p.join(mapsDir.path, '$id.json'));
    await file.writeAsString(jsonString);
  }

  Future<String?> loadMapData(String id) async {
    final mapsDir = await getMapsDirectory();
    final file = File(p.join(mapsDir.path, '$id.json'));
    if (await file.exists()) {
      return await file.readAsString();
    }
    return null;
  }
}
