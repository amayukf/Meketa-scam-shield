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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScamProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final lang = provider.currentLanguage;
        final stats = provider.stats;
        final recentAlerts = provider.alerts.take(3).toList();
        final today = DateFormat('EEEE · MMM d, yyyy').format(DateTime.now());

        return SafeArea(
          child: CustomScrollView(
            slivers: [
              // App Bar
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

              // Greeting
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        today,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.safe,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          children: [
                            TextSpan(
                                text:
                                    '${AppTranslations.get(lang, "inbox_status")}\n'),
                            TextSpan(
                              text: '${provider.scamFreePercentage}% ',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppColors.safe,
                              ),
                            ),
                            TextSpan(
                                text: AppTranslations.get(
                                    lang, 'scam_free_today')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Stats Grid
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              icon: Icons.phone_android_rounded,
                              iconColor: const Color(0xFF1565C0),
                              value: '${stats['totalScanned']}',
                              label: AppTranslations.get(lang, 'total_scanned'),
                              bgColor: AppColors.statBlue,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: StatCard(
                              icon: Icons.block_rounded,
                              iconColor: AppColors.danger,
                              value: '${stats['scamsBlocked']}',
                              label: AppTranslations.get(lang, 'scams_blocked'),
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

              // Recent Alerts Header
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

              // Recent Alerts List
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
                                    builder: (_) => ScamAlertScreen(alert: alert),
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
