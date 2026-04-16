import 'package:conectamos_platform/core/api/api_client.dart';

class AiWorkersApi {
  static Future<List<Map<String, dynamic>>> listWorkers({
    required String tenantId,
  }) async {
    final response = await ApiClient.instance.get(
      '/workers',
      queryParameters: {'tenant_id': tenantId},
    );
    return List<Map<String, dynamic>>.from(response.data);
  }
}
