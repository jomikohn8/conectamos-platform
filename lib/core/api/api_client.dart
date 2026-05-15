import 'dart:html' as html;

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: '',
);

class ApiClient {
  static const String baseUrl = _apiBaseUrl;

  static final Dio _dio = _buildDio();

  static Dio _buildDio() {
    assert(
      baseUrl.isNotEmpty,
      'API_BASE_URL no está definida. Usa run_dev.sh para correr en local.',
    );
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token =
            Supabase.instance.client.auth.currentSession?.accessToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        final tenantId = html.window.localStorage['conectamos_active_tenant_id'];
        if (tenantId != null && tenantId.isNotEmpty) {
          options.headers['X-Tenant-ID'] = tenantId;
        }
        handler.next(options);
      },
    ));
    return dio;
  }

  static Dio get instance => _dio;
}
