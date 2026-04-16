import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseMessages {
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> listConversations({
    String? tenantId,
  }) async {
    var query = _client
        .from('wa_messages')
        .select(
            'id, chat_id, from_phone, from_name, raw_body, message_type, received_at, direction, wa_status, channel_id');

    if (tenantId != null && tenantId.isNotEmpty) {
      query = query.eq('tenant_id', tenantId);
    }

    final response = await query
        .order('received_at', ascending: false)
        .limit(500);
    final messages = List<Map<String, dynamic>>.from(response);

    final Map<String, Map<String, dynamic>> byChat = {};

    for (final msg in messages) {
      final chatId = msg['chat_id'] as String? ?? '';
      if (chatId.isEmpty) continue;

      final isInbound = (msg['direction'] as String?) != 'outbound';

      if (!byChat.containsKey(chatId)) {
        byChat[chatId] = Map<String, dynamic>.from(msg);
        byChat[chatId]!['contact_name'] =
            isInbound ? msg['from_name'] : null;
      } else {
        final existingIsOutbound =
            byChat[chatId]!['direction'] == 'outbound';
        if (existingIsOutbound && isInbound) {
          byChat[chatId]!['from_name'] = msg['from_name'];
        }
        if (isInbound && byChat[chatId]!['contact_name'] == null) {
          byChat[chatId]!['contact_name'] = msg['from_name'];
        }
      }
    }

    for (final entry in byChat.entries) {
      entry.value['contact_name'] ??= entry.key;
    }

    final result = byChat.values.toList();
    result.sort((a, b) {
      final aTime =
          DateTime.tryParse(a['received_at'] as String? ?? '') ?? DateTime(0);
      final bTime =
          DateTime.tryParse(b['received_at'] as String? ?? '') ?? DateTime(0);
      return bTime.compareTo(aTime);
    });

    return result;
  }

  static Future<List<Map<String, dynamic>>> getMessages(
    String chatId, {
    int limit = 100,
    String? tenantId,
  }) async {
    var query = _client
        .from('wa_messages')
        .select(
            'id, chat_id, from_phone, from_name, raw_body, message_type, received_at, direction, wa_status, channel_id')
        .eq('chat_id', chatId);

    if (tenantId != null && tenantId.isNotEmpty) {
      query = query.eq('tenant_id', tenantId);
    }

    return List<Map<String, dynamic>>.from(
      await query.order('received_at', ascending: true).limit(limit),
    );
  }

  static Stream<List<Map<String, dynamic>>> streamMessages(
    String chatId, {
    String? tenantId,
  }) {
    return _client
        .from('wa_messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('received_at', ascending: true)
        .map((data) {
          var list = List<Map<String, dynamic>>.from(data);
          if (tenantId != null && tenantId.isNotEmpty) {
            list = list.where((m) => m['tenant_id'] == tenantId).toList();
          }
          return list;
        });
  }

  static Stream<List<Map<String, dynamic>>> streamFeed({
    String? chatId,
    String? direction,
    String? keyword,
    String? tenantId,
    int limit = 200,
  }) {
    final query = Supabase.instance.client
        .from('wa_messages')
        .stream(primaryKey: ['id'])
        .order('received_at', ascending: false)
        .limit(limit);

    return query.map((data) {
      var messages = List<Map<String, dynamic>>.from(data);

      if (tenantId != null && tenantId.isNotEmpty) {
        messages =
            messages.where((m) => m['tenant_id'] == tenantId).toList();
      }
      if (chatId != null && chatId.isNotEmpty) {
        messages = messages.where((m) => m['chat_id'] == chatId).toList();
      }
      if (direction != null && direction.isNotEmpty) {
        messages =
            messages.where((m) => m['direction'] == direction).toList();
      }
      if (keyword != null && keyword.isNotEmpty) {
        final kw = keyword.toLowerCase();
        messages = messages.where((m) {
          final body = (m['raw_body'] as String? ?? '').toLowerCase();
          final name = (m['from_name'] as String? ?? '').toLowerCase();
          return body.contains(kw) || name.contains(kw);
        }).toList();
      }
      return messages;
    });
  }
}
