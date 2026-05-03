import 'package:flutter/foundation.dart';
import 'package:conectamos_platform/core/api/api_client.dart';

class ConversationsApi {
  static Future<List<Map<String, dynamic>>> listConversations({
    required String channelId,
  }) async {
    final response = await ApiClient.instance.get(
      '/conversations',
      queryParameters: {
        'channel_id': channelId,
      },
    );
    final data = response.data;
    final List raw = data is List
        ? data
        : (data['conversations'] ?? data['items'] ?? []) as List;
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> markChatRead({
    required String chatId,
    required String channelId,
  }) async {
    try {
      await ApiClient.instance.post('/panel-read', data: {
        'chat_id': chatId,
        'channel_id': channelId,
      });
    } catch (e) {
      debugPrint('[markChatRead] error: $e');
      // Non-critical — no lanzar excepción
    }
  }
}
