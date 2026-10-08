import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';

class _Scenario {
  final String title;
  final String sender;
  final String message;
  final bool isScam;
  final String optimalAction; // 'block', 'verify', 'trust'
  final String explanation;
  final List<String> redFlags;

  const _Scenario({
    required this.title,
    required this.sender,
    required this.message,
    required this.isScam,
    required this.optimalAction,
    required this.explanation,
    required this.redFlags,
  });
}

class ScamSimulatorWidget extends StatefulWidget {
  const ScamSimulatorWidget({super.key});

  @override
  State<ScamSimulatorWidget> createState() => _ScamSimulatorWidgetState();
}

class _ScamSimulatorWidgetState extends State<ScamSimulatorWidget> {
  static const List<_Scenario> _scenarios = [
    _Scenario(
      title: 'Fake Telebirr Deposit Alert',
      sender: '0912345678',
      message: 'የ 1,500.00 ብር ዝውውር በተሳካ ሁኔታ ተፈጽሟል። ቀሪ ሂሳብዎ 2,340.50 ብር ነው። Trx ID: TB882910. ቴሌብር',
      isScam: true,
      optimalAction: 'block',
      explanation: 'ይህ የተለመደ የቴሌብር ማጭበርበር ነው። እውነተኛ የቴሌብር መልዕክት የሚላከው ከ 127 እንጂ ከ 10 ዲጂት የግል ስልክ ቁጥር (09...) አይደለም።',
      redFlags: ['Personal 09... sender', 'No bank ledger credit', 'Fake transaction formatting'],
    ),
    _Scenario(
      title: 'Urgent CBE Account Deactivation Bait',
      sender: 'CBE-ALERT',
      message: 'ውድ ደንበኛችን የ CBE አካውንትዎ በ 2 ሰዓት ውስጥ ይታገዳል። ለማደስ የላክነውን OTP የይለፍ ቃል መልሰው ይላኩልን።',
      isScam: true,
      optimalAction: 'block',
      explanation: 'ባንኮች በጭራሽ የይለፍ ቃል (OTP) በመልዕክት እንዲልኩ አይጠይቁም። የማስፈራሪያ ቃላት ("ይታገዳል") የማህበራዊ ምህንድስና (Social Engineering) ምልክት ነው።',
      redFlags: ['Demands OTP via SMS', 'Artificial urgency (2 hours)', 'Alphanumeric spoofed sender'],
    ),
    _Scenario(
      title: 'Legitimate Telecommunication Notification',
      sender: '994',
      message: 'ውድ ደንበኛችን የሳምንታዊ 1GB የኢንተርኔት ፓኬጅ ግዢዎ በተሳካ ሁኔታ ተጠናቋል። ቀሪ ሂሳብዎን በ *804# ይመልከቱ።',
      isScam: false,
      optimalAction: 'trust',
      explanation: 'ይህ ትክክለኛ የኢትዮ ቴሌኮም መልዕክት ነው። የተላከው ከዋናው አጭር ቁጥር 994 ሲሆን ምንም ዓይነት የይለፍ ቃል ወይም ውጫዊ ሊንክ አይጠይቅም።',
      redFlags: ['None - Verified Shortcode Whitelist'],
    ),
    _Scenario(
      title: 'Airtime Draining Lottery Bait',
      sender: '0922883344',
      message: 'እንኳን ደስ አለዎት! የ 50,000 ብር የቴሌብር እድለኛ ሆነዋል። ሽልማትዎን ለማረጋገጥ አሁኑኑ ወደ *804*0911223344*100# ይደውሉ።',
      isScam: true,
      optimalAction: 'block',
      explanation: 'አደገኛ ጥቃት! ኮዱ ወደ አጭበርባሪው 100 ብር የአየር ሰዓት የሚያስተላልፍ (*804*ቁጥር*ብር#) እንጂ ሽልማት የሚያስረክብ አይደለም።',
      redFlags: ['Malicious USSD airtime drain', 'Fake lottery reward', 'Zero prior lottery ticket'],
    ),
    _Scenario(
      title: 'BoA Transfer Receipt Verification',
      sender: '0933445566',
      message: 'የገዛሁትን እቃ ዋጋ 4,200 ብር በ Bank of Abyssinia አስገብቻለሁ። ደረሰኙን ይመልከቱ፡ https://cs.bankofabyssinia.com/slip/?trx=BOA99881',
      isScam: false,
      optimalAction: 'verify',
      explanation: 'ደንበኛው የባንክ ደረሰኝ ሊንክ ልኮልዎታል፤ ነገር ግን እቃውን ከመስጠትዎ በፊት ደረሰኙን በ "Receipt Verifier" ማረጋገጥ ወይም የባንክ ሂሳብዎን መፈተሽ አለብዎት።',
      redFlags: ['Requires transaction receipt check before releasing goods'],
    ),
  ];

  int _currentIndex = 0;
  int _score = 0;
  String? _selectedAction;
  bool _answered = false;

  void _handleChoice(String action) {
    if (_answered) return;
    final current = _scenarios[_currentIndex];
    final isCorrect = action == current.optimalAction;

    setState(() {
      _selectedAction = action;
      _answered = true;
      if (isCorrect) _score++;
    });
  }

  void _nextScenario() {
    setState(() {
      _answered = false;
      _selectedAction = null;
      _currentIndex = (_currentIndex + 1) % _scenarios.length;
    });
  }

  void _restart() {
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _answered = false;
      _selectedAction = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scenario = _scenarios[_currentIndex];
    final isCorrect = _selectedAction == scenario.optimalAction;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.psychology_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Defense Awareness Sandbox',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Challenge ${_currentIndex + 1} of ${_scenarios.length} • Score: $_score/$_scenarios.length',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _restart,
                  child: const Text('Reset', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Simulated Incoming SMS Card
          Text(
            'INCOMING TELECOM SMS SIMULATION',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.sms_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          scenario.sender,
                          style: GoogleFonts.robotoMono(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Just now',
                      style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Text(
                  scenario.message,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // User Decision Controls
          if (!_answered) ...[
            Text(
              'WHAT IS YOUR DEFENSIVE ACTION?',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleChoice('block'),
                    icon: const Icon(Icons.block_rounded, size: 18),
                    label: const Text('Block Scam'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleChoice('verify'),
                    icon: const Icon(Icons.verified_outlined, size: 18),
                    label: const Text('Verify'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleChoice('trust'),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Trust'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.safe,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Feedback Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCorrect ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCorrect ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: isCorrect ? AppColors.safe : AppColors.danger,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isCorrect ? 'Excellent Security Decision!' : 'Security Risk Overlooked!',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isCorrect ? const Color(0xFF166534) : const Color(0xFF991B1B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    scenario.explanation,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF334155),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: scenario.redFlags.map((flag) {
                      return Chip(
                        label: Text(flag, style: const TextStyle(fontSize: 10)),
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextScenario,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        _currentIndex + 1 == _scenarios.length ? 'Review Score' : 'Next Scenario →',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
