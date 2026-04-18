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

  static Future<void> patchStatus({
    required String sessionId,
    required String status,
  }) async {
    await ApiClient.instance.patch(
      '/sessions/$sessionId',
      data: {'status': status},
    );
  }

  /// Busca el ID de la sesión activa para un chat (phone).
  static Future<String?> findActiveSessionId({
    required String chatId,
    required String tenantId,
  }) async {
    try {
      final sessions = await listSessions(tenantId: tenantId);
      final match = sessions.firstWhere(
        (s) => (s['chat_id'] as String?) == chatId || (s['phone'] as String?) == chatId,
        orElse: () => {},
      );
      return match['id'] as String?;
    } catch (_) {
      return null;
    }
  }
}
