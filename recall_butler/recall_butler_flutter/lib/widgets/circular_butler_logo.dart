import 'package:flutter/material.dart';
import '../theme/vibrant_theme.dart';

class CircularButlerLogo extends StatelessWidget {
  final double size;
  final bool withShadow;

  const CircularButlerLogo({
    super.key,
    this.size = 100.0,
    this.withShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white, // Ensure a clean background for the logo
        boxShadow: withShadow
            ? [
                BoxShadow(
                  color: const Color(0xFF4FACFE).withOpacity(0.3),
                  blurRadius: size * 0.2, // dynamic blur
                  spreadRadius: size * 0.05,
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.contain, // Ensure the full logo is visible within the circle
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to styled circular text logo
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A5F), Color(0xFF2D5A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: const Color(0xFF4FACFE).withOpacity(0.5),
                  width: size * 0.03,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF4FACFE), Color(0xFF00D4FF)],
                      ).createShader(bounds),
                      child: Text(
                        'FB',
                        style: TextStyle(
                          fontSize: size * 0.4,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
