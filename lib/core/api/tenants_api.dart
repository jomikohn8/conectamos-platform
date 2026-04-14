import 'api_client.dart';

class TenantsApi {
  static Future<List<Map<String, dynamic>>> listTenants() async {
    final response = await ApiClient.instance.get('/tenants');
    return List<Map<String, dynamic>>.from(response.data);
  }
}
