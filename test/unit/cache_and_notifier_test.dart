import 'package:apppro/data/local/post_cache.dart';
import 'package:apppro/data/models/post.dart';
import 'package:apppro/presentation/state/post_list_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_server.dart';

void main() {
  group('PostCache', () {
    test('сохраняет и читает посты', () async {
      SharedPreferences.setMockInitialValues({});
      final cache = PostCache(await SharedPreferences.getInstance());
      expect(cache.readPosts(), isEmpty);

      await cache.savePosts(const [
        Post(userId: 1, id: 1, title: 'first', body: 'body one'),
        Post(userId: 2, id: 2, title: 'second', body: 'body two'),
      ]);
      final read = cache.readPosts();
      expect(read.map((p) => p.title), ['first', 'second']);
    });

    test('повреждённый кэш не роняет приложение', () async {
      SharedPreferences.setMockInitialValues({'cache_posts': 'это не json'});
      final cache = PostCache(await SharedPreferences.getInstance());
      expect(cache.readPosts(), isEmpty);
    });
  });

  group('PostListNotifier', () {
    test('addLocalPost: пост локальный, сверху списка и сохраняется', () async {
      final repo = await buildTestRepository(FakeAdapter(fakeServer));
      final n = PostListNotifier(repo);

      await n.addLocalPost(
          const Post(userId: 1, id: 101, title: 'My post', body: 'some body'));

      final first = n.visiblePosts.first;
      expect(first.isLocal, true);
      expect(first.id, isNegative); // уникальный локальный id, не 101
      expect(repo.cachedLocalPosts().length, 1);
    });

    test('сортировка ID ↓ отправляет _order=desc и меняет порядок', () async {
      final adapter = FakeAdapter(fakeServer);
      final n = PostListNotifier(await buildTestRepository(adapter));
      await n.load();
      expect(n.visiblePosts.first.id, 1);

      await n.setAscending(false);
      expect(adapter.requests.last.queryParameters['_order'], 'desc');
      expect(n.visiblePosts.first.id, 30);
    });

    test('сброс фильтров возвращает всех авторов и пустой поиск', () async {
      final n = PostListNotifier(
          await buildTestRepository(FakeAdapter(fakeServer)));
      await n.load();
      await n.setUserId(2);
      n.setQuery('title');

      await n.resetFilters();
      expect(n.userId, isNull);
      expect(n.query, isEmpty);
      expect(n.ascending, true);
      expect(n.visiblePosts.map((p) => p.userId).toSet(), {1});
    });
  });
}
