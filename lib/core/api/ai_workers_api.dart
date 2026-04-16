import 'package:conectamos_platform/core/api/api_client.dart';

class AiWorkersApi {
  /// Workers contratados por el tenant.
  static Future<List<Map<String, dynamic>>> listWorkers({
    required String tenantId,
  }) async {
    final response = await ApiClient.instance.get(
      '/workers',
      queryParameters: {'tenant_id': tenantId},
    );
    return List<Map<String, dynamic>>.from(response.data);
  }

  /// Catálogo global de workers disponibles (no requiere tenant_id).
  static Future<List<Map<String, dynamic>>> listCatalog() async {
    final response = await ApiClient.instance.get('/catalog/workers');
    return List<Map<String, dynamic>>.from(response.data);
  }

  /// Contratar un worker del catálogo para el tenant.
  static Future<Map<String, dynamic>> contractWorker({
    required String tenantId,
    required String catalogWorkerId,
    String? displayName,
  }) async {
    final response = await ApiClient.instance.post('/workers/contract', data: {
      'tenant_id':         tenantId,
      'catalog_worker_id': catalogWorkerId,
      'display_name':      ?displayName,
    });
    return Map<String, dynamic>.from(response.data);
  }

  /// Actualizar nombre personalizado o estado activo de un tenant_worker.
  static Future<Map<String, dynamic>> updateWorker({
    required String tenantWorkerId,
    String? displayName,
    bool? isActive,
  }) async {
    final response = await ApiClient.instance.patch(
      '/workers/$tenantWorkerId',
      data: {
        'display_name': ?displayName,
        'is_active':    ?isActive,
      },
    );
    return Map<String, dynamic>.from(response.data);
  }
}
