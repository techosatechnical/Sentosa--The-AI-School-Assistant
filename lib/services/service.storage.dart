import 'dart:io';
import 'package:flutter/foundation.dart';
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

  Future<Directory> getPicturesDirectory() async {
    final appDir = await getAppDirectory();
    final picsDir = Directory(p.join(appDir.path, 'pictures'));
    if (!await picsDir.exists()) {
      await picsDir.create(recursive: true);
    }
    return picsDir;
  }

  Future<String> saveStudentPhoto(String sourcePath) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) return sourcePath;

    final picsDir = await getPicturesDirectory();
    final ext = p.extension(sourcePath).isNotEmpty
        ? p.extension(sourcePath)
        : '.jpg';
    final filename = 'student_${DateTime.now().millisecondsSinceEpoch}$ext';
    final targetPath = p.join(picsDir.path, filename);

    final savedFile = await sourceFile.copy(targetPath);
    try {
      await sourceFile.delete();
    } catch (e) {
      debugPrint('Could not delete original picture from public folder: $e');
    }

    return savedFile.path;
  }
}
