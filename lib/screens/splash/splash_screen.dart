import 'package:flutter/material.dart';
import 'package:sifter/screens/splash/legal_notice_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LegalNoticesScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2196F3), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo.png',
                height: 50,
                width: 50,
              ).animate().fadeIn(duration: 1000.ms),
              SizedBox(height: 20),
              Image.asset('assets/map_pin_animation.json')
                  .animate()
                  .scale(duration: 500.ms, curve: Curves.bounceOut),
              SizedBox(height: 10),
              Text(
                'Connect Spontaneously, Safely',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ).animate().slideY(duration: 500.ms, begin: 1, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}
