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
  }) async {
    final response = await ApiClient.instance.post(
      '/operators',
      data: {
        'display_name': displayName,
        'phone': phone,
        'flows': flows,
        'tenant_id': tenantId,
      },
    );
    return Map<String, dynamic>.from(response.data);
  }

  static Future<Map<String, dynamic>> updateOperator({
    required String id,
    required String displayName,
    required String phone,
    required List<String> flows,
  }) async {
    final response = await ApiClient.instance.put(
      '/operators/$id',
      data: {
        'display_name': displayName,
        'phone': phone,
        'flows': flows,
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
}
