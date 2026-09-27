import 'package:flutter/material.dart';
import '../models/scam_model.dart';
import '../utils/app_theme.dart';

class AlertCard extends StatelessWidget {
  final ScamModel alert;
  final VoidCallback? onTap;

  const AlertCard({super.key, required this.alert, this.onTap});

  @override
  Widget build(BuildContext context) {
    final riskColor = _getRiskColor(alert.verdictState, alert.confidence);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(color: riskColor, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            alert.sender,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (alert.isAiEnhanced) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome, size: 11, color: Color(0xFF2563EB)),
                                SizedBox(width: 3),
                                Text(
                                  'AI',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: riskColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${alert.confidence}%',
                      style: TextStyle(
                        color: riskColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                alert.message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              if (alert.flags.isNotEmpty || alert.verdictState == VerdictState.unknown) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _buildFlagChips(alert),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFlagChips(ScamModel alert) {
    final chips = <Widget>[];
    
    switch (alert.verdictState) {
      case VerdictState.highRisk:
        chips.add(const _FlagChip(
          label: 'High Risk',
          color: AppColors.danger,
          icon: Icons.warning_rounded,
        ));
        break;
      case VerdictState.suspicious:
        chips.add(const _FlagChip(
          label: 'Suspicious',
          color: AppColors.warning,
          icon: Icons.info_outline,
        ));
        break;
      case VerdictState.lowRisk:
        chips.add(const _FlagChip(
          label: 'Low Risk',
          color: Color(0xFF0284C7),
          icon: Icons.shield_outlined,
        ));
        break;
      case VerdictState.unknown:
        chips.add(const _FlagChip(
          label: 'Signal Conflict',
          color: Color(0xFF7C3AED),
          icon: Icons.shuffle,
        ));
        break;
      case VerdictState.safe:
        chips.add(const _FlagChip(
          label: 'Safe',
          color: AppColors.safe,
          icon: Icons.check_circle_outline,
        ));
        break;
    }

    // Take first 2 flags as short tag labels
    for (final flag in alert.flags.take(2)) {
      chips.add(_FlagChip(
        label: _shortenFlag(flag),
        color: AppColors.textSecondary,
      ));
    }
    return chips;
  }

  String _shortenFlag(String flag) {
    if (flag.contains('OTP') || flag.contains('otp')) return 'OTP Demand';
    if (flag.contains('USSD')) return 'USSD Trap';
    if (flag.contains('Phishing') || flag.contains('clone')) return 'Phishing Domain';
    if (flag.contains('Impersonat') || flag.contains('impersonat')) return 'Impersonation';
    if (flag.contains('refund') || flag.contains('Refund')) return 'Fake Refund';
    if (flag.contains('lottery') || flag.contains('prize') || flag.contains('Prize')) return 'Prize Claim';
    if (flag.contains('Urgency') || flag.contains('urgency')) return 'Urgency Pressure';
    if (flag.contains('link') || flag.contains('Link')) return 'Suspicious Link';
    if (flag.contains('Community') || flag.contains('reputation')) return 'Community Flag';
    return flag.length > 20 ? '${flag.substring(0, 18)}…' : flag;
  }

  Color _getRiskColor(VerdictState state, int confidence) {
    if (state == VerdictState.unknown) return const Color(0xFF7C3AED);
    if (confidence >= 70) return AppColors.danger;
    if (confidence >= 40) return AppColors.warning;
    if (confidence >= 20) return const Color(0xFF0284C7);
    return AppColors.safe;
  }
}

class _FlagChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _FlagChip({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final Color bgColor;

  const StatCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: iconColor,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: iconColor.withValues(alpha: 0.75),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
