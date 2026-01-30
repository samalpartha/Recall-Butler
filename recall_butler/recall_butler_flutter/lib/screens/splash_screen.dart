import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../theme/vibrant_theme.dart';
import '../widgets/circular_butler_logo.dart';
import 'onboarding_screen.dart';

/// Animated Splash Screen with particle effects
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    
    // Navigate after delay
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const OnboardingScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: VibrantTheme.gradientBackground,
        ),
        child: Stack(
          children: [
            // Animated background particles
            ..._buildParticles(),
            
            // Rotating rings
            Center(
              child: AnimatedBuilder(
                animation: _rotateController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotateController.value * 2 * math.pi,
                    child: CustomPaint(
                      size: const Size(300, 300),
                      painter: RingsPainter(
                        progress: _pulseController.value,
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Center logo and text
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Flutter Butler logo
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final size = 200 + (_pulseController.value * 10);
                      return CircularButlerLogo(
                        size: size,
                      );
                    },
                  ).animate()
                    .scale(duration: 800.ms, curve: Curves.elasticOut),
                  
                  const SizedBox(height: 32),
                  
                  // App name with gradient
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [VibrantTheme.primaryPurple, VibrantTheme.primaryPink, VibrantTheme.primaryCyan],
                    ).createShader(bounds),
                    child: const Text(
                      'Recall Butler',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                  ).animate()
                    .fadeIn(delay: 300.ms, duration: 600.ms)
                    .slideY(begin: 0.3),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    'Your AI Memory Companion',
                    style: TextStyle(
                      fontSize: 16,
                      color: VibrantTheme.textSecondary,
                      letterSpacing: 2,
                    ),
                  ).animate()
                    .fadeIn(delay: 600.ms, duration: 600.ms),
                  
                  const SizedBox(height: 60),
                  
                  // Loading indicator
                  SizedBox(
                    width: 200,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        backgroundColor: VibrantTheme.bgCardLight,
                        valueColor: const AlwaysStoppedAnimation(VibrantTheme.primaryPurple),
                      ),
                    ),
                  ).animate()
                    .fadeIn(delay: 900.ms)
                    .shimmer(delay: 1000.ms, duration: 2000.ms),
                ],
              ),
            ),
            
            // Bottom text
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Text(
                'Powered by Serverpod & AI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: VibrantTheme.textMuted,
                  fontSize: 12,
                ),
              ).animate()
                .fadeIn(delay: 1200.ms),
            ),
          ],
        ),
      ),
    );
  }
  
  List<Widget> _buildParticles() {
    final random = math.Random(42);
    return List.generate(20, (index) {
      final size = 4.0 + random.nextDouble() * 8;
      final left = random.nextDouble() * MediaQuery.of(context).size.width;
      final top = random.nextDouble() * MediaQuery.of(context).size.height;
      final duration = 3000 + random.nextInt(3000);
      final delay = random.nextInt(2000);
      
      return Positioned(
        left: left,
        top: top,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: [
              VibrantTheme.primaryPurple,
              VibrantTheme.primaryPink,
              VibrantTheme.primaryCyan,
              VibrantTheme.primaryBlue,
            ][index % 4].withOpacity(0.6),
            boxShadow: [
              BoxShadow(
                color: [
                  VibrantTheme.primaryPurple,
                  VibrantTheme.primaryPink,
                  VibrantTheme.primaryCyan,
                  VibrantTheme.primaryBlue,
                ][index % 4].withOpacity(0.4),
                blurRadius: 10,
              ),
            ],
          ),
        ).animate(
          onPlay: (controller) => controller.repeat(reverse: true),
        )
          .fadeIn(delay: delay.ms)
          .then()
          .moveY(
            begin: 0,
            end: -30,
            duration: duration.ms,
            curve: Curves.easeInOut,
          )
          .fadeOut(delay: (duration - 500).ms),
      );
    });
  }
}

/// Custom bowtie painter for splash logo
class SplashBowtiePatnter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    // Left triangle of bowtie
    final leftPath = Path()
      ..moveTo(size.width / 2 - 4, size.height / 2)
      ..lineTo(0, 0)
      ..lineTo(0, size.height)
      ..close();
    
    // Right triangle of bowtie
    final rightPath = Path()
      ..moveTo(size.width / 2 + 4, size.height / 2)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();
    
    canvas.drawPath(leftPath, paint);
    canvas.drawPath(rightPath, paint);
    
    // Center knot
    final knotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      5,
      knotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for animated rings
class RingsPainter extends CustomPainter {
  final double progress;
  
  RingsPainter({required this.progress});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Outer ring
    final outerPaint = Paint()
      ..color = VibrantTheme.primaryPurple.withOpacity(0.2 + progress * 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, 140, outerPaint);
    
    // Middle ring
    final middlePaint = Paint()
      ..color = VibrantTheme.primaryPink.withOpacity(0.3 + progress * 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, 120, middlePaint);
    
    // Inner ring with gradient effect
    final innerPaint = Paint()
      ..color = VibrantTheme.primaryCyan.withOpacity(0.2 + progress * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, 100, innerPaint);
    
    // Orbiting dots
    for (var i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2);
      final dotX = center.dx + 140 * math.cos(angle);
      final dotY = center.dy + 140 * math.sin(angle);
      
      final dotPaint = Paint()
        ..color = [
          VibrantTheme.primaryPurple,
          VibrantTheme.primaryPink,
          VibrantTheme.primaryCyan,
          VibrantTheme.primaryBlue,
        ][i];
      
      canvas.drawCircle(Offset(dotX, dotY), 4 + progress * 2, dotPaint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
