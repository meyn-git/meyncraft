import 'package:flutter_test/flutter_test.dart';
import 'package:meyncraft/meyncraft/generate/sysmac/event_default_attribute.service.dart';
import 'package:shouldly/shouldly.dart';

void main() {
  group('longestSequentialMatch function', () {
    test('longestSequentialMatch("abcde", "ace").should.be(1)', () {
      longestSequentialMatch("abcde", "ace").should.be(1); // a, c or e
    });
    test('longestSequentialMatch("hello", "ollb").should.be(2)', () {
      longestSequentialMatch("hello", "ollb").should.be(2); // ll
    });
    test('longestSequentialMatch("dart", "start").should.be(3)', () {
      longestSequentialMatch("dart", "start").should.be(3); // art
    });
    test('longestSequentialMatch("abcdef","zabcf",).should.be(3)', () {
      longestSequentialMatch("abcdef", "zabcf").should.be(3); // abc
    });
  });
}
