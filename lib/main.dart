import 'package:flutter/material.dart';
import 'package:sentosa/screens/screen.home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SentosaApp());
}

class SentosaApp extends StatelessWidget {
  const SentosaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sentosa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B1120),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF38BDF8),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Segoe UI',
        fontFamilyFallback: const [
          'Nirmala UI',
          'Noto Sans Malayalam',
          'Arial',
        ],
      ),
      home: const HomeScreen(),
    );
  }
}

