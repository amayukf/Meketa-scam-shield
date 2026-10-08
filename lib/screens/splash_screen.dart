import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  int _currentStep = 0;
  Timer? _timer1;
  Timer? _timer2;
  Timer? _timer3;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 8.0, end: 24.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    // Sequential system readiness indicators
    _timer1 = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _currentStep = 1);
    });
    _timer2 = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _currentStep = 2);
    });
    _timer3 = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _currentStep = 3);
    });

    // Auto navigate to MainNavigation after 2.3 seconds
    _navTimer = Timer(const Duration(milliseconds: 2300), () {
      _navigateToMain();
    });
  }

  @override
  void dispose() {
    _timer1?.cancel();
    _timer2?.cancel();
    _timer3?.cancel();
    _navTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _navigateToMain() {
    if (!mounted) return;
    _navTimer?.cancel();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, anim, secAnim) => const MainNavigation(),
        transitionsBuilder: (context, animation, secAnim, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _navigateToMain,
      child: Scaffold(
        backgroundColor: const Color(0xFF090D16),
        body: Stack(
          children: [
            // Ambient background glow
            Positioned(
              top: -100,
              left: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              right: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),

                      // Glowing Pulsing Shield Logo
                      AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF3B82F6).withValues(alpha: 0.45),
                                    blurRadius: _glowAnimation.value,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.shield_rounded,
                                  size: 52,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 28),

                      // Brand Name
                      Text(
                        'MEKETA',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4.0,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'መከታ • Autonomous Cyber Defense',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.0,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 42),

                      // Sequential System Check Indicators
                      _buildCheckStep(
                        index: 1,
                        label: 'On-Device Heuristic Engine Armed',
                        active: _currentStep >= 1,
                      ),
                      const SizedBox(height: 10),
                      _buildCheckStep(
                        index: 2,
                        label: 'Banking Signatures Loaded (Telebirr • CBE • BoA)',
                        active: _currentStep >= 2,
                      ),
                      const SizedBox(height: 10),
                      _buildCheckStep(
                        index: 3,
                        label: 'Explainable AI Threat Detection Active',
                        active: _currentStep >= 3,
                      ),

                      const Spacer(),

                      // Tap to skip hint
                      Text(
                        'Tap anywhere to start',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.white30,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckStep({
    required int index,
    required String label,
    required bool active,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: active ? 1.0 : 0.25,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1E293B).withValues(alpha: 0.7) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? const Color(0xFF38BDF8).withValues(alpha: 0.3) : Colors.white10,
          ),
        ),
        child: Row(
          children: [
            Icon(
              active ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              size: 16,
              color: active ? const Color(0xFF34D399) : Colors.white24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? Colors.white : Colors.white54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
