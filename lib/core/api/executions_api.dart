import 'package:conectamos_platform/core/api/api_client.dart';

class ExecutionsApi {
  ExecutionsApi._();

  /// Lista executions con filtros, paginación y objetos enriquecidos.
  /// Usa GET /api/v1/dashboard/executions.
  /// X-Tenant-ID es inyectado automáticamente por el interceptor de ApiClient.
  static Future<Map<String, dynamic>> listExecutions({
    required String tenantId,
    List<String>? status,
    String? workerId,
    List<String>? operatorIds,
    String? flowId,
    String? channelType,
    String? dateRange,
    String? dateFrom,
    String? dateTo,
    String? search,
    String sortCol = 'created_at',
    String sortDir = 'desc',
    int page = 1,
    int limit = 25,
  }) async {
    final params = <String, dynamic>{
      'sort_col': sortCol,
      'sort_dir': sortDir,
      'page':     page,
      'limit':    limit,
    };
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (workerId != null) params['worker_id'] = workerId;
    if (operatorIds != null && operatorIds.isNotEmpty) params['operator_id'] = operatorIds;
    if (flowId != null) params['flow_id'] = flowId;
    if (channelType != null) params['channel_type'] = channelType;
    if (dateRange != null) params['date_range'] = dateRange;
    if (dateFrom != null) params['date_from'] = dateFrom;
    if (dateTo != null) params['date_to'] = dateTo;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final resp = await ApiClient.instance.get(
      '/api/v1/dashboard/executions',
      queryParameters: params,
    );
    final data = resp.data;
    // Normaliza: el endpoint puede devolver lista plana o wrapper con items/total
    if (data is List) {
      return {'items': data, 'total': data.length};
    }
    return Map<String, dynamic>.from(data as Map);
  }
}
