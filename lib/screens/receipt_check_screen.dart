import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/odit_verify_service.dart';
import '../utils/app_theme.dart';

class ReceiptCheckScreen extends StatefulWidget {
  const ReceiptCheckScreen({super.key});

  @override
  State<ReceiptCheckScreen> createState() => _ReceiptCheckScreenState();
}

class _ReceiptCheckScreenState extends State<ReceiptCheckScreen> {
  final TextEditingController _txController = TextEditingController();
  final TextEditingController _accController = TextEditingController();

  String _selectedProvider = 'Telebirr';
  bool _isChecking = false;
  bool _showRawJson = false;

  static const List<Map<String, dynamic>> _providers = [
    {
      'id': 'Telebirr',
      'name': 'Telebirr',
      'sub': 'Ethio Telecom',
      'color': Color(0xFF00A859),
      'lightColor': Color(0xFFE6F7EE),
      'icon': Icons.phone_android_rounded,
      'sample': 'DHB6P39JIC',
      'hint': 'e.g. DHB6P39JIC',
    },
    {
      'id': 'CBE',
      'name': 'CBE',
      'sub': 'Commercial Bank',
      'color': Color(0xFF722575),
      'lightColor': Color(0xFFF6EBF7),
      'icon': Icons.account_balance_rounded,
      'sample': 'FT24081190342',
      'hint': 'e.g. FT24081190342',
    },
    {
      'id': 'BOA',
      'name': 'Abyssinia',
      'sub': 'Bank of Abyssinia',
      'color': Color(0xFFC69214),
      'lightColor': Color(0xFFFEF9E7),
      'icon': Icons.account_balance_wallet_rounded,
      'sample': 'BOA829104',
      'hint': 'e.g. BOA829104',
    },
    {
      'id': 'Awash',
      'name': 'Awash',
      'sub': 'AwashPay',
      'color': Color(0xFFE8862B),
      'lightColor': Color(0xFFFEF3E9),
      'icon': Icons.payments_rounded,
      'sample': 'AW910238',
      'hint': 'e.g. AW910238',
    },
    {
      'id': 'Zemen',
      'name': 'Zemen',
      'sub': 'Zemen Bank',
      'color': Color(0xFFB41E40),
      'lightColor': Color(0xFFFDECEF),
      'icon': Icons.credit_card_rounded,
      'sample': 'ZM748192',
      'hint': 'e.g. ZM748192',
    },
    {
      'id': 'URL',
      'name': 'Direct URL',
      'sub': 'Paste Link',
      'color': Color(0xFF2563EB),
      'lightColor': Color(0xFFEFF6FF),
      'icon': Icons.link_rounded,
      'sample': 'https://transactioninfo.ethiotelecom.et/receipt/DHB6P39JIC',
      'hint': 'Paste verification web URL',
    },
  ];

  @override
  void dispose() {
    _txController.dispose();
    _accController.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _currentProviderData {
    return _providers.firstWhere(
      (p) => p['id'] == _selectedProvider,
      orElse: () => _providers.first,
    );
  }

  Future<void> _handleVerify() async {
    final input = _txController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a transaction reference or receipt URL',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isChecking = true);

    try {
      final result = await OditVerifyService.verify(
        input,
        selectedProvider: _selectedProvider,
        accountSuffix: _accController.text.trim(),
      );

      if (mounted) {
        setState(() => _isChecking = false);
        _showResultModal(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isChecking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification error: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text != null && data!.text!.isNotEmpty) {
        setState(() {
          _txController.text = data.text!.trim();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pasted: ${_txController.text}', style: GoogleFonts.poppins(fontSize: 12)),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (_) {}
  }

  void _showResultModal(OditVerifyResult result) {
    setState(() => _showRawJson = false);

    final providerColor = _currentProviderData['color'] as Color;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: Container(
                  height: MediaQuery.of(ctx).size.height * 0.88,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 24,
                        offset: Offset(0, -6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Modal Drag Handle
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),

                      // Header with Close
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: result.ok ? const Color(0xFFE6F7EE) : const Color(0xFFFDECEF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    result.ok ? Icons.verified_rounded : Icons.error_outline_rounded,
                                    color: result.ok ? const Color(0xFF00A859) : const Color(0xFFDC2626),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  result.ok ? 'OFFICIAL VERIFIED RECEIPT' : 'VERIFICATION FAILED',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: result.ok ? const Color(0xFF00A859) : const Color(0xFFDC2626),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.grey),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 1),

                      // Content Body
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Duplicate Scan Alert Banner
                              if (result.isDuplicate) ...[
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFBEB),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309), size: 22),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '⚠️ DUPLICATE RECEIPT SCANNED',
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF92400E),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFDE68A),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Scan #${result.timesChecked}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF78350F),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'This receipt was previously checked on ${result.lastVerifiedAt ?? "earlier today"}. Beware of customers reusing old authentic receipts for new orders!',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: const Color(0xFF78350F),
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // Main Amount Card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      providerColor.withValues(alpha: 0.08),
                                      Colors.white,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: providerColor.withValues(alpha: 0.25)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Provider Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: providerColor,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.check_circle_outline, color: Colors.white, size: 14),
                                          const SizedBox(width: 6),
                                          Text(
                                            result.providerDisplayName,
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Large Total Amount
                                    Text(
                                      result.ok ? result.totalAmountFormatted : 'Unverified Receipt',
                                      style: GoogleFonts.poppins(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0F172A),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),

                                    // Status text
                                    Text(
                                      result.ok
                                          ? '✅ ${result.transactionStatus} • Real-time Upstream Match'
                                          : (result.error ?? 'Transaction reference not found at bank source.'),
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: result.ok ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),

                                    const SizedBox(height: 16),
                                    const Divider(height: 1),
                                    const SizedBox(height: 12),

                                    // Sub breakdown row (Settled + Fee)
                                    if (result.ok && result.feeFormatted.isNotEmpty) ...[
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Settled: ${result.settledAmountFormatted}',
                                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
                                          ),
                                          Text(
                                            'Fee: ${result.feeFormatted}',
                                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              const SizedBox(height: 18),

                              // Parties Card (Sender & Receiver)
                              if (result.ok) ...[
                                Text(
                                  'TRANSACTION PARTIES',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey[600],
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    children: [
                                      // Payer Row
                                      _buildPartyRow(
                                        icon: Icons.person_rounded,
                                        iconBg: const Color(0xFFE0E7FF),
                                        iconColor: const Color(0xFF4338CA),
                                        label: 'SENDER / PAYER (ላኪ)',
                                        name: result.payerName,
                                        account: result.payerAccount,
                                        badge: result.payerAccountType,
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 12),
                                        child: Divider(height: 1),
                                      ),
                                      // Receiver Row
                                      _buildPartyRow(
                                        icon: Icons.storefront_rounded,
                                        iconBg: const Color(0xFFDCFCE7),
                                        iconColor: const Color(0xFF15803D),
                                        label: 'RECEIVER / MERCHANT (ተቀባይ)',
                                        name: result.receiverName,
                                        account: result.receiverAccount,
                                        badge: result.branch.isNotEmpty ? result.branch : 'Verified Party',
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 18),

                                // Transaction Details & Verification Proof
                                Text(
                                  'TRANSACTION METADATA',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey[600],
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    children: [
                                      _buildDetailRow(
                                        'Reference Number',
                                        result.referenceNumber,
                                        isMono: true,
                                        canCopy: true,
                                      ),
                                      const Divider(height: 16),
                                      _buildDetailRow(
                                        'Payment Date & Time',
                                        result.paymentDateFormatted,
                                      ),
                                      const Divider(height: 16),
                                      _buildDetailRow(
                                        'Payment Purpose',
                                        result.paymentReason,
                                      ),
                                      const Divider(height: 16),
                                      _buildDetailRow(
                                        'Channel / Mode',
                                        result.paymentChannel,
                                      ),
                                      const Divider(height: 16),
                                      _buildDetailRow(
                                        'Upstream Source',
                                        result.sourceBadge,
                                      ),
                                      if (result.vatReceiptNo.isNotEmpty) ...[
                                        const Divider(height: 16),
                                        _buildDetailRow('VAT Receipt No', result.vatReceiptNo),
                                      ],
                                     ],
                                  ),
                                ),
                              ],

                              // Unverified / Upstream Rejection Card
                              if (!result.ok) ...[
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFFECACA)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.cancel_rounded, color: Color(0xFFDC2626), size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'UPSTREAM REJECTION / INVALID RECEIPT',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF991B1B),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        result.error ?? 'Transaction reference not found at bank source.',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF7F1D1D),
                                          height: 1.4,
                                        ),
                                      ),
                                      if (result.resolvedUrl.isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        Text(
                                          'Target URL queried: ${result.resolvedUrl}',
                                          style: GoogleFonts.robotoMono(
                                            fontSize: 10.5,
                                            color: const Color(0xFF991B1B),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 16),

                              // Raw Odit API Response Collapsible (Always Available)
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  children: [
                                    ListTile(
                                      title: Text(
                                        'Live Odit API Response JSON',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF334155),
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Real-time API response from v.odit.et',
                                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
                                      ),
                                      trailing: Icon(
                                        _showRawJson ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                                        color: const Color(0xFF334155),
                                      ),
                                      onTap: () {
                                        setModalState(() {
                                          _showRawJson = !_showRawJson;
                                        });
                                      },
                                    ),
                                    if (_showRawJson)
                                      Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0F172A),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: SelectableText(
                                          const JsonEncoder.withIndent('  ').convert(result.rawJson),
                                          style: GoogleFonts.robotoMono(
                                            fontSize: 11,
                                            color: const Color(0xFF38BDF8),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Action Buttons
                              Row(
                                children: [
                                  if (result.resolvedUrl.isNotEmpty) ...[
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          final uri = Uri.tryParse(result.resolvedUrl);
                                          if (uri != null && await canLaunchUrl(uri)) {
                                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                                          }
                                        },
                                        icon: const Icon(Icons.open_in_new_rounded, size: 16),
                                        label: Text(
                                          'Open Bank URL',
                                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: providerColor,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                  if (result.ok)
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          final summary =
                                              '✅ VERIFIED ETHIOPIAN RECEIPT\nProvider: ${result.providerDisplayName}\nReference: ${result.referenceNumber}\nAmount: ${result.totalAmountFormatted}\nPayer: ${result.payerName}\nReceiver: ${result.receiverName}\nDate: ${result.paymentDateFormatted}\nVerified via Scam Shield (Meketa)';
                                          Clipboard.setData(ClipboardData(text: summary));
                                          ScaffoldMessenger.of(ctx).showSnackBar(
                                            SnackBar(
                                              content: Text('Receipt summary copied to clipboard!', style: GoogleFonts.poppins(fontSize: 12)),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.copy_rounded, size: 16),
                                        label: Text(
                                          'Copy Summary',
                                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFF0F172A),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPartyRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String name,
    required String account,
    required String badge,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[500],
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              if (account.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  account,
                  style: GoogleFonts.robotoMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (badge.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badge,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isMono = false, bool canCopy = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: isMono
                  ? GoogleFonts.robotoMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    )
                  : GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
            ),
            if (canCopy) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Copied: $value', style: GoogleFonts.poppins(fontSize: 12)),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF64748B)),
              ),
            ],
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cur = _currentProviderData;
    final providerColor = cur['color'] as Color;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00A859).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: Color(0xFF00A859),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Receipt Verifier',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'የደረሰኝ ትክክለኛነት ማረጋገጫ',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F7EE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF059669)),
                  const SizedBox(width: 4),
                  Text(
                    'Odit Live API',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF065F46),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bank Selector Header
            Text(
              'SELECT BANK / NETWORK',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.grey[600],
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),

            // Compact & Responsive Bank Grid (Fixed Height 58px per card)
            LayoutBuilder(
              builder: (ctx, constraints) {
                final isWide = constraints.maxWidth > 480;
                final crossAxisCount = isWide ? 3 : 2;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    mainAxisExtent: 58,
                  ),
                  itemCount: _providers.length,
                  itemBuilder: (gridCtx, index) {
                    final p = _providers[index];
                    final isSelected = _selectedProvider == p['id'];
                    final color = p['color'] as Color;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedProvider = p['id'] as String;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? color : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? color : const Color(0xFFE2E8F0),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected ? color.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.02),
                              blurRadius: isSelected ? 6 : 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white.withValues(alpha: 0.2) : color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                p['icon'] as IconData,
                                size: 18,
                                color: isSelected ? Colors.white : color,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    p['name'] as String,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    p['sub'] as String,
                                    style: GoogleFonts.poppins(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected ? Colors.white.withValues(alpha: 0.85) : Colors.grey[500],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 16),

            // Form Verification Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
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
                      Text(
                        'Transaction Reference or URL',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      GestureDetector(
                        onTap: _pasteFromClipboard,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.paste_rounded, size: 14, color: Color(0xFF2563EB)),
                              const SizedBox(width: 4),
                              Text(
                                'Paste',
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Input Box
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _txController,
                            style: GoogleFonts.robotoMono(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                            decoration: InputDecoration(
                              hintText: cur['hint'] as String,
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),
                        if (_txController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                            onPressed: () => setState(() => _txController.clear()),
                          ),
                      ],
                    ),
                  ),

                  // Optional Account Suffix for CBE
                  if (_selectedProvider == 'CBE') ...[
                    const SizedBox(height: 12),
                    Text(
                      'Account Suffix (Last 4-8 digits)',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: TextField(
                        controller: _accController,
                        style: GoogleFonts.robotoMono(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'e.g. 8472 (Optional)',
                          hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Quick Test Samples
                  Text(
                    'Quick Test Samples:',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _providers.take(5).map((p) {
                      return ActionChip(
                        label: Text(
                          '${p['name']}: ${p['sample']}',
                          style: GoogleFonts.robotoMono(fontSize: 10.5, fontWeight: FontWeight.w600),
                        ),
                        avatar: Icon(p['icon'] as IconData, size: 13, color: p['color'] as Color),
                        backgroundColor: (p['color'] as Color).withValues(alpha: 0.08),
                        side: BorderSide(color: (p['color'] as Color).withValues(alpha: 0.25)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        onPressed: () {
                          setState(() {
                            _selectedProvider = p['id'] as String;
                            _txController.text = p['sample'] as String;
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 18),

                  // Verify CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isChecking ? null : _handleVerify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: providerColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isChecking
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Verifying at Official Source...',
                                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.shield_rounded, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Verify Receipt at Source',
                                  style: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // How it works info card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF334155)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Direct Upstream Egress Verification',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Powered by Odit Verify (v.odit.et). Queries Telebirr, CBE, Abyssinia, Awash, and Zemen directly over Ethiopian internet egress to guarantee 100% genuine transaction authenticity and detect fake SMS / Photoshop receipts.',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF475569),
                            height: 1.35,
                          ),
                        ),
                      ],
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
}
