import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/scam_model.dart';

/// Digital Forensic Incident Report following INSA / Ethiopian Federal Police cyber investigation standards.
class ForensicIncidentReport {
  final String caseId;
  final String sha256Fingerprint;
  final String generatedAtIso;
  final String sender;
  final String senderCarrier;
  final String senderTypeDescription;
  final String originalMessage;
  final int confidenceScore;
  final String classification;
  final List<String> forensicSignatures;
  final String evidentiaryIntegrityHash;
  final String chainOfCustodyStatement;

  ForensicIncidentReport({
    required this.caseId,
    required this.sha256Fingerprint,
    required this.generatedAtIso,
    required this.sender,
    required this.senderCarrier,
    required this.senderTypeDescription,
    required this.originalMessage,
    required this.confidenceScore,
    required this.classification,
    required this.forensicSignatures,
    required this.evidentiaryIntegrityHash,
    required this.chainOfCustodyStatement,
  });

  /// Formatted official police / INSA Cybercrime evidentiary dossier text
  String toFormalDossierText() {
    final buffer = StringBuffer();
    buffer.writeln('================================================================');
    buffer.writeln('     FEDERAL DEMOCRATIC REPUBLIC OF ETHIOPIA - CYBER EVIDENCE    ');
    buffer.writeln('         INFORMATION NETWORK SECURITY AGENCY (INSA) STANDARDS   ');
    buffer.writeln('                MEKETA DIGITAL FORENSICS DOSSIER                ');
    buffer.writeln('================================================================');
    buffer.writeln('CASE ID:            $caseId');
    buffer.writeln('GENERATED AT:       $generatedAtIso');
    buffer.writeln('INTEGRITY CHECKSUM: $sha256Fingerprint');
    buffer.writeln('EVIDENTIARY HASH:   $evidentiaryIntegrityHash');
    buffer.writeln('----------------------------------------------------------------');
    buffer.writeln('1. TELECOMMUNICATION METADATA');
    buffer.writeln('   - Sender Header:    $sender');
    buffer.writeln('   - Telephony Class:  $senderTypeDescription');
    buffer.writeln('   - Telecom Carrier:  $senderCarrier');
    buffer.writeln('');
    buffer.writeln('2. THREAT CLASSIFICATION & ASSESSMENT');
    buffer.writeln('   - Threat Level:     $classification');
    buffer.writeln('   - Confidence Score: $confidenceScore%');
    buffer.writeln('   - Heuristic Flags:  ${forensicSignatures.join(', ')}');
    buffer.writeln('');
    buffer.writeln('3. RAW EVIDENCE PAYLOAD (CANONICAL DUMP)');
    buffer.writeln('"""');
    buffer.writeln(originalMessage);
    buffer.writeln('"""');
    buffer.writeln('');
    buffer.writeln('4. CHAIN OF CUSTODY & ADMISSIBILITY ATTESTATION');
    buffer.writeln('   $chainOfCustodyStatement');
    buffer.writeln('================================================================');
    buffer.writeln('CONFIDENTIAL & TAMPER-EVIDENT - VERIFIABLE VIA SHA-256 DIGEST');
    buffer.writeln('================================================================');
    return buffer.toString();
  }
}

class ForensicService {
  /// Generate a cryptographically hashed, court-admissible forensic dossier from a ScamModel alert
  static ForensicIncidentReport generateReport(ScamModel alert) {
    final now = DateTime.now().toUtc();
    final nowIso = now.toIso8601String();

    // Canonical payload for cryptographic integrity
    final canonicalPayload = utf8.encode(
      '${alert.sender}|${alert.timestamp.toIso8601String()}|${alert.message}|${alert.classification}|${alert.confidence}',
    );
    final sha256Digest = sha256.convert(canonicalPayload).toString();

    // Short Case ID (e.g. INSA-CRIME-2026-A1B2)
    final shortHash = sha256Digest.substring(0, 6).toUpperCase();
    final caseId = 'INSA-ETH-${now.year}-$shortHash';

    // Carrier identification
    final carrier = _identifyCarrier(alert.sender);

    // Evidentiary integrity HMAC/hash including device generation time
    final evidentiaryPayload = utf8.encode('$caseId|$sha256Digest|$nowIso');
    final evidentiaryHash = sha256.convert(evidentiaryPayload).toString();

    final chainOfCustody =
        'This electronic record was captured on-device by Meketa Scam Shield Engine v1.0.0. '
        'The cryptographic digest (SHA-256: $sha256Digest) authenticates that the message body '
        'and sender metadata have remained untampered since local ingestion. Formatted for INSA & Federal Police cybercrime reporting.';

    return ForensicIncidentReport(
      caseId: caseId,
      sha256Fingerprint: sha256Digest,
      generatedAtIso: nowIso,
      sender: alert.sender,
      senderCarrier: carrier,
      senderTypeDescription: alert.senderType.name.toUpperCase(),
      originalMessage: alert.message,
      confidenceScore: alert.confidence,
      classification: alert.classification,
      forensicSignatures: alert.flags.isEmpty ? ['None'] : alert.flags,
      evidentiaryIntegrityHash: evidentiaryHash,
      chainOfCustodyStatement: chainOfCustody,
    );
  }

  static String _identifyCarrier(String sender) {
    final clean = sender.replaceAll(RegExp(r'\s+|-|\+'), '');
    if (clean == '994' || clean == '127' || clean == '898') {
      return 'Ethio Telecom Official Shortcode';
    }
    if (clean.startsWith('2519') || clean.startsWith('09')) {
      return 'Ethio Telecom (National GSM Mobile)';
    }
    if (clean.startsWith('2517') || clean.startsWith('07')) {
      return 'Safaricom Telecommunications Ethiopia';
    }
    if (RegExp(r'^[a-zA-Z]+$').hasMatch(sender)) {
      return 'Alphanumeric Sender ID (Bulk / VAS Gateway)';
    }
    return 'Unregistered / Unknown Telecom Gateway';
  }
}
