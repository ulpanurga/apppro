import 'package:json_annotation/json_annotation.dart';

part 'post.g.dart';

/// checked: true — при отсутствии обязательного поля выбрасывается
/// CheckedFromJsonException, который мы превращаем в понятную ошибку.
@JsonSerializable(checked: true)
class Post {
  const Post({
    required this.userId,
    required this.id,
    required this.title,
    required this.body,
    this.isLocal = false,
  });

  final int userId;
  final int id;
  final String title;
  final String body;

  /// true — пост создан локально (сервер JSONPlaceholder его не хранит).
  @JsonKey(defaultValue: false)
  final bool isLocal;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
  Map<String, dynamic> toJson() => _$PostToJson(this);

  Post copyWith({int? userId, int? id, String? title, String? body, bool? isLocal}) {
    return Post(
      userId: userId ?? this.userId,
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      isLocal: isLocal ?? this.isLocal,
    );
  }
}

/// Тело POST-запроса (отдельно от Post, чтобы не отправлять служебные поля).
@JsonSerializable()
class CreatePostRequest {
  const CreatePostRequest({
    required this.title,
    required this.body,
    required this.userId,
  });

  final String title;
  final String body;
  final int userId;

  factory CreatePostRequest.fromJson(Map<String, dynamic> json) =>
      _$CreatePostRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreatePostRequestToJson(this);
}
