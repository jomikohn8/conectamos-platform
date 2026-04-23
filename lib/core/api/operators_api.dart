import 'package:conectamos_platform/core/api/api_client.dart';

class OperatorsApi {
  static Future<List<Map<String, dynamic>>> listOperators({
    String tenantId = 'default',
  }) async {
    final response = await ApiClient.instance.get(
      '/operators',
      queryParameters: {'tenant_id': tenantId},
    );
    return List<Map<String, dynamic>>.from(response.data);
  }

  static Future<Map<String, dynamic>> getOperator(String operatorId) async {
    final response = await ApiClient.instance.get('/operators/$operatorId');
    return Map<String, dynamic>.from(response.data);
  }

  static Future<Map<String, dynamic>> createOperator({
    required String displayName,
    required String phone,
    required List<String> flows,
    String tenantId = 'default',
    String? telegramChatId,
    String? email,
    String? nationality,
    String? identityNumber,
    String? profilePictureUrl,
    List<Map<String, dynamic>>? phoneSecondary,
  }) async {
    final metadata = <String, dynamic>{};
    if (telegramChatId != null && telegramChatId.isNotEmpty) {
      metadata['telegram_chat_id'] = telegramChatId;
    }
    if (phoneSecondary != null && phoneSecondary.isNotEmpty) {
      metadata['phone_secondary'] = phoneSecondary;
    }

    final response = await ApiClient.instance.post(
      '/operators',
      data: {
        'display_name': displayName,
        'phone': phone,
        'flows': flows,
        'tenant_id': tenantId,
        if (email != null && email.isNotEmpty) 'email': email,
        if (nationality != null && nationality.isNotEmpty)
          'nationality': nationality,
        if (identityNumber != null && identityNumber.isNotEmpty)
          'identity_number': identityNumber,
        if (profilePictureUrl != null && profilePictureUrl.isNotEmpty)
          'profile_picture_url': profilePictureUrl,
        if (metadata.isNotEmpty) 'metadata': metadata,
      },
    );
    return Map<String, dynamic>.from(response.data);
  }

  static Future<Map<String, dynamic>> updateOperator({
    required String id,
    required String displayName,
    required String phone,
    required List<String> flows,
    String? telegramChatId,
    String? email,
    String? nationality,
    String? identityNumber,
    String? profilePictureUrl,
    List<Map<String, dynamic>>? phoneSecondary,
  }) async {
    final extraMeta = <String, dynamic>{};
    if (phoneSecondary != null) {
      extraMeta['phone_secondary'] = phoneSecondary;
    }

    final response = await ApiClient.instance.put(
      '/operators/$id',
      data: {
        'display_name': displayName,
        'phone': phone,
        'flows': flows,
        'telegram_chat_id': telegramChatId ?? '',
        'email':                ?email,
        'nationality':          ?nationality,
        'identity_number':      ?identityNumber,
        'profile_picture_url':  ?profilePictureUrl,
        if (extraMeta.isNotEmpty) 'extra_metadata': extraMeta,
      },
    );
    return Map<String, dynamic>.from(response.data);
  }

  static Future<void> patchStatus({
    required String id,
    required String status,
  }) async {
    await ApiClient.instance.patch(
      '/operators/$id/status',
      data: {'status': status},
    );
  }

  static Future<List<Map<String, dynamic>>> listOperatorFlows({
    required String operatorId,
  }) async {
    final response = await ApiClient.instance.get('/operators/$operatorId/flows');
    return List<Map<String, dynamic>>.from(response.data);
  }

  static Future<void> assignFlow({
    required String operatorId,
    required String flowDefinitionId,
    required String tenantId,
  }) async {
    await ApiClient.instance.post(
      '/operators/$operatorId/flows',
      data: {
        'flow_definition_id': flowDefinitionId,
        'tenant_id': tenantId,
      },
    );
  }

  static Future<void> removeFlow({
    required String operatorId,
    required String flowDefinitionId,
  }) async {
    await ApiClient.instance.delete('/operators/$operatorId/flows/$flowDefinitionId');
  }

  /// Sends a Telegram invite to the operator via the given channel.
  /// Returns the response body (may include expires_at).
  static Future<Map<String, dynamic>> sendTelegramInvite({
    required String operatorId,
    required String channelId,
    String? phone,
  }) async {
    final response = await ApiClient.instance.post(
      '/operators/$operatorId/send-telegram-invite',
      data: {
        'channel_id': channelId,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );
    return response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : {};
  }

  /// GET /flows/telegram-channels?flow_ids=uuid1,uuid2
  /// Returns channels list: [{ "channel_id": "uuid", "bot_username": "..." }]
  static Future<List<Map<String, dynamic>>> getTelegramChannels({
    required List<String> flowIds,
  }) async {
    if (flowIds.isEmpty) return [];
    final response = await ApiClient.instance.get(
      '/flows/telegram-channels',
      queryParameters: {'flow_ids': flowIds.join(',')},
    );
    final data = response.data;
    if (data is Map && data['channels'] is List) {
      return List<Map<String, dynamic>>.from(data['channels'] as List);
    }
    return [];
  }
}
