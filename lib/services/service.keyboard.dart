import 'dart:io';

class KeyboardService {
  static DateTime? _lastLaunchTime;
  static void openOnScreenKeyboard() {
    if (!Platform.isWindows) return;

    final now = DateTime.now();
    if (_lastLaunchTime != null &&
        now.difference(_lastLaunchTime!) < const Duration(milliseconds: 1500)) {
      return;
    }
    _lastLaunchTime = now;
    _launchKeyboardProcess();
  }

  static Future<void> _launchKeyboardProcess() async {
    try {
      final result = await Process.run('cmd', ['/c', 'start', 'osk.exe']);
      if (result.exitCode != 0) {
        await Process.run('cmd', ['/c', 'start', 'tabtip.exe']);
      }
    } catch (_) {
      try {
        await Process.run('cmd', ['/c', 'start', 'tabtip.exe']);
      } catch (_) {}
    }
  }
}
