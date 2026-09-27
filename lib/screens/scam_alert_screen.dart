import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/scam_model.dart';
import '../utils/app_theme.dart';
import '../utils/app_translations.dart';
import '../providers/scam_provider.dart';
import '../services/gemini_service.dart';

class ScamAlertScreen extends StatefulWidget {
  final ScamModel alert;

  const ScamAlertScreen({super.key, required this.alert});

  @override
  State<ScamAlertScreen> createState() => _ScamAlertScreenState();
}

class _ScamAlertScreenState extends State<ScamAlertScreen> {
  bool _isExplaining = false;

  ScamModel get alert => widget.alert;

  Future<void> _showAiExplanation(BuildContext context, String lang, bool allowCloudAi) async {
    setState(() => _isExplaining = true);

    final explanation = await GeminiService.explainAlert(
      message: alert.message,
      sender: alert.sender,
      detectedFlags: alert.flags,
      confidence: alert.confidence,
      language: lang,
      allowCloudAnalysis: allowCloudAi,
    );

    if (!mounted) return;

    setState(() => _isExplaining = false);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        minChildSize: 0.35,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.safe, AppColors.primary],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    lang == 'Amharic' ? 'AI ማብራሪያ' : 'AI Explanation',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                lang == 'Amharic' ? 'በ Gemini AI ይሠጠዋል' : 'Powered by Gemini 3.5 Flash',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.safe,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  explanation,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                lang == 'Amharic'
                    ? '⚠️ AI ምክር ነው — ለትክክለኛ ማረጋገጫ ወደ ባንክዎ ይደውሉ።'
                    : '⚠️ This is AI advice — always verify with your bank directly.',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey[500]!,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScamProvider>();
    final lang = provider.currentLanguage;
    final allowCloudAi = provider.allowCloudAiAnalysis;
    final riskColor = _getRiskColor(alert.verdictState, alert.confidence);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Top Header Band
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 24,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  riskColor,
                  riskColor.withValues(alpha: 0.85),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _translateVerdict(lang, alert.verdictState),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _getVerdictIcon(alert.verdictState),
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
                            _translateClassification(lang, alert.classification),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${alert.confidence}% Risk Score (${alert.riskLevel})',
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Scrollable Content Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Actual Sender & Claimed Org Card
                  Container(
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
                                color: riskColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.phone_android_rounded,
                                color: riskColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppTranslations.get(lang, 'actual_sender'),
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  Text(
                                    alert.sender,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (alert.claimedOrganization != null) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.business_rounded,
                                  size: 18, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                AppTranslations.get(lang, 'claims_to_be'),
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary),
                              ),
                              Text(
                                alert.claimedOrganization!,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Recommended Action Banner
                  if (alert.recommendedAction != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.shield_outlined,
                              color: AppColors.warningDark, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppTranslations.get(lang, 'recommended_action'),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.warningDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  alert.recommendedAction!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Message Body Preview
                  Text(
                    AppTranslations.get(lang, 'message_content'),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: SelectableText(
                      '"${alert.message}"',
                      style: GoogleFonts.robotoMono(
                        fontSize: 13,
                        height: 1.6,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Explainable Decision Factors (Evidence Signals)
                  if (alert.evidence.isNotEmpty) ...[
                    Text(
                      'EXPLAINABLE EVIDENCE BREAKDOWN',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...alert.evidence.map((sig) => _buildEvidenceItem(sig)),
                    const SizedBox(height: 16),
                  ],

                  // Red Flags / Warnings
                  if (alert.flags.isNotEmpty) ...[
                    Text(
                      AppTranslations.get(lang, 'detection_evidence'),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...alert.flags.map((flag) => _buildFlagItem(flag)),
                  ],

                  const SizedBox(height: 28),

                  // ✨ AI Explain Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isExplaining
                          ? null
                          : () => _showAiExplanation(context, lang, allowCloudAi),
                      icon: _isExplaining
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.safe,
                              ),
                            )
                          : const Icon(
                              Icons.auto_awesome_rounded,
                              size: 18,
                            ),
                      label: Text(
                        _isExplaining
                            ? (lang == 'Amharic' ? 'AI እየተጠየቀ ነው...' : 'Asking AI...')
                            : (lang == 'Amharic' ? '✨ AI ያብራራ' : '✨ Explain with AI'),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.safe,
                        side: const BorderSide(color: AppColors.safe),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // User Feedback Loop
                  Text(
                    'USER FEEDBACK & ACCURACY',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            if (alert.id != null) {
                              await provider.recordUserFeedback(alert.id!, 'marked_safe');
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppTranslations.get(lang, 'marked_safe_msg')),
                                  backgroundColor: AppColors.safe,
                                ),
                              );
                              Navigator.pop(context);
                            }
                          },
                          icon: const Icon(Icons.check_circle_outline, size: 16),
                          label: const Text('Mark Safe'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.safe,
                            side: const BorderSide(color: AppColors.safe),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            if (alert.id != null) {
                              await provider.recordUserFeedback(alert.id!, 'wrong_detection');
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Feedback saved. Detection weight adjusted.'),
                                  backgroundColor: Color(0xFF0284C7),
                                ),
                              );
                              Navigator.pop(context);
                            }
                          },
                          icon: const Icon(Icons.edit_note, size: 16),
                          label: const Text('Wrong'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0284C7),
                            side: const BorderSide(color: Color(0xFF0284C7)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (alert.id != null) {
                              await provider.recordUserFeedback(alert.id!, 'marked_scam');
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppTranslations.get(lang, 'reported_scam_msg')),
                                  backgroundColor: AppColors.danger,
                                ),
                              );
                              Navigator.pop(context);
                            }
                          },
                          icon: const Icon(Icons.flag_rounded, size: 16),
                          label: const Text('Is Scam'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceItem(EvidenceSignal signal) {
    final isMitigation = signal.isMitigation;
    final color = isMitigation ? AppColors.safe : AppColors.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              signal.formattedImpact,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  signal.layerName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  signal.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlagItem(String flag) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.dangerLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.report_problem_rounded,
                size: 16, color: AppColors.danger),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              flag,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _translateVerdict(String lang, VerdictState state) {
    switch (state) {
      case VerdictState.highRisk:
        return lang == 'Amharic' ? 'ከፍተኛ ስጋት' : 'HIGH RISK';
      case VerdictState.suspicious:
        return lang == 'Amharic' ? 'አጠራጣሪ' : 'SUSPICIOUS';
      case VerdictState.lowRisk:
        return lang == 'Amharic' ? 'ዝቅተኛ ስጋት' : 'LOW RISK';
      case VerdictState.unknown:
        return lang == 'Amharic' ? 'ግጭት ያለበት' : 'CONFLICT';
      case VerdictState.safe:
        return lang == 'Amharic' ? 'ደህንነቱ የተጠበቀ' : 'SAFE';
    }
  }

  String _translateClassification(String lang, String rawClassification) {
    final clean = rawClassification.toUpperCase().replaceAll('_', ' ');
    if (lang == 'Amharic') {
      if (clean.contains('IMPERSONATION')) return 'አስመሳይ ማጭበርበር';
      if (clean.contains('SCAM')) return 'ማጭበርበር';
      if (clean.contains('HIGH RISK')) return 'ከፍተኛ ስጋት';
      if (clean.contains('SUSPICIOUS')) return 'አጠራጣሪ';
      if (clean.contains('OFFICIAL')) return 'ትክክለኛ አገልጋይ';
      if (clean.contains('NORMAL')) return 'መደበኛ';
      if (clean.contains('LOW RISK')) return 'ዝቅተኛ ስጋት';
    }
    return clean;
  }

  IconData _getVerdictIcon(VerdictState state) {
    switch (state) {
      case VerdictState.highRisk:
        return Icons.gpp_bad_rounded;
      case VerdictState.suspicious:
        return Icons.warning_amber_rounded;
      case VerdictState.lowRisk:
        return Icons.shield_outlined;
      case VerdictState.unknown:
        return Icons.shuffle;
      case VerdictState.safe:
        return Icons.verified_user_rounded;
    }
  }

  Color _getRiskColor(VerdictState state, int confidence) {
    if (state == VerdictState.unknown) return const Color(0xFF7C3AED);
    if (confidence >= 70) return AppColors.danger;
    if (confidence >= 40) return AppColors.warning;
    if (confidence >= 20) return const Color(0xFF0284C7);
    return AppColors.safe;
  }
}
