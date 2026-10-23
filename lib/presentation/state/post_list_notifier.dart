import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/error/app_exception.dart';
import '../../data/models/post.dart';
import '../../data/models/user.dart';
import '../../data/repositories/post_repository.dart';

/// Состояния всего списка.
enum ListStatus { loading, success, cached, error, empty }

/// Отдельное состояние подгрузки следующей страницы (не один общий isLoading).
enum NextPageStatus { idle, loading, error }

class PostListNotifier extends ChangeNotifier {
  PostListNotifier(this._repo, {this.pageSize = 10});

  final PostRepository _repo;
  final int pageSize;

  List<Post> _posts = [];
  List<Post> _localPosts = [];
  List<User> _users = [];

  ListStatus _status = ListStatus.loading;
  NextPageStatus _nextPage = NextPageStatus.idle;
  AppException? _error;
  AppException? _pageError;
  bool _refreshing = false;

  int _page = 0;
  bool _hasMore = true;
  int _generation = 0; // растёт при каждом сбросе — отбрасывает устаревшие ответы
  final Set<int> _inFlight = {};
  final Set<int> _loaded = {};

  int? _userId;
  bool _ascending = true;
  String _query = '';

  // ---------- геттеры ----------
  ListStatus get status =>
      (_status == ListStatus.success && visiblePosts.isEmpty)
          ? ListStatus.empty
          : _status;
  NextPageStatus get nextPageStatus => _nextPage;
  AppException? get error => _error;
  AppException? get pageError => _pageError;
  bool get isRefreshing => _refreshing;
  bool get hasMore => _hasMore;
  int? get userId => _userId;
  bool get ascending => _ascending;
  String get query => _query;
  List<User> get users => _users;
  int get loadedCount => _posts.length;
  bool get _isDefaultFilter => _userId == null && _ascending;

  /// Посты после локального поиска. Локально созданные — сверху.
  List<Post> get visiblePosts {
    final q = _query.trim().toLowerCase();
    bool match(Post p) =>
        (_userId == null || p.userId == _userId) &&
        (q.isEmpty || p.title.toLowerCase().contains(q));
    return [..._localPosts.where(match), ..._posts.where(match)];
  }

  // ---------- запуск ----------
  Future<void> init() async {
    _localPosts = _repo.cachedLocalPosts();
    _users = _repo.cachedUsers();
    unawaited(loadUsers());
    await load();
  }

  Future<void> loadUsers() async {
    try {
      _users = await _repo.fetchUsers();
      notifyListeners();
    } on AppException {
      // список авторов не критичен для просмотра
    }
  }

  /// Загрузка первой страницы. refresh=true — pull-to-refresh (список остаётся
  /// на экране, пока идёт запрос).
  Future<void> load({bool refresh = false}) async {
    final gen = ++_generation;
    _page = 0;
    _hasMore = true;
    _inFlight
      ..clear()
      ..add(1);
    _loaded.clear();
    _nextPage = NextPageStatus.idle;
    _pageError = null;
    _error = null;
    _refreshing = true;

    if (!refresh) {
      // Фильтр сменился или первый запуск: старые результаты не смешиваем.
      final cached = _isDefaultFilter ? _repo.cachedPosts() : <Post>[];
      _posts = cached;
      _status = cached.isEmpty ? ListStatus.loading : ListStatus.cached;
    } else if (_posts.isEmpty) {
      _status = ListStatus.loading;
    }
    notifyListeners();

    try {
      final result = await _repo.fetchPosts(
        page: 1,
        limit: pageSize,
        userId: _userId,
        ascending: _ascending,
      );
      if (gen != _generation) return;
      _posts = result;
      _page = 1;
      _loaded.add(1);
      _hasMore = result.length >= pageSize;
      _status = ListStatus.success;
      if (_isDefaultFilter) await _repo.cachePosts(_posts);
    } on AppException catch (e) {
      if (gen != _generation) return;
      _error = e;
      // Последний успешный результат не удаляем.
      _status = _posts.isEmpty ? ListStatus.error : ListStatus.cached;
    } finally {
      if (gen == _generation) {
        _inFlight.remove(1);
        _refreshing = false;
        notifyListeners();
      }
    }
  }

  /// Подгрузка следующей страницы. retry=true — ручная повторная попытка.
  Future<void> loadMore({bool retry = false}) async {
    if (_status != ListStatus.success || !_hasMore) return;
    if (_nextPage == NextPageStatus.loading) return;
    if (_nextPage == NextPageStatus.error && !retry) return;

    final next = _page + 1;
    // Защита от повторной загрузки той же страницы.
    if (_inFlight.contains(next) || _loaded.contains(next)) return;

    final gen = _generation;
    _inFlight.add(next);
    _nextPage = NextPageStatus.loading;
    _pageError = null;
    notifyListeners();

    try {
      final result = await _repo.fetchPosts(
        page: next,
        limit: pageSize,
        userId: _userId,
        ascending: _ascending,
      );
      if (gen != _generation) return;
      final ids = _posts.map((p) => p.id).toSet();
      _posts = [..._posts, ...result.where((p) => !ids.contains(p.id))];
      _page = next;
      _loaded.add(next);
      _hasMore = result.length >= pageSize;
      _nextPage = NextPageStatus.idle;
      if (_isDefaultFilter) await _repo.cachePosts(_posts);
    } on AppException catch (e) {
      if (gen != _generation) return;
      _pageError = e;
      _nextPage = NextPageStatus.error;
    } finally {
      _inFlight.remove(next);
      if (gen == _generation) notifyListeners();
    }
  }

  Future<void> retryNextPage() => loadMore(retry: true);

  // ---------- фильтры ----------
  Future<void> setUserId(int? id) {
    if (id == _userId) return Future.value();
    _userId = id;
    return load();
  }

  Future<void> setAscending(bool value) {
    if (value == _ascending) return Future.value();
    _ascending = value;
    return load();
  }

  /// Поиск по заголовку — локальный, только среди загруженных постов.
  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  Future<void> resetFilters() {
    _userId = null;
    _ascending = true;
    _query = '';
    return load();
  }

  // ---------- создание ----------
  /// Добавляет созданный пост в локальный список с пометкой «создан локально».
  Future<void> addLocalPost(Post serverPost) async {
    // У всех созданных постов JSONPlaceholder возвращает id=101,
    // поэтому для списка выдаём уникальный отрицательный id.
    final local = serverPost.copyWith(
      id: -DateTime.now().millisecondsSinceEpoch,
      isLocal: true,
    );
    _localPosts = [local, ..._localPosts];
    notifyListeners();
    await _repo.cacheLocalPosts(_localPosts);
  }
}
