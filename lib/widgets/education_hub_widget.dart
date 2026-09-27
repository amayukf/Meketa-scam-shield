import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';

class EducationHubWidget extends StatelessWidget {
  const EducationHubWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A3A4A), Color(0xFF2C5F6E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cyber Threat Education Hub',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Learn how to identify fake receipts, phishing links, and SMS fraud',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 1: Golden Rules
          Text(
            '4 Golden Rules for Safety',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          _RuleCard(
            number: '1',
            title: 'Never Share OTP or PIN',
            description:
                'Bank and Ethio telecom staff will NEVER call or SMS you asking for your telebirr PIN, mobile banking password, or OTP code.',
            icon: Icons.lock_person_rounded,
            color: AppColors.danger,
          ),
          _RuleCard(
            number: '2',
            title: 'Check Official Sender Shortcodes',
            description:
                'Official notices come from 3-4 digit shortcodes (e.g. 127, 994, 889). If a message arrives from a 09... personal number claiming to be a bank, it is a scam.',
            icon: Icons.mark_email_read_rounded,
            color: AppColors.primary,
          ),
          _RuleCard(
            number: '3',
            title: 'Verify Payment in Your Official App',
            description:
                'Never deliver goods or services based on SMS alone. Open your official Telebirr or bank app to confirm your account balance actually increased.',
            icon: Icons.account_balance_wallet_rounded,
            color: AppColors.safe,
          ),
          _RuleCard(
            number: '4',
            title: 'Check Link Domains Carefully',
            description:
                'Official sites end in .et or official bank domains (ethiotelecom.et, telebirr.et, combanketh.et). Beware of fake domains like .xyz, .top, or telegram links.',
            icon: Icons.link_off_rounded,
            color: AppColors.warningDark,
          ),

          const SizedBox(height: 24),

          // Section 2: Official Shortcode Directory
          Text(
            'Official Bank & Telecom Directory',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: const [
                _DirectoryRow(
                  provider: 'Ethio telecom',
                  shortcodes: '994, 805, 806, 1994',
                  domain: 'ethiotelecom.et',
                ),
                Divider(height: 16),
                _DirectoryRow(
                  provider: 'telebirr',
                  shortcodes: '127, 6060, 128',
                  domain: 'telebirr.et',
                ),
                Divider(height: 16),
                _DirectoryRow(
                  provider: 'CBE (Commercial Bank)',
                  shortcodes: '889, 8899, 688',
                  domain: 'combanketh.et',
                ),
                Divider(height: 16),
                _DirectoryRow(
                  provider: 'Bank of Abyssinia',
                  shortcodes: '888, 8800',
                  domain: 'bankofabyssinia.com',
                ),
                Divider(height: 16),
                _DirectoryRow(
                  provider: 'Awash Bank',
                  shortcodes: '898, 8989',
                  domain: 'awashbank.com',
                ),
                Divider(height: 16),
                _DirectoryRow(
                  provider: 'Dashen Bank / Amoole',
                  shortcodes: '899, 8990',
                  domain: 'dashenbanksc.com',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _RuleCard({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$number. $title',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
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

class _DirectoryRow extends StatelessWidget {
  final String provider;
  final String shortcodes;
  final String domain;

  const _DirectoryRow({
    required this.provider,
    required this.shortcodes,
    required this.domain,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            provider,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            shortcodes,
            style: GoogleFonts.robotoMono(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            domain,
            textAlign: TextAlign.end,
            style: GoogleFonts.robotoMono(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
