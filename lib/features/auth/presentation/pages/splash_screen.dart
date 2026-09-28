import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:hr_management/core/theme/theme_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _pulseController;
  late AnimationController _shineController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shineAnimation;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();

    // 1. Entrance animation (Icon pop + text fade up)
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Continuous breathing / glowing pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutSine,
      ),
    );

    // 3. Shimmer shine sweep animation
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _shineAnimation = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(
        parent: _shineController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _entryController.forward();

    // Navigate to respective initial screen after splash animation
    _navTimer = Timer(const Duration(milliseconds: 2600), _handleNavigation);
  }

  void _handleNavigation() {
    if (!mounted) return;

    final token = AuthStorage.token;
    final targetRoute = (token != null && token.isNotEmpty)
        ? '/'
        : '/login';

    Navigator.of(context).pushReplacementNamed(targetRoute);
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _entryController.dispose();
    _pulseController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme-adaptive ambient background gradient
    final bgGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF040D1A), // Deep Midnight
              Color(0xFF082032), // Dark Navy
              Color(0xFF063539), // Dark Emerald Teal
              Color(0xFF02171E), // Deep Abyss
            ],
            stops: [0.0, 0.35, 0.75, 1.0],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF0FDF4), // Mint White
              Color(0xFFE6FFFA), // Soft Aquamarine
              Color(0xFFF8FAFC), // Off-white
              Color(0xFFEDF2F7), // Light Slate
            ],
            stops: [0.0, 0.4, 0.7, 1.0],
          );

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(gradient: bgGradient),
            ),
          ),

          // Ambient Floating Glow Orbs (Themewise lighting)
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    t.primary.withValues(alpha: isDark ? 0.28 : 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -80,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    t.secondary.withValues(alpha: isDark ? 0.22 : 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Center Content
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated App Icon with Breathing Glow
                    AnimatedBuilder(
                      animation: Listenable.merge([_entryController, _pulseController, _shineController]),
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value * _pulseAnimation.value,
                          child: Opacity(
                            opacity: _fadeAnimation.value,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Pulsing Outer Aura Glow
                                Container(
                                  width: 146,
                                  height: 146,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(38),
                                    boxShadow: [
                                      BoxShadow(
                                        color: t.primary.withValues(alpha: isDark ? 0.45 : 0.28),
                                        blurRadius: 36 * _pulseAnimation.value,
                                        spreadRadius: 4 * _pulseAnimation.value,
                                      ),
                                      BoxShadow(
                                        color: t.secondary.withValues(alpha: isDark ? 0.35 : 0.20),
                                        blurRadius: 28 * _pulseAnimation.value,
                                        offset: const Offset(4, 6),
                                      ),
                                    ],
                                  ),
                                ),

                                // The Glassmorphic Icon Badge Container
                                Container(
                                  width: 128,
                                  height: 128,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(32),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.25)
                                          : Colors.white.withValues(alpha: 0.8),
                                      width: 2.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                                        blurRadius: 24,
                                        offset: const Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        // App Icon Image
                                        Image.asset(
                                          'assets/icons/app_icon.png',
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [t.primary, t.secondary],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.diversity_3_rounded,
                                                size: 56,
                                                color: Colors.white,
                                              ),
                                            );
                                          },
                                        ),

                                        // Animated Shimmer Shine Sweep
                                        Transform.rotate(
                                          angle: 0.5,
                                          child: FractionalTranslation(
                                            translation: Offset(_shineAnimation.value, 0.0),
                                            child: Container(
                                              width: 45,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.white.withValues(alpha: 0.0),
                                                    Colors.white.withValues(alpha: 0.35),
                                                    Colors.white.withValues(alpha: 0.0),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 36),

                    // App Title & Tagline with Fade-In + Slide-Up
                    AnimatedBuilder(
                      animation: _entryController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeAnimation.value,
                          child: Transform.translate(
                            offset: Offset(0, _slideAnimation.value),
                            child: Column(
                              children: [
                                // Title
                                Text(
                                  'HR MANAGEMENT',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 3.2,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Subtitle / Tagline Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : t.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.12)
                                          : t.primary.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Text(
                                    'Workforce Intelligence & Operations',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.6,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 60),

                    // Sleek Minimal Loading Indicator & Version
                    AnimatedBuilder(
                      animation: _entryController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeAnimation.value,
                          child: Column(
                            children: [
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.8,
                                  valueColor: AlwaysStoppedAnimation<Color>(t.primary),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'v1.0.0 • Enterprise Edition',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
