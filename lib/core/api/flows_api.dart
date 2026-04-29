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

  static Future<List<Map<String, dynamic>>> getFlowsByWorker({
    required String tenantId,
    required String tenantWorkerId,
  }) async {
    final response = await ApiClient.instance.get(
      '/flows',
      queryParameters: {
        'tenant_id': tenantId,
        'tenant_worker_id': tenantWorkerId,
      },
    );
    final raw = response.data;
    final list = raw is List ? raw : (raw is Map ? (raw['flows'] ?? raw['items'] ?? raw['data'] ?? []) : []);
    return List<Map<String, dynamic>>.from(
        (list as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
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
    bool? sendProactive,
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
        'send_proactive':  ?sendProactive,
      },
    );
    return Map<String, dynamic>.from(response.data);
  }

  static Future<void> deleteFlow({
    required String flowId,
    required String tenantId,
  }) async {
    await ApiClient.instance.delete(
      '/flows/$flowId',
      queryParameters: {'tenant_id': tenantId},
    );
  }

  // ── Integrations ────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> listIntegrations({
    required String tenantId,
    required String flowId,
  }) async {
    final response = await ApiClient.instance.get(
      '/flows/$flowId/integrations',
      queryParameters: {'tenant_id': tenantId},
    );
    final raw = response.data;
    final list = raw is List
        ? raw
        : (raw is Map ? (raw['integrations'] ?? raw['items'] ?? raw['data'] ?? []) : []);
    return List<Map<String, dynamic>>.from(
        (list as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
  }

  static Future<Map<String, dynamic>> createIntegration({
    required String flowId,
    required String tenantId,
    required String name,
    required String integrationType,
    String? endpointUrl,
    bool includeAncestors = false,
    int rateLimitPerMinute = 60,
  }) async {
    final response = await ApiClient.instance.post(
      '/flows/$flowId/integrations',
      queryParameters: {'tenant_id': tenantId},
      data: {
        'name':                name,
        'integration_type':    integrationType,
        'endpoint_url':        ?endpointUrl,
        'include_ancestors':   includeAncestors,
        'rate_limit_per_minute': rateLimitPerMinute,
      },
    );
    return Map<String, dynamic>.from(response.data);
  }

  static Future<Map<String, dynamic>> patchIntegration({
    required String flowId,
    required String integrationId,
    required String tenantId,
    required String endpointUrl,
  }) async {
    final response = await ApiClient.instance.patch(
      '/flows/$flowId/integrations/$integrationId',
      queryParameters: {'tenant_id': tenantId},
      data: {'endpoint_url': endpointUrl},
    );
    return Map<String, dynamic>.from(response.data);
  }

  static Future<void> deleteIntegration({
    required String flowId,
    required String integrationId,
    required String tenantId,
  }) async {
    await ApiClient.instance.delete(
      '/flows/$flowId/integrations/$integrationId',
      queryParameters: {'tenant_id': tenantId},
    );
  }

  // ── Dashboard (executions) ──────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> listPendingExecutions({
    required String tenantId,
    String? flowSlug,
  }) async {
    final params = <String, dynamic>{'tenant_id': tenantId};
    if (flowSlug != null) params['flow_slug'] = flowSlug;
    final response = await ApiClient.instance.get(
      '/api/v1/dashboard/executions',
      queryParameters: params,
    );
    final raw = response.data;
    final list = raw is List ? raw : (raw is Map ? (raw['items'] ?? raw['executions'] ?? raw['data'] ?? []) : []);
    return List<Map<String, dynamic>>.from(
        (list as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
  }

  static Future<Map<String, dynamic>?> getActiveFlow({
    required String tenantId,
    required String operatorId,
  }) async {
    final response = await ApiClient.instance.get(
      '/flows/active',
      queryParameters: {
        'tenant_id': tenantId,
        'operator_id': operatorId,
      },
    );
    final data = response.data as Map<String, dynamic>?;
    return data?['execution'] as Map<String, dynamic>?;
  }

  static Future<Map<String, dynamic>> getExecution({
    required String tenantId,
    required String executionId,
  }) async {
    final response = await ApiClient.instance.get(
      '/api/v1/dashboard/executions/$executionId',
      queryParameters: {'tenant_id': tenantId},
    );
    return Map<String, dynamic>.from(response.data);
  }

  static Future<void> submitExecution({
    required String executionId,
    required List<Map<String, dynamic>> fieldValues,
  }) async {
    await ApiClient.instance.post(
      '/api/v1/dashboard/executions/$executionId/submit',
      data: {'field_values': fieldValues},
    );
  }
}
