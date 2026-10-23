/// Валидация формы создания поста (задание F).
class PostValidators {
  static String? title(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Введите заголовок';
    if (s.length < 5) return 'Заголовок: минимум 5 символов';
    if (s.length > 100) return 'Заголовок: максимум 100 символов';
    return null;
  }

  static String? body(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Введите текст поста';
    if (s.length < 10) return 'Текст: минимум 10 символов';
    if (s.length > 1000) return 'Текст: максимум 1000 символов';
    return null;
  }

  static String? userId(int? v) => v == null ? 'Выберите автора' : null;
}
