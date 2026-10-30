import 'dart:io';

import 'package:apppro/core/error/app_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_annotation/json_annotation.dart';

DioException dioError(DioExceptionType type, {int? status, Object? error}) {
  final ro = RequestOptions(path: '/posts');
  return DioException(
    requestOptions: ro,
    type: type,
    error: error,
    response: status == null
        ? null
        : Response(requestOptions: ro, statusCode: status),
  );
}

void main() {
  group('AppException.from', () {
    test('таймауты -> timeout', () {
      for (final t in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        expect(AppException.from(dioError(t)).type, AppErrorType.timeout);
      }
    });

    test('connectionError и SocketException -> noConnection', () {
      expect(AppException.from(dioError(DioExceptionType.connectionError)).type,
          AppErrorType.noConnection);
      expect(
          AppException.from(dioError(DioExceptionType.unknown,
                  error: const SocketException('no internet')))
              .type,
          AppErrorType.noConnection);
    });

    test('HTTP 404 -> client, HTTP 503 -> server', () {
      final c = AppException.from(dioError(DioExceptionType.badResponse, status: 404));
      expect(c.type, AppErrorType.client);
      expect(c.statusCode, 404);

      final s = AppException.from(dioError(DioExceptionType.badResponse, status: 503));
      expect(s.type, AppErrorType.server);
      expect(s.statusCode, 503);
    });

    test('ошибки JSON -> parsing', () {
      expect(AppException.from(const FormatException('bad')).type,
          AppErrorType.parsing);
      expect(
          AppException.from(CheckedFromJsonException({}, 'id', 'Post', 'missing'))
              .type,
          AppErrorType.parsing);
    });

    test('всё остальное -> unknown, а готовый AppException не меняется', () {
      expect(AppException.from(StateError('x')).type, AppErrorType.unknown);
      const own = AppException(AppErrorType.client, 'msg');
      expect(identical(AppException.from(own), own), true);
    });

    test('сообщение для пользователя не содержит технических деталей', () {
      final e = AppException.from(dioError(DioExceptionType.connectionTimeout));
      expect(e.message, isNotEmpty);
      expect(e.message.contains('DioException'), false);
    });
  });
}
