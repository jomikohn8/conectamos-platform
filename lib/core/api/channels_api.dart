import 'package:conectamos_platform/core/api/api_client.dart';

class ChannelsApi {
  static Future<List<Map<String, dynamic>>> listChannels({
    required String tenantId,
  }) async {
    final response = await ApiClient.instance.get(
      '/channels',
      queryParameters: {'tenant_id': tenantId},
    );
    return List<Map<String, dynamic>>.from(response.data);
  }

  static Future<Map<String, dynamic>> createChannel({
    required String tenantId,
    required String tenantWorkerId,
    required String displayName,
    required String color,
    String channelType = 'whatsapp',
    String? phoneNumberId,
    String? wabaId,
    String? waToken,
  }) async {
    final response = await ApiClient.instance.post('/channels', data: {
      'tenant_id':        tenantId,
      'tenant_worker_id': tenantWorkerId,
      'display_name':     displayName,
      'color':            color,
      'channel_type':     channelType,
      'phone_number_id':  ?phoneNumberId,
      'waba_id':  ?wabaId,
      'wa_token': ?waToken,
    });
    return Map<String, dynamic>.from(response.data);
  }

  static Future<Map<String, dynamic>> updateChannel({
    required String channelId,
    String? displayName,
    String? color,
    bool? isActive,
    String? tenantWorkerId,
    String? channelType,
    String? phoneNumberId,
    String? wabaId,
    String? waToken,
  }) async {
    final response = await ApiClient.instance.patch(
      '/channels/$channelId',
      data: {
        'display_name':     ?displayName,
        'color':            ?color,
        'is_active':        ?isActive,
        'tenant_worker_id': ?tenantWorkerId,
        'channel_type':     ?channelType,
        'phone_number_id':  ?phoneNumberId,
        'waba_id':  ?wabaId,
        'wa_token': ?waToken,
      },
    );
    return Map<String, dynamic>.from(response.data);
  }

  static Future<void> deleteChannel({required String channelId}) async {
    await ApiClient.instance.delete('/channels/$channelId');
  }

  static Future<void> assignOperator({
    required String channelId,
    required String operatorId,
    required String tenantId,
  }) async {
    await ApiClient.instance.post(
      '/channels/$channelId/operators',
      data: {'operator_id': operatorId, 'tenant_id': tenantId},
    );
  }

  static Future<void> removeOperator({
    required String channelId,
    required String operatorId,
  }) async {
    await ApiClient.instance.delete(
      '/channels/$channelId/operators/$operatorId',
    );
  }
}
