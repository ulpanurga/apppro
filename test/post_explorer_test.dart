import 'dart:convert';
import 'dart:typed_data';

import 'package:apppro/core/error/app_exception.dart';
import 'package:apppro/core/network/dio_client.dart';
import 'package:apppro/core/validators.dart';
import 'package:apppro/data/local/post_cache.dart';
import 'package:apppro/data/models/post.dart';
import 'package:apppro/data/remote/post_api.dart';
import 'package:apppro/data/repositories/post_repository.dart';
import 'package:apppro/presentation/state/post_list_notifier.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mock-адаптер Dio: тесты не зависят от реального интернета.
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

/// 30 постов: по 10 на каждого из 3 пользователей. Понимает _page/_limit/userId.
ResponseBody fakeServer(RequestOptions o) {
  if (o.method == 'POST' && o.path == '/posts') {
    return jsonBody({...(o.data as Map), 'id': 101}, 201);
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
  final userId = o.queryParameters['userId'];
  final filtered =
      userId == null ? all : all.where((p) => p['userId'] == userId).toList();
  final page = o.queryParameters['_page'] as int;
  final limit = o.queryParameters['_limit'] as int;
  final start = (page - 1) * limit;
  final slice = filtered.skip(start).take(limit).toList();
  return jsonBody(slice);
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  PostRepository buildRepo(FakeAdapter adapter) {
    final dio = DioClient(adapter: adapter).dio;
    return PostRepository(api: PostApi(dio), cache: PostCache(prefs));
  }

  test('1. JSON -> Post', () {
    final post = Post.fromJson({
      'userId': 1,
      'id': 5,
      'title': 'hello world',
      'body': 'some body',
    });
    expect(post.id, 5);
    expect(post.userId, 1);
    expect(post.title, 'hello world');
    expect(post.isLocal, false);
  });

  test('2. Post -> JSON', () {
    const post = Post(userId: 2, id: 7, title: 't', body: 'b');
    final json = post.toJson();
    expect(json['userId'], 2);
    expect(json['id'], 7);
    expect(json['title'], 't');
    expect(json['body'], 'b');
  });

  test('3. Репозиторий успешно загружает посты', () async {
    final repo = buildRepo(FakeAdapter(fakeServer));
    final posts = await repo.fetchPosts(page: 1, limit: 10);
    expect(posts.length, 10);
    expect(posts.first.id, 1);
  });

  test('4. Ошибка сервера 500 -> AppException(server)', () async {
    final repo = buildRepo(FakeAdapter((_) => jsonBody({}, 500)));
    expect(
      repo.fetchPosts(page: 1),
      throwsA(isA<AppException>()
          .having((e) => e.type, 'type', AppErrorType.server)
          .having((e) => e.statusCode, 'statusCode', 500)),
    );
  });

  test('5. Фильтрация по автору и по заголовку', () async {
    final notifier = PostListNotifier(buildRepo(FakeAdapter(fakeServer)));
    await notifier.load();

    notifier.setQuery('title 1');
    // title 1 и title 10 из первой страницы
    expect(notifier.visiblePosts.map((p) => p.id).toList(), [1, 10]);

    notifier.setQuery('');
    await notifier.setUserId(2);
    expect(notifier.visiblePosts, isNotEmpty);
    expect(notifier.visiblePosts.every((p) => p.userId == 2), true);
  });

  test('6. Защита от дублирующейся загрузки страницы', () async {
    final adapter = FakeAdapter(fakeServer);
    final notifier = PostListNotifier(buildRepo(adapter));
    await notifier.load();

    final f1 = notifier.loadMore();
    final f2 = notifier.loadMore();
    await Future.wait([f1, f2]);

    final page2Requests =
        adapter.requests.where((r) => r.queryParameters['_page'] == 2);
    expect(page2Requests.length, 1);
    expect(notifier.visiblePosts.length, 20);
    expect(notifier.visiblePosts.map((p) => p.id).toSet().length, 20);
  });

  test('7. POST /posts через mock-адаптер', () async {
    final adapter = FakeAdapter(fakeServer);
    final repo = buildRepo(adapter);
    final created = await repo.createPost(
      const CreatePostRequest(title: 'new title', body: 'new body text', userId: 1),
    );
    expect(created.id, 101);
    expect(created.title, 'new title');
    final sent = adapter.requests.last;
    expect(sent.method, 'POST');
    expect(sent.headers['X-Client-Platform'], 'flutter');
  });

  test('8. Некорректный JSON не роняет приложение (parsing)', () async {
    final repo = buildRepo(FakeAdapter((_) => jsonBody([
          {'id': 1} // нет обязательных полей
        ])));
    expect(
      repo.fetchPosts(page: 1),
      throwsA(isA<AppException>()
          .having((e) => e.type, 'type', AppErrorType.parsing)),
    );
  });

  test('9. При сетевой ошибке остаётся кэш', () async {
    // 1-й запуск: сервер работает, кэш наполняется
    var online = true;
    final adapter = FakeAdapter(
        (o) => online ? fakeServer(o) : jsonBody({}, 503));
    final n1 = PostListNotifier(buildRepo(adapter));
    await n1.load();

    // повторное открытие без сети
    online = false;
    final n2 = PostListNotifier(buildRepo(adapter));
    await n2.load();
    expect(n2.status, ListStatus.cached);
    expect(n2.visiblePosts.length, 10);
  });

  test('10. Валидаторы формы', () {
    expect(PostValidators.title('abc'), isNotNull);
    expect(PostValidators.title('hello'), isNull);
    expect(PostValidators.body('short'), isNotNull);
    expect(PostValidators.body('long enough body'), isNull);
    expect(PostValidators.userId(null), isNotNull);
  });
}
