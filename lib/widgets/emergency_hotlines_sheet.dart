import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyHotline {
  final String name;
  final String nameAm;
  final String number;
  final String subtitle;
  final String subtitleAm;
  final IconData icon;
  final Color accentColor;

  const EmergencyHotline({
    required this.name,
    required this.nameAm,
    required this.number,
    required this.subtitle,
    required this.subtitleAm,
    required this.icon,
    required this.accentColor,
  });
}

class EmergencyHotlinesSheet extends StatelessWidget {
  final String lang;

  const EmergencyHotlinesSheet({super.key, required this.lang});

  static const List<EmergencyHotline> hotlines = [
    EmergencyHotline(
      name: 'Telebirr & Ethio Telecom',
      nameAm: 'ቴሌብር እና ኢትዮ ቴሌኮም',
      number: '994',
      subtitle: 'Unauthorized transfers, fake prize SMS, account lock',
      subtitleAm: 'ያልተፈቀደ ዝውውር፣ የሀሰት ስጦታ SMS፣ የቴሌብር እገዳ',
      icon: Icons.phone_android_rounded,
      accentColor: Color(0xFF10B981),
    ),
    EmergencyHotline(
      name: 'Commercial Bank of Ethiopia (CBE)',
      nameAm: 'የኢትዮጵያ ንግድ ባንክ (CBE)',
      number: '951',
      subtitle: 'Fake transfer alerts, unauthorized debits, fraud reports',
      subtitleAm: 'የሀሰት CBE ዝውውር SMS፣ ያልተፈቀደ ክፍያ፣ ማጭበርበር',
      icon: Icons.account_balance_rounded,
      accentColor: Color(0xFF8B5CF6),
    ),
    EmergencyHotline(
      name: 'Bank of Abyssinia (BoA)',
      nameAm: 'ባንክ ኦፍ አቢሲኒያ',
      number: '8397',
      subtitle: 'Apollo mobile banking security & fraud hotline',
      subtitleAm: 'የአፖሎ ሞባይል ባንኪንግ ደህንነት እና ጥቆማ',
      icon: Icons.savings_rounded,
      accentColor: Color(0xFFF59E0B),
    ),
    EmergencyHotline(
      name: 'Awash Bank (AwashBirr)',
      nameAm: 'አዋሽ ባንክ (አዋሽብር)',
      number: '8980',
      subtitle: 'Wallet fraud, transaction dispute & customer support',
      subtitleAm: 'የአዋሽብር ደህንነት፣ አጠራጣሪ ዝውውር እና የደንበኞች እርዳታ',
      icon: Icons.account_balance_wallet_rounded,
      accentColor: Color(0xFF3B82F6),
    ),
  ];

  static void show(BuildContext context, String lang) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF090D16),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => EmergencyHotlinesSheet(lang: lang),
    );
  }

  Future<void> _dialNumber(BuildContext context, String number) async {
    final uri = Uri.parse('tel:$number');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else if (context.mounted) {
        await _copyFallback(context, number);
      }
    } catch (_) {
      if (context.mounted) {
        await _copyFallback(context, number);
      }
    }
  }

  Future<void> _copyFallback(BuildContext context, String number) async {
    await Clipboard.setData(ClipboardData(text: number));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang == 'Amharic'
                ? '$number ወደ ስልክ ማውጫ ተቀድቷል'
                : '$number copied to clipboard',
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
          ),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAmharic = lang == 'Amharic';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.phone_in_talk_rounded,
                    color: Color(0xFFEF4444),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAmharic ? 'የድንገተኛ ማጭበርበር ሪፖርት መስመሮች' : 'Emergency Fraud Hotlines',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        isAmharic ? 'ቀጥታ ደውለው ያሳውቁ ወይም አካውንትዎን ያስግዱ' : 'One-tap dial to freeze your account or report scams',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Hotlines list
            ...hotlines.map((h) => _buildHotlineCard(context, h, isAmharic)),

            const SizedBox(height: 14),

            // Quick advice card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF131929),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF6366F1)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isAmharic
                          ? 'ሲደውሉ የማጭበርበሪያውን ስልክ ቁጥር እና የመልዕክቱን ሰዓት ያዘጋጁ። ባንኮች ወይም ቴሌብር ሚስጥራዊ የይለፍ ቃል (PIN/OTP) በስልክ አይጠይቁም።'
                          : 'Have the suspect phone number & SMS timestamp ready. Remember: Banks and Telebirr will NEVER ask for your PIN or OTP over the phone.',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white54,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotlineCard(BuildContext context, EmergencyHotline hotline, bool isAmharic) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _dialNumber(context, hotline.number),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: hotline.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hotline.accentColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Icon(
                    hotline.icon,
                    color: hotline.accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Name & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAmharic ? hotline.nameAm : hotline.name,
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAmharic ? hotline.subtitleAm : hotline.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Dial button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: hotline.accentColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: hotline.accentColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.call_rounded, size: 14, color: hotline.accentColor),
                      const SizedBox(width: 6),
                      Text(
                        hotline.number,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: hotline.accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
