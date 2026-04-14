import 'api_client.dart';

class TenantsApi {
  static Future<List<Map<String, dynamic>>> getTenants(
      {String? userId}) async {
    final queryParams =
        userId != null ? {'user_id': userId} : null;
    final response = await ApiClient.instance.get(
      '/tenants',
      queryParameters: queryParams,
    );
    return List<Map<String, dynamic>>.from(response.data);
  }
}
