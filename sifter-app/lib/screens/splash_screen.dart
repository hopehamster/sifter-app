import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

import '../services/auth_service.dart';
import 'auth_gate.dart';

/// Professional animated splash screen for Sifter Chat
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _particleController;
  late AnimationController _textController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSplashSequence();
  }

  void _initializeAnimations() {
    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Particle animation controller
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Text animation controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Logo animations
    _logoScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    // Text animations
    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    ));

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));
  }

  Future<void> _startSplashSequence() async {
    // Start particle animation immediately
    _particleController.repeat();

    // Start logo animation
    await _logoController.forward();

    // Small delay, then start text animation
    await Future.delayed(const Duration(milliseconds: 200));
    await _textController.forward();

    // Hold the splash for a moment
    await Future.delayed(const Duration(milliseconds: 1000));

    // Check authentication and navigate
    await _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      final authService = ref.read(authServiceProvider);
      final isAuthenticated = authService.isAuthenticated;

      if (mounted) {
        // Smooth page transition
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              return isAuthenticated ? const AuthGate() : const AuthGate();
            },
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    } catch (e) {
      // On error, go to auth gate
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthGate()),
        );
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _particleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            // Animated gradient background
            _buildAnimatedBackground(),

            // Floating particles
            _buildParticleField(),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated logo
                  _buildAnimatedLogo(),

                  const SizedBox(height: 32),

                  // Animated text
                  _buildAnimatedText(),

                  const SizedBox(height: 48),

                  // Loading indicator
                  _buildLoadingIndicator(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
                Theme.of(context).colorScheme.secondary.withOpacity(0.6),
              ],
              stops: [
                0.0,
                0.5 + 0.2 * math.sin(_particleController.value * 2 * math.pi),
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticleField() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(_particleController.value),
          size: MediaQuery.of(context).size,
        );
      },
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Opacity(
          opacity: _logoOpacity.value,
          child: Transform.scale(
            scale: _logoScale.value,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: _buildLogoContent(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoContent() {
    // Priority: Lottie animation > Sifter PNG logos > Fallback text
    return FutureBuilder<bool>(
      future: _checkLottieAsset(),
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Lottie.asset(
              'assets/animations/sifter_logo.json',
              fit: BoxFit.contain,
              repeat: true,
              animate: true,
              errorBuilder: (context, error, stackTrace) {
                return _buildSifterLogo();
              },
            ),
          );
        } else {
          return _buildSifterLogo();
        }
      },
    );
  }

  Widget _buildSifterLogo() {
    // Use the actual Sifter logo images
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Image.asset(
        'assets/images/high_res_logos/sifterlogo2.png',
        fit: BoxFit.contain,
        width: 120,
        height: 120,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to alternative logo
          return Image.asset(
            'assets/images/high_res_logos/BF8B9118-6C6F-4E73-9954-2E8034741B0F.png',
            fit: BoxFit.contain,
            width: 120,
            height: 120,
            errorBuilder: (context, error, stackTrace) {
              // Final fallback to third logo
              return Image.asset(
                'assets/images/high_res_logos/6949E31A-6DE8-426D-8A41-B20D89CC8C99.png',
                fit: BoxFit.contain,
                width: 120,
                height: 120,
                errorBuilder: (context, error, stackTrace) {
                  // Ultimate fallback to gradient text
                  return _buildFallbackLogo();
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFallbackLogo() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Text(
          'S',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: const Offset(2, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _checkLottieAsset() async {
    try {
      await rootBundle.load('assets/animations/sifter_logo.json');
      return true;
    } catch (e) {
      return false;
    }
  }

  Widget _buildAnimatedText() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return SlideTransition(
          position: _textSlide,
          child: FadeTransition(
            opacity: _textOpacity,
            child: Column(
              children: [
                Text(
                  'Sifter',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Connect • Discover • Chat',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 1,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return Opacity(
          opacity: 0.7,
          child: CircularProgressIndicator(
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 2,
          ),
        );
      },
    );
  }
}

/// Custom painter for floating particles
class ParticlePainter extends CustomPainter {
  final double animationValue;
  final List<Particle> particles;

  ParticlePainter(this.animationValue) : particles = _generateParticles();

  static List<Particle> _generateParticles() {
    final particles = <Particle>[];
    for (int i = 0; i < 20; i++) {
      particles.add(Particle());
    }
    return particles;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    for (final particle in particles) {
      final x = particle.x * size.width;
      final y =
          (particle.y + animationValue * particle.speed) % 1.0 * size.height;

      canvas.drawCircle(
        Offset(x, y),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Particle class for floating animation
class Particle {
  final double x;
  final double y;
  final double size;
  final double speed;

  Particle()
      : x = math.Random().nextDouble(),
        y = math.Random().nextDouble(),
        size = math.Random().nextDouble() * 3 + 1,
        speed = math.Random().nextDouble() * 0.5 + 0.1;
}
