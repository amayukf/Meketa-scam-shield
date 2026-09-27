class OfficialOrganization {
  final String id;
  final String name;
  final String category;
  final Set<String> verifiedSenderIds;
  final List<String> officialDomains;
  final int baseTrustWeight; // e.g. -35 to -45

  const OfficialOrganization({
    required this.id,
    required this.name,
    required this.category,
    required this.verifiedSenderIds,
    required this.officialDomains,
    this.baseTrustWeight = -35,
  });
}

class ImpersonationCheck {
  final bool isImpersonation;
  final String? claimedOrgName;
  final String? claimedSenderId;
  final String? reason;
  final int riskWeight; // e.g. +45 to +60

  const ImpersonationCheck({
    required this.isImpersonation,
    this.claimedOrgName,
    this.claimedSenderId,
    this.reason,
    this.riskWeight = 0,
  });
}

class OfficialRegistry {
  static const List<OfficialOrganization> organizations = [
    OfficialOrganization(
      id: 'ethio_telecom',
      name: 'Ethio telecom',
      category: 'Telecom',
      verifiedSenderIds: {
        '994', '805', '806', '807', '990', '991', '1999', '1994', '822', '8994',
        '251994', 'ethiotelecom', 'ethio_telecom', 'ethio telecom', 'ethio'
      },
      officialDomains: ['ethiotelecom.et', 'telebirr.et'],
      baseTrustWeight: -40,
    ),
    OfficialOrganization(
      id: 'telebirr',
      name: 'telebirr',
      category: 'Mobile Financial',
      verifiedSenderIds: {'127', '6060', '128', 'telebirr'},
      officialDomains: ['telebirr.et', 'ethiotelecom.et'],
      baseTrustWeight: -45,
    ),
    OfficialOrganization(
      id: 'cbe',
      name: 'Commercial Bank of Ethiopia (CBE)',
      category: 'Banking',
      verifiedSenderIds: {'889', '8899', '688', 'cbe', 'cbebirr', 'cbe_birr', 'cbe birr'},
      officialDomains: ['combanketh.et'],
      baseTrustWeight: -45,
    ),
    OfficialOrganization(
      id: 'dashen',
      name: 'Dashen Bank / Amole',
      category: 'Banking',
      verifiedSenderIds: {'899', '8990', 'dashen', 'dashenbank', 'dashen_bank', 'amole', 'amoole'},
      officialDomains: ['dashenbanksc.com'],
      baseTrustWeight: -40,
    ),
    OfficialOrganization(
      id: 'abyssinia',
      name: 'Bank of Abyssinia',
      category: 'Banking',
      verifiedSenderIds: {'888', '8800', 'abyssinia', 'bankofabyssinia', 'boa'},
      officialDomains: ['bankofabyssinia.com'],
      baseTrustWeight: -40,
    ),
    OfficialOrganization(
      id: 'awash',
      name: 'Awash Bank',
      category: 'Banking',
      verifiedSenderIds: {'898', '8989', 'awash', 'awashbank', 'awash_bank', 'awash bank'},
      officialDomains: ['awashbank.com'],
      baseTrustWeight: -40,
    ),
    OfficialOrganization(
      id: 'coop',
      name: 'Cooperative Bank of Oromia',
      category: 'Banking',
      verifiedSenderIds: {'844', '8444', 'coop', 'coopbank', 'coopbankoromia', 'coopay'},
      officialDomains: ['coopbankoromia.com.et'],
      baseTrustWeight: -40,
    ),
    OfficialOrganization(
      id: 'zemen',
      name: 'Zemen Bank',
      category: 'Banking',
      verifiedSenderIds: {'883', 'zemen', 'zemenbank', 'zemen_bank'},
      officialDomains: ['zemenbank.com'],
      baseTrustWeight: -40,
    ),
    OfficialOrganization(
      id: 'hibret',
      name: 'Hibret Bank',
      category: 'Banking',
      verifiedSenderIds: {'884', 'hibret', 'hibretbank', 'hibret_bank'},
      officialDomains: ['hibretbank.com.et'],
      baseTrustWeight: -40,
    ),
    OfficialOrganization(
      id: 'nib',
      name: 'Nib International Bank',
      category: 'Banking',
      verifiedSenderIds: {'886', 'nib', 'nibbank', 'nib_bank'},
      officialDomains: ['nibbank.com.et'],
      baseTrustWeight: -40,
    ),
    OfficialOrganization(
      id: 'wegagen',
      name: 'Wegagen Bank',
      category: 'Banking',
      verifiedSenderIds: {'866', 'wegagen', 'wegagenbank'},
      officialDomains: ['wegagen.com'],
      baseTrustWeight: -40,
    ),
    OfficialOrganization(
      id: 'fayda',
      name: 'Fayda National ID',
      category: 'Government ID',
      verifiedSenderIds: {'8888', '8080', 'fayda'},
      officialDomains: ['id.gov.et', 'fayda.et'],
      baseTrustWeight: -40,
    ),
    OfficialOrganization(
      id: 'immigration',
      name: 'Immigration & Citizenship Service',
      category: 'Government Service',
      verifiedSenderIds: {'8181', 'ics'},
      officialDomains: ['ics.gov.et', 'ethiopianpassportservices.gov.et'],
      baseTrustWeight: -40,
    ),
    OfficialOrganization(
      id: 'eservices',
      name: 'Government eServices',
      category: 'Government Service',
      verifiedSenderIds: {'808', 'eservices'},
      officialDomains: ['eservices.gov.et'],
      baseTrustWeight: -40,
    ),
    OfficialOrganization(
      id: 'ethiopian_airlines',
      name: 'Ethiopian Airlines',
      category: 'Aviation',
      verifiedSenderIds: {'ethiopian', 'ethiopianairlines', 'shebamiles'},
      officialDomains: ['ethiopianairlines.com'],
      baseTrustWeight: -35,
    ),
  ];

  static final RegExp _personalPattern = RegExp(r'^(9|7)\d{8}$');
  static final RegExp _shortcodePattern = RegExp(r'^\d{3,5}$');

  /// Standardize sender strings
  static String normalizeSender(String sender) {
    String s = sender.trim().replaceAll(RegExp(r'\s+'), '');
    if (s.startsWith('+')) s = s.substring(1);
    if (s.startsWith('251')) s = s.substring(3);
    s = s.replaceFirst(RegExp(r'^0+'), '');
    return s;
  }

  /// Return verified organization if the actual sender ID is in the registry
  static OfficialOrganization? getVerifiedOrganization(String sender) {
    final rawTrim = sender.trim();
    final lowerRaw = rawTrim.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final normalized = normalizeSender(sender);

    for (final org in organizations) {
      for (final id in org.verifiedSenderIds) {
        final idLower = id.toLowerCase().replaceAll(RegExp(r'\s+'), '');
        if (normalized == idLower || lowerRaw == idLower || rawTrim.toLowerCase() == id.toLowerCase()) {
          return org;
        }
      }
      if (lowerRaw.contains(org.id) || org.name.toLowerCase().replaceAll(RegExp(r'\s+'), '').contains(lowerRaw)) {
        return org;
      }
    }
    return null;
  }

  /// Check if a domain belongs to a verified official institution
  static bool isOfficialDomain(String domain) {
    final clean = domain.trim().toLowerCase();
    for (final org in organizations) {
      for (final d in org.officialDomains) {
        if (clean == d || clean.endsWith('.$d')) {
          return true;
        }
      }
    }
    return false;
  }

  /// Check if sender is a personal mobile number (Ethiopian 09... / 07... prefixes)
  static bool isPersonalNumber(String sender) {
    final normalized = normalizeSender(sender);
    return _personalPattern.hasMatch(normalized);
  }

  /// Check if actual sender vs message body creates an impersonation condition
  static ImpersonationCheck detectImpersonation(String sender, String message) {
    final verifiedOrg = getVerifiedOrganization(sender);

    // If actual sender is already verified official, it's NOT impersonation
    if (verifiedOrg != null) {
      return const ImpersonationCheck(isImpersonation: false);
    }

    final messageLower = message.toLowerCase();
    final normalizedSender = normalizeSender(sender);

    // 1. Check if message body explicitly prefixes with an official shortcode (e.g. "994 Dear customer...")
    for (final org in organizations) {
      for (final shortcode in org.verifiedSenderIds) {
        final bodyShortcodeMatch = RegExp('^\\s*\\b$shortcode\\b', caseSensitive: false).hasMatch(messageLower) ||
            RegExp('\\b$shortcode\\s+(dear|customer|package|account|your|ethio)', caseSensitive: false).hasMatch(messageLower);

        if (bodyShortcodeMatch && normalizedSender != shortcode) {
          return ImpersonationCheck(
            isImpersonation: true,
            claimedOrgName: org.name,
            claimedSenderId: shortcode,
            riskWeight: 55,
            reason: 'Official shortcode "$shortcode" placed in message body, but sender is "$sender"',
          );
        }
      }
    }

    // 2. Check if personal number claims official organization name or package notice text
    if (isPersonalNumber(sender) || _shortcodePattern.hasMatch(normalizedSender)) {
      final hasPackageKeywords = RegExp(
        r'(dear\s+customer|voice\s+from|monthly\s+from|mint\b|package|credited|voice\s+package|data\s+package|will\s+expire|expir\w+|ethio\s*telecom|telebirr)',
        caseSensitive: false,
      ).hasMatch(messageLower);

      if (hasPackageKeywords &&
          (messageLower.contains('dear customer') ||
              messageLower.contains('mint') ||
              messageLower.contains('voice') ||
              messageLower.contains('sms') ||
              messageLower.contains('gb') ||
              messageLower.contains('mb') ||
              messageLower.contains('birr'))) {
        return ImpersonationCheck(
          isImpersonation: true,
          claimedOrgName: 'Ethio telecom',
          riskWeight: 50,
          reason: 'Personal mobile number sending official telecom package notification text',
        );
      }

      if (RegExp(r'\b(telebirr|tele\s*birr)\b', caseSensitive: false).hasMatch(messageLower) &&
          RegExp(r'(account|blocked|otp|pin|transfer|bonus|package|upgrade|restrict|received|credited)', caseSensitive: false).hasMatch(messageLower)) {
        return ImpersonationCheck(
          isImpersonation: true,
          claimedOrgName: 'telebirr',
          riskWeight: 55,
          reason: 'Personal sender pretending to send official telebirr transaction notice',
        );
      }

      if (RegExp(r'\b(cbe|cbebirr|commercial\s+bank|bank\s+of\s+abyssinia|dashen|awash|zemen)\b', caseSensitive: false).hasMatch(messageLower) &&
          RegExp(r'(account|blocked|otp|pin|transfer|win|birr|credited|debited)', caseSensitive: false).hasMatch(messageLower)) {
        return ImpersonationCheck(
          isImpersonation: true,
          claimedOrgName: 'Banking Service',
          riskWeight: 55,
          reason: 'Personal sender claiming official bank transfer / account status',
        );
      }
    }

    return const ImpersonationCheck(isImpersonation: false);
  }
}
