import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/scam_provider.dart';
import '../utils/app_theme.dart';
import '../utils/app_translations.dart';
import '../widgets/alert_card.dart';
import 'scam_alert_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
        final rawAlerts = provider.filteredAlerts;

        final alerts = _searchQuery.isEmpty
            ? rawAlerts
            : rawAlerts.where((a) {
                final q = _searchQuery.toLowerCase();
                return a.message.toLowerCase().contains(q) ||
                    a.sender.toLowerCase().contains(q) ||
                    (a.claimedOrganization?.toLowerCase().contains(q) ?? false);
              }).toList();

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
                      const SizedBox(height: 12),

                      // Search bar
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: AppTranslations.get(lang, 'search_placeholder'),
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary.withValues(alpha: 0.7),
                            ),
                            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                    tooltip: 'Clear search',
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Risk Summary Strip
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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

              // Alert List with Dismissible & Undo
              alerts.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.sms_rounded,
                              size: 56,
                              color: AppColors.textSecondary.withValues(alpha: 0.3),
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
                                color: AppColors.textSecondary.withValues(alpha: 0.7),
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
                            return Dismissible(
                              key: Key('alert_${alert.id ?? index}'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.danger,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                              ),
                              onDismissed: (_) async {
                                final deletedAlert = alert;
                                await provider.deleteAlert(alert.id!);

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Alert deleted'),
                                      behavior: SnackBarBehavior.floating,
                                      action: SnackBarAction(
                                        label: AppTranslations.get(lang, 'undo'),
                                        onPressed: () {
                                          provider.analyzeAndSave(
                                            deletedAlert.message,
                                            deletedAlert.sender,
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: AlertCard(
                                alert: alert,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ScamAlertScreen(alert: alert),
                                    ),
                                  );
                                },
                              ),
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
    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Filter $label',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
