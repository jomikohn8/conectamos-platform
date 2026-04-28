import 'package:conectamos_platform/core/api/api_client.dart';

class FlowsApi {
  static Future<List<Map<String, dynamic>>> listFlows({
    required String tenantId,
  }) async {
    final response = await ApiClient.instance.get(
      '/flows',
      queryParameters: {'tenant_id': tenantId},
    );
    return List<Map<String, dynamic>>.from(response.data);
  }

  static Future<Map<String, dynamic>> getFlow({
    required String tenantId,
    required String flowId,
  }) async {
    final response = await ApiClient.instance.get(
      '/flows/$flowId',
      queryParameters: {'tenant_id': tenantId},
    );
    return Map<String, dynamic>.from(response.data);
  }

  static Future<Map<String, dynamic>> createFlow({
    required String tenantId,
    required String tenantWorkerId,
    required String name,
    String? description,
    List<Map<String, dynamic>> fields = const [],
    Map<String, dynamic> behavior = const {},
  }) async {
    final response = await ApiClient.instance.post('/flows', data: {
      'tenant_id':        tenantId,
      'tenant_worker_id': tenantWorkerId,
      'name':             name,
      'description':      ?description,
      'fields':   fields,
      'behavior': behavior,
    });
    return Map<String, dynamic>.from(response.data);
  }

  static Future<Map<String, dynamic>> updateFlow({
    required String flowId,
    String? name,
    String? slug,
    String? description,
    bool? isActive,
    List<Map<String, dynamic>>? fields,
    Map<String, dynamic>? behavior,
    Map<String, dynamic>? onComplete,
    List<String>? triggerSources,
  }) async {
    final response = await ApiClient.instance.patch(
      '/flows/$flowId',
      data: {
        'name':            ?name,
        'slug':            ?slug,
        'description':     ?description,
        'is_active':       ?isActive,
        'fields':          ?fields,
        'behavior':        ?behavior,
        'on_complete':     ?onComplete,
        'trigger_sources': ?triggerSources,
      },
    );
    return Map<String, dynamic>.from(response.data);
  }

  static Future<void> deleteFlow({required String flowId}) async {
    await ApiClient.instance.delete('/flows/$flowId');
  }

  // ── Dashboard (executions) ──────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> listPendingExecutions({
    required String tenantId,
    String? flowSlug,
  }) async {
    final params = <String, dynamic>{'tenant_id': tenantId};
    if (flowSlug != null) params['flow_slug'] = flowSlug;
    final response = await ApiClient.instance.get(
      '/api/v1/dashboard/',
      queryParameters: params,
    );
    return List<Map<String, dynamic>>.from(response.data);
  }

  static Future<Map<String, dynamic>> getExecution({
    required String tenantId,
    required String executionId,
  }) async {
    final response = await ApiClient.instance.get(
      '/api/v1/dashboard/$executionId',
      queryParameters: {'tenant_id': tenantId},
    );
    return Map<String, dynamic>.from(response.data);
  }

  static Future<void> submitExecution({
    required String executionId,
    required List<Map<String, dynamic>> fieldValues,
  }) async {
    await ApiClient.instance.post(
      '/api/v1/dashboard/$executionId/submit',
      data: {'field_values': fieldValues},
    );
  }
}
