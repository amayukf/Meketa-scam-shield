import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeBriefingDialog {
  static const String _prefKey = 'has_seen_welcome_briefing_v2';

  /// Check if the user has already seen the welcome briefing; if not, show it automatically
  static Future<void> checkAndShow(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeen = prefs.getBool(_prefKey) ?? false;
      if (!hasSeen && context.mounted) {
        await Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false,
            barrierDismissible: false,
            pageBuilder: (ctx, anim, sec) => FadeTransition(
              opacity: anim,
              child: const _OnboardingScreen(),
            ),
          ),
        );
        await prefs.setBool(_prefKey, true);
      }
    } catch (_) {}
  }

  /// Show the Welcome Briefing explicitly (e.g., from Settings)
  static void show(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (ctx, anim, sec) => FadeTransition(
          opacity: anim,
          child: const _OnboardingScreen(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Onboarding Data
// ─────────────────────────────────────────────────────────────────────────────

class _Page {
  final String emoji;
  final String title;
  final String subtitle;
  final String body;
  final Color accentColor;
  final List<Color> gradientColors;
  final IconData icon;

  const _Page({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.accentColor,
    required this.gradientColors,
    required this.icon,
  });
}

const List<_Page> _pages = [
  _Page(
    emoji: '🛡️',
    title: 'MEKETA',
    subtitle: 'መከታ • Ethiopian Cyber Defense',
    body:
        'Ethiopia\'s first AI-powered mobile scam shield.\nProtects you from Telebirr fraud, fake CBE receipts, USSD airtime traps, and phishing links — entirely on your device.',
    accentColor: Color(0xFF3B82F6),
    gradientColors: [Color(0xFF1E3A5F), Color(0xFF0F172A)],
    icon: Icons.shield_rounded,
  ),
  _Page(
    emoji: '📱',
    title: 'Real-Time SMS Guard',
    subtitle: 'On-Device • Zero Privacy Risk',
    body:
        'Every incoming SMS is scanned instantly using AI heuristics. Fake Telebirr deposit alerts, OTP theft attempts, and phishing links are caught before you even read them.',
    accentColor: Color(0xFF06B6D4),
    gradientColors: [Color(0xFF0E3A44), Color(0xFF0F172A)],
    icon: Icons.mark_email_unread_rounded,
  ),
  _Page(
    emoji: '🧾',
    title: 'Live Receipt Verifier',
    subtitle: 'Direct Bank Network Validation',
    body:
        'Verify any mobile money receipt instantly via v.odit.et — the official Ethiopian banking transaction verification system. Stop fake receipt fraud before delivering goods.',
    accentColor: Color(0xFF10B981),
    gradientColors: [Color(0xFF0A3D2E), Color(0xFF0F172A)],
    icon: Icons.receipt_long_rounded,
  ),
  _Page(
    emoji: '🤖',
    title: 'AI Security Assistant',
    subtitle: 'Powered by Gemini • English & Amharic',
    body:
        'Ask anything about digital fraud in Ethiopia. Get instant, expert guidance on suspicious messages, fake receipts, and scam tactics — in English or Amharic.',
    accentColor: Color(0xFF8B5CF6),
    gradientColors: [Color(0xFF2D1B4E), Color(0xFF0F172A)],
    icon: Icons.auto_awesome_rounded,
  ),
  _Page(
    emoji: '🎓',
    title: 'Defense Sandbox',
    subtitle: 'Train. Learn. Stay Protected.',
    body:
        'Practice identifying scam messages in our interactive simulator. Learn the 4 Golden Rules of digital security and master the official shortcode directory for all Ethiopian banks.',
    accentColor: Color(0xFFF59E0B),
    gradientColors: [Color(0xFF3D2B0A), Color(0xFF0F172A)],
    icon: Icons.psychology_rounded,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Main Onboarding Screen
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardingScreen extends StatefulWidget {
  const _OnboardingScreen();

  @override
  State<_OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<_OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _bgAnimController;
  late AnimationController _iconPulseController;
  late Animation<double> _iconPulse;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();

    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _iconPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _iconPulse = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _iconPulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgAnimController.dispose();
    _iconPulseController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _dismiss();
    }
  }

  void _dismiss() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: _bgAnimController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  page.gradientColors[0],
                  page.gradientColors[1],
                ],
              ),
            ),
            child: child,
          );
        },
        child: Stack(
          children: [
            // Animated particle/orb background
            ..._buildOrbs(page.accentColor, size),

            // Safe area content
            SafeArea(
              child: Column(
                children: [
                  // Skip button
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, right: 16),
                      child: TextButton(
                        onPressed: _dismiss,
                        child: Text(
                          'Skip',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Page content
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _pages.length,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      itemBuilder: (context, index) {
                        return _PageContent(
                          page: _pages[index],
                          iconPulse: _iconPulse,
                          isActive: index == _currentPage,
                        );
                      },
                    ),
                  ),

                  // Bottom navigation
                  _buildBottomNav(page),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOrbs(Color accent, Size size) {
    return [
      Positioned(
        top: -80,
        left: -60,
        child: AnimatedBuilder(
          animation: _bgAnimController,
          builder: (context, child2) => Transform.scale(
            scale: 0.85 + 0.15 * _bgAnimController.value,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.12),
              ),
            ),
          ),
        ),
      ),
      Positioned(
        bottom: -100,
        right: -80,
        child: AnimatedBuilder(
          animation: _bgAnimController,
          builder: (context, child3) => Transform.scale(
            scale: 1.0 - 0.12 * _bgAnimController.value,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.08),
              ),
            ),
          ),
        ),
      ),
      Positioned(
        top: size.height * 0.3,
        right: -40,
        child: AnimatedBuilder(
          animation: _bgAnimController,
          builder: (context, child4) => Transform.rotate(
            angle: _bgAnimController.value * math.pi * 0.2,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: accent.withValues(alpha: 0.06),
              ),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildBottomNav(_Page page) {
    final isLast = _currentPage == _pages.length - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
      child: Column(
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _currentPage ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _currentPage
                      ? page.accentColor
                      : Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Primary action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: page.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLast ? 'Activate Protection' : 'Next',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isLast
                        ? Icons.shield_rounded
                        : Icons.arrow_forward_rounded,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual Page Content
// ─────────────────────────────────────────────────────────────────────────────

class _PageContent extends StatelessWidget {
  final _Page page;
  final Animation<double> iconPulse;
  final bool isActive;

  const _PageContent({
    required this.page,
    required this.iconPulse,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Pulsing icon badge
          AnimatedBuilder(
            animation: iconPulse,
            builder: (context, child5) => Transform.scale(
              scale: isActive ? iconPulse.value : 1.0,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      page.accentColor.withValues(alpha: 0.3),
                      page.accentColor.withValues(alpha: 0.05),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: page.accentColor.withValues(alpha: 0.35),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: page.accentColor.withValues(alpha: 0.2),
                      border: Border.all(
                        color: page.accentColor.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      page.icon,
                      size: 38,
                      color: page.accentColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Emoji
          Text(
            page.emoji,
            style: const TextStyle(fontSize: 36),
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),

          // Subtitle badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: page.accentColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: page.accentColor.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              page.subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: page.accentColor,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 22),

          // Body text
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white70,
              height: 1.65,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
