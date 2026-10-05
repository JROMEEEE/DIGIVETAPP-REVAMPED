import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

import '../config.dart';

/// A failed API call, already turned into something safe to show the user.
class ApiException implements Exception {
  ApiException(
    this.message, {
    this.status,
    this.retryAfter,
    this.network = false,
  });

  final String message;
  final int? status;

  /// From the server's Retry-After header on a 429 (rate limit).
  final Duration? retryAfter;

  /// True when the server couldn't be reached at all (offline, wrong address).
  final bool network;

  bool get unauthorized => status == 401;

  @override
  String toString() => message;
}

/// The app's only door to the backend: the DIGIVET Online API.
///
/// Auth is the server's cookie session (`digivet_online_session`). The cookie
/// jar is persisted in the app's private folder, so the session survives app
/// restarts and never touches shared storage. The app never sends an owner id
/// — the server reads who you are from the cookie.
class Api {
  Api._();
  static final Api instance = Api._();

  Dio? _dio;
  PersistCookieJar?
  _jar; // the SAME jar the client uses, so clearing it really logs out

  /// Called when any request comes back 401 (session ended). Set by AuthService.
  void Function()? onUnauthorized;

  Future<Dio> get _client async {
    final existing = _dio;
    if (existing != null) return existing;

    final dir = await getApplicationSupportDirectory();
    final jar = _jar = PersistCookieJar(
      storage: FileStorage('${dir.path}${Platform.pathSeparator}cookies'),
    );

    final dio = Dio(
      BaseOptions(
        baseUrl: apiBase,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {'Accept': 'application/json'},
      ),
    )..interceptors.add(CookieManager(jar));
    return _dio = dio;
  }

  /// Forget the session cookie (after logout or when the server ended it).
  Future<void> clearCookies() async {
    await _client; // make sure the jar exists
    await _jar!.deleteAll();
  }

  Future<Map<String, dynamic>> get(String path) => _send('GET', path);

  Future<Map<String, dynamic>> post(
    String path, [
    Map<String, dynamic>? body,
  ]) => _send('POST', path, body: body);

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) =>
      _send('PATCH', path, body: body);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final dio = await _client;
    try {
      final res = await dio.request<dynamic>(
        path,
        data: body,
        options: Options(method: method),
      );
      final data = res.data;
      return data is Map<String, dynamic> ? data : <String, dynamic>{};
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  ApiException _toException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return ApiException(
          'Can’t reach the server. Check your internet connection and try again.',
          network: true,
        );
      default:
        break;
    }

    final status = e.response?.statusCode;
    final data = e.response?.data;
    final serverMessage = data is Map && data['error'] is String
        ? data['error'] as String
        : null;

    if (status == 401) {
      onUnauthorized?.call();
      return ApiException(
        serverMessage ?? 'Your session has ended. Please sign in again.',
        status: 401,
      );
    }
    if (status == 429) {
      final seconds = int.tryParse(
        e.response?.headers.value('retry-after') ?? '',
      );
      final wait = seconds == null ? null : Duration(seconds: seconds);
      return ApiException(
        wait == null
            ? 'Too many attempts. Please wait a while and try again.'
            : 'Too many attempts. Please try again in ${_describe(wait)}.',
        status: 429,
        retryAfter: wait,
      );
    }
    if (status != null && status >= 500) {
      return ApiException(
        'Something went wrong on our side. Please try again later.',
        status: status,
      );
    }
    return ApiException(
      serverMessage ?? 'Something went wrong. Please try again.',
      status: status,
    );
  }

  static String _describe(Duration d) {
    if (d.inMinutes >= 1) {
      final m = (d.inSeconds / 60).ceil();
      return '$m minute${m == 1 ? '' : 's'}';
    }
    return '${d.inSeconds} second${d.inSeconds == 1 ? '' : 's'}';
  }
}
