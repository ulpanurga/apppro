import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_interceptor.dart';

/// Единый клиент: Dio создаётся один раз и передаётся в Retrofit.
class DioClient {
  DioClient({
    String baseUrl = defaultBaseUrl,
    HttpClientAdapter? adapter,
  }) : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 15),
            headers: {'Accept': 'application/json'},
          ),
        ) {
    if (adapter != null) dio.httpClientAdapter = adapter;
    dio.interceptors.add(ApiInterceptor());
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: false));
    }
  }

  static const defaultBaseUrl = 'https://jsonplaceholder.typicode.com';

  final Dio dio;
}
