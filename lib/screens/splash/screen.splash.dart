import 'package:flutter/material.dart';
import 'package:nira/screens/home/screen.home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final String text = "NIRA AI";
  final List<bool> _visibleLetters = List.generate(7, (index) => false);
  bool _readyToTransition = false;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 600));

    for (int i = 0; i < text.length; i++) {
      if (!mounted) return;
      setState(() {
        _visibleLetters[i] = true;
      });
      await Future.delayed(const Duration(milliseconds: 180));
    }

    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;
    setState(() {
      _readyToTransition = true;
    });

    await Future.delayed(const Duration(milliseconds: 400));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 1000),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedOpacity(
          opacity: _readyToTransition ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 400),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(text.length, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: AnimatedOpacity(
                  opacity: _visibleLetters[index] ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    text[index],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 14.0,
                      fontFamily: 'Segoe UI',
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
