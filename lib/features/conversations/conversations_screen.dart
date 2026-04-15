import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:async';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

import 'package:url_launcher/url_launcher.dart';

import '../../core/api/messages_api.dart';
import '../../core/api/operators_api.dart';
import '../../core/api/supabase_messages.dart';
import '../../core/api/supabase_read_receipts.dart';
import '../../core/providers/tenant_provider.dart';
import '../../core/theme/app_theme.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final selectedConvoTabProvider = StateProvider<int>((ref) => 0);
final selectedChatIdProvider = StateProvider<String?>((ref) => null);
final selectedChatNameProvider = StateProvider<String?>((ref) => null);

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

class _ActionBar extends StatelessWidget {
  const _ActionBar();

  @override
  Widget build(BuildContext context) {
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
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ctText,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Canal WhatsApp · Mensajes en tiempo real',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.ctText2,
                  ),
                ),
              ],
            ),
          ),
          _ActionBarGhostButton(
            label: '📢  Broadcast a todos',
            onTap: () => context.go('/broadcast'),
          ),
          const SizedBox(width: 8),
          _PrimaryButton(
            label: '+ Nuevo mensaje',
            onTap: () {},
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
              fontFamily: 'Inter',
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
              fontFamily: 'Inter',
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

class _ConversationsBody extends ConsumerWidget {
  const _ConversationsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(selectedConvoTabProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pill tab bar
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
              label: 'Por operador',
              selected: selectedIndex == 0,
              onTap: () =>
                  ref.read(selectedConvoTabProvider.notifier).state = 0,
            ),
            const SizedBox(width: 2),
            _TabPill(
              label: 'Feed global',
              selected: selectedIndex == 1,
              onTap: () =>
                  ref.read(selectedConvoTabProvider.notifier).state = 1,
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
              fontFamily: 'Inter',
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

// ── Tab 1: Por operador ───────────────────────────────────────────────────────

class _TabOperador extends ConsumerWidget {
  const _TabOperador();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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

String _previewText(Map<String, dynamic> msg) {
  final raw = msg['raw_body'] as String?;
  if (raw != null && raw.isNotEmpty) return raw;
  return _mediaFallback(msg['message_type'] as String? ?? '');
}

String _msgBody(Map<String, dynamic> msg) {
  final raw = msg['raw_body'] as String?;
  if (raw != null && raw.isNotEmpty) return raw;
  return _mediaFallback(msg['message_type'] as String? ?? '');
}

String _initials(String name) {
  final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
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

  final DateTime _sessionStartAt = DateTime.now().toUtc();

  String _search = '';
  List<Map<String, dynamic>> _operators = [];
  List<Map<String, dynamic>> _allStreamMessages = [];
  bool _loading = false;
  StreamSubscription<List<Map<String, dynamic>>>? _convoSubscription;

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
      if (mounted) {
        _fetchOperators();
        _subscribeToConversations();
      }
    });
  }

  @override
  void dispose() {
    _convoSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchOperators() async {
    setState(() => _loading = true);
    try {
      final tenantId = ref.read(activeTenantIdProvider);
      final ops = await OperatorsApi.listOperators(
        tenantId: tenantId.isNotEmpty ? tenantId : 'default',
      );
      if (mounted) setState(() { _operators = ops; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _countUnread(String chatId) {
    final lastRead = _lastReadAtCache[chatId];
    final cutoff = lastRead ?? _sessionStartAt;

    return _allStreamMessages.where((m) {
      if (m['chat_id'] != chatId) return false;
      if (m['direction'] == 'outbound') return false;
      final receivedAt =
          DateTime.tryParse(m['received_at'] as String? ?? '');
      if (receivedAt == null) return false;
      return receivedAt.isAfter(cutoff);
    }).length;
  }

  void _subscribeToConversations() {
    final tenantId = ref.read(activeTenantIdProvider);
    _convoSubscription = Supabase.instance.client
        .from('wa_messages')
        .stream(primaryKey: ['id'])
        .order('received_at', ascending: false)
        .limit(500)
        .listen((data) {
          if (!mounted) return;
          var msgs = List<Map<String, dynamic>>.from(data);
          if (tenantId.isNotEmpty) {
            msgs = msgs.where((m) => m['tenant_id'] == tenantId).toList();
          }
          setState(() { _allStreamMessages = msgs; });
        });
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: TextField(
        onChanged: (v) => setState(() => _search = v),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: AppColors.ctText,
        ),
        decoration: InputDecoration(
          hintText: 'Buscar operador…',
          hintStyle: const TextStyle(
            fontFamily: 'Inter',
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
    // Reinicia streams y operadores cuando cambia el tenant
    ref.listen<String>(activeTenantIdProvider, (prev, next) {
      if (prev != null && prev != next) {
        _convoSubscription?.cancel();
        setState(() { _operators = []; _allStreamMessages = []; });
        _fetchOperators();
        _subscribeToConversations();
        ref.read(selectedChatIdProvider.notifier).state = null;
        ref.read(selectedChatNameProvider.notifier).state = null;
      }
    });

    final selectedChatId = ref.watch(selectedChatIdProvider);
    final filtered = _operators.where((op) {
      final name = op['display_name'] as String? ??
          op['phone'] as String? ?? '';
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
          else if (_operators.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No hay operadores registrados',
                  style: TextStyle(
                    fontFamily: 'Inter',
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
                  final op = filtered[i];
                  final phone = op['phone'] as String? ?? '';
                  final name = op['name'] as String? ??
                      op['display_name'] as String? ??
                      phone;
                  final lastMsg = _allStreamMessages
                      .where((m) => (m['chat_id'] as String?) == phone)
                      .firstOrNull;
                  return _ApiConvoItem(
                    name: name,
                    preview: lastMsg != null
                        ? _previewText(lastMsg)
                        : 'Sin mensajes',
                    time: lastMsg != null
                        ? _formatTime(lastMsg['received_at'] as String?)
                        : '',
                    isToday: lastMsg != null &&
                        _isToday(lastMsg['received_at'] as String?),
                    isSelected: phone == selectedChatId,
                    unreadCount: _countUnread(phone),
                    onTap: () {
                      final prev = getLastReadSync(phone);
                      if (prev != null) {
                        _preOpenLastRead[phone] = prev;
                      } else {
                        _preOpenLastRead.remove(phone);
                      }
                      setLastRead(phone, DateTime.now().toUtc(),
                          ref.read(activeTenantIdProvider));
                      setState(() {});
                      ref.read(selectedChatIdProvider.notifier).state = phone;
                      ref.read(selectedChatNameProvider.notifier).state = name;
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
    required this.preview,
    required this.time,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
    this.unreadCount = 0,
  });
  final String name;
  final String preview;
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
                    fontFamily: 'Inter',
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
                              fontFamily: 'Inter',
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
                            fontFamily: 'Inter',
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
                          child: Text(
                            widget.preview,
                            style: const TextStyle(
                              fontFamily: 'Inter',
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
                                fontFamily: 'Inter',
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
  bool _sending = false;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  String? _firstUnreadMessageId;
  final _firstUnreadKey = GlobalKey();
  final Set<String> _processedReadIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final chatId = ref.read(selectedChatIdProvider);
    if (chatId != null && _apiMessages.isEmpty && !_msgLoading) {
      _subscribeToMessages(chatId);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final chatId = ref.read(selectedChatIdProvider);
      if (chatId != null) _subscribeToMessages(chatId);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToFirstUnread() {
    if (!_scrollCtrl.hasClients) return;

    if (_firstUnreadMessageId == null) {
      _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
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

  void _sendReadReceipts(List<Map<String, dynamic>> messages) {
    for (final msg in messages) {
      if ((msg['direction'] as String?) == 'outbound') continue;
      final waId = msg['wa_message_id'] as String?;
      if (waId == null || waId.isEmpty) continue;
      if (_processedReadIds.contains(waId)) continue;
      _processedReadIds.add(waId);
      MessagesApi.markRead(waId); // fire-and-forget
    }
  }

  void _handleTyping() {
    final lastInbound = _apiMessages
        .lastWhere(
          (m) => (m['direction'] as String?) != 'outbound' &&
              (m['wa_message_id'] as String?) != null &&
              (m['wa_message_id'] as String?)!.isNotEmpty,
          orElse: () => {},
        );
    final waId = lastInbound['wa_message_id'] as String?;
    if (waId == null || waId.isEmpty) return;
    MessagesApi.sendTyping(waId); // fire-and-forget
  }

  void _subscribeToMessages(String chatId) {
    _subscription?.cancel();
    _processedReadIds.clear();
    setState(() {
      _msgLoading = true;
      _apiMessages = [];
      _firstUnreadMessageId = null;
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
      setState(() { _apiMessages = messages; _msgLoading = false; });
      _sendReadReceipts(messages);

      if (firstEmit) {
        firstEmit = false;
        WidgetsBinding.instance.addPostFrameCallback(
            (_) => _scrollToFirstUnread());
      }
    }, onError: (_) {
      if (mounted) setState(() => _msgLoading = false);
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    final chatId = ref.read(selectedChatIdProvider) ?? '';
    if (chatId.isEmpty) return;

    final tenantId = ref.read(activeTenantIdProvider);

    _msgCtrl.clear();
    setState(() => _sending = true);

    try {
      await MessagesApi.sendWhatsAppMessage(
          to: chatId,
          text: text,
          tenantId: tenantId,
          sentByUserId:
              Supabase.instance.client.auth.currentUser?.id);
      if (mounted) setState(() => _sending = false);
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

  bool get _windowOpen {
    final lastInbound = _apiMessages
        .where((m) => (m['direction'] as String?) != 'outbound')
        .lastOrNull;
    if (lastInbound == null) return false;
    final receivedAt =
        DateTime.tryParse(lastInbound['received_at'] as String? ?? '');
    if (receivedAt == null) return false;
    return DateTime.now().toUtc().difference(receivedAt.toUtc()).inHours < 24;
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final direction = msg['direction'] as String? ?? 'inbound';
    final isOutbound = direction == 'outbound';
    return _ApiMessageBubble(
      body: _msgBody(msg),
      time: _formatTime(msg['received_at'] as String?),
      senderName: isOutbound
          ? 'Supervisor'
          : (msg['from_name'] as String? ??
              msg['from_phone'] as String? ?? ''),
      isOutbound: isOutbound,
      waStatus: msg['wa_status'] as String?,
      messageType: msg['message_type'] as String?,
      mediaUrl: msg['media_url'] as String?,
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
              fontFamily: 'Inter',
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

    if (chatId == null) return _emptyState();

      return Column(
        children: [
          // Header
          _ApiChatHeader(
            name: chatName ?? chatId,
            windowOpen: _windowOpen,
          ),

          // Mensajes
          if (_msgLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: ColoredBox(
                color: const Color(0xFFEBEBE9),
                child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                itemCount: _apiMessages.length,
                itemBuilder: (context, i) {
                  final msg = _apiMessages[i];
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
                                    fontFamily: 'Inter',
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
                        _buildMessageBubble(msg),
                      ],
                    );
                  }
                  return _buildMessageBubble(msg);
                },
              ),
              ),
            ),

          // Banner ventana cerrada
          if (!_windowOpen)
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
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Input
          _ChatInput(
            controller: _msgCtrl,
            onSend: _windowOpen ? _sendMessage : null,
            onTyping: _windowOpen ? _handleTyping : null,
            sending: _sending,
            enabled: _windowOpen,
          ),
        ],
      );
  }
}

// ── Header de chat (modo API) ─────────────────────────────────────────────────

class _ApiChatHeader extends StatelessWidget {
  const _ApiChatHeader({required this.name, required this.windowOpen});
  final String name;
  final bool windowOpen;

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
                fontFamily: 'Inter',
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
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ctText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: windowOpen
                            ? const Color(0xFFD1FAE5)
                            : AppColors.ctSurface2,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        windowOpen ? 'Ventana abierta' : 'Ventana cerrada',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: windowOpen
                              ? const Color(0xFF065F46)
                              : AppColors.ctText3,
                        ),
                      ),
                    ),
                  ],
                ),
                const Text(
                  'WhatsApp · API',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.ctText2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Burbuja de mensaje (modo API) ─────────────────────────────────────────────

class _ApiMessageBubble extends StatelessWidget {
  const _ApiMessageBubble({
    required this.body,
    required this.time,
    required this.senderName,
    required this.isOutbound,
    this.waStatus,
    this.messageType,
    this.mediaUrl,
  });
  final String body;
  final String time;
  final String senderName;
  final bool isOutbound;
  final String? waStatus;
  final String? messageType;
  final String? mediaUrl;

  static final Set<String> _registeredMediaViews = {};

  Widget _fallback(String label) => Text(
        label,
        style: const TextStyle(
            fontFamily: 'Inter', fontSize: 13, color: Color(0xFF667781)),
      );

  Widget _buildContent(BuildContext context) {
    final mType = messageType ?? 'text';
    final mUrl = (mediaUrl != null && mediaUrl!.isNotEmpty) ? mediaUrl : null;

    Future<void> openUrl(String url) async {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }

    switch (mType) {
      case 'image':
        if (mUrl == null) return _fallback('[Imagen]');
        return GestureDetector(
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
        );

      case 'audio':
        if (mUrl == null) return _fallback('[Audio]');
        final audioUrl = mUrl;
        final audioViewId = 'audio-${audioUrl.hashCode}';
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
                ..src = audioUrl
                ..type = 'audio/ogg');
              audio.append(html.SourceElement()
                ..src = audioUrl
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

      case 'video':
        if (mUrl == null) return _fallback('[Video]');
        final videoUrl = mUrl;
        final videoViewId = 'video-${videoUrl.hashCode}';
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
                ..src = videoUrl
                ..type = 'video/mp4');
              return video;
            },
          );
        }
        return SizedBox(
          width: 240,
          height: 135,
          child: HtmlElementView(viewType: videoViewId),
        );

      case 'document':
        if (mUrl == null) return _fallback('[Documento]');
        final fileName =
            Uri.parse(mUrl).pathSegments.lastOrNull ?? 'Documento';
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file,
                size: 24, color: Color(0xFF667781)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(fileName,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFF111B21)),
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => openUrl(mUrl),
              child: const Text('Abrir',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFF53BDEB),
                      fontWeight: FontWeight.w600)),
            ),
          ],
        );

      case 'sticker':
        if (mUrl == null) return _fallback('[Sticker]');
        return Image.network(
          mUrl,
          width: 120,
          height: 120,
          fit: BoxFit.contain,
          errorBuilder: (ctx, e, s) => _fallback('[Sticker]'),
        );

      case 'location':
        final coords = body.replaceAll('📍', '').trim();
        final mapsUrl = 'https://maps.google.com/?q=$coords';
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, color: Colors.red, size: 20),
            const SizedBox(width: 6),
            Flexible(
              child: Text(body,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Color(0xFF111B21))),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => openUrl(mapsUrl),
              child: const Text('Ver en mapa',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFF53BDEB),
                      fontWeight: FontWeight.w600)),
            ),
          ],
        );

      default:
        return Text(
          body,
          style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Color(0xFF111B21),
              height: 1.4),
        );
    }
  }

  Widget _statusIcon() {
    switch (waStatus) {
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
    final isSticker = messageType == 'sticker';
    final bubbleBg = isSticker
        ? Colors.transparent
        : isOutbound
            ? const Color(0xFFD9FDD3)
            : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isOutbound
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isOutbound) const SizedBox(width: 60),
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                border: null,
              ),
              child: Column(
                crossAxisAlignment: isOutbound
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (senderName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        senderName,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: timeColor,
                        ),
                      ),
                    ),
                  _buildContent(context),
                  const SizedBox(height: 3),
                  if (isOutbound)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          time,
                          style: TextStyle(
                            fontFamily: 'Inter',
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
                      time,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: timeColor,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (!isOutbound) const SizedBox(width: 60),
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
  });
  final TextEditingController controller;
  final Future<void> Function()? onSend;
  final VoidCallback? onTyping;
  final bool sending;
  final bool enabled;

  @override
  State<_ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<_ChatInput> {
  bool _hoverSend = false;
  Timer? _typingTimer;

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  void _onChanged(String _) {
    if (widget.onTyping == null) return;
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 800), widget.onTyping!);
  }

  @override
  Widget build(BuildContext context) {
    final canSend = widget.onSend != null && !widget.sending && widget.enabled;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.ctSurface,
        border: Border(top: BorderSide(color: AppColors.ctBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.ctText,
              ),
              enabled: widget.enabled,
              onChanged: widget.enabled ? _onChanged : null,
              onSubmitted: canSend ? (_) => widget.onSend!() : null,
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje…',
                hintStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.ctText3,
                ),
                filled: true,
                fillColor: AppColors.ctSurface2,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 9),
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
                  borderSide: const BorderSide(
                      color: AppColors.ctTeal, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          MouseRegion(
            onEnter: (_) => setState(() => _hoverSend = true),
            onExit: (_) => setState(() => _hoverSend = false),
            cursor: canSend
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            child: GestureDetector(
              onTap: canSend ? widget.onSend : null,
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
        ],
      ),
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
    // Reinicia el feed cuando cambia el tenant
    ref.listen<String>(activeTenantIdProvider, (prev, next) {
      if (prev != null && prev != next) _resubscribe();
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
                            fontFamily: 'Inter', fontSize: 13),
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
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.ctText,
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar…',
                  hintStyle: const TextStyle(
                    fontFamily: 'Inter',
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
              fontFamily: 'Inter',
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
                      fontFamily: 'Inter',
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

            if (isOutbound) {
              return _FeedOutboundBubble(
                key: ValueKey(msgId),
                body: body,
                time: time,
                toPhone: chatId,
                waStatus: waStatus,
                isSelected: isSelected,
                selectionMode: selectionMode,
                onToggleSelect: () => onToggleSelect(msgId),
                onLongPress: () => onLongPress(msgId),
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
            );
          },
        ),
      ),
    );
  }
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
                  fontFamily: 'Inter',
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
                      fontFamily: 'Inter',
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
                        Text(
                          body,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF111827),
                            fontFamily: 'Inter',
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            time,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF9CA3AF),
                              fontFamily: 'Inter',
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
    required this.waStatus,
    required this.isSelected,
    required this.selectionMode,
    required this.onToggleSelect,
    required this.onLongPress,
  });

  final String body;
  final String time;
  final String toPhone;
  final String? waStatus;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onToggleSelect;
  final VoidCallback onLongPress;

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
                    'Supervisor → $toPhone',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9CA3AF),
                      fontFamily: 'Inter',
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
                        Text(
                          body,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF0F2937),
                            fontFamily: 'Inter',
                            height: 1.4,
                          ),
                        ),
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
                                fontFamily: 'Inter',
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
                  fontFamily: 'Inter',
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
                    fontFamily: 'Inter',
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
            fontFamily: 'Inter',
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
                  fontFamily: 'Inter',
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
                            fontFamily: 'Inter',
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
                            fontFamily: 'Inter',
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
                          fontFamily: 'Inter',
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
                          fontFamily: 'Inter',
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
                        fontFamily: 'Inter',
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
                        fontFamily: 'Inter',
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
                        fontFamily: 'Inter',
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
