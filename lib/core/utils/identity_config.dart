// Identity document configuration per nationality (ISO 3166-1 alpha-2).

class IdentityConfig {
  const IdentityConfig({
    required this.type,
    required this.label,
    required this.regex,
    required this.example,
    required this.maxLength,
  });

  final String type;
  final String label;
  final String regex;
  final String example;
  final int maxLength;

  /// Returns true if [value] matches this config's regex (case-insensitive).
  bool validate(String value) =>
      RegExp(regex).hasMatch(value.toUpperCase().trim());
}

const Map<String, IdentityConfig> kIdentityConfig = {
  'MX': IdentityConfig(
    type: 'curp',
    label: 'CURP',
    regex:
        r'^[A-Z]{4}[0-9]{6}[HM][A-Z]{2}[B-DF-HJ-NP-TV-Z]{3}[A-Z0-9][0-9]$',
    example: 'LOOA530101HTCPBN02',
    maxLength: 18,
  ),
  'US': IdentityConfig(
    type: 'ssn',
    label: 'SSN',
    regex: r'^\d{3}-?\d{2}-?\d{4}$',
    example: '123-45-6789',
    maxLength: 11,
  ),
  'CO': IdentityConfig(
    type: 'cedula',
    label: 'Cédula de ciudadanía',
    regex: r'^\d{6,10}$',
    example: '1234567890',
    maxLength: 10,
  ),
  'GT': IdentityConfig(
    type: 'dpi',
    label: 'DPI / CUI',
    regex: r'^\d{13}$',
    example: '1234567890123',
    maxLength: 13,
  ),
  'HN': IdentityConfig(
    type: 'dni',
    label: 'DNI Honduras',
    regex: r'^\d{13}$',
    example: '0101199912345',
    maxLength: 13,
  ),
  'SV': IdentityConfig(
    type: 'dui',
    label: 'DUI',
    regex: r'^\d{8}-?\d$',
    example: '12345678-9',
    maxLength: 10,
  ),
  'ES': IdentityConfig(
    type: 'nie_nif',
    label: 'NIF / NIE',
    regex: r'^[A-Z0-9]{8,9}[A-Z]$',
    example: '12345678A',
    maxLength: 10,
  ),
};

/// Returns the [IdentityConfig] for [nationalityIso], or null for unmapped countries.
IdentityConfig? getIdentityConfig(String nationalityIso) =>
    kIdentityConfig[nationalityIso.toUpperCase()];
