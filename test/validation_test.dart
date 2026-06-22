import 'package:flutter_test/flutter_test.dart';
import 'package:athletica_fitness/utils/validators.dart';

void main() {
  group('isValidDuration', () {
    test('valid positive integer', () {
      expect(isValidDuration('30'), isTrue);
    });

    test('zero is invalid', () {
      expect(isValidDuration('0'), isFalse);
    });

    test('negative is invalid', () {
      expect(isValidDuration('-5'), isFalse);
    });

    test('non-numeric is invalid', () {
      expect(isValidDuration('abc'), isFalse);
    });
  });

  group('isValidRutubeUrl', () {
    test('valid rutube url', () {
      expect(isValidRutubeUrl('https://rutube.ru/video/abcd1234'), isTrue);
      expect(isValidRutubeUrl('http://rutube.ru/video/abcd1234/'), isTrue);
      expect(isValidRutubeUrl('https://www.rutube.ru/video/abcd1234'), isTrue);
    });

    test('invalid urls', () {
      expect(isValidRutubeUrl('https://youtube.com/watch?v=abc'), isFalse);
      expect(isValidRutubeUrl('rutube.ru/video/abcd1234'), isFalse);
      expect(isValidRutubeUrl(''), isFalse);
    });
  });
}
