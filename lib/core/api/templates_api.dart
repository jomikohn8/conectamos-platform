import 'package:dio/dio.dart';
import 'package:conectamos_platform/core/api/api_client.dart';

class TemplatesApi {
  /// Lista plantillas de un tenant. Usar [ChannelsApi.listTemplates] cuando
  /// se tenga channel_id — este método es el fallback legacy por tenant.
  static Future<List<Map<String, dynamic>>> listTemplates({
    required String tenantId,
  }) async {
    final response = await ApiClient.instance.get(
      '/templates',
      queryParameters: {'tenant_id': tenantId},
    );
    final data = response.data;
    final List raw = data is List
        ? data
        : (data['templates'] ?? data['items'] ?? []) as List;
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Sincroniza plantillas desde Meta para un tenant.
  /// Usar [ChannelsApi.syncTemplates] cuando se tenga channel_id.
  static Future<void> syncTemplates({required String tenantId}) async {
    await ApiClient.instance.post(
      '/templates/sync',
      queryParameters: {'tenant_id': tenantId},
    );
  }

  /// Obtiene la plantilla de bienvenida del sistema (sin canal específico).
  static Future<Map<String, dynamic>?> getDefault() async {
    try {
      final response = await ApiClient.instance.get('/templates/default');
      return Map<String, dynamic>.from(response.data as Map);
    } catch (_) {
      return null;
    }
  }

  /// Crea una nueva plantilla y la envía a Meta para aprobación.
  static Future<void> createTemplate({
    required String tenantId,
    required String name,
    required String category,
    required String language,
    required String bodyText,
    required List<Map<String, dynamic>> variables,
    bool isWelcome = false,
    String? channelId,
  }) async {
    await ApiClient.instance.post(
      '/templates',
      data: {
        'tenant_id':  tenantId,
        'name':       name,
        'category':   category,
        'language':   language,
        'body_text':  bodyText,
        'variables':  variables,
        'is_welcome': isWelcome,
        'channel_id': ?channelId,
      },
      options: Options(
        validateStatus: (s) => s != null && s >= 200 && s < 300,
      ),
    );
  }

  /// Elimina una plantilla por ID.
  static Future<void> deleteTemplate({required String templateId}) async {
    await ApiClient.instance.delete('/templates/$templateId');
  }
}
