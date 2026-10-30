/// Client-side Offline PromptPay QR Payload Generator
/// Compliant with EMVCo QR Code Specification and Bank of Thailand PromptPay Standard
/// Operates 100% offline without network requests!
class PromptPayService {
  static String formatTlv(String tag, String value) {
    final length = value.length.toString().padLeft(2, '0');
    return '$tag$length$value';
  }

  static String sanitizeTarget(String target) {
    return target.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Format phone (08x-xxx-xxxx -> 00668xxxxxxxx) or National ID (13 digits)
  static String formatPromptPayTarget(String target) {
    final cleaned = sanitizeTarget(target);
    if (cleaned.length == 10 && cleaned.startsWith('0')) {
      // Mobile Phone: 08x -> 00668x (13 chars)
      final international = '0066${cleaned.substring(1)}';
      return formatTlv('01', international.padLeft(13, '0'));
    } else if (cleaned.length == 13) {
      // National ID
      return formatTlv('02', cleaned);
    } else {
      // Fallback
      return formatTlv('01', cleaned.padLeft(13, '0'));
    }
  }

  /// Generate dynamic PromptPay QR payload string with amount
  static String generatePayload({
    required String promptpayId,
    required double amount,
  }) {
    final cleanTarget = formatPromptPayTarget(promptpayId);

    // Merchant Account Information (Tag 29)
    final aid = formatTlv('00', 'A000000677010111');
    final tag29Content = '$aid$cleanTarget';
    final tag29 = formatTlv('29', tag29Content);

    // Transaction Details
    final tag00 = formatTlv('00', '01'); // Payload Format Indicator
    final tag01 = formatTlv('01', '12'); // Dynamic QR (includes amount)
    final tag53 = formatTlv('53', '764'); // Currency THB (ISO 4217)
    final tag54 = formatTlv('54', amount.toStringAsFixed(2)); // Transaction Amount
    final tag58 = formatTlv('58', 'TH'); // Country Code

    final payloadWithoutCrc = '$tag00$tag01$tag29$tag53$tag54$tag58' '6304';
    final crc = calculateCrc16(payloadWithoutCrc);

    return '$payloadWithoutCrc$crc';
  }

  /// CRC16-CCITT (0x1021, init 0xFFFF)
  static String calculateCrc16(String input) {
    var crc = 0xFFFF;
    final bytes = input.codeUnits;

    for (var b in bytes) {
      crc ^= (b << 8);
      for (var i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }

    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }
}
