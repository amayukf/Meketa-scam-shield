import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/odit_verify_service.dart';
import '../utils/app_theme.dart';
import '../widgets/receipt/receipt_provider_selector.dart';
import '../widgets/receipt/receipt_result_sheet.dart';

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
        HapticFeedback.lightImpact();
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
    ReceiptResultSheet.show(
      context,
      result,
      _currentProviderData['color'] as Color,
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

            ReceiptProviderSelector(
              providers: _providers,
              selectedProvider: _selectedProvider,
              onSelected: (p) {
                setState(() {
                  _selectedProvider = p;
                });
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
