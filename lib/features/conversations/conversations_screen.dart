import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

import 'package:desktop_drop/desktop_drop.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/api/channels_api.dart';
import '../../core/api/conversations_api.dart';
import '../../core/api/messages_api.dart';
import '../../core/api/operators_api.dart';
import '../../core/api/sessions_api.dart';
import '../../core/api/supabase_messages.dart';
import '../../core/api/supabase_read_receipts.dart';
import '../../core/providers/permissions_provider.dart';
import '../../core/providers/tenant_provider.dart';
import '../../core/theme/app_theme.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final selectedChannelIdProvider  = StateProvider<String?>((ref) => null);
final selectedChannelTabProvider = StateProvider<int>((ref) => 0);
final selectedChatIdProvider     = StateProvider<String?>((ref) => null);
final selectedChatNameProvider = StateProvider<String?>((ref) => null);
final selectedOperatorChannelsProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) => []);
final selectedChannelIndexProvider = StateProvider<int>((ref) => 0);
final replyingToProvider =
    StateProvider<Map<String, dynamic>?>((ref) => null);
final selectedConvOperatorIdProvider = StateProvider<String?>((ref) => null);
final selectedChannelTypeProvider    = StateProvider<String?>((ref) => null);

// ── Pantalla ──────────────────────────────────────────────────────────────────

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Column(
      children: [
        _ActionBar(),
        Expanded(child: _ConversationsBody()),
      ],
    );
  }
}

// ── Action bar ────────────────────────────────────────────────────────────────

class _ActionBar extends ConsumerWidget {
  const _ActionBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 48,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.ctSurface,
        border: Border(bottom: BorderSide(color: AppColors.ctBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Conversaciones',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ctText,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Canal WhatsApp · Mensajes en tiempo real',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 11,
                    color: AppColors.ctText2,
                  ),
                ),
              ],
            ),
          ),
          _ActionBarGhostButton(
            label: '📢  Broadcast a todos',
            onTap: () {
              final channelId   = ref.read(selectedChannelIdProvider)   ?? '';
              final channelType = ref.read(selectedChannelTypeProvider) ?? 'whatsapp';
              context.go('/broadcast?channel_id=$channelId&channel_type=$channelType');
            },
          ),
          const SizedBox(width: 8),
          _PrimaryButton(
            label: '+ Nuevo mensaje',
            onTap: () => showDialog(
              context: context,
              builder: (_) => const _NewMessageDialog(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBarGhostButton extends StatefulWidget {
  const _ActionBarGhostButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_ActionBarGhostButton> createState() => _ActionBarGhostButtonState();
}

class _ActionBarGhostButtonState extends State<_ActionBarGhostButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.ctSurface2 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.ctBorder2),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.ctText,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.ctTealDark : AppColors.ctTeal,
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

// ── Cuerpo con tabs ───────────────────────────────────────────────────────────

class _ConversationsBody extends ConsumerStatefulWidget {
  const _ConversationsBody();

  @override
  ConsumerState<_ConversationsBody> createState() => _ConversationsBodyState();
}

class _ConversationsBodyState extends ConsumerState<_ConversationsBody> {
  List<Map<String, dynamic>> _channels = [];
  bool _loadingChannels = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadChannels());
  }

  Future<void> _loadChannels() async {
    if (!mounted) return;
    setState(() => _loadingChannels = true);
    final tenantId = ref.read(activeTenantIdProvider);
    try {
      final all = await ChannelsApi.listChannels(tenantId: tenantId);
      final active = all
          .where((c) => c['is_active'] as bool? ?? false)
          .toList()
        ..sort((a, b) => (a['created_at'] as String? ?? '')
            .compareTo(b['created_at'] as String? ?? ''));
      if (!mounted) return;
      setState(() { _channels = active; _loadingChannels = false; });
      if (active.isNotEmpty && ref.read(selectedChannelIdProvider) == null) {
        ref.read(selectedChannelIdProvider.notifier).state =
            active.first['id'] as String?;
        ref.read(selectedChannelTypeProvider.notifier).state =
            active.first['channel_type'] as String?;
      }
    } catch (_) {
      if (mounted) setState(() => _loadingChannels = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(activeTenantIdProvider, (prev, next) {
      if (prev != null && prev != next) {
        ref.read(selectedChannelIdProvider.notifier).state = null;
        ref.read(selectedChannelTabProvider.notifier).state = 0;
        ref.read(selectedChatIdProvider.notifier).state = null;
        ref.read(selectedChatNameProvider.notifier).state = null;
        ref.read(selectedOperatorChannelsProvider.notifier).state = [];
        ref.read(replyingToProvider.notifier).state = null;
        setState(() { _channels = []; _loadingChannels = true; });
        _loadChannels();
      }
    });

    ref.listen<int>(channelStateVersionProvider, (prev, next) {
      if (prev != null && prev != next) _loadChannels();
    });

    final tab = ref.watch(selectedChannelTabProvider);
    final selectedChannelId = ref.watch(selectedChannelIdProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nivel 1 — Canal selector (solo si hay más de 1 canal)
        if (!_loadingChannels && _channels.length > 1)
          _ChannelSelectorBar(
            channels: _channels,
            selectedChannelId: selectedChannelId,
            onChannelSelected: (id) {
              final ch = _channels.firstWhere(
                (c) => (c['id'] as String?) == id,
                orElse: () => {},
              );
              ref.read(selectedChannelIdProvider.notifier).state = id;
              ref.read(selectedChannelTypeProvider.notifier).state =
                  ch['channel_type'] as String?;
              ref.read(selectedChannelTabProvider.notifier).state = 0;
              ref.read(selectedChatIdProvider.notifier).state = null;
              ref.read(selectedChatNameProvider.notifier).state = null;
              ref.read(selectedOperatorChannelsProvider.notifier).state = [];
              ref.read(selectedConvOperatorIdProvider.notifier).state = null;
              ref.read(replyingToProvider.notifier).state = null;
            },
          ),

        // Nivel 2 — Pill tab bar (Conversaciones / Feed global)
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
          child: _TabBar(selectedIndex: tab),
        ),
        const SizedBox(height: 14),

        // Tab content
        Expanded(
          child: IndexedStack(
            index: tab,
            children: const [
              _TabOperador(),
              _TabFeed(),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Pill tab bar ──────────────────────────────────────────────────────────────

class _TabBar extends ConsumerWidget {
  const _TabBar({required this.selectedIndex});
  final int selectedIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.ctSurface2,
        borderRadius: BorderRadius.circular(9),
      ),
      child: IntrinsicWidth(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TabPill(
              label: 'Conversaciones',
              selected: selectedIndex == 0,
              onTap: () =>
                  ref.read(selectedChannelTabProvider.notifier).state = 0,
            ),
            const SizedBox(width: 2),
            _TabPill(
              label: 'Feed global',
              selected: selectedIndex == 1,
              onTap: () =>
                  ref.read(selectedChannelTabProvider.notifier).state = 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.ctSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 13,
              fontWeight:
                  selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? AppColors.ctText : AppColors.ctText2,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Channel selector bar (Nivel 1) ────────────────────────────────────────────

class _ChannelSelectorBar extends StatelessWidget {
  const _ChannelSelectorBar({
    required this.channels,
    required this.selectedChannelId,
    required this.onChannelSelected,
  });
  final List<Map<String, dynamic>> channels;
  final String? selectedChannelId;
  final ValueChanged<String> onChannelSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: const BoxDecoration(
        color: AppColors.ctSurface,
        border: Border(bottom: BorderSide(color: AppColors.ctBorder)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: channels.length,
        itemBuilder: (context, i) {
          final ch = channels[i];
          final chId = ch['id'] as String?;
          final isSelected = chId == selectedChannelId;
          final color = _hexColor(ch['color'] as String?);
          final label = ch['display_name'] as String? ?? 'Canal ${i + 1}';
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () { if (chId != null) onChannelSelected(chId); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.ctSurface : Colors.transparent,
                  border: isSelected
                      ? Border(bottom: BorderSide(color: color, width: 2))
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.ctText
                            : AppColors.ctText2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Tab 1: Por operador ───────────────────────────────────────────────────────

class _TabOperador extends ConsumerWidget {
  const _TabOperador();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        _ConvoList(),
        VerticalDivider(width: 1, color: AppColors.ctBorder),
        Expanded(child: _ChatPanel()),
      ],
    );
  }
}

// ── Helpers de formato ────────────────────────────────────────────────────────

String _formatTime(String? iso) {
  if (iso == null) return '';
  try {
    final dt = DateTime.parse(iso).toLocal();
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return '';
  }
}

bool _isToday(String? iso) {
  if (iso == null) return false;
  try {
    final dt = DateTime.parse(iso).toLocal();
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  } catch (_) {
    return false;
  }
}

String _mediaFallback(String type) {
  switch (type) {
    case 'image': return '[📷 Imagen]';
    case 'audio': return '[🎤 Nota de voz]';
    case 'video': return '[🎥 Video]';
    case 'document': return '[📄 Documento]';
    case 'sticker': return '[😊 Sticker]';
    case 'location': return '[📍 Ubicación]';
    default: return '[📎 Archivo]';
  }
}


String _msgBody(Map<String, dynamic> msg) {
  final raw = msg['raw_body'] as String?;
  if (raw != null && raw.isNotEmpty) return raw;
  return _mediaFallback(msg['message_type'] as String? ?? '');
}

/// Resuelve el nombre a mostrar para mensajes outbound.
/// Usa from_name si está disponible; luego deriva del origin o sent_by_user_id.
String _outboundSenderName(Map<String, dynamic> msg) {
  final fromName = msg['from_name'] as String?;
  if (fromName != null && fromName.isNotEmpty) return fromName;
  final origin = msg['origin'] as String?;
  if (origin == 'ai_worker') return 'AI Worker';
  final sentByUserId = msg['sent_by_user_id'] as String?;
  if (sentByUserId != null && sentByUserId.isNotEmpty) return 'Agente';
  return 'Supervisor';
}

/// Devuelve el color del nombre y el badge de origen para mensajes outbound.
({Color nameColor, Widget? badge}) _outboundOriginStyle(
    Map<String, dynamic> msg) {
  final origin = msg['origin'] as String?;
  switch (origin) {
    case 'ai_worker':
      return (
        nameColor: const Color(0xFF1e40af),
        badge: _OriginBadge(
          label: 'IA',
          bg: const Color(0xFFDBEAFE),
          fg: const Color(0xFF1e40af),
        ),
      );
    case 'human':
      return (nameColor: const Color(0xFF065F46), badge: null);
    case 'external':
      return (
        nameColor: const Color(0xFF6B7280),
        badge: _OriginBadge(
          label: 'Externo',
          bg: const Color(0xFFF3F4F6),
          fg: const Color(0xFF6B7280),
        ),
      );
    default:
      return (
        nameColor: const Color(0xFF6B7280),
        badge: _OriginBadge(
          label: 'Sistema',
          bg: const Color(0xFFF3F4F6),
          fg: const Color(0xFF6B7280),
        ),
      );
  }
}

class _OriginBadge extends StatelessWidget {
  const _OriginBadge({required this.label, required this.bg, required this.fg});
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Geist',
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

Color _hexColor(String? hex) {
  try {
    final h = (hex ?? '#9CA3AF').replaceAll('#', '');
    if (h.length != 6) return const Color(0xFF9CA3AF);
    return Color(int.parse('FF$h', radix: 16));
  } catch (_) {
    return const Color(0xFF9CA3AF);
  }
}

IconData _mediaIcon(String mediaType) {
  switch (mediaType) {
    case 'image':    return Icons.image_outlined;
    case 'video':    return Icons.videocam_outlined;
    case 'audio':    return Icons.mic_outlined;
    case 'document': return Icons.attach_file_rounded;
    default:         return Icons.attach_file_rounded;
  }
}

String _mediaLabel(String mediaType) {
  switch (mediaType) {
    case 'image':    return 'Imagen';
    case 'video':    return 'Video';
    case 'audio':    return 'Audio';
    case 'document': return 'Archivo';
    default:         return 'Adjunto';
  }
}

// ── Lista de conversaciones (240px) ───────────────────────────────────────────

class _ConvoList extends ConsumerStatefulWidget {
  const _ConvoList();

  @override
  ConsumerState<_ConvoList> createState() => _ConvoListState();
}

class _ConvoListState extends ConsumerState<_ConvoList> {
  static final Map<String, DateTime> _lastReadAtCache = {};
  static final Map<String, DateTime> _preOpenLastRead = {};

  String _search = '';
  List<Map<String, dynamic>> _conversations = [];
  final Map<String, int> _unreadOverride = {};
  bool _loading = false;

  static DateTime? getLastReadSync(String chatId) => _lastReadAtCache[chatId];

  static Future<void> setLastRead(
      String chatId, DateTime time, String tenantId) async {
    _lastReadAtCache[chatId] = time;
    SupabaseReadReceipts.setLastRead(chatId, time, tenantId);
  }

  Future<void> _loadLastReadCache() async {
    final userId =
        Supabase.instance.client.auth.currentUser?.id ?? '';
    final tenantId = ref.read(activeTenantIdProvider);
    if (userId.isEmpty || tenantId.isEmpty) return;
    final data = await SupabaseReadReceipts.loadAll(
        userId: userId, tenantId: tenantId);
    _lastReadAtCache.addAll(data);
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _loadLastReadCache().then((_) {
      if (mounted) _fetchConversations();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchConversations() async {
    final channelId = ref.read(selectedChannelIdProvider);
    if (channelId == null) return;
    setState(() => _loading = true);
    try {
      final tenantId = ref.read(activeTenantIdProvider);
      final convs = await ConversationsApi.listConversations(
        tenantId: tenantId.isNotEmpty ? tenantId : 'default',
        channelId: channelId,
      );
      if (mounted) setState(() { _conversations = convs; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: TextField(
        onChanged: (v) => setState(() => _search = v),
        style: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 13,
          color: AppColors.ctText,
        ),
        decoration: InputDecoration(
          hintText: 'Buscar conversación…',
          hintStyle: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 13,
            color: AppColors.ctText3,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 16,
            color: AppColors.ctText3,
          ),
          filled: true,
          fillColor: AppColors.ctSurface2,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.ctBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.ctBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppColors.ctTeal, width: 1.5),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Reinicia conversaciones cuando cambia el tenant
    ref.listen<String>(activeTenantIdProvider, (prev, next) {
      if (prev != null && prev != next) {
        setState(() { _conversations = []; _unreadOverride.clear(); });
        _fetchConversations();
        ref.read(selectedChatIdProvider.notifier).state = null;
        ref.read(selectedChatNameProvider.notifier).state = null;
        ref.read(selectedOperatorChannelsProvider.notifier).state = [];
        ref.read(selectedConvOperatorIdProvider.notifier).state = null;
        ref.read(selectedChannelIndexProvider.notifier).state = 0;
        ref.read(selectedChannelIdProvider.notifier).state = null;
        ref.read(replyingToProvider.notifier).state = null;
      }
    });
    // Recarga cuando cambia el estado de canales (activar/desactivar)
    ref.listen<int>(channelStateVersionProvider, (prev, next) {
      if (prev != null && prev != next) _fetchConversations();
    });
    // Recarga cuando cambia el canal seleccionado
    ref.listen<String?>(selectedChannelIdProvider, (prev, next) {
      if (prev != next) _fetchConversations();
    });

    final selectedChatId = ref.watch(selectedChatIdProvider);
    final filtered = _conversations.where((conv) {
      final name = conv['display_name'] as String? ?? '';
      return name.toLowerCase().contains(_search.toLowerCase());
    }).toList();

    return SizedBox(
      width: 240,
      child: Column(
        children: [
          _searchBar(),
          if (_loading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_conversations.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'Sin conversaciones',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 12,
                    color: AppColors.ctText3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final conv    = filtered[i];
                  final chatId  = conv['chat_id'] as String? ?? '';
                  final name    = conv['display_name'] as String? ?? chatId;
                  final lastMsg = conv['last_message'] as Map<String, dynamic>?;
                  final body      = lastMsg?['body'] as String?;
                  final mediaType = lastMsg?['media_type'] as String?;
                  final createdAt = lastMsg?['created_at'] as String?;
                  final unread = _unreadOverride[chatId]
                      ?? (conv['unread_count'] as int? ?? 0);
                  return _ApiConvoItem(
                    name: name,
                    preview: mediaType != null
                        ? null
                        : (body?.isNotEmpty == true ? body! : 'Sin mensajes'),
                    mediaType: mediaType,
                    time: _formatTime(createdAt),
                    isToday: _isToday(createdAt),
                    isSelected: chatId == selectedChatId,
                    unreadCount: unread,
                    onTap: () {
                      final prev = getLastReadSync(chatId);
                      if (prev != null) {
                        _preOpenLastRead[chatId] = prev;
                      } else {
                        _preOpenLastRead.remove(chatId);
                      }
                      setLastRead(chatId, DateTime.now().toUtc(),
                          ref.read(activeTenantIdProvider));
                      setState(() { _unreadOverride[chatId] = 0; });
                      ref.read(selectedChatIdProvider.notifier).state = chatId;
                      ref.read(selectedChatNameProvider.notifier).state = name;
                      ref.read(selectedOperatorChannelsProvider.notifier).state = [];
                      ref.read(selectedConvOperatorIdProvider.notifier).state =
                          conv['operator_id'] as String?;
                      ref.read(selectedChannelIndexProvider.notifier).state = 0;
                      ref.read(replyingToProvider.notifier).state = null;
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ── Item de conversación (modo API) ───────────────────────────────────────────

class _ApiConvoItem extends StatefulWidget {
  const _ApiConvoItem({
    required this.name,
    required this.time,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
    this.preview,
    this.mediaType,
    this.unreadCount = 0,
  });
  final String name;
  final String? preview;
  final String? mediaType;
  final String time;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;
  final int unreadCount;

  @override
  State<_ApiConvoItem> createState() => _ApiConvoItemState();
}

class _ApiConvoItemState extends State<_ApiConvoItem> {
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
          duration: const Duration(milliseconds: 100),
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.ctTealLight
                : _hovered
                    ? AppColors.ctSurface2
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: widget.isSelected
                ? const Border(
                    left: BorderSide(color: AppColors.ctTeal, width: 2),
                  )
                : null,
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.ctTealLight,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials(widget.name),
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ctTealDark,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              // Nombre + preview
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.name,
                            style: TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 12,
                              fontWeight: widget.isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: AppColors.ctText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          widget.time,
                          style: const TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 10,
                            color: AppColors.ctText3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: widget.mediaType != null
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _mediaIcon(widget.mediaType!),
                                      size: 11,
                                      color: AppColors.ctText2,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      _mediaLabel(widget.mediaType!),
                                      style: const TextStyle(
                                        fontFamily: 'Geist',
                                        fontSize: 11,
                                        color: AppColors.ctText2,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  widget.preview ?? 'Sin mensajes',
                                  style: const TextStyle(
                                    fontFamily: 'Geist',
                                    fontSize: 11,
                                    color: AppColors.ctText2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                        const SizedBox(width: 4),
                        if (widget.unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(
                                minWidth: 18, minHeight: 18),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2DD4BF),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              widget.unreadCount > 99
                                  ? '99+'
                                  : '${widget.unreadCount}',
                              style: const TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F2937),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        else
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: widget.isToday
                                  ? const Color(0xFF22C55E)
                                  : AppColors.ctText3,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Panel de chat ─────────────────────────────────────────────────────────────

class _ChatPanel extends ConsumerStatefulWidget {
  const _ChatPanel();

  @override
  ConsumerState<_ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends ConsumerState<_ChatPanel>
    with WidgetsBindingObserver {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<Map<String, dynamic>> _apiMessages = [];
  bool _msgLoading = false;
  bool? _windowOpen; // null = cargando, true = abierta, false = cerrada
  bool _streamError = false;
  bool _sending = false;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  String? _firstUnreadMessageId;
  final _firstUnreadKey = GlobalKey();
  final Set<String> _processedReadIds = {};
  // Optimistic reactions keyed by wa_message_id of the target message
  final Map<String, List<String>> _pendingReactions = {};

  // Multimedia
  bool _isDragOver = false;
  StreamSubscription? _pasteSub;

  // Voice recording
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  html.MediaRecorder? _mediaRecorder;
  html.MediaStream? _micStream;
  final List<html.Blob> _recordingChunks = [];
  String _recordingMimeType = 'audio/webm';

  // Track current subscribed chatId to avoid re-subscribing on web tab focus
  String? _subscribedChatId;

  // Supervisor mode — true after user explicitly taps "Intervenir"
  bool _isSupervisorMode = false;

  // Auto-scroll state
  bool _atBottom = true;       // true mientras el usuario esté cerca del fondo
  bool _hasNewMessage = false; // badge "↓ Nuevo mensaje" visible

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pasteSub = html.document.onPaste.listen(_handleDocumentPaste);
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    final nearBottom = pos.maxScrollExtent - pos.pixels <= 100;
    if (nearBottom != _atBottom) setState(() => _atBottom = nearBottom);
    if (nearBottom && _hasNewMessage) setState(() => _hasNewMessage = false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final chatId = ref.read(selectedChatIdProvider);
    final tenantId = ref.read(activeTenantIdProvider);
    // Require tenantId to be loaded before subscribing; otherwise the
    // stream would have no tenant filter and deliver cross-tenant messages.
    if (chatId != null && tenantId.isNotEmpty && _apiMessages.isEmpty && !_msgLoading) {
      _subscribeToMessages(chatId);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final chatId = ref.read(selectedChatIdProvider);
      // Only re-subscribe if chatId changed — on web, 'resumed' fires on every
      // tab focus/blur which would spam read receipts if we always re-subscribe.
      if (chatId != null && chatId != _subscribedChatId) {
        _subscribeToMessages(chatId);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _pasteSub?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToFirstUnread() {
    if (!_scrollCtrl.hasClients) return;

    if (_firstUnreadMessageId == null) {
      _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      // ListView.builder solo mide ítems visibles en el primer frame; maxScrollExtent
      // puede estar subestimado. Un segundo jump tras el re-layout alcanza el fondo real.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollCtrl.hasClients) return;
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      });
      return;
    }

    // Try to scroll to the separator via GlobalKey
    final ctx = _firstUnreadKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.0,
        duration: const Duration(milliseconds: 300),
      );
    } else {
      // Fallback: estimate by index
      final idx = _apiMessages
          .indexWhere((m) => (m['id'] as String?) == _firstUnreadMessageId);
      if (idx >= 0) {
        final offset = (idx * 80.0)
            .clamp(0.0, _scrollCtrl.position.maxScrollExtent);
        _scrollCtrl.jumpTo(offset);
      } else {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    }
  }

  String? _activeChannelId() {
    return ref.read(selectedChannelIdProvider);
  }

  Future<void> _sendReadReceipts(List<Map<String, dynamic>> messages) async {
    final tenantId = ref.read(activeTenantIdProvider);
    if (tenantId.isEmpty) {
      debugPrint('[markRead] SKIP — tenantId empty');
      return;
    }
    // Fase 1: recolectar IDs pendientes (dedup + validación),
    // añadiendo a _processedReadIds antes del async para evitar
    // que un segundo emit encole los mismos IDs mientras este procesa.
    final pending = <({String waId, String channelId})>[];
    for (final msg in messages) {
      if ((msg['direction'] as String?) == 'outbound') continue;

      // Only process messages that belong to the active tenant.
      // The stream subscription may lack a tenant filter if tenantId was
      // empty at subscription time, so messages from other tenants can
      // arrive here — calling markRead for them causes 400s from Meta.
      final msgTenantId = msg['tenant_id'] as String?;
      if (msgTenantId != tenantId) {
        debugPrint('[markRead] SKIP tenant mismatch — msgTenant=$msgTenantId activeTenant=$tenantId');
        continue;
      }

      final waId = msg['wa_message_id'] as String?;
      if (waId == null || waId.isEmpty || waId == 'null') continue;
      // Validate it is a real Meta wamid (format: wamid.XXXXX)
      if (!waId.startsWith('wamid.')) {
        debugPrint('[markRead] SKIP invalid waId format: "$waId"');
        continue;
      }
      if (_processedReadIds.contains(waId)) continue;

      final channelId = msg['channel_id'] as String? ?? '';
      if (channelId.isEmpty) {
        debugPrint('[markRead] SKIP — no channel_id for $waId');
        continue;
      }

      _processedReadIds.add(waId);
      pending.add((waId: waId, channelId: channelId));
    }
    // Fase 2: procesar en serie con 50ms entre requests para
    // evitar la ráfaga de N POSTs simultáneos en el primer emit.
    for (final item in pending) {
      if (!mounted) return;
      debugPrint('[markRead] CALLING — tenantId=$tenantId waId=${item.waId} channelId=${item.channelId}');
      await MessagesApi.markRead(item.waId, tenantId: tenantId, channelId: item.channelId);
      if (item.waId != pending.last.waId) await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  void _handleTyping() {
    final tenantId = ref.read(activeTenantIdProvider);
    if (tenantId.isEmpty) return;
    final lastInbound = _apiMessages
        .lastWhere(
          (m) => (m['direction'] as String?) != 'outbound' &&
              (m['wa_message_id'] as String?) != null &&
              (m['wa_message_id'] as String?)!.isNotEmpty,
          orElse: () => {},
        );
    final waId = lastInbound['wa_message_id'] as String?;
    if (waId == null || waId.isEmpty || waId == 'null') return;
    final channelId = lastInbound['channel_id'] as String? ?? '';
    if (channelId.isEmpty) {
      debugPrint('[_handleTyping] SKIP — no channel_id');
      return;
    }
    MessagesApi.sendTyping(waId, tenantId: tenantId, channelId: channelId); // fire-and-forget
  }

  Future<void> _sendReaction(
      Map<String, dynamic> msg, String emoji) async {
    final waId = msg['wa_message_id'] as String?;
    if (waId == null || waId.isEmpty) return;
    final chatId = ref.read(selectedChatIdProvider) ?? '';
    final tenantId = ref.read(activeTenantIdProvider);
    final channelId = msg['channel_id'] as String? ?? '';
    if (channelId.isEmpty) {
      debugPrint('[_sendReaction] SKIP — no channel_id for $waId');
      return;
    }
    // Optimistic: mostrar reacción antes de que el POST confirme
    if (mounted) {
      setState(() {
        final existing = _pendingReactions.putIfAbsent(waId, () => []);
        if (!existing.contains(emoji)) existing.add(emoji);
      });
    }
    try {
      await MessagesApi.sendReaction(
        messageId: waId,
        emoji: emoji,
        toPhone: chatId,
        tenantId: tenantId,
        channelId: channelId,
      );
    } catch (e) {
      if (mounted) {
        // Revertir actualización optimista
        setState(() => _pendingReactions[waId]?.remove(emoji));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al enviar reacción: $e'),
          backgroundColor: AppColors.ctDanger,
          duration: const Duration(seconds: 3),
        ));
      }
    }
  }

  // ── Multimedia ──────────────────────────────────────────────────────────────

  void _handleDocumentPaste(html.ClipboardEvent event) {
    try {
      final items = event.clipboardData?.items;
      if (items == null) return;
      final len = items.length ?? 0;
      for (var i = 0; i < len; i++) {
        final item = items[i];
        final type = item.type ?? '';
        if (type.startsWith('image/')) {
          final file = item.getAsFile();
          if (file == null) return;
          event.preventDefault();
          final reader = html.FileReader();
          reader.readAsArrayBuffer(file);
          reader.onLoadEnd.listen((_) {
            try {
              final result = reader.result;
              Uint8List? bytes;
              if (result is Uint8List) {
                bytes = result;
              } else if (result is ByteBuffer) {
                bytes = result.asUint8List();
              }
              if (bytes != null && mounted) {
                final name = 'clipboard_image_${DateTime.now().millisecondsSinceEpoch}.png';
                _openPreviewModal(bytes, name);
              }
            } catch (_) {}
          });
          break;
        }
      }
    } catch (_) {}
  }

  Future<void> _pickFile(String type) async {
    try {
      FilePickerResult? result;
      if (type == 'image') {
        result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
      } else if (type == 'audio') {
        result = await FilePicker.platform.pickFiles(type: FileType.audio, withData: true);
      } else {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'],
          withData: true,
        );
      }
      if (result == null) return;
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;
      if (mounted) _openPreviewModal(bytes, file.name);
    } catch (_) {}
  }

  void _openPreviewModal(Uint8List bytes, String filename, {int? audioDuration}) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) => _MediaPreviewDialog(
        bytes: bytes,
        filename: filename,
        audioDuration: audioDuration,
        onSend: (caption) {
          // Use dialog's own context so the barrier closes immediately
          Navigator.of(dialogContext).pop();
          _sendMedia(bytes, filename, caption);
        },
      ),
    );
  }

  Future<void> _sendMedia(Uint8List bytes, String filename, String? caption) async {
    final chatId = ref.read(selectedChatIdProvider) ?? '';
    if (chatId.isEmpty) return;
    final tenantId = ref.read(activeTenantIdProvider);
    final channelId = _activeChannelId() ?? '';
    if (channelId.isEmpty) {
      debugPrint('[_sendMedia] SKIP — no channelId');
      return;
    }
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (mounted) setState(() { _sending = true; _isDragOver = false; });
    try {
      await MessagesApi.sendMedia(
        to: chatId,
        fileBytes: bytes,
        filename: filename,
        tenantId: tenantId,
        channelId: channelId,
        caption: caption,
        sentByUserId: userId,
      );
      if (mounted) setState(() { _sending = false; _isDragOver = false; });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() { _sending = false; _isDragOver = false; });
      final String errorMsg = _dioErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMsg),
        backgroundColor: const Color(0xFFEF4444),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() { _sending = false; _isDragOver = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al enviar archivo: $e'),
        backgroundColor: const Color(0xFFEF4444),
      ));
    }
  }

  /// Extrae un mensaje legible de un [DioException] sin usar ! en datos opcionales.
  String _dioErrorMessage(DioException e) {
    final response = e.response;
    if (response == null) {
      // Timeout, sin conexión, etc.
      return 'Error de conexión al enviar archivo';
    }
    final data = response.data;
    if (data is Map) {
      final detail = data['detail'];
      if (detail != null) return 'Error: $detail';
    }
    final status = response.statusCode;
    if (status == 415) return 'Formato de archivo no soportado por WhatsApp';
    if (status != null) return 'Error $status al enviar archivo';
    return 'Error desconocido al enviar archivo';
  }

  void _handleAttach(String type) {
    switch (type) {
      case 'image':
      case 'doc':
        _pickFile(type);
        break;
      case 'location-request':
        _sendLocationRequest();
        break;
    }
  }

  Future<void> _sendLocationRequest() async {
    final chatId = ref.read(selectedChatIdProvider) ?? '';
    if (chatId.isEmpty) return;
    final tenantId = ref.read(activeTenantIdProvider);
    final channelId = _activeChannelId() ?? '';
    if (channelId.isEmpty) {
      debugPrint('[_sendLocationRequest] SKIP — no channelId');
      return;
    }
    final userId = Supabase.instance.client.auth.currentUser?.id;
    try {
      await MessagesApi.sendLocationRequest(
        to: chatId,
        tenantId: tenantId,
        channelId: channelId,
        sentByUserId: userId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Solicitud de ubicación enviada'),
          backgroundColor: Color(0xFF10B981),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('❌ Error al enviar solicitud'),
          backgroundColor: Color(0xFFEF4444),
        ));
      }
    }
  }

  /// Picks the first MIME type the browser's MediaRecorder actually accepts.
  /// The MediaRecorder constructor throws NotSupportedError for unsupported
  /// types, so we probe by construction and discard the test instance.
  String _pickRecorderMimeType(html.MediaStream stream) {
    for (final mime in const [
      'audio/ogg;codecs=opus',       // Firefox — Meta acepta
      'audio/mp4;codecs=mp4a.40.2',  // Chrome AAC — Meta acepta
      'audio/mp4',                    // mp4 genérico
      'audio/webm;codecs=opus',       // último recurso — Meta no acepta webm
    ]) {
      try {
        html.MediaRecorder(stream, {'mimeType': mime}); // throws if unsupported
        return mime;
      } catch (_) {}
    }
    return 'audio/mp4'; // fallback: mp4 sobre webm
  }

  Future<void> _startVoiceRecording() async {
    try {
      final stream = await html.window.navigator.mediaDevices!
          .getUserMedia({'audio': true, 'video': false});
      _micStream = stream;
      _recordingChunks.clear();
      final mimeType = _pickRecorderMimeType(stream);
      _recordingMimeType = mimeType;
      final recorder = html.MediaRecorder(stream, {'mimeType': mimeType});
      _mediaRecorder = recorder;
      recorder.addEventListener('dataavailable', (html.Event event) {
        try {
          // ignore: avoid_dynamic_calls
          final data = (event as dynamic).data;
          if (data == null) return;
          final blob = data as html.Blob;
          if (blob.size > 0) _recordingChunks.add(blob);
        } catch (_) {}
      });
      recorder.start();
      if (mounted) {
        setState(() {
          _isRecording = true;
          _recordingSeconds = 0;
        });
      }
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordingSeconds++);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('No se pudo acceder al micrófono: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ));
      }
    }
  }

  Future<void> _stopVoiceRecording() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    final recorder = _mediaRecorder;
    if (recorder == null) return;

    final stopCompleter = Completer<void>();
    recorder.addEventListener('stop', (html.Event _) {
      if (!stopCompleter.isCompleted) stopCompleter.complete();
    });
    recorder.stop();
    _micStream?.getTracks().forEach((t) => t.stop());
    if (mounted) setState(() => _isRecording = false);

    await stopCompleter.future;

    if (_recordingChunks.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se capturó audio. Intenta de nuevo.'),
          backgroundColor: Color(0xFFEF4444),
        ));
      }
      return;
    }

    try {
      final mimeType = _recordingMimeType;
      final blob = html.Blob(_recordingChunks, mimeType);

      if (blob.size == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No se capturó audio. Intenta de nuevo.'),
            backgroundColor: Color(0xFFEF4444),
          ));
        }
        return;
      }

      final fileReader = html.FileReader();
      final readCompleter = Completer<Uint8List>();

      fileReader.onLoad.listen((_) {
        try {
          final result = fileReader.result;
          Uint8List bytes;
          if (result is ByteBuffer) {
            bytes = result.asUint8List();
          } else if (result is Uint8List) {
            bytes = result;
          } else {
            // Last resort for environments where result wraps a raw JS ArrayBuffer
            // ignore: avoid_dynamic_calls
            bytes = (result as dynamic).asUint8List() as Uint8List;
          }
          if (!readCompleter.isCompleted) readCompleter.complete(bytes);
        } catch (e) {
          if (!readCompleter.isCompleted) readCompleter.completeError(e);
        }
      });
      fileReader.onError.listen((_) {
        if (!readCompleter.isCompleted) {
          readCompleter.completeError('FileReader error');
        }
      });

      fileReader.readAsArrayBuffer(blob);
      final bytes = await readCompleter.future;

      if (bytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No se capturó audio. Intenta de nuevo.'),
            backgroundColor: Color(0xFFEF4444),
          ));
        }
        return;
      }

      final ext = mimeType.contains('ogg') ? 'ogg' : mimeType.contains('mp4') ? 'mp4' : 'webm';
      await _sendMedia(bytes, 'voice_note.$ext', null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al procesar audio: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ));
      }
    }
  }

  void _cancelVoiceRecording() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _mediaRecorder?.stop();
    _micStream?.getTracks().forEach((t) => t.stop());
    _recordingChunks.clear();
    if (mounted) setState(() => _isRecording = false);
  }

  Widget _buildDragOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: AppColors.ctTeal.withValues(alpha: 0.2),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_downward_rounded, size: 52, color: AppColors.ctTeal),
              SizedBox(height: 12),
              Text(
                'Suelta para adjuntar',
                style: TextStyle(fontFamily: 'Geist', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ctTeal),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _subscribeToMessages(String chatId) {
    _subscription?.cancel();
    _subscribedChatId = chatId;
    _processedReadIds.clear();
    _pendingReactions.clear();
    setState(() {
      _msgLoading = true;
      _apiMessages = [];
      _firstUnreadMessageId = null;
      _windowOpen = null;
      _isSupervisorMode = false;
      _atBottom = true;
      _hasNewMessage = false;
      _streamError = false;
    });

    // Use the pre-tap lastRead so we correctly find "new" messages
    final lastRead = _ConvoListState._preOpenLastRead[chatId];

    final tenantId = ref.read(activeTenantIdProvider);
    var firstEmit = true;
    _subscription = SupabaseMessages.streamMessages(
      chatId,
      tenantId: tenantId.isNotEmpty ? tenantId : null,
    ).listen((messages) {
      if (!mounted) return;

      // Determine first unread only once, on first emit
      if (firstEmit && _firstUnreadMessageId == null) {
        if (lastRead != null) {
          for (final msg in messages) {
            if ((msg['direction'] as String?) == 'outbound') continue;
            final receivedAt =
                DateTime.tryParse(msg['received_at'] as String? ?? '');
            if (receivedAt != null && receivedAt.isAfter(lastRead)) {
              _firstUnreadMessageId = msg['id'] as String?;
              break;
            }
          }
        }
      }

      // Mientras el chat está abierto, marcar mensajes como leídos en tiempo real
      _ConvoListState.setLastRead(
          chatId, DateTime.now().toUtc(), ref.read(activeTenantIdProvider));
      final lastInbound = messages
          .where((m) => (m['direction'] as String?) != 'outbound')
          .lastOrNull;
      final receivedAt = lastInbound != null
          ? DateTime.tryParse(lastInbound['received_at'] as String? ?? '')
          : null;
      final channelType = ref.read(selectedChannelTypeProvider);
      final operatorId  = ref.read(selectedConvOperatorIdProvider);
      final hasRecentInbound = receivedAt != null &&
          DateTime.now().toUtc().difference(receivedAt.toUtc()).inHours < 24;
      final computed = operatorId == null
          ? true
          : (channelType != 'whatsapp') || hasRecentInbound;
      setState(() {
        _apiMessages = messages;
        _msgLoading = false;
        _windowOpen = computed;
        _streamError = false;
      });
      _sendReadReceipts(messages);

      if (firstEmit) {
        firstEmit = false;
        WidgetsBinding.instance.addPostFrameCallback(
            (_) => _scrollToFirstUnread());
      } else {
        // Emit posterior: mensaje nuevo en tiempo real
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_scrollCtrl.hasClients) return;
          if (_atBottom) {
            _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
          } else {
            setState(() => _hasNewMessage = true);
          }
        });
      }
    }, onError: (_) {
      if (mounted) setState(() { _msgLoading = false; _streamError = true; });
    });
  }

  bool _isGoogleMapsUrl(String text) {
    final lower = text.toLowerCase();
    return lower.contains('maps.google.com') ||
        lower.contains('google.com/maps') ||
        lower.contains('goo.gl/maps') ||
        lower.contains('maps.app.goo.gl');
  }

  Future<void> _intervene() async {
    final chatId = ref.read(selectedChatIdProvider);
    if (chatId == null) return;
    setState(() => _isSupervisorMode = true);
    try {
      final tenantId = ref.read(activeTenantIdProvider);
      final sessionId = await SessionsApi.findActiveSessionId(
        chatId: chatId,
        tenantId: tenantId,
      );
      if (sessionId != null) {
        await SessionsApi.patchStatus(sessionId: sessionId, status: 'supervisor');
      }
    } catch (_) {
      // best-effort — supervisor mode is already enabled locally
    }
  }

  Future<void> _stopIntervening() async {
    final chatId = ref.read(selectedChatIdProvider);
    if (chatId == null) return;
    setState(() => _isSupervisorMode = false);
    try {
      final tenantId = ref.read(activeTenantIdProvider);
      final sessionId = await SessionsApi.findActiveSessionId(
        chatId: chatId,
        tenantId: tenantId,
      );
      if (sessionId != null) {
        await SessionsApi.patchStatus(sessionId: sessionId, status: 'worker');
      }
    } catch (_) {
      // best-effort
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    final chatId = ref.read(selectedChatIdProvider) ?? '';
    if (chatId.isEmpty) return;

    final tenantId = ref.read(activeTenantIdProvider);
    if (tenantId.isEmpty) return;

    final channelId = _activeChannelId() ?? '';
    if (channelId.isEmpty) {
      debugPrint('[_sendMessage] SKIP — no channelId');
      return;
    }

    // Auto-detect Google Maps URLs
    if (_isGoogleMapsUrl(text)) {
      _msgCtrl.clear();
      setState(() => _sending = true);
      try {
        await MessagesApi.sendLocation(
          to: chatId,
          tenantId: tenantId,
          channelId: channelId,
          googleMapsUrl: text,
          sentByUserId: Supabase.instance.client.auth.currentUser?.id,
        );
        if (mounted) {
          setState(() => _sending = false);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _scrollCtrl.hasClients) {
              _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Ubicación enviada'),
            backgroundColor: Color(0xFF10B981),
          ));
        }
      } on DioException catch (e) {
        if (mounted) {
          setState(() => _sending = false);
          final isInvalid = e.response?.statusCode == 400;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isInvalid ? '❌ URL de Google Maps no válida' : '❌ Error al enviar ubicación'),
            backgroundColor: const Color(0xFFEF4444),
          ));
        }
      } catch (e) {
        if (mounted) {
          setState(() => _sending = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('❌ Error al enviar ubicación'),
            backgroundColor: Color(0xFFEF4444),
          ));
        }
      }
      return;
    }

    final replyTo = ref.read(replyingToProvider);
    ref.read(replyingToProvider.notifier).state = null;

    _msgCtrl.clear();
    setState(() => _sending = true);

    try {
      await MessagesApi.sendWhatsAppMessage(
          to: chatId,
          text: text,
          tenantId: tenantId,
          channelId: channelId,
          sentByUserId: Supabase.instance.client.auth.currentUser?.id,
          replyToMessageId: replyTo?['wa_message_id'] as String?);
      if (mounted) {
        setState(() => _sending = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scrollCtrl.hasClients) {
            _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Widget _buildMessageBubble(
    Map<String, dynamic> msg, {
    required Map<String, List<String>> reactionsMap,
  }) {
    final direction = msg['direction'] as String? ?? 'inbound';
    final isOutbound = direction == 'outbound';
    final msgId = msg['id'] as String? ?? '';
    final msgWaId = msg['wa_message_id'] as String?;

    // Resolve reply context
    final contextMsgId = msg['context_message_id'] as String?;
    String? contextFrom;
    String? contextBody;
    if (contextMsgId != null && contextMsgId.isNotEmpty) {
      final ref_ = _apiMessages.cast<Map<String, dynamic>?>().firstWhere(
            (m) =>
                (m!['wa_message_id'] as String?) == contextMsgId ||
                (m['id'] as String?) == contextMsgId,
            orElse: () => null,
          );
      if (ref_ != null) {
        // Bug 2 fix: resolve display name from original message
        final refIsOutbound = (ref_['direction'] as String?) == 'outbound';
        contextFrom = refIsOutbound
            ? _outboundSenderName(ref_)
            : (ref_['from_name'] as String? ??
                ref_['from_phone'] as String? ?? '');
        // Bug 3 & 4 fix: media-aware preview
        final refType = ref_['message_type'] as String?;
        final refBody = ref_['raw_body'] as String? ?? '';
        if (refBody.isNotEmpty) {
          contextBody = refBody;
        } else {
          contextBody = switch (refType) {
            'image'    => '📷 Imagen',
            'video'    => '🎥 Video',
            'document' => '📄 Documento',
            'audio'    => '🎵 Audio',
            'location' => '📍 Ubicación',
            _          => null,
          };
        }
      } else {
        // Original not found: fall back to raw context_from (phone) as name
        contextFrom = msg['context_from'] as String?;
        contextBody = null; // → "Mensaje citado"
      }
    }

    // Reactions for this message: keyed by wa_message_id or id
    final msgReactions = reactionsMap[msgWaId ?? msgId] ??
        reactionsMap[msgId] ??
        const <String>[];

    final originStyle = isOutbound ? _outboundOriginStyle(msg) : null;

    // "Sin operador" badge for unregistered inbound with no assigned operator
    final isUnregisteredNoOp = !isOutbound &&
        (msg['unregistered'] as bool? ?? false) &&
        msg['operator_id'] == null;
    final inboundBadge = isUnregisteredNoOp
        ? _OriginBadge(label: 'Sin operador', bg: AppColors.ctSurface2, fg: AppColors.ctText2)
        : null;

    return _ApiMessageBubble(
      key: ValueKey(msgId),
      body: _msgBody(msg),
      time: _formatTime(msg['received_at'] as String?),
      senderName: isOutbound
          ? _outboundSenderName(msg)
          : (msg['from_name'] as String? ??
              msg['from_phone'] as String? ?? ''),
      isOutbound: isOutbound,
      waStatus: msg['wa_status'] as String?,
      messageType: msg['message_type'] as String?,
      mediaUrl: msg['media_url'] as String?,
      hasContext: contextMsgId != null && contextMsgId.isNotEmpty,
      contextFrom: contextFrom,
      contextBody: contextBody,
      reactions: msgReactions,
      onReply: () =>
          ref.read(replyingToProvider.notifier).state = msg,
      onReact: (emoji) => _sendReaction(msg, emoji),
      senderNameColor: originStyle?.nameColor,
      senderBadge: originStyle?.badge ?? inboundBadge,
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 48,
            color: AppColors.ctText3,
          ),
          SizedBox(height: 12),
          Text(
            'Selecciona una conversación',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 14,
              color: AppColors.ctText3,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatId = ref.watch(selectedChatIdProvider);
    final chatName = ref.watch(selectedChatNameProvider);

    ref.listen<String?>(selectedChatIdProvider, (prev, next) {
      if (next != null && next != prev) _subscribeToMessages(next);
    });

    // If the tenant was not loaded when didChangeDependencies first ran,
    // subscribe now that we have a valid tenantId.
    ref.listen<String>(activeTenantIdProvider, (prev, next) {
      if (next.isNotEmpty && prev != next) {
        final cid = ref.read(selectedChatIdProvider);
        // Re-subscribe only if we have no active subscription yet (or the
        // existing one was created without tenant filtering).
        if (cid != null && (cid != _subscribedChatId || _apiMessages.isEmpty)) {
          debugPrint('[ChatPanel] tenant loaded ($next), re-subscribing for chat $cid');
          _subscribeToMessages(cid);
        }
      }
    });

    if (chatId == null) return _emptyState();

    final channels       = ref.watch(selectedOperatorChannelsProvider);
    final activeChannelId = ref.watch(selectedChannelIdProvider);
    final activeChannel   = channels
        .where((c) => (c['channel_id'] as String?) == activeChannelId)
        .firstOrNull;

    final channelFiltered = activeChannelId != null
        ? _apiMessages.where((m) {
            final msgChannelId = m['channel_id'] as String?;
            return msgChannelId == null || msgChannelId == activeChannelId;
          }).toList()
        : List<Map<String, dynamic>>.from(_apiMessages);

    // Build reactions map (keyed by reaction_message_id) and filter out
    // reaction-type messages from the display list.
    final reactionsMap = <String, List<String>>{};
    for (final m in channelFiltered) {
      if ((m['message_type'] as String?) == 'reaction') {
        final targetId = m['reaction_message_id'] as String?;
        final emoji = m['reaction_emoji'] as String?;
        if (targetId != null && targetId.isNotEmpty &&
            emoji != null && emoji.isNotEmpty) {
          (reactionsMap[targetId] ??= []).add(emoji);
        }
      }
    }
    // Merge pending (optimistic) reactions, avoiding duplicates.
    for (final entry in _pendingReactions.entries) {
      final existing = reactionsMap.putIfAbsent(entry.key, () => []);
      for (final e in entry.value) {
        if (!existing.contains(e)) existing.add(e);
      }
    }
    final visibleMessages = channelFiltered
        .where((m) => (m['message_type'] as String?) != 'reaction')
        .toList();

    final replyingTo = ref.watch(replyingToProvider);

    final body = Column(
      children: [
        // Header
        _ApiChatHeader(
          name: chatName ?? chatId,
          windowOpen: _windowOpen,
          channelName: activeChannel?['name'] as String?,
          workerName: activeChannel?['worker_name'] as String?,
          channelColor: activeChannel?['color'] as String?,
          onIntervene: hasPermission(ref, 'conversations', 'send')
              ? (!_isSupervisorMode ? _intervene : _stopIntervening)
              : null,
          isSupervisorMode: _isSupervisorMode,
        ),

        // Mensajes
        if (_msgLoading)
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_streamError)
          Expanded(
            child: ColoredBox(
              color: const Color(0xFFEBEBE9),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded,
                        size: 40, color: AppColors.ctText3),
                    const SizedBox(height: 12),
                    const Text(
                      'No se pudieron cargar los mensajes',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 13,
                        color: AppColors.ctText3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => _subscribeToMessages(chatId),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Reintentar',
                          style: TextStyle(fontFamily: 'Geist', fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ctTeal,
                        side: const BorderSide(color: AppColors.ctTeal),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ColoredBox(
              color: const Color(0xFFEBEBE9),
              child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 16),
              itemCount: visibleMessages.length,
              itemBuilder: (context, i) {
                final msg = visibleMessages[i];
                final msgId = msg['id'] as String?;
                final isFirstUnread = msgId != null &&
                    msgId == _firstUnreadMessageId;

                if (isFirstUnread) {
                  return Column(
                    key: _firstUnreadKey,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Divider(
                                color: Color(0xFF2DD4BF),
                                thickness: 0.5,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                'Mensajes nuevos',
                                style: TextStyle(
                                  fontFamily: 'Geist',
                                  fontSize: 11,
                                  color: Color(0xFF2DD4BF),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(
                                color: Color(0xFF2DD4BF),
                                thickness: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildMessageBubble(msg,
                          reactionsMap: reactionsMap),
                    ],
                  );
                }
                return _buildMessageBubble(msg,
                    reactionsMap: reactionsMap);
              },
            ),
            ),
          ),

        // Banner ventana cerrada
        if (_windowOpen == false)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            color: const Color(0xFFFEF3C7),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 16, color: Color(0xFF92400E)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ventana de 24hrs cerrada. Solo puedes enviar plantillas aprobadas.',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 11,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Reply bar (shown when replying to a message)
        if (replyingTo != null)
          _ReplyBar(
            message: replyingTo,
            onDismiss: () =>
                ref.read(replyingToProvider.notifier).state = null,
          ),

        // Badge "Nuevo mensaje"
        if (_hasNewMessage)
          GestureDetector(
            onTap: () {
              if (_scrollCtrl.hasClients) {
                _scrollCtrl.animateTo(
                  _scrollCtrl.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                );
              }
              setState(() => _hasNewMessage = false);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              color: AppColors.ctTeal.withValues(alpha: 0.12),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_downward_rounded,
                      size: 13, color: AppColors.ctTealDark),
                  SizedBox(width: 6),
                  Text(
                    'Nuevo mensaje',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ctTealDark,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Input
        _ChatInput(
          controller: _msgCtrl,
          onSend: (_windowOpen == true && _isSupervisorMode) ? _sendMessage : null,
          onTyping: (_windowOpen == true && _isSupervisorMode) ? _handleTyping : null,
          sending: _sending,
          enabled: _windowOpen == true && _isSupervisorMode,
          onAttach: _handleAttach,
          onMic: (_windowOpen == true && _isSupervisorMode) ? _startVoiceRecording : null,
          isRecording: _isRecording,
          recordingSeconds: _recordingSeconds,
          onStop: _stopVoiceRecording,
          onCancel: _cancelVoiceRecording,
        ),
      ],
    );

    return DropTarget(
      onDragDone: (details) {
        if (details.files.isEmpty) return;
        final file = details.files.first;
        file.readAsBytes().then((bytes) {
          if (mounted) _openPreviewModal(bytes, file.name);
        });
        setState(() => _isDragOver = false);
      },
      onDragEntered: (_) => setState(() => _isDragOver = true),
      onDragExited: (_) => setState(() => _isDragOver = false),
      child: Stack(
        children: [
          body,
          if (_isDragOver) _buildDragOverlay(),
        ],
      ),
    );
  }
}

// ── Intervene button ──────────────────────────────────────────────────────────

class _InterveneButton extends StatefulWidget {
  const _InterveneButton({required this.onTap, this.isSupervisorMode = false});
  final VoidCallback onTap;
  final bool isSupervisorMode;

  @override
  State<_InterveneButton> createState() => _InterveneButtonState();
}

class _InterveneButtonState extends State<_InterveneButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isSupervisorMode;
    final borderColor = isActive ? AppColors.ctTeal : const Color(0xFFFB923C);
    final hoverBg = isActive ? AppColors.ctTealLight : const Color(0xFFFFF7ED);
    final iconColor = isActive ? AppColors.ctTeal : const Color(0xFFFB923C);
    final label = isActive ? 'Dejar de intervenir' : 'Intervenir';
    final icon = isActive ? Icons.stop_circle_outlined : Icons.pan_tool_outlined;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered ? hoverBg : (isActive ? AppColors.ctTealLight.withValues(alpha: 0.5) : Colors.transparent),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header de chat (modo API) ─────────────────────────────────────────────────

class _ApiChatHeader extends StatelessWidget {
  const _ApiChatHeader({
    required this.name,
    required this.windowOpen,
    this.channelName,
    this.workerName,
    this.channelColor,
    this.onIntervene,
    this.isSupervisorMode = false,
  });
  final String name;
  final bool? windowOpen;
  final String? channelName;
  final String? workerName;
  final String? channelColor;
  final VoidCallback? onIntervene;
  final bool isSupervisorMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.ctSurface,
        border: Border(bottom: BorderSide(color: AppColors.ctBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: AppColors.ctTealLight,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(name),
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.ctTealDark,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ctText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (windowOpen != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: windowOpen!
                              ? const Color(0xFFD1FAE5)
                              : AppColors.ctSurface2,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          windowOpen! ? 'Ventana abierta' : 'Ventana cerrada',
                          style: TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: windowOpen!
                                ? const Color(0xFF065F46)
                                : AppColors.ctText3,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  channelName != null
                      ? '$channelName${workerName != null ? ' · $workerName' : ''}'
                      : 'WhatsApp · Sin canal asignado',
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 11,
                    color: AppColors.ctText2,
                  ),
                ),
              ],
            ),
          ),
          if (onIntervene != null) ...[
            const SizedBox(width: 12),
            _InterveneButton(onTap: onIntervene!, isSupervisorMode: isSupervisorMode),
          ],
        ],
      ),
    );
  }
}

// ── Burbuja de mensaje (modo API) ─────────────────────────────────────────────

class _ApiMessageBubble extends StatefulWidget {
  const _ApiMessageBubble({
    super.key,
    required this.body,
    required this.time,
    required this.senderName,
    required this.isOutbound,
    this.waStatus,
    this.messageType,
    this.mediaUrl,
    this.hasContext = false,
    this.contextFrom,
    this.contextBody,
    this.reactions = const [],
    this.onReply,
    this.onReact,
    this.senderNameColor,
    this.senderBadge,
  });
  final String body;
  final String time;
  final String senderName;
  final bool isOutbound;
  final Color? senderNameColor;
  final Widget? senderBadge;
  final String? waStatus;
  final String? messageType;
  final String? mediaUrl;
  // Reply context
  final bool hasContext;
  final String? contextFrom;
  final String? contextBody;
  // Reactions
  final List<String> reactions;
  final VoidCallback? onReply;
  final void Function(String emoji)? onReact;

  @override
  State<_ApiMessageBubble> createState() => _ApiMessageBubbleState();
}

class _ApiMessageBubbleState extends State<_ApiMessageBubble> {
  double _swipeDx = 0;

  static final Set<String> _registeredMediaViews = {};

  void _onDragUpdate(DragUpdateDetails d) {
    if (d.delta.dx > 0 && widget.onReply != null) {
      setState(() =>
          _swipeDx = (_swipeDx + d.delta.dx).clamp(0.0, 64.0));
    }
  }

  void _onDragEnd(DragEndDetails d) {
    final triggered = _swipeDx >= 50;
    setState(() => _swipeDx = 0);
    if (triggered) widget.onReply?.call();
  }

  void _showEmojiPicker() {
    if (widget.onReact == null && widget.onReply == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _EmojiPickerSheet(
        onEmoji: (emoji) {
          Navigator.pop(context);
          widget.onReact?.call(emoji);
        },
        onReply: widget.onReply != null
            ? () {
                Navigator.pop(context);
                widget.onReply!();
              }
            : null,
      ),
    );
  }

  Widget _buildQuote() {
    final isOut = widget.isOutbound;
    final name = (widget.contextFrom?.isNotEmpty == true)
        ? widget.contextFrom!
        : 'Mensaje citado';
    final raw = widget.contextBody ?? '';
    final preview = raw.isNotEmpty
        ? (raw.length > 80 ? '${raw.substring(0, 80)}…' : raw)
        : 'Mensaje citado';
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isOut
            ? Colors.white.withValues(alpha: 0.5)
            : const Color(0xFFE4E8EA),
        borderRadius: BorderRadius.circular(6),
        border: Border(
          left: BorderSide(
            width: 3,
            color: isOut
                ? const Color(0xFF2DD4BF)
                : const Color(0xFF9CA3AF),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2DD4BF),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            preview,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 11,
              color: Color(0xFF667781),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionPills() {
    if (widget.reactions.isEmpty) return const SizedBox.shrink();
    final counts = <String, int>{};
    for (final e in widget.reactions) {
      counts[e] = (counts[e] ?? 0) + 1;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        children: counts.entries
            .map((entry) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    entry.value > 1
                        ? '${entry.key} ${entry.value}'
                        : entry.key,
                    style: const TextStyle(fontSize: 12),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _fallback(String label) => Text(
        label,
        style: const TextStyle(
            fontFamily: 'Geist', fontSize: 13, color: Color(0xFF667781)),
      );

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildImageContent() {
    final mUrl = (widget.mediaUrl?.isNotEmpty == true) ? widget.mediaUrl! : null;
    if (mUrl == null) return _fallback('[Imagen]');
    final caption =
        (widget.body.isNotEmpty && !widget.body.startsWith('[')) ? widget.body : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => showDialog(
            context: context,
            builder: (_) => Dialog(
              backgroundColor: Colors.transparent,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Image.network(mUrl,
                    errorBuilder: (ctx, e, s) => _fallback('[Imagen]')),
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              mUrl,
              width: 240,
              fit: BoxFit.cover,
              errorBuilder: (ctx, e, s) => _fallback('[Imagen]'),
            ),
          ),
        ),
        if (caption != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              caption,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 13,
                color: Color(0xFF111B21),
                height: 1.4,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAudioContent() {
    final mUrl = (widget.mediaUrl?.isNotEmpty == true) ? widget.mediaUrl! : null;
    if (mUrl == null) return _fallback('[Audio]');
    final audioViewId = 'audio-${mUrl.hashCode}';
    if (!_registeredMediaViews.contains(audioViewId)) {
      _registeredMediaViews.add(audioViewId);
      ui_web.platformViewRegistry.registerViewFactory(
        audioViewId,
        (int id) {
          final audio = html.AudioElement()
            ..controls = true
            ..style.width = '220px'
            ..style.outline = 'none'
            ..style.display = 'block';
          audio.append(html.SourceElement()
            ..src = mUrl
            ..type = 'audio/ogg');
          audio.append(html.SourceElement()
            ..src = mUrl
            ..type = 'audio/mpeg');
          return audio;
        },
      );
    }
    return SizedBox(
      width: 220,
      height: 54,
      child: HtmlElementView(viewType: audioViewId),
    );
  }

  Widget _buildVideoContent() {
    final mUrl = (widget.mediaUrl?.isNotEmpty == true) ? widget.mediaUrl! : null;
    if (mUrl == null) return _fallback('[Video]');
    final videoViewId = 'video-${mUrl.hashCode}';
    if (!_registeredMediaViews.contains(videoViewId)) {
      _registeredMediaViews.add(videoViewId);
      ui_web.platformViewRegistry.registerViewFactory(
        videoViewId,
        (int id) {
          final video = html.VideoElement()
            ..controls = true
            ..style.width = '240px'
            ..style.height = '135px'
            ..style.borderRadius = '8px'
            ..style.background = '#000'
            ..style.outline = 'none'
            ..style.display = 'block';
          video.append(html.SourceElement()
            ..src = mUrl
            ..type = 'video/mp4');
          return video;
        },
      );
    }
    final caption =
        (widget.body.isNotEmpty && !widget.body.startsWith('[')) ? widget.body : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 240,
          height: 135,
          child: HtmlElementView(viewType: videoViewId),
        ),
        if (caption != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              caption,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 13,
                color: Color(0xFF111B21),
                height: 1.4,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDocumentContent() {
    final mUrl = (widget.mediaUrl?.isNotEmpty == true) ? widget.mediaUrl! : null;
    if (mUrl == null) return _fallback('[Documento]');
    final fileName = Uri.parse(mUrl).pathSegments.lastOrNull ?? 'Documento';
    final caption =
        (widget.body.isNotEmpty && !widget.body.startsWith('[')) ? widget.body : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file, size: 24, color: Color(0xFF667781)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(fileName,
                  style: const TextStyle(
                      fontFamily: 'Geist', fontSize: 12, color: Color(0xFF111B21)),
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _openUrl(mUrl),
              child: const Text('Abrir',
                  style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 12,
                      color: Color(0xFF53BDEB),
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        if (caption != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              caption,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 13,
                color: Color(0xFF111B21),
                height: 1.4,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStickerContent() {
    final mUrl = (widget.mediaUrl?.isNotEmpty == true) ? widget.mediaUrl! : null;
    if (mUrl == null) return _fallback('[Sticker]');
    return Image.network(
      mUrl,
      width: 120,
      height: 120,
      fit: BoxFit.contain,
      errorBuilder: (ctx, e, s) => _fallback('[Sticker]'),
    );
  }

  Widget _buildLocationContent() {
    Map<String, dynamic>? locData;
    try {
      locData = jsonDecode(widget.body) as Map<String, dynamic>;
    } catch (_) {}
    final locName = locData?['name'] as String? ??
        locData?['address'] as String? ??
        'Ubicación compartida';
    final lat = locData?['latitude']?.toString() ?? '';
    final lng = locData?['longitude']?.toString() ?? '';
    final mapsUrl = (lat.isNotEmpty && lng.isNotEmpty)
        ? 'https://maps.google.com/?q=$lat,$lng'
        : 'https://maps.google.com/';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, color: Colors.red, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(locName,
                  style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111B21))),
            ),
          ],
        ),
        if (lat.isNotEmpty && lng.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 24),
            child: Text('$lat, $lng',
                style: const TextStyle(
                    fontFamily: 'Geist', fontSize: 11, color: Color(0xFF667781))),
          ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _openUrl(mapsUrl),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF53BDEB).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('Ver en mapa',
                style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 12,
                    color: Color(0xFF53BDEB),
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildTextContent() {
    return Text(
      widget.body,
      style: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 13,
          color: Color(0xFF111B21),
          height: 1.4),
    );
  }

  Widget _statusIcon() {
    switch (widget.waStatus) {
      case 'read':
        return const Icon(Icons.done_all,
            size: 12, color: Color(0xFF53BDEB));
      case 'delivered':
        return const Icon(Icons.done_all,
            size: 12, color: Color(0xFF667781));
      case 'sent':
        return const Icon(Icons.check,
            size: 12, color: Color(0xFF667781));
      case 'failed':
        return const Icon(Icons.error_outline,
            size: 12, color: Colors.red);
      default:
        return const Icon(Icons.check,
            size: 12, color: Color(0xFF667781));
    }
  }

  @override
  Widget build(BuildContext context) {
    const timeColor = Color(0xFF667781);
    final isSticker = widget.messageType == 'sticker';
    final isOutbound = widget.isOutbound;
    final bubbleBg = isSticker
        ? Colors.transparent
        : isOutbound
            ? const Color(0xFFD9FDD3)
            : Colors.white;

    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bubbleBg,
        borderRadius: isOutbound
            ? const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(2),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              )
            : const BorderRadius.only(
                topLeft: Radius.circular(2),
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
      ),
      child: Column(
        crossAxisAlignment: isOutbound
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (widget.hasContext) _buildQuote(),
          if (widget.senderName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.senderName,
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: widget.senderNameColor ?? timeColor,
                    ),
                  ),
                  if (widget.senderBadge != null) ...[
                    const SizedBox(width: 4),
                    widget.senderBadge!,
                  ],
                ],
              ),
            ),
          if (widget.messageType == 'image')   _buildImageContent(),
          if (widget.messageType == 'video')   _buildVideoContent(),
          if (widget.messageType == 'audio')   _buildAudioContent(),
          if (widget.messageType == 'document') _buildDocumentContent(),
          if (widget.messageType == 'sticker') _buildStickerContent(),
          if (widget.messageType == 'location') _buildLocationContent(),
          if (!const ['image', 'video', 'audio', 'document', 'sticker', 'location']
              .contains(widget.messageType))
            _buildTextContent(),
          const SizedBox(height: 3),
          if (isOutbound)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.time,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 10,
                    color: timeColor,
                  ),
                ),
                const SizedBox(width: 4),
                _statusIcon(),
              ],
            )
          else
            Text(
              widget.time,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 10,
                color: timeColor,
              ),
            ),
        ],
      ),
    );

    final bubbleWithReactions = Column(
      crossAxisAlignment:
          isOutbound ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        bubble,
        _buildReactionPills(),
      ],
    );

    // Reply icon that appears during swipe
    final replyHint = _swipeDx > 8
        ? Positioned(
            left: isOutbound ? null : 0,
            right: isOutbound ? 0 : null,
            top: 0,
            bottom: 0,
            child: Center(
              child: Opacity(
                opacity: (_swipeDx / 50).clamp(0.0, 1.0),
                child: const Icon(
                  Icons.reply_rounded,
                  color: Color(0xFF667781),
                  size: 20,
                ),
              ),
            ),
          )
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        onLongPress: _showEmojiPicker,
        child: Row(
          mainAxisAlignment:
              isOutbound ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isOutbound) const SizedBox(width: 60),
            Flexible(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Transform.translate(
                    offset: Offset(_swipeDx, 0),
                    child: bubbleWithReactions,
                  ),
                  ?replyHint,
                ],
              ),
            ),
            if (!isOutbound) const SizedBox(width: 60),
          ],
        ),
      ),
    );
  }
}

// ── Reply bar ─────────────────────────────────────────────────────────────────

class _ReplyBar extends StatelessWidget {
  const _ReplyBar({required this.message, required this.onDismiss});
  final Map<String, dynamic> message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final isOutbound = (message['direction'] as String?) == 'outbound';
    final name = isOutbound
        ? _outboundSenderName(message)
        : (message['from_name'] as String? ??
            message['from_phone'] as String? ?? '');
    final raw = message['raw_body'] as String? ?? '';
    final preview = raw.length > 60 ? '${raw.substring(0, 60)}…' : raw;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: const BoxDecoration(
        color: AppColors.ctSurface,
        border: Border(top: BorderSide(color: AppColors.ctBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF2DD4BF),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.reply_rounded,
                        size: 13, color: Color(0xFF2DD4BF)),
                    const SizedBox(width: 4),
                    Text(
                      'Respondiendo a $name',
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2DD4BF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  preview,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 11,
                    color: AppColors.ctText2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded,
                size: 16, color: AppColors.ctText2),
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}

// ── Emoji picker bottom sheet ─────────────────────────────────────────────────

class _EmojiPickerSheet extends StatelessWidget {
  const _EmojiPickerSheet({required this.onEmoji, this.onReply});
  final void Function(String emoji) onEmoji;
  final VoidCallback? onReply;

  static const _emojis = ['❤️', '👍', '😂', '😮', '😢', '👎'];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.ctSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ctBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _emojis
                .map((e) => GestureDetector(
                      onTap: () => onEmoji(e),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.ctSurface2,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(e,
                            style: const TextStyle(fontSize: 26)),
                      ),
                    ))
                .toList(),
          ),
          if (onReply != null) ...[
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.ctBorder),
            InkWell(
              onTap: onReply,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.reply_rounded,
                        size: 18, color: AppColors.ctText2),
                    SizedBox(width: 10),
                    Text(
                      'Responder',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 14,
                        color: AppColors.ctText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Input de chat ─────────────────────────────────────────────────────────────

class _ChatInput extends StatefulWidget {
  const _ChatInput({
    required this.controller,
    this.onSend,
    this.onTyping,
    this.sending = false,
    this.enabled = true,
    this.onAttach,
    this.onMic,
    this.isRecording = false,
    this.recordingSeconds = 0,
    this.onStop,
    this.onCancel,
  });
  final TextEditingController controller;
  final Future<void> Function()? onSend;
  final VoidCallback? onTyping;
  final bool sending;
  final bool enabled;
  final void Function(String type)? onAttach;
  final VoidCallback? onMic;
  final bool isRecording;
  final int recordingSeconds;
  final Future<void> Function()? onStop;
  final VoidCallback? onCancel;

  @override
  State<_ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<_ChatInput>
    with SingleTickerProviderStateMixin {
  bool _hoverSend = false;
  bool _stoppingRec = false;
  Timer? _typingTimer;
  late final AnimationController _pulse;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _focusNode = FocusNode(onKeyEvent: (node, event) {
      // En desktop/web: Enter envía, Shift+Enter inserta salto de línea
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.enter &&
          !HardwareKeyboard.instance.isShiftPressed) {
        final canSend =
            widget.onSend != null && !widget.sending && widget.enabled;
        if (canSend) widget.onSend!();
        return KeyEventResult.handled; // previene inserción de newline
      }
      return KeyEventResult.ignored;
    });
  }

  @override
  void didUpdateWidget(_ChatInput old) {
    super.didUpdateWidget(old);
    // Reset stopping state when a new recording starts
    if (widget.isRecording && !old.isRecording) {
      _stoppingRec = false;
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _pulse.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    if (widget.onTyping == null) return;
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 800), widget.onTyping!);
  }

  String _formatDuration(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  PopupMenuItem<String> _buildAttachItem(
      String value, IconData icon, Color color, String label) {
    return PopupMenuItem(
      value: value,
      height: 40,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 13,
                  color: AppColors.ctNavy)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ── Recording mode ──────────────────────────────────────────────
    if (widget.isRecording) {
      return Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: AppColors.ctSurface,
          border: Border(top: BorderSide(color: AppColors.ctBorder)),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: widget.onCancel,
              icon: const Icon(Icons.close_rounded,
                  size: 20, color: AppColors.ctText3),
              tooltip: 'Cancelar',
            ),
            const SizedBox(width: 4),
            FadeTransition(
              opacity: _pulse,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Grabando… ${_formatDuration(widget.recordingSeconds)}',
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 13,
                  color: AppColors.ctText,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: (_stoppingRec || widget.onStop == null)
                  ? null
                  : () async {
                      setState(() => _stoppingRec = true);
                      await widget.onStop!();
                      if (mounted) setState(() => _stoppingRec = false);
                    },
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.ctTeal),
              icon: const Icon(Icons.stop_rounded,
                  size: 16, color: AppColors.ctNavy),
              label: const Text(
                'Detener',
                style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 13,
                    color: AppColors.ctNavy,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    // ── Normal input mode ───────────────────────────────────────────
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.controller,
      builder: (context, value, _) {
        final textEmpty = value.text.isEmpty;
        final canSend =
            widget.onSend != null && !widget.sending && widget.enabled;
        final canMic =
            widget.onMic != null && widget.enabled && !widget.sending;

        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: AppColors.ctSurface,
            border:
                Border(top: BorderSide(color: AppColors.ctBorder)),
          ),
          child: Row(
            children: [
              // Attach button (no voice note — moved to mic button)
              if (widget.onAttach != null) ...[
                PopupMenuButton<String>(
                  onSelected: widget.onAttach,
                  tooltip: 'Adjuntar',
                  color: AppColors.ctSurface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  offset: const Offset(0, -175),
                  itemBuilder: (context) => [
                    _buildAttachItem('image', Icons.image_rounded,
                        const Color(0xFF3B82F6), 'Imagen'),
                    _buildAttachItem('doc',
                        Icons.description_rounded,
                        const Color(0xFFEF4444), 'Documento'),
                    _buildAttachItem(
                        'location-request',
                        Icons.location_searching_rounded,
                        AppColors.ctTeal,
                        'Solicitar ubicación'),
                  ],
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: const Icon(Icons.attach_file_rounded,
                        size: 20, color: AppColors.ctText3),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              // TextField
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  minLines: 1,
                  maxLines: 5,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 13,
                    color: AppColors.ctText,
                  ),
                  enabled: widget.enabled && !widget.sending,
                  onChanged: widget.enabled ? _onChanged : null,
                  decoration: InputDecoration(
                    hintText: widget.enabled
                        ? 'Escribe un mensaje…'
                        : 'Ventana de 24h cerrada — usa una plantilla',
                    hintStyle: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 13,
                      color: AppColors.ctText3,
                    ),
                    filled: true,
                    fillColor: AppColors.ctSurface2,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.ctBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.ctBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: AppColors.ctTeal, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Right button: mic (text empty) or send (text present)
              if (textEmpty && !widget.sending)
                MouseRegion(
                  cursor: canMic
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.basic,
                  child: GestureDetector(
                    onTap: canMic ? widget.onMic : null,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: canMic
                                ? AppColors.ctTeal
                                : AppColors.ctSurface2,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.mic_rounded,
                            size: 18,
                            color: canMic
                                ? AppColors.ctNavy
                                : AppColors.ctText3,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                MouseRegion(
                  onEnter: (_) =>
                      setState(() => _hoverSend = true),
                  onExit: (_) =>
                      setState(() => _hoverSend = false),
                  cursor: canSend
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.basic,
                  child: GestureDetector(
                    onTap: canSend ? widget.onSend : null,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: canSend
                                ? (_hoverSend
                                    ? AppColors.ctTealDark
                                    : AppColors.ctTeal)
                                : AppColors.ctSurface2,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: widget.sending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.ctNavy,
                                  ),
                                )
                              : Icon(
                                  Icons.send_rounded,
                                  size: 16,
                                  color: canSend
                                      ? AppColors.ctNavy
                                      : AppColors.ctText3,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Tab 2: Feed global ────────────────────────────────────────────────────────

class _TabFeed extends ConsumerStatefulWidget {
  const _TabFeed();

  @override
  ConsumerState<_TabFeed> createState() => _TabFeedState();
}

class _TabFeedState extends ConsumerState<_TabFeed> {
  DateTimeRange? _dateRange;
  TimeOfDay? _fromTime;
  TimeOfDay? _toTime;
  String _filterContact = '';
  String _filterContactPhone = '';
  String _filterDirection = '';
  String _filterFlow = '';
  String _keyword = '';
  final Set<String> _selectedIds = {};
  bool _selectionMode = false;
  List<Map<String, dynamic>> _feedMessages = [];
  StreamSubscription<List<Map<String, dynamic>>>? _feedSub;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _resubscribe();
  }

  @override
  void dispose() {
    _feedSub?.cancel();
    super.dispose();
  }

  void _resubscribe() {
    _feedSub?.cancel();
    setState(() => _loading = true);
    final tenantId = ref.read(activeTenantIdProvider);
    _feedSub = SupabaseMessages.streamFeed(
      direction: _filterDirection.isEmpty ? null : _filterDirection,
      keyword: _keyword.isEmpty ? null : _keyword,
      tenantId: tenantId.isNotEmpty ? tenantId : null,
    ).listen((messages) {
      if (!mounted) return;
      // messages arrive descending; filter then reverse to ascending for display
      final filtered = messages.where(_matchesFilters).toList().reversed.toList();
      setState(() {
        _feedMessages = filtered;
        _loading = false;
      });
    }, onError: (_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  bool _matchesFilters(Map<String, dynamic> msg) {
    final selectedChannelId = ref.read(selectedChannelIdProvider);
    if (selectedChannelId != null) {
      final msgChannelId = msg['channel_id'] as String?;
      if (msgChannelId != null && msgChannelId != selectedChannelId) return false;
    }
    if (_filterContact.isNotEmpty) {
      final direction = msg['direction'] as String?;
      final fromPhone = msg['from_phone'] as String? ?? '';
      final fromName = msg['from_name'] as String? ?? '';
      final toPhone = msg['to_phone'] as String? ?? '';
      // chat_id carries the recipient number on outbound messages
      final chatId = msg['chat_id'] as String? ?? '';
      final matchInbound = direction == 'inbound' &&
          (fromPhone == _filterContactPhone ||
              fromName == _filterContact);
      final matchOutbound = direction == 'outbound' &&
          (toPhone == _filterContactPhone || chatId == _filterContactPhone);
      if (!matchInbound && !matchOutbound) return false;
    }
    if (_filterFlow.isNotEmpty) {
      final flow = msg['flow_number'] as String? ?? '';
      if (flow != _filterFlow) return false;
    }
    return _matchesDateFilter(msg);
  }

  bool _matchesDateFilter(Map<String, dynamic> msg) {
    if (_dateRange == null && _fromTime == null) return true;
    final receivedAt =
        DateTime.tryParse(msg['received_at'] as String? ?? '');
    if (receivedAt == null) return false;
    final local = receivedAt.toLocal();
    if (_dateRange != null) {
      if (local.isBefore(_dateRange!.start)) { return false; }
      if (local.isAfter(
          _dateRange!.end.add(const Duration(days: 1)))) { return false; }
    }
    if (_fromTime != null) {
      final fromMinutes = _fromTime!.hour * 60 + _fromTime!.minute;
      final msgMinutes = local.hour * 60 + local.minute;
      if (msgMinutes < fromMinutes) { return false; }
    }
    if (_toTime != null) {
      final toMinutes = _toTime!.hour * 60 + _toTime!.minute;
      final msgMinutes = local.hour * 60 + local.minute;
      if (msgMinutes > toMinutes) { return false; }
    }
    return true;
  }

  // name → phone, built from inbound messages only
  Map<String, String> get _contactPhoneMap {
    final map = <String, String>{};
    for (final m in _feedMessages) {
      if ((m['direction'] as String?) != 'inbound') continue;
      final name = m['from_name'] as String? ?? '';
      final phone = m['from_phone'] as String? ?? '';
      if (name.isNotEmpty && phone.isNotEmpty) map[name] = phone;
    }
    return map;
  }

  List<String> get _uniqueContacts {
    final keys = _contactPhoneMap.keys.toList()..sort();
    return keys;
  }

  @override
  Widget build(BuildContext context) {
    // Reinicia el feed cuando cambia el tenant o el canal seleccionado
    ref.listen<String>(activeTenantIdProvider, (prev, next) {
      if (prev != null && prev != next) _resubscribe();
    });
    ref.listen<String?>(selectedChannelIdProvider, (prev, next) {
      if (prev != next) _resubscribe();
    });

    return Column(
      children: [
        _FeedFilters(
          dateRange: _dateRange,
          fromTime: _fromTime,
          toTime: _toTime,
          filterContact: _filterContact,
          filterDirection: _filterDirection,
          filterFlow: _filterFlow,
          keyword: _keyword,
          contacts: _uniqueContacts,
          selectedCount: _selectedIds.length,
          onDateRange: (range, from, to) {
            setState(() {
              _dateRange = range;
              _fromTime = from;
              _toTime = to;
            });
            _resubscribe();
          },
          onContact: (v) {
            final name = v == 'Todos los contactos' ? '' : v;
            final phone = name.isEmpty ? '' : (_contactPhoneMap[name] ?? '');
            setState(() {
              _filterContact = name;
              _filterContactPhone = phone;
            });
            _resubscribe();
          },
          onDirection: (v) {
            setState(() => _filterDirection =
                v == 'Entrantes'
                    ? 'inbound'
                    : v == 'Salientes'
                        ? 'outbound'
                        : '');
            _resubscribe();
          },
          onFlow: (v) {
            setState(() =>
                _filterFlow = v == 'Todos los flujos' ? '' : v);
            _resubscribe();
          },
          onKeyword: (v) {
            setState(() => _keyword = v);
            _resubscribe();
          },
          onReprocesar: _selectedIds.isEmpty
              ? null
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${_selectedIds.length} mensajes seleccionados para reprocesar',
                        style: const TextStyle(
                            fontFamily: 'Geist', fontSize: 13),
                      ),
                      duration: const Duration(seconds: 2),
                      backgroundColor: AppColors.ctNavy,
                    ),
                  );
                },
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _FeedMessages(
                  messages: _feedMessages,
                  selectedIds: _selectedIds,
                  selectionMode: _selectionMode,
                  onToggleSelect: (id) {
                    setState(() {
                      if (_selectedIds.contains(id)) {
                        _selectedIds.remove(id);
                        if (_selectedIds.isEmpty) _selectionMode = false;
                      } else {
                        _selectedIds.add(id);
                      }
                    });
                  },
                  onLongPress: (id) {
                    setState(() {
                      _selectionMode = true;
                      _selectedIds.add(id);
                    });
                  },
                  onTapOutside: () {
                    setState(() {
                      _selectionMode = false;
                      _selectedIds.clear();
                    });
                  },
                ),
        ),
      ],
    );
  }
}

// ── Feed: filtros ─────────────────────────────────────────────────────────────

class _FeedFilters extends StatefulWidget {
  const _FeedFilters({
    required this.dateRange,
    required this.fromTime,
    required this.toTime,
    required this.filterContact,
    required this.filterDirection,
    required this.filterFlow,
    required this.keyword,
    required this.contacts,
    required this.selectedCount,
    required this.onDateRange,
    required this.onContact,
    required this.onDirection,
    required this.onFlow,
    required this.onKeyword,
    required this.onReprocesar,
  });

  final DateTimeRange? dateRange;
  final TimeOfDay? fromTime;
  final TimeOfDay? toTime;
  final String filterContact;
  final String filterDirection;
  final String filterFlow;
  final String keyword;
  final List<String> contacts;
  final int selectedCount;
  final void Function(DateTimeRange?, TimeOfDay?, TimeOfDay?) onDateRange;
  final ValueChanged<String> onContact;
  final ValueChanged<String> onDirection;
  final ValueChanged<String> onFlow;
  final ValueChanged<String> onKeyword;
  final VoidCallback? onReprocesar;

  @override
  State<_FeedFilters> createState() => _FeedFiltersState();
}

class _FeedFiltersState extends State<_FeedFilters> {
  late TextEditingController _keywordCtrl;

  @override
  void initState() {
    super.initState();
    _keywordCtrl = TextEditingController(text: widget.keyword);
  }

  @override
  void dispose() {
    _keywordCtrl.dispose();
    super.dispose();
  }

  String _dateLabel() {
    final dr = widget.dateRange;
    final ft = widget.fromTime;
    final tt = widget.toTime;
    if (dr == null && ft == null) return 'Todas las fechas';

    String dateStr;
    if (dr == null) {
      dateStr = 'Hoy';
    } else {
      final now = DateTime.now();
      final isToday = dr.start.year == now.year &&
          dr.start.month == now.month &&
          dr.start.day == now.day &&
          dr.end.year == now.year &&
          dr.end.month == now.month &&
          dr.end.day == now.day;
      if (isToday) {
        dateStr = 'Hoy';
      } else {
        final s = dr.start;
        final e = dr.end;
        final sameDay = s.year == e.year &&
            s.month == e.month &&
            s.day == e.day;
        if (sameDay) {
          dateStr =
              '${s.day.toString().padLeft(2, '0')}/${s.month.toString().padLeft(2, '0')}';
        } else {
          dateStr =
              '${s.day.toString().padLeft(2, '0')}/${s.month.toString().padLeft(2, '0')}'
              ' – ${e.day.toString().padLeft(2, '0')}/${e.month.toString().padLeft(2, '0')}';
        }
      }
    }

    if (ft != null || tt != null) {
      String fmtTime(TimeOfDay t) =>
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      final fromStr = ft != null ? fmtTime(ft) : '00:00';
      final toStr = tt != null ? fmtTime(tt) : '23:59';
      return '$dateStr $fromStr–$toStr';
    }
    return dateStr;
  }

  @override
  Widget build(BuildContext context) {
    final dirLabel = widget.filterDirection.isEmpty
        ? 'Todas las direcciones'
        : widget.filterDirection == 'inbound'
            ? 'Entrantes'
            : 'Salientes';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          // Date range picker
          _GhostButton(
            label: _dateLabel(),
            icon: Icons.date_range_rounded,
            active: widget.dateRange != null || widget.fromTime != null,
            onTap: () async {
              final result = await showDialog<
                  ({
                    DateTimeRange? range,
                    TimeOfDay? fromTime,
                    TimeOfDay? toTime
                  })>(
                context: context,
                builder: (_) => _DateFilterModal(
                  initialRange: widget.dateRange,
                  initialFromTime: widget.fromTime,
                  initialToTime: widget.toTime,
                ),
              );
              if (result == null) return;
              widget.onDateRange(result.range, result.fromTime, result.toTime);
            },
          ),
          const SizedBox(width: 8),
          _FilterDropdown(
            label: 'Todos los contactos',
            value: widget.filterContact.isEmpty
                ? 'Todos los contactos'
                : widget.filterContact,
            options: ['Todos los contactos', ...widget.contacts],
            onChanged: widget.onContact,
          ),
          const SizedBox(width: 8),
          _FilterDropdown(
            label: 'Todas las direcciones',
            value: dirLabel,
            options: const [
              'Todas las direcciones',
              'Entrantes',
              'Salientes',
            ],
            onChanged: widget.onDirection,
          ),
          const SizedBox(width: 8),
          _FilterDropdown(
            label: 'Todos los flujos',
            value: widget.filterFlow.isEmpty
                ? 'Todos los flujos'
                : widget.filterFlow,
            options: const [
              'Todos los flujos',
              'Flujo 1',
              'Flujo 2',
              'Flujo 3',
            ],
            onChanged: widget.onFlow,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 30,
              child: TextField(
                controller: _keywordCtrl,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12,
                  color: AppColors.ctText,
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar…',
                  hintStyle: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 12,
                    color: AppColors.ctText3,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 14,
                    color: AppColors.ctText3,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 6),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                    borderSide: const BorderSide(
                        color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                    borderSide: const BorderSide(
                        color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                    borderSide: const BorderSide(
                        color: AppColors.ctTeal, width: 1.5),
                  ),
                ),
                onChanged: widget.onKeyword,
              ),
            ),
          ),
          if (widget.selectedCount > 0) ...[
            const SizedBox(width: 8),
            _GhostButton(
              label:
                  '${widget.selectedCount} seleccionados · Reprocesar',
              icon: Icons.refresh_rounded,
              active: true,
              onTap: widget.onReprocesar,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Feed: lista de mensajes ───────────────────────────────────────────────────

class _FeedMessages extends StatelessWidget {
  const _FeedMessages({
    required this.messages,
    required this.selectedIds,
    required this.selectionMode,
    required this.onToggleSelect,
    required this.onLongPress,
    required this.onTapOutside,
  });

  final List<Map<String, dynamic>> messages;
  final Set<String> selectedIds;
  final bool selectionMode;
  final void Function(String id) onToggleSelect;
  final void Function(String id) onLongPress;
  final VoidCallback onTapOutside;

  static const _avatarColors = [
    Color(0xFFDCFCE7),
    Color(0xFFDBEAFE),
    Color(0xFFFEF3C7),
    Color(0xFFFCE7F3),
    Color(0xFFEDE9FE),
    Color(0xFFFFEDD5),
  ];
  static const _avatarTextColors = [
    Color(0xFF166534),
    Color(0xFF1E40AF),
    Color(0xFF92400E),
    Color(0xFF9D174D),
    Color(0xFF5B21B6),
    Color(0xFF9A3412),
  ];

  static Color _avatarBg(String phone) =>
      _avatarColors[phone.hashCode.abs() % _avatarColors.length];

  static Color _avatarFg(String phone) =>
      _avatarTextColors[phone.hashCode.abs() % _avatarTextColors.length];

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return 'Hoy';
    if (d == yesterday) return 'Ayer';
    const months = [
      '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }

  String _timeLabel(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return GestureDetector(
        onTap: onTapOutside,
        child: Container(
          color: const Color(0xFFF0F2F5),
          alignment: Alignment.center,
          child: const Text(
            'Sin mensajes',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 13,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ),
      );
    }

    // Build item list with date separators
    final items = <({bool isSep, String? label, Map<String, dynamic>? msg})>[];
    DateTime? lastDate;
    for (final msg in messages) {
      final iso = msg['received_at'] as String?;
      if (iso != null) {
        final dt = DateTime.tryParse(iso)?.toLocal();
        if (dt != null) {
          final day = DateTime(dt.year, dt.month, dt.day);
          if (lastDate == null || day != lastDate) {
            items.add((isSep: true, label: _formatDate(dt), msg: null));
            lastDate = day;
          }
        }
      }
      items.add((isSep: false, label: null, msg: msg));
    }

    return GestureDetector(
      onTap: onTapOutside,
      child: Container(
        color: const Color(0xFFF0F2F5),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            if (item.isSep) {
              return Center(
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.label!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                      fontFamily: 'Geist',
                    ),
                  ),
                ),
              );
            }

            final msg = item.msg!;
            final msgId = msg['id'] as String? ?? '';
            final isSelected = selectedIds.contains(msgId);
            final direction = msg['direction'] as String?;
            final isOutbound = direction == 'outbound';
            final phone = msg['from_phone'] as String? ??
                msg['chat_id'] as String? ?? '';
            final name =
                msg['from_name'] as String? ?? phone;
            final chatId = msg['chat_id'] as String? ?? '';
            final time =
                _timeLabel(msg['received_at'] as String?);
            final waStatus = msg['wa_status'] as String?;
            final body = _msgBody(msg);
            final messageType =
                msg['message_type'] as String?;

            if (isOutbound) {
              return _FeedOutboundBubble(
                key: ValueKey(msgId),
                body: body,
                time: time,
                toPhone: chatId,
                senderName: _outboundSenderName(msg),
                waStatus: waStatus,
                isSelected: isSelected,
                selectionMode: selectionMode,
                onToggleSelect: () => onToggleSelect(msgId),
                onLongPress: () => onLongPress(msgId),
                messageType: messageType,
              );
            }
            return _FeedInboundBubble(
              key: ValueKey(msgId),
              body: body,
              time: time,
              name: name,
              phone: phone,
              chatId: chatId,
              avatarBg: _avatarBg(phone),
              avatarTextColor: _avatarFg(phone),
              isSelected: isSelected,
              selectionMode: selectionMode,
              onToggleSelect: () => onToggleSelect(msgId),
              onLongPress: () => onLongPress(msgId),
              messageType: messageType,
            );
          },
        ),
      ),
    );
  }
}

// ── Feed: helper de contenido ────────────────────────────────────────────────

Widget _buildFeedBody(String body, String? messageType, String direction) {
  final isOutbound = direction == 'outbound';
  final textColor = isOutbound
      ? const Color(0xFF0F2937)
      : const Color(0xFF111827);

  if (messageType == 'location') {
    Map<String, dynamic>? locData;
    try {
      locData = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {}
    final locName = locData?['name'] as String? ??
        locData?['address'] as String? ??
        'Ubicación compartida';
    final lat = locData?['latitude']?.toString() ?? '';
    final lng = locData?['longitude']?.toString() ?? '';
    final mapsUrl = (lat.isNotEmpty && lng.isNotEmpty)
        ? 'https://maps.google.com/?q=$lat,$lng'
        : 'https://maps.google.com/';

    return Column(
      crossAxisAlignment: isOutbound
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on,
                color: Colors.red, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                locName,
                style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor),
              ),
            ),
          ],
        ),
        if (lat.isNotEmpty && lng.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 24),
            child: Text(
              '$lat, $lng',
              style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 11,
                  color: textColor.withValues(alpha: 0.6)),
            ),
          ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => launchUrl(Uri.parse(mapsUrl)),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF53BDEB).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Ver en mapa',
              style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12,
                  color: Color(0xFF53BDEB),
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  return Text(
    body,
    style: TextStyle(
      fontSize: 13,
      color: textColor,
      fontFamily: 'Geist',
      height: 1.4,
    ),
  );
}

// ── Feed: burbuja inbound ─────────────────────────────────────────────────────

class _FeedInboundBubble extends StatelessWidget {
  const _FeedInboundBubble({
    super.key,
    required this.body,
    required this.time,
    required this.name,
    required this.phone,
    required this.chatId,
    required this.avatarBg,
    required this.avatarTextColor,
    required this.isSelected,
    required this.selectionMode,
    required this.onToggleSelect,
    required this.onLongPress,
    this.messageType,
  });

  final String body;
  final String time;
  final String name;
  final String phone;
  final String chatId;
  final Color avatarBg;
  final Color avatarTextColor;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onToggleSelect;
  final VoidCallback onLongPress;
  final String? messageType;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: selectionMode ? onToggleSelect : null,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectionMode)
              Padding(
                padding:
                    const EdgeInsets.only(right: 4, top: 4),
                child: Checkbox(
                  value: isSelected,
                  onChanged: (_) => onToggleSelect(),
                  materialTapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                  activeColor: AppColors.ctTeal,
                  checkColor: AppColors.ctNavy,
                ),
              ),
            // Avatar
            Container(
              width: 28,
              height: 28,
              margin:
                  const EdgeInsets.only(top: 4, right: 6),
              decoration: BoxDecoration(
                color: avatarBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _initials(name),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: avatarTextColor,
                  fontFamily: 'Geist',
                ),
              ),
            ),
            // Bubble
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$name · $chatId',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9CA3AF),
                      fontFamily: 'Geist',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    constraints:
                        const BoxConstraints(maxWidth: 440),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(2),
                        topRight: Radius.circular(10),
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.ctTeal
                            : const Color(0xFFE5E7EB),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _buildFeedBody(
                            body, messageType, 'inbound'),
                        const SizedBox(height: 2),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            time,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF9CA3AF),
                              fontFamily: 'Geist',
                            ),
                          ),
                        ),
                      ],
                    ),
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

// ── Feed: burbuja outbound ────────────────────────────────────────────────────

class _FeedOutboundBubble extends StatelessWidget {
  const _FeedOutboundBubble({
    super.key,
    required this.body,
    required this.time,
    required this.toPhone,
    required this.senderName,
    required this.waStatus,
    required this.isSelected,
    required this.selectionMode,
    required this.onToggleSelect,
    required this.onLongPress,
    this.messageType,
  });

  final String body;
  final String time;
  final String toPhone;
  final String senderName;
  final String? waStatus;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onToggleSelect;
  final VoidCallback onLongPress;
  final String? messageType;

  Widget _statusIcon() {
    switch (waStatus) {
      case 'read':
        return const Icon(Icons.done_all,
            size: 12, color: Color(0xFF0F2937));
      case 'delivered':
        return Icon(Icons.done_all,
            size: 12,
            color: const Color(0xFF0F2937).withValues(alpha: 0.5));
      case 'sent':
        return Icon(Icons.check,
            size: 12,
            color: const Color(0xFF0F2937).withValues(alpha: 0.5));
      case 'failed':
        return const Icon(Icons.error_outline,
            size: 12, color: Color(0xFF991B1B));
      default:
        return Icon(Icons.check,
            size: 12,
            color: const Color(0xFF0F2937).withValues(alpha: 0.5));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: selectionMode ? onToggleSelect : null,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$senderName → $toPhone',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9CA3AF),
                      fontFamily: 'Geist',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    constraints:
                        const BoxConstraints(maxWidth: 440),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.ctTeal,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(2),
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                      border: isSelected
                          ? Border.all(
                              color: AppColors.ctNavy,
                              width: 2)
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.end,
                      children: [
                        _buildFeedBody(
                            body, messageType, 'outbound'),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 10,
                                color: const Color(0xFF0F2937)
                                    .withValues(alpha: 0.7),
                                fontFamily: 'Geist',
                              ),
                            ),
                            const SizedBox(width: 3),
                            _statusIcon(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (selectionMode)
              Padding(
                padding:
                    const EdgeInsets.only(left: 4, top: 4),
                child: Checkbox(
                  value: isSelected,
                  onChanged: (_) => onToggleSelect(),
                  materialTapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                  activeColor: AppColors.ctTeal,
                  checkColor: AppColors.ctNavy,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Ghost button ──────────────────────────────────────────────────────────────

class _GhostButton extends StatefulWidget {
  const _GhostButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.active = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool active;

  @override
  State<_GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<_GhostButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return MouseRegion(
      onEnter: enabled ? (_) => setState(() => _hovered = true) : null,
      onExit: enabled ? (_) => setState(() => _hovered = false) : null,
      cursor:
          enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: widget.active || _hovered
                ? AppColors.ctSurface2
                : AppColors.ctSurface,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: widget.active
                  ? AppColors.ctTeal
                  : AppColors.ctBorder2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 13,
                color: widget.active
                    ? AppColors.ctTeal
                    : AppColors.ctText2,
              ),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12,
                  color: widget.active
                      ? AppColors.ctTeal
                      : AppColors.ctText2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Botón Reprocesar (aparece al hover) ───────────────────────────────────────

class _ReprocesarBtn extends StatefulWidget {
  const _ReprocesarBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_ReprocesarBtn> createState() => _ReprocesarBtnState();
}

class _ReprocesarBtnState extends State<_ReprocesarBtn> {
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
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.ctSurface2
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color:
                  _hovered ? AppColors.ctBorder2 : Colors.transparent,
            ),
          ),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 120),
            opacity: _hovered ? 1.0 : 0.0,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.refresh_rounded,
                  size: 12,
                  color: AppColors.ctText2,
                ),
                SizedBox(width: 4),
                Text(
                  'Reprocesar',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ctText2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Dropdown de filtro ────────────────────────────────────────────────────────

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.ctSurface,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.ctBorder2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 12,
            color: AppColors.ctText,
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 14,
            color: AppColors.ctText3,
          ),
          items: options
              .map(
                (o) => DropdownMenuItem(
                  value: o,
                  child: Text(o),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ── Modal de filtro de fecha ──────────────────────────────────────────────────

class _DateFilterModal extends StatefulWidget {
  const _DateFilterModal({
    required this.initialRange,
    required this.initialFromTime,
    required this.initialToTime,
  });
  final DateTimeRange? initialRange;
  final TimeOfDay? initialFromTime;
  final TimeOfDay? initialToTime;

  @override
  State<_DateFilterModal> createState() => _DateFilterModalState();
}

class _DateFilterModalState extends State<_DateFilterModal> {
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _fromTime;
  TimeOfDay? _toTime;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialRange?.start;
    _endDate = widget.initialRange?.end;
    _fromTime = widget.initialFromTime;
    _toTime = widget.initialToTime;
  }

  String _timeLabel(TimeOfDay? t, String placeholder) {
    if (t == null) return placeholder;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  void _pop({required bool clear}) {
    if (clear) {
      Navigator.of(context).pop(
        (range: null, fromTime: null, toTime: null),
      );
      return;
    }
    DateTimeRange? range;
    if (_startDate != null) {
      range = DateTimeRange(
        start: _startDate!,
        end: _endDate ?? _startDate!,
      );
    }
    Navigator.of(context).pop(
      (range: range, fromTime: _fromTime, toTime: _toTime),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                'Filtrar por fecha y hora',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ctText,
                ),
              ),
              const SizedBox(height: 16),

              // Two calendars side by side
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Desde',
                          style: TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 290,
                          child: CalendarDatePicker(
                            key: ValueKey('start_${_startDate?.toIso8601String()}'),
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime(2024),
                            lastDate: DateTime.now(),
                            onDateChanged: (d) => setState(() {
                              _startDate = d;
                              if (_endDate != null &&
                                  _endDate!.isBefore(d)) {
                                _endDate = d;
                              }
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const VerticalDivider(width: 1),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Hasta',
                          style: TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 290,
                          child: CalendarDatePicker(
                            key: ValueKey('end_${_endDate?.toIso8601String()}'),
                            initialDate: _endDate ?? DateTime.now(),
                            firstDate: _startDate ?? DateTime(2024),
                            lastDate: DateTime.now(),
                            onDateChanged: (d) =>
                                setState(() => _endDate = d),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Time pickers
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _fromTime ??
                              const TimeOfDay(hour: 0, minute: 0),
                          helpText: 'Hora desde',
                        );
                        if (t != null) setState(() => _fromTime = t);
                      },
                      icon: const Icon(Icons.access_time_rounded,
                          size: 14),
                      label: Text(
                        _timeLabel(_fromTime, 'Hora desde'),
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _toTime ??
                              const TimeOfDay(hour: 23, minute: 59),
                          helpText: 'Hora hasta',
                        );
                        if (t != null) setState(() => _toTime = t);
                      },
                      icon: const Icon(Icons.access_time_rounded,
                          size: 14),
                      label: Text(
                        _timeLabel(_toTime, 'Hora hasta'),
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Actions
              Row(
                children: [
                  TextButton(
                    onPressed: () => _pop(clear: true),
                    child: const Text(
                      'Limpiar',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => _pop(clear: false),
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.ctTeal),
                    child: const Text(
                      'Aplicar',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 12,
                        color: AppColors.ctNavy,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Nuevo Mensaje Dialog ───────────────────────────────────────────────────────

class _NewMessageDialog extends ConsumerStatefulWidget {
  const _NewMessageDialog();

  @override
  ConsumerState<_NewMessageDialog> createState() => _NewMessageDialogState();
}

class _NewMessageDialogState extends ConsumerState<_NewMessageDialog> {
  int _step = 0;

  // Step 1 — recipient selection
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _operators = [];
  List<Map<String, dynamic>> _iamUsers = [];
  bool _loadingAll = true;
  String? _loadError;

  // Step 2 — compose
  Map<String, dynamic>? _selected; // {name, phone}
  bool _checkingWindow = false;
  bool _windowOpen = false;
  bool _useTemplate = false;
  final _msgCtrl = TextEditingController();
  List<Map<String, dynamic>> _templates = [];
  String? _selectedTemplateId;
  bool _sending = false;
  String? _sendError;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() { _loadingAll = true; _loadError = null; });
    try {
      final tenantId = ref.read(activeTenantIdProvider);
      final results = await Future.wait([
        OperatorsApi.listOperators(tenantId: tenantId),
        ApiClient.instance.get('/iam/users', queryParameters: {'tenant_id': tenantId}),
        ApiClient.instance.get('/templates', queryParameters: {'tenant_id': tenantId}),
      ]);
      final ops = results[0] as List<Map<String, dynamic>>;
      final iamRaw = results[1] as dynamic;
      final iamData = iamRaw.data;
      final List iamList = iamData is List
          ? iamData
          : (iamData['users'] ?? iamData['items'] ?? []) as List;
      final iamUsers = iamList.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      final tplRaw = results[2] as dynamic;
      final tplData = tplRaw.data;
      final List tplList = tplData is List
          ? tplData
          : (tplData['templates'] ?? tplData['items'] ?? []) as List;
      final templates = tplList.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      if (mounted) {
        setState(() {
          _operators = ops;
          _iamUsers = iamUsers;
          _templates = templates;
          _loadingAll = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _loadingAll = false; _loadError = e.toString(); });
    }
  }

  Future<void> _selectRecipient(Map<String, dynamic> recipient) async {
    setState(() { _selected = recipient; _checkingWindow = true; _step = 1; });
    try {
      final phone = recipient['phone'] as String? ?? '';
      final db = Supabase.instance.client;
      final cutoff = DateTime.now().toUtc().subtract(const Duration(hours: 24)).toIso8601String();
      final rows = await db
          .from('wa_messages')
          .select('received_at')
          .eq('chat_id', phone)
          .neq('direction', 'outbound')
          .gte('received_at', cutoff)
          .limit(1);
      final hasRecentInbound = (rows as List).isNotEmpty;
      if (mounted) {
        setState(() {
          _windowOpen = hasRecentInbound;
          _checkingWindow = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _windowOpen = false; _checkingWindow = false; });
    }
  }

  String _resolvePreview(Map<String, dynamic> tpl) {
    final body = tpl['body'] as String? ?? tpl['text'] as String? ?? '';
    final vars = tpl['variables'] as Map? ?? {};
    var result = body;
    vars.forEach((k, v) {
      result = result.replaceAll('{{$k}}', v?.toString() ?? '[$k]');
    });
    return result;
  }

  Map<String, String> _resolveVars(Map<String, dynamic> tpl) {
    final vars = tpl['variables'] as Map? ?? {};
    return vars.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
  }

  Future<void> _send() async {
    if (_selected == null) return;
    final phone = _selected!['phone'] as String? ?? '';
    final name = _selected!['name'] as String? ?? phone;
    final tenantId = ref.read(activeTenantIdProvider);
    final userId = Supabase.instance.client.auth.currentUser?.id;

    setState(() { _sending = true; _sendError = null; });
    try {
      if (_useTemplate && _selectedTemplateId != null) {
        final tpl = _templates.firstWhere(
          (t) => (t['id'] ?? t['template_id'])?.toString() == _selectedTemplateId,
          orElse: () => {},
        );
        await ApiClient.instance.post(
          '/messages/send',
          data: {
            'to': phone,
            'tenant_id': tenantId,
            'template_name': tpl['name'] ?? tpl['template_name'] ?? '',
            'template_language': tpl['language'] ?? tpl['lang'] ?? 'es',
            'template_variables': _resolveVars(tpl),
            'sent_by_user_id': ?userId,
          },
        );
      } else {
        final text = _msgCtrl.text.trim();
        if (text.isEmpty) {
          setState(() { _sending = false; _sendError = 'Escribe un mensaje.'; });
          return;
        }
        final channels = ref.read(selectedOperatorChannelsProvider);
        final idx = ref.read(selectedChannelIndexProvider).clamp(
            0, channels.isEmpty ? 0 : channels.length - 1);
        final channelId = channels.isNotEmpty
            ? channels[idx]['channel_id'] as String? ?? ''
            : '';
        if (channelId.isEmpty) {
          debugPrint('[_NewMessageDialog._send] SKIP — no channelId');
          setState(() { _sending = false; _sendError = 'No hay canal activo. Selecciona un operador primero.'; });
          return;
        }
        await MessagesApi.sendWhatsAppMessage(
          to: phone,
          text: text,
          tenantId: tenantId,
          channelId: channelId,
          sentByUserId: userId,
        );
      }
      if (mounted) {
        Navigator.of(context).pop();
        ref.read(selectedChannelTabProvider.notifier).state = 0;
        ref.read(selectedChatIdProvider.notifier).state = phone;
        ref.read(selectedChatNameProvider.notifier).state = name;
      }
    } on DioException catch (e) {
      final raw = e.response?.data?.toString() ?? e.message ?? '';
      if (mounted) setState(() { _sending = false; _sendError = _parseErrorMessage(raw); });
    } catch (e) {
      if (mounted) setState(() { _sending = false; _sendError = _parseErrorMessage(e.toString()); });
    }
  }

  String _parseErrorMessage(dynamic error) {
    try {
      final detail = error.toString();
      if (detail.contains('131037') || detail.contains('display name')) {
        return 'El número aún no tiene el nombre de perfil aprobado por Meta. Por favor espera la aprobación antes de iniciar nuevas conversaciones.';
      }
      if (detail.contains('131026') || detail.contains('not in whitelist')) {
        return 'Este número no está registrado como destinatario de prueba.';
      }
      return 'Error al enviar el mensaje. Intenta de nuevo.';
    } catch (_) {
      return 'Error al enviar el mensaje. Intenta de nuevo.';
    }
  }

  List<Map<String, dynamic>> get _filteredOps {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _operators;
    return _operators.where((o) {
      final n = (o['display_name'] ?? o['name'] ?? '').toString().toLowerCase();
      final p = (o['phone'] ?? '').toString();
      return n.contains(q) || p.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredIam {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _iamUsers;
    return _iamUsers.where((u) {
      final n = (u['display_name'] ?? u['name'] ?? u['email'] ?? '').toString().toLowerCase();
      final p = (u['phone'] ?? '').toString();
      return n.contains(q) || p.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.ctSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: SizedBox(
        width: 480,
        height: _step == 0 ? 520 : null,
        child: _step == 0 ? _buildStep1() : _buildStep2(),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Nuevo mensaje',
                  style: TextStyle(fontFamily: 'Geist', fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ctNavy),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: AppColors.ctText3),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontFamily: 'Geist', fontSize: 13, color: AppColors.ctNavy),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o teléfono…',
              hintStyle: const TextStyle(fontFamily: 'Geist', fontSize: 13, color: AppColors.ctText3),
              prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.ctText3),
              filled: true,
              fillColor: AppColors.ctSurface2,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // List
        Expanded(
          child: _loadingAll
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _loadError != null
                  ? Center(child: Text(_loadError!, style: const TextStyle(fontFamily: 'Geist', fontSize: 12, color: Colors.red)))
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 12),
                      children: [
                        if (_filteredOps.isNotEmpty) ...[
                          _NmSectionHeader(label: 'Operadores (${_filteredOps.length})'),
                          ..._filteredOps.map((op) => _NmRecipientItem(
                            name: op['display_name'] ?? op['name'] ?? '—',
                            phone: op['phone'] ?? '',
                            onTap: () => _selectRecipient({
                              'name': op['display_name'] ?? op['name'] ?? '',
                              'phone': op['phone'] ?? '',
                            }),
                          )),
                        ],
                        if (_filteredIam.isNotEmpty) ...[
                          _NmSectionHeader(label: 'Usuarios de la plataforma (${_filteredIam.length})'),
                          ..._filteredIam.map((u) => _NmRecipientItem(
                            name: u['display_name'] ?? u['name'] ?? u['email'] ?? '—',
                            phone: u['phone'] ?? '',
                            onTap: () => _selectRecipient({
                              'name': u['display_name'] ?? u['name'] ?? u['email'] ?? '',
                              'phone': u['phone'] ?? '',
                            }),
                          )),
                        ],
                        if (_filteredOps.isEmpty && _filteredIam.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: Text('Sin resultados', style: TextStyle(fontFamily: 'Geist', fontSize: 13, color: AppColors.ctText3))),
                          ),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    final name = _selected?['name'] as String? ?? '';
    final phone = _selected?['phone'] as String? ?? '';
    final tpl = _selectedTemplateId == null
        ? null
        : _templates.firstWhere(
            (t) => (t['id'] ?? t['template_id'])?.toString() == _selectedTemplateId,
            orElse: () => {},
          );

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 18, color: AppColors.ctText3),
                onPressed: () => setState(() { _step = 0; _selected = null; }),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Nuevo mensaje',
                  style: TextStyle(fontFamily: 'Geist', fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ctNavy),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: AppColors.ctText3),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Recipient card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.ctSurface2,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.ctTeal.withValues(alpha: 0.15),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(fontFamily: 'Geist', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ctTeal),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontFamily: 'Geist', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ctNavy)),
                    if (phone.isNotEmpty)
                      Text(phone, style: const TextStyle(fontFamily: 'Geist', fontSize: 11, color: AppColors.ctText3)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Window status
          if (_checkingWindow)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(children: [
                SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 8),
                Text('Verificando ventana de 24h…', style: TextStyle(fontFamily: 'Geist', fontSize: 11, color: AppColors.ctText3)),
              ]),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _windowOpen ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _windowOpen ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                      size: 13,
                      color: _windowOpen ? const Color(0xFF065F46) : const Color(0xFF92400E),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _windowOpen
                          ? 'Ventana de 24h abierta — puedes enviar texto libre.'
                          : 'Ventana cerrada — solo puedes enviar plantillas aprobadas.',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 11,
                        color: _windowOpen ? const Color(0xFF065F46) : const Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Mode toggle (only if window open)
          if (!_checkingWindow && _windowOpen) ...[
            Row(
              children: [
                _NmToggleBtn(
                  label: 'Texto libre',
                  active: !_useTemplate,
                  onTap: () => setState(() => _useTemplate = false),
                ),
                const SizedBox(width: 8),
                _NmToggleBtn(
                  label: 'Plantilla',
                  active: _useTemplate,
                  onTap: () => setState(() => _useTemplate = true),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          // Input area
          if (!_checkingWindow) ...[
            if (!_useTemplate || !_windowOpen) ...[
              // Template selector (required when window closed, or optional when toggled)
              if (_useTemplate || !_windowOpen)
                _NmTemplateDropdown(
                  templates: _templates,
                  selectedId: _selectedTemplateId,
                  onChanged: (id) => setState(() => _selectedTemplateId = id),
                )
              else
                TextField(
                  controller: _msgCtrl,
                  maxLines: 4,
                  style: const TextStyle(fontFamily: 'Geist', fontSize: 13, color: AppColors.ctNavy),
                  decoration: InputDecoration(
                    hintText: 'Escribe tu mensaje…',
                    hintStyle: const TextStyle(fontFamily: 'Geist', fontSize: 13, color: AppColors.ctText3),
                    filled: true,
                    fillColor: AppColors.ctSurface2,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
            ] else ...[
              // Free text field
              TextField(
                controller: _msgCtrl,
                maxLines: 4,
                style: const TextStyle(fontFamily: 'Geist', fontSize: 13, color: AppColors.ctNavy),
                decoration: InputDecoration(
                  hintText: 'Escribe tu mensaje…',
                  hintStyle: const TextStyle(fontFamily: 'Geist', fontSize: 13, color: AppColors.ctText3),
                  filled: true,
                  fillColor: AppColors.ctSurface2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
            // Template preview
            if (_useTemplate && tpl != null && (tpl['body'] ?? tpl['text']) != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.ctTeal.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _resolvePreview(tpl),
                  style: const TextStyle(fontFamily: 'Geist', fontSize: 12, color: AppColors.ctNavy),
                ),
              ),
            ],
          ],
          // Error
          if (_sendError != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(6)),
              child: Text(_sendError!, style: const TextStyle(fontFamily: 'Geist', fontSize: 11, color: Color(0xFF991B1B))),
            ),
          ],
          const SizedBox(height: 16),
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _sending ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancelar', style: TextStyle(fontFamily: 'Geist', fontSize: 13, color: AppColors.ctText3)),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _sending || _checkingWindow ? null : _send,
                style: FilledButton.styleFrom(backgroundColor: AppColors.ctTeal),
                child: _sending
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Enviar', style: TextStyle(fontFamily: 'Geist', fontSize: 13, color: AppColors.ctNavy, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Helpers internos del diálogo ─────────────────────────────────────────────

class _NmSectionHeader extends StatelessWidget {
  const _NmSectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        label,
        style: const TextStyle(fontFamily: 'Geist', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.ctText3, letterSpacing: 0.3),
      ),
    );
  }
}

class _NmRecipientItem extends StatefulWidget {
  const _NmRecipientItem({required this.name, required this.phone, required this.onTap});
  final String name;
  final String phone;
  final VoidCallback onTap;

  @override
  State<_NmRecipientItem> createState() => _NmRecipientItemState();
}

class _NmRecipientItemState extends State<_NmRecipientItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          color: _hover ? AppColors.ctSurface2 : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.ctTeal.withValues(alpha: 0.12),
                child: Text(
                  widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
                  style: const TextStyle(fontFamily: 'Geist', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.ctTeal),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.name, style: const TextStyle(fontFamily: 'Geist', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ctNavy)),
                  if (widget.phone.isNotEmpty)
                    Text(widget.phone, style: const TextStyle(fontFamily: 'Geist', fontSize: 11, color: AppColors.ctText3)),
                ],
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, size: 16, color: AppColors.ctText3),
            ],
          ),
        ),
      ),
    );
  }
}

class _NmToggleBtn extends StatelessWidget {
  const _NmToggleBtn({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.ctTeal : AppColors.ctSurface2,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: active ? AppColors.ctNavy : AppColors.ctText3,
          ),
        ),
      ),
    );
  }
}

class _NmTemplateDropdown extends StatelessWidget {
  const _NmTemplateDropdown({required this.templates, required this.selectedId, required this.onChanged});
  final List<Map<String, dynamic>> templates;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (templates.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.ctSurface2, borderRadius: BorderRadius.circular(8)),
        child: const Text('No hay plantillas disponibles.', style: TextStyle(fontFamily: 'Geist', fontSize: 12, color: AppColors.ctText3)),
      );
    }
    return DropdownButtonFormField<String>(
      initialValue: selectedId,
      hint: const Text('Seleccionar plantilla…', style: TextStyle(fontFamily: 'Geist', fontSize: 13, color: AppColors.ctText3)),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.ctSurface2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: templates.map((t) {
        final id = (t['id'] ?? t['template_id'])?.toString() ?? '';
        final name = (t['name'] ?? t['template_name'] ?? id).toString();
        return DropdownMenuItem(value: id, child: Text(name, style: const TextStyle(fontFamily: 'Geist', fontSize: 13, color: AppColors.ctNavy)));
      }).toList(),
      onChanged: onChanged,
      dropdownColor: AppColors.ctSurface,
      style: const TextStyle(fontFamily: 'Geist', fontSize: 13, color: AppColors.ctNavy),
    );
  }
}

// ── Media Preview Dialog ──────────────────────────────────────────────────────

class _MediaPreviewDialog extends StatefulWidget {
  const _MediaPreviewDialog({
    required this.bytes,
    required this.filename,
    required this.onSend,
    this.audioDuration,
  });
  final Uint8List bytes;
  final String filename;
  final void Function(String? caption) onSend;
  final int? audioDuration;

  @override
  State<_MediaPreviewDialog> createState() => _MediaPreviewDialogState();
}

class _MediaPreviewDialogState extends State<_MediaPreviewDialog> {
  final _captionCtrl = TextEditingController();

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  void _handleSend() {
    widget.onSend(_isAudio ? null : _captionCtrl.text.trim());
  }

  String get _ext => widget.filename.contains('.')
      ? widget.filename.split('.').last.toLowerCase()
      : '';

  bool get _isImage => ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(_ext);
  bool get _isAudio => ['mp3', 'wav', 'ogg', 'aac', 'm4a', 'opus'].contains(_ext);

  String get _sizeLabel {
    final kb = widget.bytes.length / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  IconData get _docIcon {
    if (_ext == 'pdf') return Icons.picture_as_pdf_rounded;
    if (['doc', 'docx'].contains(_ext)) return Icons.article_rounded;
    if (['xls', 'xlsx'].contains(_ext)) return Icons.table_chart_rounded;
    if (['ppt', 'pptx'].contains(_ext)) return Icons.slideshow_rounded;
    return Icons.description_rounded;
  }

  Color get _docColor {
    if (_ext == 'pdf') return const Color(0xFFEF4444);
    if (['doc', 'docx'].contains(_ext)) return const Color(0xFF3B82F6);
    if (['xls', 'xlsx'].contains(_ext)) return const Color(0xFF22C55E);
    if (['ppt', 'pptx'].contains(_ext)) return const Color(0xFFF97316);
    return AppColors.ctText3;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.ctSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vista previa',
                style: TextStyle(fontFamily: 'Geist', fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ctNavy),
              ),
              const SizedBox(height: 16),
              // Preview area
              if (_isImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: Image.memory(widget.bytes, fit: BoxFit.contain),
                  ),
                )
              else if (_isAudio)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.ctSurface2,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.mic_rounded, size: 32, color: AppColors.ctTeal),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.filename,
                              style: const TextStyle(fontFamily: 'Geist', fontSize: 13, color: AppColors.ctNavy),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.audioDuration != null)
                              Text(
                                '${widget.audioDuration! ~/ 60}:${(widget.audioDuration! % 60).toString().padLeft(2, '0')}',
                                style: const TextStyle(fontFamily: 'Geist', fontSize: 11, color: AppColors.ctText3),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.ctSurface2,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(_docIcon, size: 32, color: _docColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.filename,
                              style: const TextStyle(fontFamily: 'Geist', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ctNavy),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _sizeLabel,
                              style: const TextStyle(fontFamily: 'Geist', fontSize: 11, color: AppColors.ctText3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              // Caption (not for audio)
              if (!_isAudio) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _captionCtrl,
                  style: const TextStyle(fontFamily: 'Geist', fontSize: 13, color: AppColors.ctNavy),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                  decoration: InputDecoration(
                    hintText: 'Agregar caption…',
                    hintStyle: const TextStyle(fontFamily: 'Geist', fontSize: 13, color: AppColors.ctText3),
                    filled: true,
                    fillColor: AppColors.ctSurface2,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar', style: TextStyle(fontFamily: 'Geist', fontSize: 13, color: AppColors.ctText3)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _handleSend,
                    style: FilledButton.styleFrom(backgroundColor: AppColors.ctTeal),
                    icon: const Icon(Icons.send_rounded, size: 16, color: AppColors.ctNavy),
                    label: const Text('Enviar', style: TextStyle(fontFamily: 'Geist', fontSize: 13, color: AppColors.ctNavy, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Location Dialog ───────────────────────────────────────────────────────────

class _LocationDialog extends StatefulWidget {
  const _LocationDialog({required this.onSend});
  final void Function(String url) onSend;

  @override
  State<_LocationDialog> createState() => _LocationDialogState();
}

class _LocationDialogState extends State<_LocationDialog> {
  final _urlCtrl = TextEditingController();

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _urlCtrl.text.trim().isNotEmpty;

    return AlertDialog(
      backgroundColor: AppColors.ctSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text(
        'Enviar ubicación',
        style: TextStyle(fontFamily: 'Geist', fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ctNavy),
      ),
      content: SizedBox(
        width: 380,
        child: TextField(
          controller: _urlCtrl,
          onChanged: (_) => setState(() {}),
          autofocus: true,
          style: const TextStyle(fontFamily: 'Geist', fontSize: 13, color: AppColors.ctNavy),
          decoration: InputDecoration(
            hintText: 'Pega una URL de Google Maps…',
            hintStyle: const TextStyle(fontFamily: 'Geist', fontSize: 13, color: AppColors.ctText3),
            prefixIcon: const Icon(Icons.location_on_rounded, size: 18, color: AppColors.ctText3),
            filled: true,
            fillColor: AppColors.ctSurface2,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar', style: TextStyle(fontFamily: 'Geist', fontSize: 13, color: AppColors.ctText3)),
        ),
        FilledButton(
          onPressed: canSend ? () => widget.onSend(_urlCtrl.text.trim()) : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.ctTeal,
            disabledBackgroundColor: AppColors.ctSurface2,
          ),
          child: const Text(
            'Enviar',
            style: TextStyle(fontFamily: 'Geist', fontSize: 13, color: AppColors.ctNavy, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

