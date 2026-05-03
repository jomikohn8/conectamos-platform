import 'package:conectamos_platform/core/api/api_client.dart';

class OperatorFieldsApi {
  static Future<List<Map<String, dynamic>>> getOperatorFields() async {
    final res = await ApiClient.instance.get('/operator-fields');
    final data = res.data;
    final List raw = data is List
        ? data
        : (data is Map ? (data['fields'] ?? data['items'] ?? []) : []) as List;
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<Map<String, dynamic>> createOperatorField({
    required String label,
    required String fieldType,
    bool isRequired = false,
    int? displayOrder,
    List<String>? options,
  }) async {
    final res = await ApiClient.instance.post(
      '/operator-fields',
      data: {
        'label': label,
        'field_type': fieldType,
        'required': isRequired,
        'display_order': ?displayOrder,
        if (options != null && options.isNotEmpty) 'options': options,
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  static Future<Map<String, dynamic>> updateOperatorField(
    String fieldId, {
    String? label,
    bool? isRequired,
    int? displayOrder,
    List<String>? options,
    bool? isActive,
  }) async {
    final res = await ApiClient.instance.patch(
      '/operator-fields/$fieldId',
      data: {
        'label':         ?label,
        'required':      ?isRequired,
        'display_order': ?displayOrder,
        'options':       ?options,
        'is_active':     ?isActive,
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  static Future<Map<String, dynamic>> reorderOperatorFields(
    List<Map<String, dynamic>> order,
  ) async {
    final res = await ApiClient.instance.patch(
      '/operator-fields/reorder',
      data: {'order': order},
    );
    return res.data is Map
        ? Map<String, dynamic>.from(res.data as Map)
        : {};
  }

  static Future<Map<String, dynamic>> deleteOperatorField(
    String fieldId,
  ) async {
    final res = await ApiClient.instance.delete('/operator-fields/$fieldId');
    return res.data is Map
        ? Map<String, dynamic>.from(res.data as Map)
        : {};
  }
}
