import 'package:apppro/core/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PostValidators.title', () {
    test('пустой и из пробелов — ошибка', () {
      expect(PostValidators.title(null), isNotNull);
      expect(PostValidators.title(''), isNotNull);
      expect(PostValidators.title('     '), isNotNull);
    });

    test('границы 5 и 100 символов', () {
      expect(PostValidators.title('abcd'), isNotNull); // 4
      expect(PostValidators.title('abcde'), isNull); // 5
      expect(PostValidators.title('a' * 100), isNull); // 100
      expect(PostValidators.title('a' * 101), isNotNull); // 101
    });
  });

  group('PostValidators.body', () {
    test('границы 10 и 1000 символов', () {
      expect(PostValidators.body('a' * 9), isNotNull);
      expect(PostValidators.body('a' * 10), isNull);
      expect(PostValidators.body('a' * 1000), isNull);
      expect(PostValidators.body('a' * 1001), isNotNull);
    });

    test('пробелы по краям не считаются символами', () {
      expect(PostValidators.body('   short   '), isNotNull);
    });
  });

  test('PostValidators.userId: автор обязателен', () {
    expect(PostValidators.userId(null), isNotNull);
    expect(PostValidators.userId(3), isNull);
  });
}
