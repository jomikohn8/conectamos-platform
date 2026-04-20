import 'package:conectamos_platform/core/api/api_client.dart';

class ConversationsApi {
  static Future<List<Map<String, dynamic>>> listConversations({
    required String tenantId,
    required String channelId,
  }) async {
    final response = await ApiClient.instance.get(
      '/conversations',
      queryParameters: {
        'tenant_id':  tenantId,
        'channel_id': channelId,
      },
    );
    final data = response.data;
    final List raw = data is List
        ? data
        : (data['conversations'] ?? data['items'] ?? []) as List;
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
