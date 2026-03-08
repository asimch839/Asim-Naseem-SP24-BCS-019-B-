import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _zoomAnimation;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));

    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _zoomAnimation =
        Tween<double>(begin: 0.5, end: 1.0).animate(_controller);

    _controller.forward();

    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacementNamed(context, '/');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4e73df), Color(0xFF1cc88a)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                /// Logo Zoom Animation
                ScaleTransition(
                  scale: _zoomAnimation,
                  child: Image.asset(
                    "assets/logo.jpg",
                    height: 120,
                  ),
                ),

                const SizedBox(height: 20),

                /// Animated Typing Text
                AnimatedTextKit(
                  animatedTexts: [
                    TyperAnimatedText(
                      'Subject Based Quiz App',
                      textStyle: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      speed: const Duration(milliseconds: 100),
                    ),
                  ],
                  totalRepeatCount: 1,
                ),

                const SizedBox(height: 30),

                /// Lottie Animation
                SizedBox(
                  height: 120,
                  child: Lottie.asset(
                    "assets/animations/Exams.json",
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}