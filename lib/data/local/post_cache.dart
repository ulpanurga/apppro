import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/post.dart';
import '../models/user.dart';

/// Простой локальный кэш на SharedPreferences (JSON-строки).
class PostCache {
  PostCache(this._prefs);

  final SharedPreferences _prefs;

  static const _postsKey = 'cache_posts';
  static const _localPostsKey = 'cache_local_posts';
  static const _usersKey = 'cache_users';

  List<Post> readPosts() => _read(_postsKey, Post.fromJson);
  Future<void> savePosts(List<Post> posts) =>
      _write(_postsKey, posts.map((e) => e.toJson()).toList());

  List<Post> readLocalPosts() => _read(_localPostsKey, Post.fromJson);
  Future<void> saveLocalPosts(List<Post> posts) =>
      _write(_localPostsKey, posts.map((e) => e.toJson()).toList());

  List<User> readUsers() => _read(_usersKey, User.fromJson);
  Future<void> saveUsers(List<User> users) =>
      _write(_usersKey, users.map((e) => e.toJson()).toList());

  Future<void> _write(String key, Object data) async {
    await _prefs.setString(key, jsonEncode(data));
  }

  List<T> _read<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      // Повреждённый кэш не должен ронять приложение.
      return [];
    }
  }
}
