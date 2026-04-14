import 'package:conectamos_platform/core/api/api_client.dart';

class SessionsApi {
  static Future<List<Map<String, dynamic>>> listSessions({
    String tenantId = 'default',
    String? status,
    String? operatorId,
  }) async {
    final response = await ApiClient.instance.get(
      '/sessions',
      queryParameters: {
        'tenant_id': tenantId,
        'status': ?status,
        'operator_id': ?operatorId,
      },
    );
    return List<Map<String, dynamic>>.from(response.data);
  }

  static Future<List<Map<String, dynamic>>> getSessionEvents(
    String sessionId,
  ) async {
    final response = await ApiClient.instance.get(
      '/sessions/$sessionId/events',
    );
    return List<Map<String, dynamic>>.from(response.data);
  }
}
