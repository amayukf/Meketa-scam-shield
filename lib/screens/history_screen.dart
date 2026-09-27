import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/scam_provider.dart';
import '../utils/app_theme.dart';
import '../utils/app_translations.dart';
import '../widgets/alert_card.dart';
import 'scam_alert_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

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
        final alerts = provider.filteredAlerts;

        return SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.get(lang, 'history_title'),
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${alerts.length} alerts found',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Risk Summary Strip
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      _RiskBadge(
                        icon: Icons.dangerous_rounded,
                        iconColor: AppColors.danger,
                        bgColor: AppColors.dangerLight,
                        count: provider.highRiskCount,
                        label: AppTranslations.get(lang, 'high_risk'),
                      ),
                      const SizedBox(width: 14),
                      _RiskBadge(
                        icon: Icons.warning_rounded,
                        iconColor: AppColors.warning,
                        bgColor: AppColors.warningLight,
                        count: provider.mediumRiskCount,
                        label: AppTranslations.get(lang, 'medium_risk'),
                      ),
                      const SizedBox(width: 14),
                      _RiskBadge(
                        icon: Icons.check_box_rounded,
                        iconColor: AppColors.safe,
                        bgColor: AppColors.safeLight,
                        count: provider.safeCount,
                        label: AppTranslations.get(lang, 'safe'),
                      ),
                    ],
                  ),
                ),
              ),

              // Filter Chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: AppTranslations.get(lang, 'filter_today'),
                        value: 'today',
                        isSelected: provider.currentFilter == 'today',
                        onTap: () => provider.setFilter('today'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: AppTranslations.get(lang, 'filter_week'),
                        value: 'week',
                        isSelected: provider.currentFilter == 'week',
                        onTap: () => provider.setFilter('week'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: AppTranslations.get(lang, 'filter_month'),
                        value: 'month',
                        isSelected: provider.currentFilter == 'month',
                        onTap: () => provider.setFilter('month'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: AppTranslations.get(lang, 'filter_all'),
                        value: 'all',
                        isSelected: provider.currentFilter == 'all',
                        onTap: () => provider.setFilter('all'),
                      ),
                    ],
                  ),
                ),
              ),

              // Alert List
              alerts.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.sms_rounded,
                              size: 56,
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppTranslations.get(lang, 'no_messages'),
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              AppTranslations.get(lang, 'waiting_sms'),
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final alert = alerts[index];
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
                          childCount: alerts.length,
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

class _RiskBadge extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final int count;
  final String label;

  const _RiskBadge({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: iconColor,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: iconColor.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
