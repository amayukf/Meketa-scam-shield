import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/odit_verify_service.dart';

class ReceiptResultSheet extends StatefulWidget {
  final OditVerifyResult result;
  final Color providerColor;

  const ReceiptResultSheet({
    super.key,
    required this.result,
    required this.providerColor,
  });

  static void show(BuildContext context, OditVerifyResult result, Color providerColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReceiptResultSheet(
        result: result,
        providerColor: providerColor,
      ),
    );
  }

  @override
  State<ReceiptResultSheet> createState() => _ReceiptResultSheetState();
}

class _ReceiptResultSheetState extends State<ReceiptResultSheet> {
  bool _showRawJson = false;

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final providerColor = widget.providerColor;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.88,
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
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // Header bar
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
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Close result',
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
                            Text(
                              result.ok
                                  ? '✅ ${result.transactionStatus} • Real-time Upstream Match'
                                  : (result.error ?? 'Transaction reference not found at bank source.'),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: result.ok ? const Color(0xFF00A859) : const Color(0xFFDC2626),
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Details Section
                      if (result.ok) ...[
                        _buildDetailTile('Transaction ID / Ref', result.referenceNumber, isBold: true),
                        if (result.paymentDateFormatted.isNotEmpty)
                          _buildDetailTile('Transaction Date', result.paymentDateFormatted),
                        if (result.payerName.isNotEmpty)
                          _buildDetailTile('Payer / Sender', result.payerName),
                        if (result.receiverName.isNotEmpty)
                          _buildDetailTile('Recipient / Receiver', result.receiverName),
                        if (result.receiverAccount.isNotEmpty)
                          _buildDetailTile('Recipient Account', result.receiverAccount),
                        const SizedBox(height: 16),
                      ],

                      // Raw JSON Expandable Toggle
                      Center(
                        child: TextButton.icon(
                          onPressed: () => setState(() => _showRawJson = !_showRawJson),
                          icon: Icon(
                            _showRawJson ? Icons.unfold_less_rounded : Icons.code_rounded,
                            size: 16,
                            color: Colors.grey[700],
                          ),
                          label: Text(
                            _showRawJson ? 'Hide Raw Bank Payload' : 'View Raw Bank Payload',
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
                          ),
                        ),
                      ),
                      if (_showRawJson) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SelectableText(
                            const JsonEncoder.withIndent('  ').convert(result.rawJson),
                            style: GoogleFonts.firaCode(fontSize: 11, color: Colors.greenAccent),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailTile(String label, String value, {bool isBold = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
          Flexible(
            child: SelectableText(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
