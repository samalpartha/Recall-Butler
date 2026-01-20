import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/vibrant_theme.dart';
import 'home_screen.dart';

/// Authentication Screen with Social Login & Email/Password
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _pulseController;
  bool _isLoading = false;
  String? _loadingProvider;
  
  // Auth mode
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signInWith(String provider) async {
    setState(() {
      _isLoading = true;
      _loadingProvider = provider;
    });
    
    // Simulate OAuth flow
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      AuthManager().login(provider, userName: 'User');
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  Future<void> _submitEmailForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _loadingProvider = 'email';
    });
    
    // Simulate authentication
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      final username = _usernameController.text.isNotEmpty 
          ? _usernameController.text 
          : _emailController.text.split('@').first;
      
      AuthManager().login('email', userName: username);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSignUp ? 'Account created! 🎉' : 'Welcome back! 👋'),
          backgroundColor: VibrantTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
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
            // Animated background elements
            ..._buildFloatingElements(),
            
            // Main content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        
                        // Logo
                        _buildLogo(),
                        
                        const SizedBox(height: 16),
                        
                        // App name
                        _buildAppTitle(),
                        
                        const SizedBox(height: 8),
                        
                        // Tagline
                        Text(
                          'Your AI-Powered Memory Assistant',
                          style: TextStyle(
                            color: VibrantTheme.textSecondary,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 400.ms),
                        
                        const SizedBox(height: 32),
                        
                        // Auth form
                        _buildAuthForm(),
                        
                        const SizedBox(height: 24),
                        
                        // Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: VibrantTheme.textSecondary.withOpacity(0.3))),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'or',
                                style: TextStyle(color: VibrantTheme.textSecondary, fontSize: 13),
                              ),
                            ),
                            Expanded(child: Divider(color: VibrantTheme.textSecondary.withOpacity(0.3))),
                          ],
                        ).animate().fadeIn(delay: 700.ms),
                        
                        const SizedBox(height: 24),
                        
                        // Social login icons (compact)
                        _buildSocialLoginRow(),
                        
                        const SizedBox(height: 24),
                        
                        // Toggle sign up / sign in
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isSignUp ? 'Already have an account?' : "Don't have an account?",
                              style: TextStyle(color: VibrantTheme.textSecondary, fontSize: 13),
                            ),
                            TextButton(
                              onPressed: () => setState(() {
                                _isSignUp = !_isSignUp;
                                _formKey.currentState?.reset();
                              }),
                              child: Text(
                                _isSignUp ? 'Sign In' : 'Sign Up',
                                style: const TextStyle(
                                  color: VibrantTheme.primaryPurple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 900.ms),
                        
                        const SizedBox(height: 16),
                        
                        // Terms
                        Text(
                          'By continuing, you agree to our Terms & Privacy Policy',
                          style: TextStyle(
                            color: VibrantTheme.textSecondary,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 1000.ms),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Username field (for sign up only)
          if (_isSignUp) ...[
            _buildTextField(
              controller: _usernameController,
              label: 'Username',
              hint: 'Choose a username',
              icon: LucideIcons.user,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a username';
                }
                if (value.length < 3) {
                  return 'Username must be at least 3 characters';
                }
                return null;
              },
            ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.1),
            const SizedBox(height: 12),
          ],
          
          // Email field
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'Enter your email',
            icon: LucideIcons.mail,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ).animate().fadeIn(delay: 550.ms).slideX(begin: 0.1),
          
          const SizedBox(height: 12),
          
          // Password field
          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter your password',
            icon: LucideIcons.lock,
            obscureText: _obscurePassword,
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
              child: Icon(
                _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                color: VibrantTheme.textSecondary,
                size: 18,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (_isSignUp && value.length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
          ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.1),
          
          // Confirm password (for sign up only)
          if (_isSignUp) ...[
            const SizedBox(height: 12),
            _buildTextField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              hint: 'Confirm your password',
              icon: LucideIcons.keyRound,
              obscureText: _obscureConfirmPassword,
              suffixIcon: GestureDetector(
                onTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                child: Icon(
                  _obscureConfirmPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                  color: VibrantTheme.textSecondary,
                  size: 18,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ).animate().fadeIn(delay: 650.ms).slideX(begin: 0.1),
          ],
          
          // Forgot password (sign in only)
          if (!_isSignUp) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showForgotPasswordDialog,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 30),
                ),
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: VibrantTheme.primaryPurple,
                    fontSize: 13,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 650.ms),
          ],
          
          const SizedBox(height: 20),
          
          // Submit button
          GestureDetector(
            onTap: _isLoading ? null : _submitEmailForm,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: VibrantTheme.gradientPrimary,
                boxShadow: [
                  BoxShadow(
                    color: VibrantTheme.primaryPurple.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: _isLoading && _loadingProvider == 'email'
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _isSignUp ? 'Create Account' : 'Sign In',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ).animate().fadeIn(delay: 680.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }

  Widget _buildSocialLoginRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Google
        _buildSocialIcon(
          provider: 'Google',
          icon: FontAwesomeIcons.google,
          colors: [
            const Color(0xFF4285F4),
            const Color(0xFF34A853),
            const Color(0xFFFBBC05),
            const Color(0xFFEA4335),
          ],
          isGradient: true,
        ),
        const SizedBox(width: 16),
        
        // Facebook
        _buildSocialIcon(
          provider: 'Facebook',
          icon: FontAwesomeIcons.facebookF,
          colors: [const Color(0xFF1877F2)],
        ),
        const SizedBox(width: 16),
        
        // Apple
        _buildSocialIcon(
          provider: 'Apple',
          icon: FontAwesomeIcons.apple,
          colors: [Colors.black],
        ),
        const SizedBox(width: 16),
        
        // X (Twitter)
        _buildSocialIcon(
          provider: 'X',
          icon: FontAwesomeIcons.xTwitter,
          colors: [Colors.black],
        ),
      ],
    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2);
  }

  Widget _buildSocialIcon({
    required String provider,
    required IconData icon,
    required List<Color> colors,
    bool isGradient = false,
  }) {
    final isLoading = _isLoading && _loadingProvider == provider;
    
    return Tooltip(
      message: 'Sign in with $provider',
      child: GestureDetector(
        onTap: isLoading ? null : () => _signInWith(provider),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colors.first.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.first,
                    ),
                  )
                : isGradient
                    ? ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: colors,
                          stops: const [0.0, 0.33, 0.66, 1.0],
                        ).createShader(bounds),
                        child: FaIcon(
                          icon,
                          size: 26,
                          color: Colors.white,
                        ),
                      )
                    : FaIcon(
                        icon,
                        size: 26,
                        color: colors.first,
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: VibrantTheme.textSecondary.withOpacity(0.5), fontSize: 14),
        labelStyle: TextStyle(color: VibrantTheme.textSecondary, fontSize: 14),
        prefixIcon: Icon(icon, color: VibrantTheme.primaryPurple, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: VibrantTheme.bgCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: VibrantTheme.primaryPurple.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: VibrantTheme.primaryPurple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        errorStyle: const TextStyle(fontSize: 11),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VibrantTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(LucideIcons.keyRound, color: VibrantTheme.primaryPurple, size: 22),
            SizedBox(width: 10),
            Text('Reset Password', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your email to receive a reset link.',
              style: TextStyle(color: VibrantTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Enter your email',
                prefixIcon: const Icon(LucideIcons.mail, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: VibrantTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Reset link sent! 📧'),
                  backgroundColor: VibrantTheme.primaryGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: VibrantTheme.primaryPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Send', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFloatingElements() {
    return [
      AnimatedBuilder(
        animation: _floatController,
        builder: (context, _) {
          return Positioned(
            top: 80 + 25 * math.sin(_floatController.value * math.pi),
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    VibrantTheme.primaryPurple.withOpacity(0.35),
                    VibrantTheme.primaryPurple.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      AnimatedBuilder(
        animation: _floatController,
        builder: (context, _) {
          return Positioned(
            bottom: 150 + 30 * math.cos(_floatController.value * math.pi),
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    VibrantTheme.primaryPink.withOpacity(0.25),
                    VibrantTheme.primaryPink.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ];
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + 0.02 * _pulseController.value;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4FACFE).withOpacity(0.3),
                  blurRadius: 30 + 10 * _pulseController.value,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to styled text logo
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A5F), Color(0xFF2D5A8A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: const Color(0xFF4FACFE).withOpacity(0.5),
                      width: 3,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF4FACFE), Color(0xFF00D4FF)],
                        ).createShader(bounds),
                        child: const Text(
                          'FB',
                          style: TextStyle(
                            fontSize: 60,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Text(
                        'BUTLER',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4FACFE),
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    ).animate().fadeIn().scale(begin: const Offset(0.5, 0.5), duration: 500.ms, curve: Curves.easeOutBack);
  }

  Widget _buildAppTitle() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [VibrantTheme.primaryPurple, VibrantTheme.primaryPink, VibrantTheme.primaryBlue],
      ).createShader(bounds),
      child: const Text(
        'Recall Butler',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2);
  }
}

/// Custom bowtie painter for the butler logo
class BowtiePatnter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    // Left triangle of bowtie
    final leftPath = Path()
      ..moveTo(size.width / 2 - 3, size.height / 2)
      ..lineTo(0, 0)
      ..lineTo(0, size.height)
      ..close();
    
    // Right triangle of bowtie
    final rightPath = Path()
      ..moveTo(size.width / 2 + 3, size.height / 2)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();
    
    canvas.drawPath(leftPath, paint);
    canvas.drawPath(rightPath, paint);
    
    // Center knot
    final knotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      4,
      knotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Global auth state manager
class AuthManager {
  static final AuthManager _instance = AuthManager._internal();
  factory AuthManager() => _instance;
  AuthManager._internal();

  bool _isLoggedIn = false;
  String? _currentUser;
  String? _loginProvider;
  String? _email;

  bool get isLoggedIn => _isLoggedIn;
  String? get currentUser => _currentUser;
  String? get loginProvider => _loginProvider;
  String? get email => _email;

  void login(String provider, {String? userName, String? userEmail}) {
    _isLoggedIn = true;
    _loginProvider = provider;
    _currentUser = userName ?? 'User';
    _email = userEmail;
  }

  void logout() {
    _isLoggedIn = false;
    _currentUser = null;
    _loginProvider = null;
    _email = null;
  }
}
