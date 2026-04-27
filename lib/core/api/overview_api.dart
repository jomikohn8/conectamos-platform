import 'package:conectamos_platform/core/api/api_client.dart';

class OverviewApi {
  static Future<Map<String, dynamic>> getKpis({
    required String tenantId,
  }) async {
    final response = await ApiClient.instance.get(
      '/tenants/$tenantId/kpis',
    );
    return Map<String, dynamic>.from(response.data);
  }

  static Future<Map<String, dynamic>> getFlowExecutionsDebug({
    required String tenantId,
  }) async {
    final response = await ApiClient.instance.get(
      '/tenants/$tenantId/flow-executions/debug',
    );
    return Map<String, dynamic>.from(response.data);
  }
}
