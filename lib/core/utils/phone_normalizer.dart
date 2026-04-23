// Normalization utilities for phone numbers.

/// Legacy WhatsApp country adjustments.
/// MX mobile numbers require inserting '1' after +52 for WhatsApp routing.
const Map<String, Map<String, String>> kLegacyWaCountries = {
  'MX': {'insertDigit': '1', 'afterPrefix': '+52'},
};

const Map<String, String> _kDialCodes = {
  'MX': '+52',
  'US': '+1',
  'CO': '+57',
  'GT': '+502',
  'HN': '+504',
  'SV': '+503',
  'ES': '+34',
  'AR': '+54',
  'CL': '+56',
  'PE': '+51',
  'VE': '+58',
  'EC': '+593',
  'BO': '+591',
  'PY': '+595',
  'UY': '+598',
  'BR': '+55',
  'CA': '+1',
  'FR': '+33',
  'DE': '+49',
  'IT': '+39',
  'GB': '+44',
};

abstract class PhoneNormalizer {
  /// Returns the E.164 dial prefix for [countryCode], e.g. '+52' for 'MX'.
  static String dialCode(String countryCode) =>
      _kDialCodes[countryCode.toUpperCase()] ?? '+1';

  /// Combines [rawPhone] (local digits) with [countryCode]'s prefix to E.164.
  /// If [rawPhone] already starts with the country dial digits, avoids doubling.
  static String formatToE164(String rawPhone, String countryCode) {
    final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    final prefix = _kDialCodes[countryCode.toUpperCase()] ?? '+1';
    final prefixDigits = prefix.replaceAll('+', '');
    if (digits.startsWith(prefixDigits)) return '+$digits';
    return '$prefix$digits';
  }

  /// For MX: inserts '1' after +52 if missing (WhatsApp mobile requirement).
  static String toWhatsappFormat(String e164Phone) {
    const afterPrefix = '+52';
    const insertDigit = '1';
    if (e164Phone.startsWith(afterPrefix) &&
        !e164Phone.startsWith('$afterPrefix$insertDigit')) {
      return '$afterPrefix$insertDigit${e164Phone.substring(afterPrefix.length)}';
    }
    return e164Phone;
  }

  /// Converts an E.164 operator phone to WhatsApp chat_id format (no '+').
  /// E.g. "+52XXXXXXXXXX" → "521XXXXXXXXXX".
  static String toChatId(String e164Phone) {
    final withWa = toWhatsappFormat(e164Phone);
    return withWa.startsWith('+') ? withWa.substring(1) : withWa;
  }

  /// Returns null if [phone] is valid for [countryCode], or an error message.
  static String? validatePhone(String phone, String countryCode) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Teléfono requerido';
    if (digits.length < 7) return 'Número demasiado corto';
    if (digits.length > 15) return 'Número demasiado largo';
    return null;
  }

  /// Parses a raw phone string into (isoCode, localNumber).
  /// Tries known dial codes longest-first to avoid false prefix matches.
  static (String, String) parsePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    // Ordered by prefix length descending to avoid false matches (e.g. +1 vs +502)
    const ordered = [
      ('GT', '502'), ('HN', '504'), ('SV', '503'), ('EC', '593'),
      ('PY', '595'), ('UY', '598'), ('ES', '34'),  ('FR', '33'),
      ('DE', '49'),  ('IT', '39'),  ('GB', '44'),  ('CO', '57'),
      ('BR', '55'),  ('CL', '56'),  ('AR', '54'),  ('PE', '51'),
      ('VE', '58'),  ('BO', '591'), ('MX', '52'),  ('US', '1'),
    ];
    for (final (iso, code) in ordered) {
      if (digits.startsWith(code)) {
        return (iso, digits.substring(code.length));
      }
    }
    return ('MX', digits);
  }
}
