import 'package:conectamos_platform/core/api/api_client.dart';

class IamApi {
  static Future<List<Map<String, dynamic>>> getUsers({
    required String tenantId,
  }) async {
    final res = await ApiClient.instance.get(
      '/iam/users',
      queryParameters: {'tenant_id': tenantId},
    );
    final data = res.data;
    final List raw = data is List
        ? data
        : (data['users'] ?? data['items'] ?? []) as List;
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<List<Map<String, dynamic>>> getRoles({
    required String tenantId,
  }) async {
    final res = await ApiClient.instance.get(
      '/iam/roles',
      queryParameters: {'tenant_id': tenantId},
    );
    final data = res.data;
    final List raw = data is List
        ? data
        : (data['roles'] ?? data['items'] ?? []) as List;
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> updateUser(
    String id,
    Map<String, dynamic> data,
  ) async {
    await ApiClient.instance.patch('/iam/users/$id', data: data);
  }

  static Future<void> updateUserRole(String id, String roleId) async {
    await ApiClient.instance.patch(
      '/iam/users/$id/role',
      data: {'role_id': roleId},
    );
  }

  static Future<void> resendInvite(
    String id, {
    required String tenantId,
  }) async {
    await ApiClient.instance.post(
      '/iam/users/$id/resend-invite',
      data: {'tenant_id': tenantId},
    );
  }

  static Future<void> inviteUser(Map<String, dynamic> data) async {
    await ApiClient.instance.post('/iam/invite', data: data);
  }

  static Future<void> resetPassword(String email) async {
    await ApiClient.instance.post(
      '/iam/password-reset',
      data: {'email': email},
    );
  }

  static Future<List<Map<String, dynamic>>> getUserChannels({
    required String tenantUserId,
  }) async {
    final res = await ApiClient.instance.get(
      '/supervisor-channel-access',
      queryParameters: {'tenant_user_id': tenantUserId},
    );
    final data = res.data;
    final List raw = data is List ? data : (data['items'] ?? []) as List;
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> assignChannel({
    required String tenantUserId,
    required String channelId,
  }) async {
    await ApiClient.instance.post(
      '/supervisor-channel-access',
      data: {
        'tenant_user_id': tenantUserId,
        'channel_id':     channelId,
      },
    );
  }

  static Future<void> removeChannel({
    required String tenantUserId,
    required String channelId,
  }) async {
    await ApiClient.instance.delete(
      '/supervisor-channel-access',
      data: {
        'tenant_user_id': tenantUserId,
        'channel_id':     channelId,
      },
    );
  }
}
