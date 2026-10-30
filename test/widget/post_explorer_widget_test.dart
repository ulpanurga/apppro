import 'package:apppro/data/repositories/post_repository.dart';
import 'package:apppro/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:apppro/presentation/widgets/post_card.dart';

import '../helpers/fake_server.dart';

Future<void> pumpApp(WidgetTester tester, PostRepository repo) async {
  // Высокий «экран», чтобы все элементы формы и списка были видны.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(PostExplorerApp(repository: repo));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('1. Главный экран: заголовок, элементы управления и посты',
      (tester) async {
    final repo = await buildTestRepository(FakeAdapter(fakeServer));
    await pumpApp(tester, repo);

    expect(find.text('Post Explorer'), findsOneWidget); // заголовок
    expect(find.byType(TextField), findsOneWidget); // поиск
    expect(find.text('Все авторы'), findsOneWidget);
    expect(find.text('ID ↑'), findsOneWidget);
    expect(find.text('ID ↓'), findsOneWidget);
    expect(find.text('Новый пост'), findsOneWidget); // кнопка
    expect(find.text('title 1'), findsOneWidget); // данные загружены
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('2. Поиск по заголовку меняет список', (tester) async {
    final repo = await buildTestRepository(FakeAdapter(fakeServer));
    await pumpApp(tester, repo);

    await tester.enterText(find.byType(TextField), 'title 1');
    await tester.pump();

    expect(find.byType(PostCard), findsNWidgets(2));    expect(find.text('title 10'), findsOneWidget);
    expect(find.text('title 2'), findsNothing);

    await tester.enterText(find.byType(TextField), 'нет такого поста');
    await tester.pump();
    expect(find.textContaining('ничего не найдено'), findsOneWidget); // Empty
  });

  testWidgets('3. Фильтр по автору показывает только его посты',
      (tester) async {
    final repo = await buildTestRepository(FakeAdapter(fakeServer));
    await pumpApp(tester, repo);

    await tester.tap(find.byType(DropdownButton<int?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2. User Two').last);
    await tester.pumpAndSettle();

    expect(find.text('title 11'), findsOneWidget); // пост 2-го автора
    expect(find.text('title 1'), findsNothing); // пост 1-го автора пропал
  });

  testWidgets('4. Переход на экран деталей: пост, автор и комментарии',
      (tester) async {
    final repo = await buildTestRepository(FakeAdapter(fakeServer));
    await pumpApp(tester, repo);

    await tester.tap(find.text('title 1'));
    await tester.pumpAndSettle();

    expect(find.text('Пост'), findsOneWidget); // заголовок нового экрана
    expect(find.text('Комментарии (2)'), findsOneWidget);
    expect(find.text('Comment A'), findsOneWidget);
    expect(find.textContaining('User One'), findsOneWidget);
  });

  testWidgets('5. Форма создания: валидация, отправка и «создан локально»',
      (tester) async {
    final repo = await buildTestRepository(FakeAdapter(fakeServer));
    await pumpApp(tester, repo);

    await tester.tap(find.text('Новый пост'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Новый пост'), findsOneWidget);

    // Пустая форма -> сообщения валидации, запрос не отправляется.
    await tester.tap(find.text('Создать'));
    await tester.pump();
    expect(find.text('Введите заголовок'), findsOneWidget);
    expect(find.text('Введите текст поста'), findsOneWidget);
    expect(find.text('Выберите автора'), findsOneWidget);

    // Заполняем форму.
    await tester.enterText(find.byType(TextFormField).at(0), 'Мой новый пост');
    await tester.enterText(find.byType(TextFormField).at(1), 'Текст нового поста');
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1. User One').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Создать'));
    await tester.pumpAndSettle();

    // Ответ сервера показан на экране.
    expect(find.text('Ответ сервера'), findsOneWidget);
    expect(find.textContaining('id: 101'), findsOneWidget);

    // Возвращаемся: пост есть в списке с пометкой.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Мой новый пост'), findsOneWidget);
    expect(find.text('создан локально'), findsOneWidget);
  });

  testWidgets('6. Ошибка сервера: экран ошибки и повтор запроса',
      (tester) async {
    var online = false;
    final adapter = FakeAdapter(
        (o) => online ? fakeServer(o) : jsonBody(<String, dynamic>{}, 500));
    final repo = await buildTestRepository(adapter);
    await pumpApp(tester, repo);

    expect(find.text('Ошибка сервера (500). Попробуйте позже.'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
    expect(find.text('title 1'), findsNothing);

    online = true;
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();

    expect(find.text('title 1'), findsOneWidget);
    expect(find.text('Повторить'), findsNothing);
  });
}
