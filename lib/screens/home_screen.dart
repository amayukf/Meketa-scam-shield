import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/scam_provider.dart';
import '../utils/app_theme.dart';
import '../utils/app_translations.dart';
import '../widgets/alert_card.dart';
import '../main.dart';
import 'scam_alert_screen.dart';
import '../widgets/emergency_hotlines_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScamProvider>(
      builder: (context, provider, _) {
        final lang = provider.currentLanguage;
        final stats = provider.stats;
        final recentAlerts = provider.alerts.take(3).toList();
        final today = DateFormat('EEEE · MMM d, yyyy').format(DateTime.now());
        final scamFree = provider.scamFreePercentage;

        // Compute a live Threat Risk Score (0-100) — inverse of scamFree, weighted by recent high-risk
        final highRisk = provider.highRiskCount;
        final riskScore = (100 - scamFree).clamp(0, 100);
        final riskLevel = riskScore >= 60
            ? 'HIGH'
            : riskScore >= 30
                ? 'MEDIUM'
                : 'LOW';
        final riskColor = riskScore >= 60
            ? AppColors.danger
            : riskScore >= 30
                ? AppColors.warningDark
                : AppColors.safe;

        return SafeArea(
          child: CustomScrollView(
            slivers: [
              if (provider.isLoading)
                const SliverToBoxAdapter(
                  child: LinearProgressIndicator(
                    color: AppColors.primary,
                    minHeight: 3,
                  ),
                ),

              // ── App Bar ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.shield_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppTranslations.get(lang, 'app_title'),
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      // Emergency Hotline button
                      IconButton(
                        onPressed: () => EmergencyHotlinesSheet.show(context, lang),
                        icon: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.phone_in_talk_rounded,
                            color: Color(0xFFEF4444),
                            size: 18,
                          ),
                        ),
                        tooltip: lang == 'Amharic'
                            ? 'የድንገተኛ ማጭበርበር ስልክ መስመሮች'
                            : 'Emergency Hotlines',
                      ),
                      const SizedBox(width: 4),
                      // Protected badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.protectedBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.protectedText,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              AppTranslations.get(lang, 'protected'),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.protectedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Threat Intelligence Command Banner ────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _ThreatBanner(
                    today: today,
                    scamFree: scamFree,
                    riskScore: riskScore,
                    riskLevel: riskLevel,
                    riskColor: riskColor,
                    highRiskCount: highRisk,
                    lang: lang,
                  ),
                ),
              ),

              // ── Stats Grid ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Protection Metrics',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              icon: Icons.phone_android_rounded,
                              iconColor: const Color(0xFF1565C0),
                              value: '${stats['totalScanned']}',
                              label: AppTranslations.get(
                                  lang, 'total_scanned'),
                              bgColor: AppColors.statBlue,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: StatCard(
                              icon: Icons.block_rounded,
                              iconColor: AppColors.danger,
                              value: '${stats['scamsBlocked']}',
                              label: AppTranslations.get(
                                  lang, 'scams_blocked'),
                              bgColor: AppColors.statRed,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              icon: Icons.verified_user_rounded,
                              iconColor: AppColors.safe,
                              value: '${stats['blockRate']}%',
                              label: AppTranslations.get(lang, 'block_rate'),
                              bgColor: AppColors.statTeal,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: StatCard(
                              icon: Icons.receipt_long_rounded,
                              iconColor: const Color(0xFF6A1B9A),
                              value: 'Offline',
                              label: 'Format Check',
                              bgColor: AppColors.statPurple,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Emergency Fraud Hotlines Quick Banner ─────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFEF4444).withValues(alpha: 0.12),
                          const Color(0xFFF97316).withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.phone_in_talk_rounded,
                            color: Color(0xFFEF4444),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang == 'Amharic'
                                    ? 'የድንገተኛ ማጭበርበር ስልክ መስመሮች'
                                    : 'Emergency Fraud Hotlines',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Telebirr (994) • CBE (951) • BoA (8397)',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => EmergencyHotlinesSheet.show(context, lang),
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.2),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            lang == 'Amharic' ? 'ደውል' : 'Call',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFF87171),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Recent Alerts Header ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppTranslations.get(lang, 'recent_alerts'),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          final navState = context
                              .findAncestorStateOfType<MainNavigationState>();
                          navState?.onItemTapped(1);
                        },
                        child: Text(
                          AppTranslations.get(lang, 'see_all'),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.safe,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Recent Alerts List ────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                sliver: recentAlerts.isEmpty
                    ? SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.sms_rounded,
                                size: 48,
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                AppTranslations.get(lang, 'no_messages'),
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppTranslations.get(lang, 'waiting_sms'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final alert = recentAlerts[index];
                            return AlertCard(
                              alert: alert,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ScamAlertScreen(alert: alert),
                                  ),
                                );
                              },
                            );
                          },
                          childCount: recentAlerts.length,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Threat Intelligence Command Banner (premium widget)
// ─────────────────────────────────────────────────────────────────────────────

class _ThreatBanner extends StatefulWidget {
  final String today;
  final int scamFree;
  final int riskScore;
  final String riskLevel;
  final Color riskColor;
  final int highRiskCount;
  final String lang;

  const _ThreatBanner({
    required this.today,
    required this.scamFree,
    required this.riskScore,
    required this.riskLevel,
    required this.riskColor,
    required this.highRiskCount,
    required this.lang,
  });

  @override
  State<_ThreatBanner> createState() => _ThreatBannerState();
}

class _ThreatBannerState extends State<_ThreatBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 6.0, end: 18.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLow = widget.riskScore < 30;
    final List<Color> gradientColors = isLow
        ? [const Color(0xFF0A3D2E), const Color(0xFF0F2A24)]
        : widget.riskScore < 60
            ? [const Color(0xFF3D2500), const Color(0xFF2A1A00)]
            : [const Color(0xFF3D0A0A), const Color(0xFF2A0505)];

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.riskColor.withValues(alpha: 0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: widget.riskColor.withValues(alpha: 0.15),
                blurRadius: _glowAnim.value,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: date & risk badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.today,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white54,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.riskColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: widget.riskColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.riskColor,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${widget.riskLevel} RISK',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: widget.riskColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Main stats row
          Row(
            children: [
              // Arc gauge
              _ArcGauge(
                value: widget.scamFree / 100.0,
                color: widget.riskColor.withValues(alpha: 0.9),
                safePercent: widget.scamFree,
              ),
              const SizedBox(width: 18),

              // Text stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${widget.scamFree}% ',
                            style: GoogleFonts.poppins(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: widget.riskColor,
                              height: 1.0,
                            ),
                          ),
                          TextSpan(
                            text: 'Scam-Free',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppTranslations.get(widget.lang, 'inbox_status'),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white60,
                        height: 1.3,
                      ),
                    ),
                    if (widget.highRiskCount > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 14,
                            color: AppColors.danger,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.highRiskCount} high-risk detected',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Status bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.security_rounded,
                    size: 14, color: Colors.white54),
                const SizedBox(width: 6),
                Text(
                  'Meketa On-Device Heuristic Engine • Active',
                  style: GoogleFonts.robotoMono(
                    fontSize: 10,
                    color: Colors.white38,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.safe,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Circular Arc Gauge
// ─────────────────────────────────────────────────────────────────────────────

class _ArcGauge extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final Color color;
  final int safePercent;

  const _ArcGauge({
    required this.value,
    required this.color,
    required this.safePercent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: CustomPaint(
        painter: _ArcPainter(value: value, color: color),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shield_rounded, size: 22, color: Colors.white54),
              Text(
                '$safePercent%',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double value;
  final Color color;

  _ArcPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const startAngle = -math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    // Background track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Value arc
    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * value,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.value != value || old.color != color;
}
