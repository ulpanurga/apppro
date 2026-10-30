import 'dart:convert';
import 'dart:typed_data';

import 'package:apppro/core/network/dio_client.dart';
import 'package:apppro/data/local/post_cache.dart';
import 'package:apppro/data/remote/post_api.dart';
import 'package:apppro/data/repositories/post_repository.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Подменённый адаптер Dio: тесты не ходят в интернет.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(Object data, [int status = 200]) =>
    ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

const _userNames = ['User One', 'User Two', 'User Three'];

Map<String, dynamic> _user(int id) => {
      'id': id,
      'name': _userNames[id - 1],
      'username': 'user$id',
      'email': 'user$id@test.com',
    };

/// «Сервер» на 30 постов (по 10 на каждого из 3 пользователей).
/// Понимает /posts (+_page, _limit, userId, _order), /posts/{id},
/// /posts/{id}/comments, /users, /users/{id} и POST /posts.
ResponseBody fakeServer(RequestOptions o) {
  final path = o.path;

  if (o.method == 'POST' && path == '/posts') {
    return jsonBody({...(o.data as Map), 'id': 101}, 201);
  }
  if (path == '/users') {
    return jsonBody([for (var i = 1; i <= 3; i++) _user(i)]);
  }
  final userMatch = RegExp(r'^/users/(\d+)$').firstMatch(path);
  if (userMatch != null) {
    return jsonBody(_user(int.parse(userMatch.group(1)!)));
  }
  final commentsMatch = RegExp(r'^/posts/(\d+)/comments$').firstMatch(path);
  if (commentsMatch != null) {
    final id = int.parse(commentsMatch.group(1)!);
    return jsonBody([
      {'postId': id, 'id': 1, 'name': 'Comment A', 'email': 'a@test.com', 'body': 'text a'},
      {'postId': id, 'id': 2, 'name': 'Comment B', 'email': 'b@test.com', 'body': 'text b'},
    ]);
  }

  final all = List.generate(
    30,
    (i) => {
      'userId': i ~/ 10 + 1,
      'id': i + 1,
      'title': 'title ${i + 1}',
      'body': 'body of post ${i + 1}',
    },
  );

  final postMatch = RegExp(r'^/posts/(\d+)$').firstMatch(path);
  if (postMatch != null) {
    return jsonBody(all[int.parse(postMatch.group(1)!) - 1]);
  }

  var list = all;
  final userId = o.queryParameters['userId'];
  if (userId != null) list = list.where((p) => p['userId'] == userId).toList();
  if (o.queryParameters['_order'] == 'desc') list = list.reversed.toList();
  final page = o.queryParameters['_page'] as int;
  final limit = o.queryParameters['_limit'] as int;
  return jsonBody(list.skip((page - 1) * limit).take(limit).toList());
}

/// Репозиторий поверх подменённого адаптера и мок-SharedPreferences.
Future<PostRepository> buildTestRepository(FakeAdapter adapter) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final dio = DioClient(adapter: adapter).dio;
  return PostRepository(api: PostApi(dio), cache: PostCache(prefs));
}
