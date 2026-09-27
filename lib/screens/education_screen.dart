import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';

class EducationTopic {
  final String title;
  final String category;
  final IconData icon;
  final Color color;
  final String summary;
  final List<String> keyRules;

  EducationTopic({
    required this.title,
    required this.category,
    required this.icon,
    required this.color,
    required this.summary,
    required this.keyRules,
  });
}

class ScamEducationScreen extends StatelessWidget {
  const ScamEducationScreen({super.key});

  static final List<EducationTopic> _topics = [
    EducationTopic(
      title: 'Protecting Your OTP & Banking PIN',
      category: 'Credential Theft',
      icon: Icons.shield_rounded,
      color: const Color(0xFFD32F2F),
      summary:
          'Scammers call or text pretending to be CBE, Telebirr, or Awash Bank asking for your SMS verification code (OTP).',
      keyRules: [
        'NEVER share 4-digit or 6-digit OTP codes with anyone, even if they call from an "official" looking number.',
        'Banks and Ethio Telecom will NEVER ask for your PIN over phone call or SMS.',
        'If you receive an unsolicited OTP code, your account password may be compromised.',
      ],
    ),
    EducationTopic(
      title: 'Fake Ethio Telecom Package Offers',
      category: 'Impersonation',
      icon: Icons.cell_tower_rounded,
      color: const Color(0xFF1976D2),
      summary:
          'Impersonators text from personal mobile numbers (+251 9...) claiming you won or received cheap voice/data packages.',
      keyRules: [
        'Official package notifications ONLY arrive from shortcode "994" or "251994".',
        'Ethio Telecom never asks for money transfer via regular personal numbers.',
        'Always check your balance using *804# or telebirr App directly.',
      ],
    ),
    EducationTopic(
      title: 'Mistaken Transfer & Fake Refund Scam',
      category: 'Financial Fraud',
      icon: Icons.account_balance_wallet_rounded,
      color: const Color(0xFFED6C02),
      summary:
          'A scammer sends a fake Telebirr / SMS alert saying "I accidentally sent you 5,000 Birr, please return it".',
      keyRules: [
        'Do not rely on the text message. Log into your official Telebirr / CBE app to check actual balance.',
        'Look closely at the sender address: scammers use personal mobile numbers (+2519...) instead of shortcode "telebirr".',
        'Instruct the caller to deal directly with official customer service (*127# or 994).',
      ],
    ),
    EducationTopic(
      title: 'Phishing Links & Malicious URLs',
      category: 'Phishing',
      icon: Icons.link_off_rounded,
      color: const Color(0xFF9C27B0),
      summary:
          'Scammers send links like "bit.ly/cbe-bonus" or ".xyz" domain names to steal your login credentials.',
      keyRules: [
        'Never enter bank credentials or phone numbers on external links sent via SMS.',
        'Official Ethiopian telecom and bank apps are downloaded from official stores (Play Store / App Gallery).',
        'Use Scam Shield\'s Link Safety Checker before opening suspicious links.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Scam Education Center',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _topics.length,
        itemBuilder: (context, index) {
          final topic = _topics[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: topic.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(topic.icon, color: topic.color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topic.category.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: topic.color,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            topic.title,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  topic.summary,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Text(
                  'Safety Guide Rules:',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                ...topic.keyRules.map(
                  (rule) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.safe)),
                        Expanded(
                          child: Text(
                            rule,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
