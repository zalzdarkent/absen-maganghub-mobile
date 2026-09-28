import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import '../../../core/theme/ios_colors.dart';
import '../auth/auth_screen.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/generate_view_model.dart';
import '../../view_models/history_view_model.dart';
import '../../view_models/settings_view_model.dart';
import '../main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  final GenerateViewModel generateViewModel;
  final HistoryViewModel historyViewModel;
  final SettingsViewModel settingsViewModel;
  final AuthViewModel authViewModel;

  const SplashScreen({
    super.key,
    required this.generateViewModel,
    required this.historyViewModel,
    required this.settingsViewModel,
    required this.authViewModel,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _pulseController;
  late final AnimationController _progressController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _glowRadius;
  late final Animation<double> _textSlide;
  late final Animation<double> _textOpacity;
  late final Animation<double> _badgeOpacity;

  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    // 1. Entrance animation sequence (1200ms)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );

    _textSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
      ),
    );

    _badgeOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    // 2. Pulse / Breathing Glow animation (2000ms loop)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowRadius = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutSine,
      ),
    );

    // 3. Progress bar animation (2400ms)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // Start session check in background during splash animation
    widget.authViewModel.checkSession();

    _entranceController.forward();
    _progressController.forward();

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToNext();
      }
    });
  }

  void _navigateToNext() {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;

    if (widget.authViewModel.currentUser != null) {
      _openMainScreen();
    } else {
      _openAuthScreen();
    }
  }

  Future<void> _handleScreenTap() async {
    if (_isNavigating || !mounted) return;
    if (widget.authViewModel.isLoading) {
      await widget.authViewModel.checkSession();
    }
    _navigateToNext();
  }

  void _openMainScreen() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 650),
        pageBuilder: (context, animation, secondaryAnimation) =>
            MainNavigationScreen(
          generateViewModel: widget.generateViewModel,
          historyViewModel: widget.historyViewModel,
          settingsViewModel: widget.settingsViewModel,
          authViewModel: widget.authViewModel,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: child,
          );
        },
      ),
    );
  }

  void _openAuthScreen() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 650),
        pageBuilder: (context, animation, secondaryAnimation) =>
            AuthScreen(
          authViewModel: widget.authViewModel,
          generateViewModel: widget.generateViewModel,
          historyViewModel: widget.historyViewModel,
          settingsViewModel: widget.settingsViewModel,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  String _getProgressStatus(double value) {
    if (value < 0.3) return 'Memuat sistem...';
    if (value < 0.65) return 'Sinkronisasi profil & data...';
    if (value < 0.92) return 'Menyiapkan AI Assistant...';
    return 'Siap!';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return CupertinoPageScaffold(
      backgroundColor: IosColors.darkBackground,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleScreenTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ambient background glow (animated radial pulse)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Positioned.fill(
                  child: CustomPaint(
                    painter: _AmbientGlowPainter(
                      glowScale: _glowRadius.value,
                    ),
                  ),
                );
              },
            ),

            // Top subtle gradient accent
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: size.height * 0.35,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF30D158).withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Main center content
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),

                    // Logo with pulse ring & squircle glass container
                    AnimatedBuilder(
                      animation: Listenable.merge([_entranceController, _pulseController]),
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _logoScale.value,
                          child: Opacity(
                            opacity: _logoOpacity.value.clamp(0.0, 1.0),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Pulsing outer neon glow circle
                                Container(
                                  width: 140 * _glowRadius.value,
                                  height: 140 * _glowRadius.value,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        const Color(0xFF30D158).withValues(
                                          alpha: 0.28 * (1.3 - _glowRadius.value * 0.3),
                                        ),
                                        const Color(0xFF0A84FF).withValues(alpha: 0.05),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),

                                // Squircle icon container
                                Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(26),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF1E2922),
                                        Color(0xFF0F1511),
                                        Color(0xFF080C0A),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: const Color(0xFF30D158).withValues(alpha: 0.4),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF30D158).withValues(
                                          alpha: 0.35 + 0.15 * (1.0 - _glowRadius.value),
                                        ),
                                        blurRadius: 30,
                                        spreadRadius: 2,
                                      ),
                                      const BoxShadow(
                                        color: Color(0x99000000),
                                        blurRadius: 18,
                                        offset: Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.asset(
                                    'assets/icon/app_icon.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(
                                          CupertinoIcons.book_fill,
                                          color: IosColors.statusGreen,
                                          size: 54,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // App Title & Tagline with smooth entrance
                    AnimatedBuilder(
                      animation: _entranceController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _textSlide.value),
                          child: Opacity(
                            opacity: _textOpacity.value.clamp(0.0, 1.0),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          // App Title with glowing dot
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'MagangHub',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.6,
                                  color: CupertinoColors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: IosColors.statusGreen,
                                  boxShadow: [
                                    BoxShadow(
                                      color: IosColors.statusGreen.withValues(alpha: 0.8),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Subtitle
                          Text(
                            'Automated Logbook & Smart Attendance',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.1,
                              color: CupertinoColors.systemGrey.resolveFrom(context),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 3),

                    // Bottom: Progress capsule & Status text
                    AnimatedBuilder(
                      animation: _entranceController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _badgeOpacity.value.clamp(0.0, 1.0),
                          child: child,
                        );
                      },
                      child: Column(
                        children: [
                          // Animated Progress Bar
                          AnimatedBuilder(
                            animation: _progressController,
                            builder: (context, child) {
                              final progress = _progressController.value;
                              return Column(
                                children: [
                                  Container(
                                    width: 180,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1C1C1E),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Stack(
                                      children: [
                                        FractionallySizedBox(
                                          widthFactor: progress,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(10),
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFF00C853),
                                                  Color(0xFF30D158),
                                                  Color(0xFF69F0AE),
                                                ],
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF30D158).withValues(alpha: 0.6),
                                                  blurRadius: 8,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    _getProgressStatus(progress),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF8E8E93),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 36),

                          // Pill badge with subtle glassmorphic look
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141916).withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF30D158).withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  CupertinoIcons.sparkles,
                                  size: 13,
                                  color: IosColors.statusGreen,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Zalz • AI Powered v1.0.0',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: CupertinoColors.white.withValues(alpha: 0.75),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 1),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmbientGlowPainter extends CustomPainter {
  final double glowScale;

  _AmbientGlowPainter({required this.glowScale});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    final baseRadius = math.min(size.width, size.height) * 0.5 * glowScale;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF30D158).withValues(alpha: 0.14),
          const Color(0xFF00E676).withValues(alpha: 0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(
        Rect.fromCircle(center: center, radius: baseRadius),
      );

    canvas.drawCircle(center, baseRadius, paint);
  }

  @override
  bool shouldRepaint(_AmbientGlowPainter oldDelegate) {
    return oldDelegate.glowScale != glowScale;
  }
}
