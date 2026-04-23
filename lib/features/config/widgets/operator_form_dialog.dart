import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/api/flows_api.dart';
import '../../../core/api/operators_api.dart';
import '../../../core/providers/tenant_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/phone_normalizer.dart';
import 'nationality_identity_widget.dart';
import 'phone_field_widget.dart';
import 'phone_secondary_widget.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

bool _isTelegramExpired(String? expiresAt) {
  if (expiresAt == null) return false;
  try {
    return DateTime.now().toUtc()
        .isAfter(DateTime.parse(expiresAt).toUtc());
  } catch (_) {
    return false;
  }
}

String _formatTelegramExpiry(String iso) {
  try {
    final dt = DateTime.parse(iso).toLocal();
    return '${dt.day}/${dt.month}/${dt.year} '
        '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return iso;
  }
}

Color _avatarColor(String name) {
  const palette = [
    Color(0xFF2DD4BF),
    Color(0xFF818CF8),
    Color(0xFFFB923C),
    Color(0xFFF472B6),
    Color(0xFF34D399),
    Color(0xFF60A5FA),
  ];
  if (name.isEmpty) return palette[0];
  final hash = name.codeUnits.fold(0, (a, b) => a + b);
  return palette[hash % palette.length];
}

String _initials(String name) {
  final parts =
      name.trim().split(' ').where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
}

// ── OperatorFormDialog ────────────────────────────────────────────────────────

class OperatorFormDialog extends ConsumerStatefulWidget {
  const OperatorFormDialog({
    super.key,
    this.operatorId,
    this.initialName,
    this.initialPhone,
    this.initialFlows,
    this.initialTelegramChatId,
    this.initialMetadata,
    required this.onSaved,
    this.onOperatorMetadataUpdated,
  });

  final String? operatorId;
  final String? initialName;
  final String? initialPhone;
  final List<String>? initialFlows;
  final String? initialTelegramChatId;
  final Map<String, dynamic>? initialMetadata;
  final VoidCallback onSaved;
  final void Function(String id, Map<String, dynamic> metadata)?
      onOperatorMetadataUpdated;

  bool get isEdit => operatorId != null;

  @override
  ConsumerState<OperatorFormDialog> createState() =>
      _OperatorFormDialogState();
}

class _OperatorFormDialogState extends ConsumerState<OperatorFormDialog> {
  // ── Basic fields ──────────────────────────────────────────────────────────
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _telegramCtrl;

  // Phone (WhatsApp primary)
  String _phoneCountryIso = 'MX';
  String _phoneLocalNumber = '';
  String _phoneE164 = '';

  // Identification
  String _nationalityIso = '';
  String _identityNumber = '';

  // Secondary phones
  List<Map<String, dynamic>> _phoneSecondary = [];

  // Profile photo
  Uint8List? _profileBytes;

  // ── UI state ──────────────────────────────────────────────────────────────
  bool _saving = false;
  String? _errorMsg;
  Map<String, String> _fieldErrors = {};
  bool _secondaryExpanded = false;

  // Telegram invite
  bool _sendingInvite = false;
  List<String> _inviteResults = [];

  // Telegram linking state
  String _telegramLinkStatus = 'none';
  String? _telegramLinkExpiresAt;
  String? _telegramChannelId;

  // Realtime subscription
  RealtimeChannel? _realtimeChannel;

  // Flows
  List<Map<String, dynamic>> _availableFlows = [];
  bool _flowsLoading = true;
  Set<String> _selectedFlowIds = {};

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
    _emailCtrl = TextEditingController(
      text: (widget.initialMetadata?['email'] as String?) ?? '',
    );
    _telegramCtrl =
        TextEditingController(text: widget.initialTelegramChatId ?? '');
    _selectedFlowIds = Set<String>.from(widget.initialFlows ?? []);

    // Parse initial phone
    final rawPhone = widget.initialPhone ?? '';
    if (rawPhone.isNotEmpty) {
      final (iso, local) = PhoneNormalizer.parsePhone(rawPhone);
      _phoneCountryIso = iso;
      _phoneLocalNumber = local;
      _phoneE164 = PhoneNormalizer.formatToE164(local, iso);
    }

    // Identity fields from metadata
    final meta = widget.initialMetadata ?? {};
    _telegramLinkStatus =
        (meta['telegram_link_status'] as String?) ?? 'none';
    _telegramLinkExpiresAt =
        meta['telegram_link_expires_at'] as String?;
    _nationalityIso = meta['nationality'] as String? ?? '';
    _identityNumber = meta['identity_number'] as String? ?? '';
    _phoneSecondary = ((meta['phone_secondary'] as List?) ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    WidgetsBinding.instance
        .addPostFrameCallback((_) => _loadFlows());

    // Realtime subscription — DO NOT MODIFY THIS BLOCK
    if (widget.isEdit && widget.operatorId != null) {
      try {
        _realtimeChannel = Supabase.instance.client
            .channel('op_${widget.operatorId}')
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'operators',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'id',
                value: widget.operatorId!,
              ),
              callback: _handleRealtimeUpdate,
            )
            .subscribe();
      } catch (e) {
        debugPrint('[Realtime] subscribe error: $e');
        _realtimeChannel = null;
      }
    }
  }

  // ── _handleRealtimeUpdate — DO NOT MODIFY ────────────────────────────────

  void _handleRealtimeUpdate(PostgresChangePayload payload) {
    if (!mounted) return;
    final row = payload.newRecord;
    final rawMeta = row['metadata'];
    Map<String, dynamic> meta;
    if (rawMeta is Map) {
      meta = Map<String, dynamic>.from(rawMeta);
    } else if (rawMeta is String) {
      try {
        meta = Map<String, dynamic>.from(json.decode(rawMeta) as Map);
      } catch (_) {
        meta = {};
      }
    } else {
      meta = {};
    }

    final newChatId = meta['telegram_chat_id'] as String?;
    final newStatus = (meta['telegram_link_status'] as String?) ?? 'none';
    final newExpiresAt = meta['telegram_link_expires_at'] as String?;

    setState(() {
      if (newChatId != null && newChatId.isNotEmpty) {
        _telegramCtrl.text = newChatId;
        _telegramLinkStatus = 'linked';
        _telegramLinkExpiresAt = null;
      } else {
        _telegramLinkStatus = newStatus;
        _telegramLinkExpiresAt = newExpiresAt;
      }
    });

    widget.onOperatorMetadataUpdated?.call(widget.operatorId!, meta);
  }

  // ── Flows ─────────────────────────────────────────────────────────────────

  Future<void> _loadFlows() async {
    try {
      final tenantId = ref.read(activeTenantIdProvider);
      final flows = await FlowsApi.listFlows(
        tenantId: tenantId.isNotEmpty ? tenantId : 'default',
      );
      if (mounted) {
        setState(() {
          _availableFlows = flows;
          _flowsLoading = false;
        });
        _fetchTelegramChannels();
      }
    } catch (_) {
      if (mounted) setState(() => _flowsLoading = false);
    }
  }

  Future<void> _fetchTelegramChannels() async {
    final flowIds = _selectedFlowIds.toList();
    if (flowIds.isEmpty) {
      if (mounted) setState(() => _telegramChannelId = null);
      return;
    }
    try {
      final channels =
          await OperatorsApi.getTelegramChannels(flowIds: flowIds);
      if (!mounted) return;
      setState(() {
        _telegramChannelId = channels.isNotEmpty
            ? channels.first['channel_id'] as String?
            : null;
      });
    } catch (_) {
      if (mounted) setState(() => _telegramChannelId = null);
    }
  }

  // ── Profile photo ─────────────────────────────────────────────────────────

  Future<void> _pickProfilePhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final bytes = result.files.first.bytes;
      if (bytes != null && mounted) {
        setState(() => _profileBytes = bytes);
      }
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneE164.isNotEmpty ? _phoneE164 : _phoneLocalNumber;

    setState(() {
      _fieldErrors = {};
      _errorMsg = null;
    });

    // Required field validation
    bool hasErrors = false;
    if (name.isEmpty) {
      _fieldErrors['display_name'] = 'Nombre obligatorio';
      hasErrors = true;
    }
    if (phone.isEmpty) {
      _fieldErrors['phone'] = 'Teléfono obligatorio';
      hasErrors = true;
    }
    if (hasErrors) {
      setState(() {});
      return;
    }

    // Non-blocking Telegram warning
    final hasTelegramFlow = _availableFlows
        .where((f) => _selectedFlowIds.contains(f['id']))
        .any((f) {
      final types = f['channel_types'];
      return types is List && types.contains('telegram');
    });
    if (hasTelegramFlow && _telegramCtrl.text.trim().isEmpty) {
      setState(() {
        _errorMsg =
            'Este operador tiene flujos Telegram asignados. '
            'Ingresa su Telegram Chat ID o usa "Vincular vía Telegram".';
      });
      // Warning only — do not block save
    }

    setState(() => _saving = true);

    try {
      final flows = _selectedFlowIds.toList();
      final tgId = _telegramCtrl.text.trim();
      final metadata = <String, dynamic>{};
      if (_phoneSecondary.isNotEmpty) {
        metadata['phone_secondary'] = _phoneSecondary;
      }

      if (widget.isEdit) {
        await OperatorsApi.updateOperator(
          id: widget.operatorId!,
          displayName: name,
          phone: phone,
          flows: flows,
          telegramChatId: tgId,
          email: email.isNotEmpty ? email : null,
          nationality:
              _nationalityIso.isNotEmpty ? _nationalityIso : null,
          identityNumber:
              _identityNumber.isNotEmpty ? _identityNumber : null,
          phoneSecondary:
              _phoneSecondary.isNotEmpty ? _phoneSecondary : null,
        );
      } else {
        final tenantId = ref.read(activeTenantIdProvider);
        await OperatorsApi.createOperator(
          displayName: name,
          phone: phone,
          flows: flows,
          tenantId: tenantId.isNotEmpty ? tenantId : 'default',
          telegramChatId: tgId.isNotEmpty ? tgId : null,
          email: email.isNotEmpty ? email : null,
          nationality:
              _nationalityIso.isNotEmpty ? _nationalityIso : null,
          identityNumber:
              _identityNumber.isNotEmpty ? _identityNumber : null,
          phoneSecondary:
              _phoneSecondary.isNotEmpty ? _phoneSecondary : null,
        );
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEdit
                  ? 'Operador actualizado.'
                  : 'Operador creado. Mensaje de bienvenida enviado.',
              style:
                  const TextStyle(fontFamily: 'Geist', fontSize: 13),
            ),
            backgroundColor: AppColors.ctNavy,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map) {
        final message =
            data['message'] as String? ?? 'Error al guardar';
        final field = data['field'] as String?;

        if (field != null && field.isNotEmpty) {
          setState(() {
            _saving = false;
            _fieldErrors[field] = message;
          });
        } else {
          setState(() {
            _saving = false;
            _errorMsg = message;
          });
        }
      } else {
        final statusCode = e.response?.statusCode;
        setState(() {
          _saving = false;
          _errorMsg = statusCode == 409
              ? 'Ya existe un operador con ese número de teléfono.'
              : 'Error al guardar. Intenta de nuevo.';
        });
      }
    } catch (_) {
      setState(() {
        _saving = false;
        _errorMsg = 'Error inesperado. Intenta de nuevo.';
      });
    }
  }

  // ── Telegram invite — DO NOT MODIFY LOGIC ────────────────────────────────

  Future<void> _sendInvite() async {
    if (_sendingInvite || widget.operatorId == null) return;
    if (_telegramChannelId == null) {
      setState(() => _inviteResults = [
            '⚠ No se encontraron canales Telegram en los flujos seleccionados.'
          ]);
      return;
    }
    setState(() {
      _sendingInvite = true;
      _inviteResults = [];
    });
    try {
      final result = await OperatorsApi.sendTelegramInvite(
        operatorId: widget.operatorId!,
        channelId: _telegramChannelId!,
        phone: _phoneE164.isNotEmpty ? _phoneE164 : _phoneLocalNumber,
      );
      final expiresAt = result['expires_at'] as String?;
      if (mounted) {
        setState(() {
          _sendingInvite = false;
          _telegramLinkStatus = 'pending';
          if (expiresAt != null) _telegramLinkExpiresAt = expiresAt;
          _inviteResults = ['✓ Invitación enviada'];
        });
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final String errorMsg;
      if (statusCode == 409) {
        errorMsg =
            'Este operador ya tiene Telegram vinculado. '
            'Borra el Chat ID actual y guarda para poder reenviar.';
      } else {
        errorMsg = 'No se pudo enviar la invitación. Intenta de nuevo.';
      }
      if (mounted) {
        setState(() {
          _sendingInvite = false;
          _inviteResults = ['✗ $errorMsg'];
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _sendingInvite = false;
          _inviteResults = [
            '✗ No se pudo enviar la invitación. Intenta de nuevo.'
          ];
        });
      }
    }
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _telegramCtrl.dispose();
    if (_realtimeChannel != null) {
      Supabase.instance.client
          .removeChannel(_realtimeChannel!)
          .catchError((e) {
        debugPrint('[Realtime] removeChannel error: $e');
        return 'error';
      });
    }
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.ctSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.ctBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.isEdit
                          ? 'Editar operador'
                          : 'Agregar operador',
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ctText,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: const Icon(Icons.close_rounded,
                          size: 18, color: AppColors.ctText3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.ctBorder),

            // ── Scrollable body ──────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Error banner ─────────────────────────────────────
                    if (_errorMsg != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.ctRedBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.ctDanger
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                size: 14, color: AppColors.ctDanger),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMsg!,
                                style: const TextStyle(
                                  fontFamily: 'Geist',
                                  fontSize: 12,
                                  color: AppColors.ctRedText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── SECCIÓN 1: Datos básicos ─────────────────────────
                    _SectionHeader(label: 'Datos básicos'),
                    const SizedBox(height: 14),

                    // Profile photo
                    Center(
                      child: GestureDetector(
                        onTap: _pickProfilePhoto,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: _profileBytes == null
                                    ? _avatarColor(
                                        _nameCtrl.text.trim())
                                    : AppColors.ctSurface2,
                                backgroundImage: _profileBytes != null
                                    ? MemoryImage(_profileBytes!)
                                    : null,
                                child: _profileBytes == null
                                    ? ListenableBuilder(
                                        listenable: _nameCtrl,
                                        builder: (context, child) => Text(
                                          _initials(
                                              _nameCtrl.text),
                                          style: const TextStyle(
                                            fontFamily: 'Onest',
                                            fontSize: 18,
                                            fontWeight:
                                                FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: AppColors.ctTeal,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 12,
                                    color: AppColors.ctNavy),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nombre
                    _FieldLabel('Nombre completo *'),
                    const SizedBox(height: 6),
                    _FormField(
                      controller: _nameCtrl,
                      placeholder: 'Ej: Roberto Medina',
                      errorText: _fieldErrors['display_name'],
                    ),
                    const SizedBox(height: 14),

                    // Teléfono WhatsApp (PhoneFieldWidget)
                    PhoneFieldWidget(
                      label: 'Número de WhatsApp *',
                      initialCountryIso: _phoneCountryIso,
                      initialLocalNumber: _phoneLocalNumber,
                      errorText: _fieldErrors['phone'],
                      onChanged: (e164) =>
                          setState(() => _phoneE164 = e164),
                    ),
                    const SizedBox(height: 14),

                    // Email
                    _FieldLabel('Email (opcional)'),
                    const SizedBox(height: 6),
                    _FormField(
                      controller: _emailCtrl,
                      placeholder: 'correo@ejemplo.com',
                      keyboardType: TextInputType.emailAddress,
                      errorText: _fieldErrors['email'],
                    ),

                    const SizedBox(height: 20),

                    // ── SECCIÓN 2: Identificación ─────────────────────────
                    _SectionHeader(label: 'Identificación'),
                    const SizedBox(height: 14),
                    NationalityIdentityWidget(
                      initialNationality: _nationalityIso.isNotEmpty
                          ? _nationalityIso
                          : null,
                      initialIdentityNumber: _identityNumber.isNotEmpty
                          ? _identityNumber
                          : null,
                      onNationalityChanged: (iso) =>
                          setState(() => _nationalityIso = iso),
                      onIdentityChanged: (v) =>
                          setState(() => _identityNumber = v),
                    ),

                    const SizedBox(height: 20),

                    // ── SECCIÓN 3: Contacto adicional (collapsible) ───────
                    GestureDetector(
                      onTap: () => setState(
                          () => _secondaryExpanded = !_secondaryExpanded),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Row(
                          children: [
                            _SectionHeader(
                                label: 'Contacto adicional'),
                            const Spacer(),
                            Icon(
                              _secondaryExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: AppColors.ctText2,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _secondaryExpanded ? 'Colapsar' : 'Expandir',
                              style: const TextStyle(
                                  fontFamily: 'Geist',
                                  fontSize: 11,
                                  color: AppColors.ctText2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_secondaryExpanded) ...[
                      const SizedBox(height: 10),
                      PhoneSecondaryWidget(
                        initial: _phoneSecondary.isNotEmpty
                            ? _phoneSecondary
                            : null,
                        onChanged: (list) =>
                            setState(() => _phoneSecondary = list),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── SECCIÓN 4: Flujos asignados ───────────────────────
                    _SectionHeader(label: 'Flujos asignados'),
                    const SizedBox(height: 10),
                    if (_flowsLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.ctTeal),
                          ),
                        ),
                      )
                    else if (_availableFlows.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.ctBorder),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'No hay flujos disponibles en este tenant.',
                          style: TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 12,
                              color: AppColors.ctText2),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.ctBorder),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children:
                              _availableFlows.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final flow = entry.value;
                            final flowId =
                                flow['id'] as String? ?? '';
                            final flowName =
                                flow['name'] as String? ?? flowId;
                            final workerName =
                                flow['worker_name'] as String? ??
                                    flow['tenant_worker_name']
                                        as String? ??
                                    '';
                            final isFlowActive =
                                flow['is_active'] as bool? ?? true;
                            final isSelected =
                                _selectedFlowIds.contains(flowId);
                            final isLast = idx ==
                                _availableFlows.length - 1;
                            return Column(
                              children: [
                                InkWell(
                                  borderRadius: isLast
                                      ? const BorderRadius.only(
                                          bottomLeft:
                                              Radius.circular(7),
                                          bottomRight:
                                              Radius.circular(7))
                                      : BorderRadius.zero,
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedFlowIds
                                            .remove(flowId);
                                      } else {
                                        _selectedFlowIds.add(flowId);
                                      }
                                    });
                                    _fetchTelegramChannels();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: Checkbox(
                                            value: isSelected,
                                            onChanged: (v) {
                                              setState(() {
                                                if (v == true) {
                                                  _selectedFlowIds
                                                      .add(flowId);
                                                } else {
                                                  _selectedFlowIds
                                                      .remove(flowId);
                                                }
                                              });
                                              _fetchTelegramChannels();
                                            },
                                            activeColor:
                                                AppColors.ctTeal,
                                            checkColor:
                                                AppColors.ctNavy,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            side: const BorderSide(
                                                color:
                                                    AppColors.ctBorder2),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start,
                                            mainAxisSize:
                                                MainAxisSize.min,
                                            children: [
                                              Text(flowName,
                                                  style: const TextStyle(
                                                      fontFamily:
                                                          'Geist',
                                                      fontSize: 13,
                                                      color: AppColors
                                                          .ctText)),
                                              if (workerName.isNotEmpty)
                                                Text(workerName,
                                                    style: const TextStyle(
                                                        fontFamily:
                                                            'Geist',
                                                        fontSize: 11,
                                                        color: AppColors
                                                            .ctText2)),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets
                                              .symmetric(
                                              horizontal: 7,
                                              vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isFlowActive
                                                ? AppColors.ctOkBg
                                                : AppColors.ctSurface2,
                                            borderRadius:
                                                BorderRadius.circular(
                                                    20),
                                          ),
                                          child: Text(
                                            isFlowActive
                                                ? 'Activo'
                                                : 'Inactivo',
                                            style: TextStyle(
                                              fontFamily: 'Geist',
                                              fontSize: 10,
                                              fontWeight:
                                                  FontWeight.w600,
                                              color: isFlowActive
                                                  ? AppColors.ctOkText
                                                  : AppColors.ctText2,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (!isLast)
                                  const Divider(
                                      height: 1,
                                      color: AppColors.ctBorder),
                              ],
                            );
                          }).toList(),
                        ),
                      ),

                    // ── SECCIÓN 5: Telegram Chat ID ───────────────────────
                    const SizedBox(height: 20),
                    _SectionHeader(label: 'Vinculación Telegram'),
                    const SizedBox(height: 10),
                    if (_telegramLinkStatus == 'linked') ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.ctSurface2,
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: AppColors.ctBorder2),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _telegramCtrl.text,
                                style: const TextStyle(
                                  fontFamily: 'Geist',
                                  fontSize: 13,
                                  color: AppColors.ctText,
                                ),
                              ),
                            ),
                            const Icon(Icons.check_circle_rounded,
                                size: 16, color: AppColors.ctTeal),
                          ],
                        ),
                      ),
                    ] else ...[
                      _FieldLabel('Telegram Chat ID'),
                      const SizedBox(height: 6),
                      _FormField(
                        controller: _telegramCtrl,
                        placeholder: 'Ej: 123456789',
                        keyboardType: TextInputType.number,
                      ),
                    ],

                    // Vincular vía Telegram button
                    if (_telegramChannelId != null &&
                        _telegramLinkStatus != 'linked' &&
                        widget.isEdit) ...[
                      const SizedBox(height: 12),
                      Builder(builder: (ctx) {
                        final isExpired =
                            _telegramLinkStatus == 'expired' ||
                                (_telegramLinkStatus == 'pending' &&
                                    _isTelegramExpired(
                                        _telegramLinkExpiresAt));
                        final isPendingActive =
                            _telegramLinkStatus == 'pending' &&
                                !isExpired &&
                                _telegramLinkExpiresAt != null;
                        final btnLabel =
                            _telegramLinkStatus == 'none'
                                ? 'Vincular vía Telegram'
                                : 'Reenviar invitación';
                        return Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            if (isExpired)
                              const Padding(
                                padding:
                                    EdgeInsets.only(bottom: 6),
                                child: Text(
                                  'Invitación expirada',
                                  style: TextStyle(
                                    fontFamily: 'Geist',
                                    fontSize: 11,
                                    color: AppColors.ctDanger,
                                  ),
                                ),
                              )
                            else if (isPendingActive)
                              Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 6),
                                child: Text(
                                  'Invitación enviada · expira ${_formatTelegramExpiry(_telegramLinkExpiresAt!)}',
                                  style: const TextStyle(
                                    fontFamily: 'Geist',
                                    fontSize: 11,
                                    color: AppColors.ctText2,
                                  ),
                                ),
                              ),
                            SizedBox(
                              width: double.infinity,
                              height: 36,
                              child: _sendingInvite
                                  ? const Center(
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child:
                                            CircularProgressIndicator(
                                                strokeWidth: 2),
                                      ),
                                    )
                                  : OutlinedButton.icon(
                                      onPressed: _sendInvite,
                                      icon: const Icon(
                                          Icons.telegram,
                                          size: 16),
                                      label: Text(btnLabel,
                                          style: const TextStyle(
                                              fontFamily: 'Geist',
                                              fontSize: 13)),
                                      style:
                                          OutlinedButton.styleFrom(
                                        foregroundColor:
                                            const Color(0xFF229ED9),
                                        side: const BorderSide(
                                            color:
                                                Color(0xFF229ED9)),
                                        shape:
                                            RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(
                                                  8),
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        );
                      }),
                      if (_inviteResults.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ..._inviteResults.map(
                          (r) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: 4),
                            child: Text(
                              r,
                              style: const TextStyle(
                                  fontFamily: 'Geist',
                                  fontSize: 11,
                                  color: AppColors.ctText2),
                            ),
                          ),
                        ),
                      ],
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── Footer with action buttons ─────────────────────────────
            const Divider(height: 1, color: AppColors.ctBorder),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _FormGhostButton(
                    label: 'Cancelar',
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  if (_saving)
                    const SizedBox(
                      width: 120,
                      height: 36,
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2),
                        ),
                      ),
                    )
                  else
                    _FormPrimaryButton(
                      label: 'Guardar operador',
                      onTap: _save,
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

// ── Local widgets ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Onest',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.ctText,
        letterSpacing: 0.1,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Geist',
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.ctText,
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.placeholder,
    this.keyboardType,
    this.errorText,
  });
  final TextEditingController controller;
  final String placeholder;
  final TextInputType? keyboardType;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 13,
            color: AppColors.ctText,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 13,
              color: AppColors.ctText3,
            ),
            filled: true,
            fillColor: AppColors.ctSurface2,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: errorText != null
                    ? AppColors.ctDanger
                    : AppColors.ctBorder2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: errorText != null
                    ? AppColors.ctDanger
                    : AppColors.ctBorder2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: errorText != null
                    ? AppColors.ctDanger
                    : AppColors.ctTeal,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 3),
          Text(
            errorText!,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 11,
              color: AppColors.ctDanger,
            ),
          ),
        ],
      ],
    );
  }
}

class _FormPrimaryButton extends StatefulWidget {
  const _FormPrimaryButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_FormPrimaryButton> createState() => _FormPrimaryButtonState();
}

class _FormPrimaryButtonState extends State<_FormPrimaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color:
                _hovered ? AppColors.ctTealDark : AppColors.ctTeal,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.ctNavy,
            ),
          ),
        ),
      ),
    );
  }
}

class _FormGhostButton extends StatefulWidget {
  const _FormGhostButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_FormGhostButton> createState() => _FormGhostButtonState();
}

class _FormGhostButtonState extends State<_FormGhostButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.ctSurface2
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.ctBorder2),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.ctText2,
            ),
          ),
        ),
      ),
    );
  }
}
