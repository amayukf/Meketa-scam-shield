import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/scam_provider.dart';
import '../utils/app_theme.dart';
import '../utils/app_translations.dart';
import 'receipt_check_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.select<ScamProvider, String>((p) => p.currentLanguage);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTranslations.get(lang, 'settings_title'),
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Selector<ScamProvider, bool>(
              selector: (_, p) => p.notificationsEnabled,
              builder: (ctx, enabled, _) => _SettingsTile(
                icon: Icons.notifications_rounded,
                title: AppTranslations.get(lang, 'notifications'),
                subtitle: AppTranslations.get(lang, 'notif_sub'),
                trailing: Switch(
                  value: enabled,
                  onChanged: (v) => ctx.read<ScamProvider>().setNotificationsEnabled(v),
                  activeThumbColor: AppColors.safe,
                  activeTrackColor: AppColors.safe.withValues(alpha: 0.3),
                ),
              ),
            ),
            Selector<ScamProvider, bool>(
              selector: (_, p) => p.autoScanEnabled,
              builder: (ctx, enabled, _) => _SettingsTile(
                icon: Icons.shield_rounded,
                title: AppTranslations.get(lang, 'auto_scan'),
                subtitle: AppTranslations.get(lang, 'auto_scan_sub'),
                trailing: Switch(
                  value: enabled,
                  onChanged: (v) => ctx.read<ScamProvider>().setAutoScanEnabled(v),
                  activeThumbColor: AppColors.safe,
                  activeTrackColor: AppColors.safe.withValues(alpha: 0.3),
                ),
              ),
            ),
            Selector<ScamProvider, bool>(
              selector: (_, p) => p.allowCloudAiAnalysis,
              builder: (ctx, enabled, _) => _SettingsTile(
                icon: Icons.psychology_rounded,
                title: AppTranslations.get(lang, 'cloud_ai_privacy'),
                subtitle: AppTranslations.get(lang, 'cloud_ai_privacy_sub'),
                trailing: Switch(
                  value: enabled,
                  onChanged: (v) => ctx.read<ScamProvider>().setAllowCloudAiAnalysis(v),
                  activeThumbColor: AppColors.safe,
                  activeTrackColor: AppColors.safe.withValues(alpha: 0.3),
                ),
              ),
            ),
            _SettingsTile(
              icon: Icons.receipt_long_rounded,
              title: 'Transaction Receipt Verifier',
              subtitle: 'Verify live Telebirr, CBE, and bank receipts',
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ReceiptCheckScreen(),
                  ),
                );
              },
            ),
            _SettingsTile(
              icon: Icons.language_rounded,
              title: AppTranslations.get(lang, 'language'),
              subtitle: lang == 'Amharic'
                  ? 'አማርኛ (Amharic)'
                  : lang == 'Oromo'
                      ? 'Afaan Oromoo'
                      : 'English',
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    title: Text(AppTranslations.get(lang, 'select_lang')),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: const Text('English'),
                          trailing: lang == 'English'
                              ? const Icon(Icons.check_circle_rounded,
                                  color: AppColors.safe)
                              : null,
                          onTap: () {
                            context
                                .read<ScamProvider>()
                                .setLanguage('English');
                            Navigator.pop(dialogCtx);
                          },
                        ),
                        ListTile(
                          title: const Text('አማርኛ (Amharic)'),
                          trailing: lang == 'Amharic'
                              ? const Icon(Icons.check_circle_rounded,
                                  color: AppColors.safe)
                              : null,
                          onTap: () {
                            context
                                .read<ScamProvider>()
                                .setLanguage('Amharic');
                            Navigator.pop(dialogCtx);
                          },
                        ),
                        ListTile(
                          title: const Text('Afaan Oromoo'),
                          trailing: lang == 'Oromo'
                              ? const Icon(Icons.check_circle_rounded,
                                  color: AppColors.safe)
                              : null,
                          onTap: () {
                            context
                                .read<ScamProvider>()
                                .setLanguage('Oromo');
                            Navigator.pop(dialogCtx);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            _SettingsTile(
              icon: Icons.info_outline_rounded,
              title: AppTranslations.get(lang, 'about'),
              subtitle: AppTranslations.get(lang, 'about_sub'),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    title: Text(AppTranslations.get(lang, 'about')),
                    content: Text(AppTranslations.get(lang, 'about_body')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
            _SettingsTile(
              icon: Icons.privacy_tip_rounded,
              title: AppTranslations.get(lang, 'privacy'),
              subtitle: AppTranslations.get(lang, 'privacy_sub'),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    title: Text(AppTranslations.get(lang, 'privacy_policy_title')),
                    content: Text(AppTranslations.get(lang, 'privacy_policy_body')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
