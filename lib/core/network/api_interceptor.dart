import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../error/app_exception.dart';

/// Добавляет технические заголовки и централизованно преобразует ошибки.
class ApiInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['X-Client-Platform'] = 'flutter';
    options.headers['X-App-Version'] = '1.0.0';
    options.headers['X-Request-Id'] =
        DateTime.now().microsecondsSinceEpoch.toString();
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final appError = AppException.fromDio(err);
    // Технические подробности — только в лог разработки.
    debugPrint('[API ERROR] ${err.requestOptions.method} '
        '${err.requestOptions.uri} -> $appError');
    handler.next(err.copyWith(error: appError));
  }
}
