import 'package:dio/dio.dart';

class ApiClient {
  static const String baseUrl = 'https://poc-api-lilac.vercel.app';

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  static Dio get instance => _dio;
}
