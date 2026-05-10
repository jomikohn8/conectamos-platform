import 'package:conectamos_platform/core/api/api_client.dart';

class ConnectionsApi {
  /// Returns the Google OAuth authorization URL.
  static Future<String> getGoogleAuthUrl() async {
    final resp = await ApiClient.instance.get('/integrations/google/auth-url');
    return resp.data['auth_url'] as String;
  }

  /// Returns Google connection status.
  /// Shape: { connected: bool, email: String|null, connected_at: String|null }
  static Future<Map<String, dynamic>> getGoogleStatus() async {
    final resp = await ApiClient.instance.get('/integrations/google/status');
    return Map<String, dynamic>.from(resp.data as Map);
  }

  /// Disconnects the Google integration for the active tenant.
  static Future<void> disconnectGoogle() async {
    await ApiClient.instance.delete('/integrations/google');
  }

  // ── Microsoft OAuth ────────────────────────────────────────────────────────

  /// Returns the Microsoft OAuth authorization URL.
  /// Shape: { url: "https://login.microsoftonline.com/..." }
  static Future<String> getMicrosoftAuthUrl({required String tenantId}) async {
    final resp = await ApiClient.instance.get(
      '/oauth/microsoft/url',
      queryParameters: {'tenant_id': tenantId},
    );
    return resp.data['url'] as String;
  }

  /// Returns Microsoft connection status for the tenant.
  static Future<Map<String, dynamic>> getMicrosoftStatus({
    required String tenantId,
  }) async {
    final resp = await ApiClient.instance.get(
      '/oauth/status',
      queryParameters: {'tenant_id': tenantId},
    );
    return Map<String, dynamic>.from(resp.data as Map);
  }

  /// Revokes the Microsoft integration for the active tenant.
  static Future<void> disconnectMicrosoft({required String tenantId}) async {
    await ApiClient.instance.delete(
      '/oauth/microsoft/revoke',
      queryParameters: {'tenant_id': tenantId},
    );
  }
}
