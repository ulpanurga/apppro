import 'package:flutter/foundation.dart';

import '../../core/error/app_exception.dart';
import '../../data/models/comment.dart';
import '../../data/models/post.dart';
import '../../data/models/user.dart';
import '../../data/repositories/post_repository.dart';

enum DetailsStatus { loading, success, error }

class PostDetailsNotifier extends ChangeNotifier {
  PostDetailsNotifier(this._repo, Post post) : _post = post;

  final PostRepository _repo;

  Post _post;
  List<Comment> _comments = [];
  User? _author;
  DetailsStatus _status = DetailsStatus.loading;
  AppException? _error;

  Post get post => _post;
  List<Comment> get comments => _comments;
  User? get author => _author;
  DetailsStatus get status => _status;
  AppException? get error => _error;

  Future<void> load() async {
    _status = DetailsStatus.loading;
    _error = null;
    notifyListeners();

    // Локальный пост на сервере не существует.
    if (_post.isLocal) {
      _status = DetailsStatus.success;
      notifyListeners();
      return;
    }

    try {
      _comments = await _repo.fetchComments(_post.id); // обязательно
      try {
        _post = (await _repo.fetchPost(_post.id)).copyWith(); // GET /posts/{id}
        _author = await _repo.fetchUser(_post.userId); // GET /users/{id}
      } on AppException {
        // автор и свежая версия поста — не критичны
      }
      _status = DetailsStatus.success;
    } on AppException catch (e) {
      _error = e;
      _status = DetailsStatus.error;
    }
    notifyListeners();
  }
}
