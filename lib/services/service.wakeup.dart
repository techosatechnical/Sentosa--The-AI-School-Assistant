import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:sentosa/services/services.dart';

class WakeWordService {
  Process? _process;
  StreamSubscription? _stdoutSub;
  StreamSubscription? _stderrSub;
  bool _isRunning = false;

  Function(String phrase, double confidence)? onWakeWordDetected;
  Function(String phrase)? onInterruptDetected;
  Function(String status)? onStatusUpdate;

  bool get isRunning => _isRunning;

  Future<void> start() async {
    if (_isRunning) return;

    try {
      await Process.run('taskkill', ['/F', '/IM', 'sentosa_wake.exe']);
    } catch (_) {}

    final currentDir = Directory.current.path;
    final exeFile = File('$currentDir/windows/wake_word/sentosa_wake.exe');
    final psScript = File('$currentDir/windows/wake_word/wake_fallback.ps1');

    try {
      if (await exeFile.exists()) {
        logger.i("Starting Windows native wake-word engine: ${exeFile.path} (Parent PID: $pid)");
        _process = await Process.start(
          exeFile.path,
          [pid.toString()],
          mode: ProcessStartMode.normal,
        );
      } else if (await psScript.exists()) {
        logger.i(
          "Starting PowerShell fallback wake-word engine: ${psScript.path} (Parent PID: $pid)",
        );
        _process = await Process.start('powershell.exe', [
          '-NoProfile',
          '-ExecutionPolicy',
          'Bypass',
          '-File',
          psScript.path,
          '-ParentPid',
          pid.toString(),
        ], mode: ProcessStartMode.normal);
      } else {
        logger.w(
          "Wake word engine files not found at $currentDir/windows/wake_word/",
        );
        return;
      }

      _isRunning = true;
      onStatusUpdate?.call("Wake-word engine active ('Sentosa')");

      _stdoutSub = _process!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
              _handleOutputLine(line.trim());
            },
            onError: (err) {
              logger.e("WakeWordService stdout error: $err");
            },
            onDone: () {
              logger.w("WakeWordService process stdout closed.");
              _isRunning = false;
            },
          );

      _stderrSub = _process!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((errLine) {
            if (errLine.trim().isNotEmpty) {
              logger.w("WakeWordService stderr: $errLine");
            }
          });
    } catch (e, stack) {
      logger.e(
        "Failed to launch wake-word engine: $e",
        error: e,
        stackTrace: stack,
      );
      _isRunning = false;
    }
  }

  void _handleOutputLine(String line) {
    if (line.isEmpty) return;
    logger.d("WakeEngine output: $line");

    if (line.startsWith("READY")) {
      logger.i(
        "Windows Speech Recognizer is READY and listening for 'Sentosa'! ($line)",
      );
      onStatusUpdate?.call("Listening for 'Sentosa'...");
      return;
    }

    if (line.startsWith("LOW_CONFIDENCE:") || line.startsWith("REJECTED:")) {
      logger.d("WakeEngine diagnostic: $line");
      return;
    }

    if (line.startsWith("RECOGNIZED:")) {
      final parts = line.split(':');
      if (parts.length >= 3) {
        final phrase = parts[1].trim();
        final confidence = double.tryParse(parts[2].trim()) ?? 0.5;
        logger.i("WakeEngine recognized: '$phrase' (confidence: $confidence)");
        final lower = phrase.toLowerCase();

        // Dedicated Stop / Cancel compound commands
        if (lower.contains("stop") || lower.contains("cancel")) {
          onInterruptDetected?.call(phrase);
          return;
        }


        // Wake-word & phonetic greeting variants
        if (lower.contains("sentosa") ||
            lower.contains("centosa") ||
            lower.contains("santosa") ||
            lower.contains("tosa") ||
            lower.contains("start")) {
          onWakeWordDetected?.call("Sentosa", confidence);
        }
      }
    }
  }

  Future<void> stop() async {
    _isRunning = false;
    await _stdoutSub?.cancel();
    await _stderrSub?.cancel();
    _stdoutSub = null;
    _stderrSub = null;

    if (_process != null) {
      try {
        _process!.stdin.writeln("QUIT");
        await _process!.stdin.flush();
      } catch (_) {}

      try {
        _process!.kill();
      } catch (_) {}
      _process = null;
    }
    logger.i("WakeWordService stopped.");
  }

  void dispose() {
    stop();
  }
}
