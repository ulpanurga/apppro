import 'package:flutter/foundation.dart';

import '../../core/error/app_exception.dart';
import '../../data/models/post.dart';
import '../../data/repositories/post_repository.dart';

enum SubmitStatus { idle, submitting, success, failure }

/// Состояние формы отдельно от состояния списка.
class CreatePostNotifier extends ChangeNotifier {
  CreatePostNotifier(this._repo);

  final PostRepository _repo;

  SubmitStatus _status = SubmitStatus.idle;
  Post? _created;
  AppException? _error;

  SubmitStatus get status => _status;
  bool get isSubmitting => _status == SubmitStatus.submitting;
  Post? get createdPost => _created;
  AppException? get error => _error;

  Future<Post?> submit({
    required String title,
    required String body,
    required int userId,
  }) async {
    if (isSubmitting) return null; // защита от повторного нажатия
    _status = SubmitStatus.submitting;
    _error = null;
    notifyListeners();
    try {
      final post = await _repo.createPost(
        CreatePostRequest(title: title, body: body, userId: userId),
      );
      _created = post;
      _status = SubmitStatus.success;
      notifyListeners();
      return post;
    } on AppException catch (e) {
      _error = e;
      _status = SubmitStatus.failure;
      notifyListeners();
      return null;
    }
  }
}
