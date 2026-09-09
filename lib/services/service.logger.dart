import 'dart:io';
import 'package:logger/logger.dart';

class DirectStdoutOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (var line in event.lines) {
      stdout.writeln(line);
    }
  }
}

final logger = Logger(
  output: DirectStdoutOutput(),
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 80,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);