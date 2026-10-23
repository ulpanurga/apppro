import 'package:flutter/foundation.dart';

import '../../core/error/app_exception.dart';
import '../local/post_cache.dart';
import '../models/comment.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../remote/post_api.dart';

/// Единая точка доступа к данным: сеть + кэш + преобразование ошибок.
class PostRepository {
  PostRepository({required this._api, required this._cache});

    final PostApi _api;
    final PostCache _cache;

  Future<List<Post>> fetchPosts({
    required int page,
    int limit = 10,
    int? userId,
    bool ascending = true,
  }) {
    final order = ascending ? 'asc' : 'desc';
    return _guard(() {
      if (userId == null) {
        return _api.getPosts(
            page: page, limit: limit, sort: 'id', order: order);
      }
      return _api.getPostsByUser(
          userId: userId, page: page, limit: limit, sort: 'id', order: order);
    });
  }

  Future<Post> fetchPost(int id) => _guard(() => _api.getPost(id));

  Future<List<Comment>> fetchComments(int postId) =>
      _guard(() => _api.getComments(postId));

  Future<Post> createPost(CreatePostRequest request) =>
      _guard(() => _api.createPost(request));

  Future<User> fetchUser(int id) => _guard(() => _api.getUser(id));

  /// Авторы: при ошибке сети отдаём кэш, если он есть.
  Future<List<User>> fetchUsers() async {
    try {
      final users = await _guard(() => _api.getUsers());
      await _cache.saveUsers(users);
      return users;
    } on AppException {
      final cached = _cache.readUsers();
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  // --- кэш ---
  List<Post> cachedPosts() => _cache.readPosts();
  Future<void> cachePosts(List<Post> posts) => _cache.savePosts(posts);
  List<Post> cachedLocalPosts() => _cache.readLocalPosts();
  Future<void> cacheLocalPosts(List<Post> posts) =>
      _cache.saveLocalPosts(posts);
  List<User> cachedUsers() => _cache.readUsers();

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (e, s) {
      debugPrint('[Repository] $e\n$s');
      throw AppException.from(e);
    }
  }
}
