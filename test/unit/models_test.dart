import 'package:apppro/data/models/post.dart';
import 'package:apppro/data/models/user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_annotation/json_annotation.dart';

void main() {
  group('Post', () {
    test('нет обязательного поля -> CheckedFromJsonException, а не падение', () {
      expect(
        () => Post.fromJson({'id': 1, 'userId': 1, 'title': 'only title'}),
        throwsA(isA<CheckedFromJsonException>()),
      );
    });

    test('isLocal по умолчанию false, если поля нет в JSON', () {
      final p = Post.fromJson({'userId': 1, 'id': 1, 'title': 't', 'body': 'b'});
      expect(p.isLocal, false);
    });

    test('toJson -> fromJson сохраняет все поля, включая isLocal', () {
      const original =
          Post(userId: 3, id: -5, title: 'Мой пост', body: 'Текст', isLocal: true);
      final restored = Post.fromJson(original.toJson());
      expect(restored.userId, 3);
      expect(restored.id, -5);
      expect(restored.title, 'Мой пост');
      expect(restored.isLocal, true);
    });

    test('CreatePostRequest отправляет только title, body, userId', () {
      final req = CreatePostRequest(title: 'abcde', body: 'x' * 10, userId: 2);
      expect(req.toJson().keys.toSet(), {'title', 'body', 'userId'});
    });
  });

  group('User (вложенные модели)', () {
    test('company и address разбираются', () {
      final u = User.fromJson({
        'id': 1,
        'name': 'Leanne',
        'username': 'Bret',
        'email': 'a@b.c',
        'company': {'name': 'Romaguera-Crona'},
        'address': {'city': 'Gwenborough'},
      });
      expect(u.company?.name, 'Romaguera-Crona');
      expect(u.address?.city, 'Gwenborough');
      expect(u.phone, isNull);
    });

    test('без вложенных объектов поля равны null', () {
      final u = User.fromJson(
          {'id': 2, 'name': 'N', 'username': 'u', 'email': 'e@e.e'});
      expect(u.company, isNull);
      expect(u.address, isNull);
    });
  });
}
