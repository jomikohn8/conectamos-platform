import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/phone_normalizer.dart';
import 'phone_field_widget.dart';

const List<String> _kChannelOptions = ['whatsapp', 'sms', 'call', 'other'];
const Map<String, String> _kChannelLabels = {
  'whatsapp': 'WhatsApp',
  'sms': 'SMS',
  'call': 'Llamada',
  'other': 'Otro',
};

// ── PhoneSecondaryWidget ──────────────────────────────────────────────────────

/// Displays a dynamic list of up to 3 secondary phone entries. Each entry
/// has a label, a [PhoneFieldWidget] and a channel-type selector.
/// Calls [onChanged] with the serialized list whenever any entry changes.
class PhoneSecondaryWidget extends StatefulWidget {
  const PhoneSecondaryWidget({
    super.key,
    this.initial,
    required this.onChanged,
  });

  final List<Map<String, dynamic>>? initial;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  @override
  State<PhoneSecondaryWidget> createState() => _PhoneSecondaryWidgetState();
}

class _PhoneSecondaryWidgetState extends State<PhoneSecondaryWidget> {
  late final List<_SecondaryEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = (widget.initial ?? []).map((m) {
      final raw = m['number'] as String? ?? '';
      final (iso, local) = PhoneNormalizer.parsePhone(raw);
      return _SecondaryEntry(
        labelCtrl: TextEditingController(text: m['label'] as String? ?? ''),
        localNumber: local,
        countryIso: iso,
        e164: raw.isNotEmpty ? PhoneNormalizer.formatToE164(local, iso) : '',
        channel: m['channel'] as String? ?? 'whatsapp',
      );
    }).toList();
    _clampEntries();
  }

  @override
  void dispose() {
    for (final e in _entries) {
      e.labelCtrl.dispose();
    }
    super.dispose();
  }

  void _clampEntries() {
    while (_entries.length > 3) {
      _entries.last.labelCtrl.dispose();
      _entries.removeLast();
    }
  }

  void _emit() {
    widget.onChanged(_entries.map((e) => {
          'label': e.labelCtrl.text.trim(),
          'number': e.e164,
          'channel': e.channel,
        }).toList());
  }

  void _addEntry() {
    if (_entries.length >= 3) return;
    setState(() {
      _entries.add(_SecondaryEntry(
        labelCtrl: TextEditingController(),
        localNumber: '',
        countryIso: 'MX',
        e164: '',
        channel: 'whatsapp',
      ));
    });
    _emit();
  }

  void _removeEntry(int idx) {
    setState(() {
      _entries[idx].labelCtrl.dispose();
      _entries.removeAt(idx);
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < _entries.length; i++) ...[
          _EntryCard(
            entry: _entries[i],
            onRemove: () => _removeEntry(i),
            onChanged: () => setState(_emit),
          ),
          const SizedBox(height: 10),
        ],
        if (_entries.length < 3)
          GestureDetector(
            onTap: _addEntry,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                height: 36,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.ctSurface2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.ctBorder2),
                ),
                alignment: Alignment.center,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded,
                        size: 14, color: AppColors.ctTeal),
                    SizedBox(width: 6),
                    Text(
                      'Agregar teléfono secundario',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ctTeal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Per-entry card ────────────────────────────────────────────────────────────

class _EntryCard extends StatefulWidget {
  const _EntryCard({
    required this.entry,
    required this.onRemove,
    required this.onChanged,
  });
  final _SecondaryEntry entry;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  State<_EntryCard> createState() => _EntryCardState();
}

class _EntryCardState extends State<_EntryCard> {
  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.ctSurface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.ctBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: label field + remove button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: entry.labelCtrl,
                  maxLength: 30,
                  onChanged: (_) => widget.onChanged(),
                  style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 12,
                      color: AppColors.ctText),
                  decoration: const InputDecoration(
                    hintText: 'Etiqueta (ej: Trabajo)',
                    hintStyle: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 12,
                        color: AppColors.ctText3),
                    counterText: '',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 0, vertical: 0),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              GestureDetector(
                onTap: widget.onRemove,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: const Icon(Icons.close_rounded,
                      size: 16, color: AppColors.ctText3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Phone field
          PhoneFieldWidget(
            initialLocalNumber: entry.localNumber,
            initialCountryIso: entry.countryIso,
            onChanged: (e164) {
              entry.e164 = e164;
              widget.onChanged();
            },
          ),
          const SizedBox(height: 8),
          // Channel selector
          Row(
            children: [
              const Text(
                'Canal:',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12,
                  color: AppColors.ctText2,
                ),
              ),
              const SizedBox(width: 8),
              ..._kChannelOptions.map((ch) {
                final selected = entry.channel == ch;
                return GestureDetector(
                  onTap: () {
                    setState(() => entry.channel = ch);
                    widget.onChanged();
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.ctTealLight
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppColors.ctTeal
                              : AppColors.ctBorder2,
                        ),
                      ),
                      child: Text(
                        _kChannelLabels[ch] ?? ch,
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: selected
                              ? AppColors.ctTealDark
                              : AppColors.ctText2,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Entry model ───────────────────────────────────────────────────────────────

class _SecondaryEntry {
  _SecondaryEntry({
    required this.labelCtrl,
    required this.localNumber,
    required this.countryIso,
    required this.e164,
    required this.channel,
  });
  final TextEditingController labelCtrl;
  final String localNumber;
  final String countryIso;
  String e164;
  String channel;
}
