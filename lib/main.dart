import 'package:flutter/material.dart';
import 'package:sentosa/screens/splash/screen.splash.dart';
import 'package:sentosa/services/service.config.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ConfigService().init();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setFullScreen(true);
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const SentosaApp());
}

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class SentosaApp extends StatelessWidget {
  const SentosaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sentosa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFDBEAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0284C7),
          brightness: Brightness.light,
        ),
        fontFamily: 'Segoe UI',
        fontFamilyFallback: const [
          'Nirmala UI',
          'Noto Sans Malayalam',
          'Arial',
        ],
      ),
      navigatorObservers: [routeObserver],
      home: const SplashScreen(),
    );
  }
}
