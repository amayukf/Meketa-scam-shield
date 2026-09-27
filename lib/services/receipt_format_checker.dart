class FormatCheckResult {
  final String provider;
  final String referenceNumber;
  final bool formatValid;
  final String reason;
  final String? officialUrl;

  const FormatCheckResult({
    required this.provider,
    required this.referenceNumber,
    required this.formatValid,
    required this.reason,
    this.officialUrl,
  });
}

class ReceiptFormatChecker {
  /// Confirmed public online verification URL for Telebirr only
  static const String _telebirrBaseUrl =
      'https://transactioninfo.ethiotelecom.et/receipt/';

  static FormatCheckResult check(String rawInput) {
    String cleanInput = rawInput.trim();
    if (cleanInput.isEmpty) {
      return const FormatCheckResult(
        provider: 'Unknown',
        referenceNumber: '',
        formatValid: false,
        reason: 'Reference number or URL cannot be empty.',
        officialUrl: null,
      );
    }

    // Extract reference ID if user pasted a full Telebirr URL
    if (cleanInput.contains('transactioninfo.ethiotelecom.et/receipt/')) {
      final uri = Uri.tryParse(cleanInput);
      if (uri != null && uri.pathSegments.isNotEmpty) {
        cleanInput = uri.pathSegments.last.trim();
      }
    }

    final ref = cleanInput.toUpperCase();

    // 1. Telebirr Format Check (10 alphanumeric characters)
    if (RegExp(r'^[A-Z0-9]{10}$').hasMatch(ref)) {
      return FormatCheckResult(
        provider: 'Telebirr',
        referenceNumber: ref,
        formatValid: true,
        reason: 'Matches Telebirr\'s standard 10-character reference format.',
        officialUrl: '$_telebirrBaseUrl$ref',
      );
    }

    // 2. Commercial Bank of Ethiopia (CBE) Format Check (Starts with FT...)
    if (RegExp(r'^FT[A-Z0-9]{10,14}$').hasMatch(ref)) {
      return FormatCheckResult(
        provider: 'Commercial Bank of Ethiopia (CBE)',
        referenceNumber: ref,
        formatValid: true,
        reason:
            'Matches Commercial Bank of Ethiopia\'s FT reference code structure.',
        officialUrl: 'https://combanketh.et',
      );
    }

    // 3. Bank of Abyssinia (BOA) Format Check (Starts with BOA or BA)
    if (RegExp(r'^(BOA|BA)[A-Z0-9]{8,14}$').hasMatch(ref)) {
      return FormatCheckResult(
        provider: 'Bank of Abyssinia',
        referenceNumber: ref,
        formatValid: true,
        reason: 'Matches Bank of Abyssinia reference code pattern.',
        officialUrl: 'https://www.bankofabyssinia.com',
      );
    }

    // 4. Awash Bank Format Check (Starts with AW|AWB|TT)
    if (RegExp(r'^(AW|AWB|TT)[A-Z0-9]{8,18}$').hasMatch(ref)) {
      return FormatCheckResult(
        provider: 'Awash Bank',
        referenceNumber: ref,
        formatValid: true,
        reason: 'Matches Awash Bank transaction reference structure.',
        officialUrl: 'https://awashbank.com',
      );
    }

    // 5. Dashen Bank / Amoole Format Check (Starts with DASH or DS)
    if (RegExp(r'^(DASH|DS)[A-Z0-9]{8,14}$').hasMatch(ref)) {
      return FormatCheckResult(
        provider: 'Dashen Bank',
        referenceNumber: ref,
        formatValid: true,
        reason: 'Matches Dashen Bank transaction reference format.',
        officialUrl: 'https://dashenbanksc.com',
      );
    }

    // Unrecognized format
    return FormatCheckResult(
      provider: 'Unrecognized',
      referenceNumber: ref,
      formatValid: false,
      reason:
          'Does not match any known Ethiopian bank or telecom reference format — likely fabricated.',
      officialUrl: null,
    );
  }
}
