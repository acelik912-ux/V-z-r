import 'package:flutter_test/flutter_test.dart';
import 'package:vizir/syllables.dart';

void main() {
  test('1. grup heceleri sadece öğrenilmiş harfleri kullanır', () {
    final bank = Bank(1, 1);
    for (final s in bank.items()) {
      for (final ch in s.split('')) {
        expect(letterGroups[0].contains(ch), isTrue);
      }
    }
  });
}
