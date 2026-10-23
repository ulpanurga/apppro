import 'dart:io';

import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';

/// Типы ошибок, которые различает приложение (раздел 6 SRS).
enum AppErrorType { noConnection, timeout, client, server, parsing, unknown }

class AppException implements Exception {
  const AppException(
    this.type,
    this.message, {
    this.statusCode,
    this.technical,
  });

  final AppErrorType type;

  /// Понятное сообщение для пользователя.
  final String message;
  final int? statusCode;

  /// Технические подробности — только для логов.
  final String? technical;

  factory AppException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppException(
          AppErrorType.timeout,
          'Сервер слишком долго отвечает. Попробуйте ещё раз.',
          technical: e.message,
        );
      case DioExceptionType.connectionError:
        return AppException(
          AppErrorType.noConnection,
          'Нет подключения к интернету.',
          technical: e.message,
        );
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode ?? 0;
        if (code >= 500) {
          return AppException(
            AppErrorType.server,
            'Ошибка сервера ($code). Попробуйте позже.',
            statusCode: code,
            technical: e.message,
          );
        }
        return AppException(
          AppErrorType.client,
          code == 404
              ? 'Данные не найдены (404).'
              : 'Некорректный запрос ($code).',
          statusCode: code,
          technical: e.message,
        );
      case DioExceptionType.cancel:
        return const AppException(AppErrorType.unknown, 'Запрос отменён.');
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        final inner = e.error;
        if (inner is SocketException) {
          return AppException(
            AppErrorType.noConnection,
            'Нет подключения к интернету.',
            technical: inner.message,
          );
        }
        if (inner is FormatException) {
          return AppException(
            AppErrorType.parsing,
            'Сервер вернул некорректные данные.',
            technical: inner.message,
          );
        }
        return AppException(
          AppErrorType.unknown,
          'Произошла неизвестная ошибка.',
          technical: '${e.error}',
        );
    }
  }

  /// Приводит любую ошибку к AppException.
  factory AppException.from(Object error) {
    if (error is AppException) return error;
    if (error is DioException) {
      final inner = error.error;
      if (inner is AppException) return inner;
      return AppException.fromDio(error);
    }
    if (error is CheckedFromJsonException ||
        error is FormatException ||
        error is TypeError) {
      return AppException(
        AppErrorType.parsing,
        'Сервер вернул некорректные данные.',
        technical: '$error',
      );
    }
    if (error is SocketException) {
      return AppException(
        AppErrorType.noConnection,
        'Нет подключения к интернету.',
        technical: error.message,
      );
    }
    return AppException(
      AppErrorType.unknown,
      'Произошла неизвестная ошибка.',
      technical: '$error',
    );
  }

  @override
  String toString() => 'AppException($type, code=$statusCode): $technical';
}
