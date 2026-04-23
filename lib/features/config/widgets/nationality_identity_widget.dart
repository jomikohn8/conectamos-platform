import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/identity_config.dart';
import 'phone_field_widget.dart' show CountryPickerDialog, countryFlag;

// ── Nationality country list (broader than phone dial list) ───────────────────

const List<(String, String)> _kNationalityCountries = [
  ('MX', 'México'),
  ('US', 'Estados Unidos'),
  ('CO', 'Colombia'),
  ('GT', 'Guatemala'),
  ('HN', 'Honduras'),
  ('SV', 'El Salvador'),
  ('ES', 'España'),
  ('AR', 'Argentina'),
  ('CL', 'Chile'),
  ('PE', 'Perú'),
  ('VE', 'Venezuela'),
  ('EC', 'Ecuador'),
  ('BO', 'Bolivia'),
  ('PY', 'Paraguay'),
  ('UY', 'Uruguay'),
  ('BR', 'Brasil'),
  ('CA', 'Canadá'),
  ('FR', 'Francia'),
  ('DE', 'Alemania'),
  ('IT', 'Italia'),
  ('GB', 'Reino Unido'),
  ('CR', 'Costa Rica'),
  ('PA', 'Panamá'),
  ('NI', 'Nicaragua'),
  ('DO', 'República Dominicana'),
  ('CU', 'Cuba'),
  ('PR', 'Puerto Rico'),
  ('OTHER', 'Otro'),
];

// ── NationalityIdentityWidget ─────────────────────────────────────────────────

/// Displays a nationality selector and a conditional identity-number field
/// whose label, hint, and validation change according to the selected country.
/// If no mapping exists for the country, shows a free-text "Número de
/// identificación" field without regex validation.
class NationalityIdentityWidget extends StatefulWidget {
  const NationalityIdentityWidget({
    super.key,
    this.initialNationality,
    this.initialIdentityNumber,
    required this.onNationalityChanged,
    required this.onIdentityChanged,
  });

  final String? initialNationality;
  final String? initialIdentityNumber;
  final ValueChanged<String> onNationalityChanged;
  final ValueChanged<String> onIdentityChanged;

  @override
  State<NationalityIdentityWidget> createState() =>
      _NationalityIdentityWidgetState();
}

class _NationalityIdentityWidgetState
    extends State<NationalityIdentityWidget> {
  String _iso = '';
  late final TextEditingController _idCtrl;
  String? _idError;

  IdentityConfig? get _cfg =>
      _iso.isNotEmpty ? getIdentityConfig(_iso) : null;

  String get _idLabel {
    final cfg = _cfg;
    if (cfg != null) return cfg.label;
    if (_iso.isNotEmpty) return 'Número de identificación';
    return 'Número de identificación';
  }

  String get _idHint {
    final cfg = _cfg;
    if (cfg != null) return 'Ej: ${cfg.example}';
    return 'Número de documento';
  }

  int get _idMaxLength => _cfg?.maxLength ?? 30;

  @override
  void initState() {
    super.initState();
    _iso = widget.initialNationality ?? '';
    _idCtrl =
        TextEditingController(text: widget.initialIdentityNumber ?? '');
    _idCtrl.addListener(() => widget.onIdentityChanged(_idCtrl.text.trim()));
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    super.dispose();
  }

  void _validateId() {
    final cfg = _cfg;
    if (cfg == null || _idCtrl.text.trim().isEmpty) {
      setState(() => _idError = null);
      return;
    }
    final valid = cfg.validate(_idCtrl.text.trim());
    setState(() => _idError = valid
        ? null
        : 'Formato inválido · ejemplo: ${cfg.example}');
  }

  Future<void> _pickNationality() async {
    // Build (iso, name, '') tuples for CountryPickerDialog
    final list = _kNationalityCountries
        .map<(String, String, String)>((e) => (e.$1, e.$2, ''))
        .toList();

    final result = await showDialog<(String, String)>(
      context: context,
      builder: (ctx) => CountryPickerDialog(
        countries: list,
        selectedIso: _iso,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _iso = result.$1;
        _idError = null;
      });
      widget.onNationalityChanged(_iso);
      widget.onIdentityChanged(_idCtrl.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Nationality selector
        const Text(
          'Nacionalidad',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.ctText,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _pickNationality,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.ctSurface2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.ctBorder2),
              ),
              child: Row(
                children: [
                  if (_iso.isNotEmpty && _iso != 'OTHER') ...[
                    Text(countryFlag(_iso),
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      _iso.isEmpty
                          ? 'Seleccionar nacionalidad'
                          : (_kNationalityCountries
                                  .firstWhere((c) => c.$1 == _iso,
                                      orElse: () => (_iso, _iso))
                                  .$2),
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 13,
                        color: _iso.isEmpty
                            ? AppColors.ctText3
                            : AppColors.ctText,
                      ),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 14, color: AppColors.ctText3),
                ],
              ),
            ),
          ),
        ),

        // Identity number field (appears when nationality is selected)
        if (_iso.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            _idLabel,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.ctText,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _idCtrl,
            maxLength: _idMaxLength,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              LengthLimitingTextInputFormatter(_idMaxLength),
              FilteringTextInputFormatter.allow(
                  RegExp(r'[A-Za-z0-9\-]')),
            ],
            onEditingComplete: _validateId,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 13,
              color: AppColors.ctText,
            ),
            decoration: InputDecoration(
              hintText: _idHint,
              hintStyle: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 13,
                color: AppColors.ctText3,
              ),
              counterText: '',
              filled: true,
              fillColor: AppColors.ctSurface2,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _idError != null
                      ? AppColors.ctDanger
                      : AppColors.ctBorder2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _idError != null
                      ? AppColors.ctDanger
                      : AppColors.ctBorder2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _idError != null
                      ? AppColors.ctDanger
                      : AppColors.ctTeal,
                  width: 1.5,
                ),
              ),
            ),
          ),
          if (_idError != null) ...[
            const SizedBox(height: 3),
            Text(
              _idError!,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 11,
                color: AppColors.ctDanger,
              ),
            ),
          ],
        ],

        // Warning if no identity provided
        if (_iso.isEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 13, color: AppColors.ctText3),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Sin identificador no se pueden detectar duplicados',
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 11,
                    color: AppColors.ctText2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
