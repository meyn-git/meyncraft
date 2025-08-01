import 'package:flutter_test/flutter_test.dart';
import 'package:meyncraft/meyncraft/source/sysmac/event/comment_attribute.domain.dart';
import 'package:petitparser/petitparser.dart';
import 'package:shouldly/shouldly.dart';

void main() {
  group('ConditionalAppendCommentAttribute class', () {
    test(
      "ConditionalAppendCommentAttribute.suffixParser.end().parse('StopBox16')",
      () {
        var result = ConditionalAppendCommentAttribute.suffixParser.end().parse(
          'StopBox16',
        );
        result.should.beOfType<Success<String>>();
        result.value.should.be('StopBox16');
      },
    );
    test(
      "ConditionalAppendCommentAttribute.parser.allMatches('[StopBox16=123S1] Satellite panel-Touch screen-Start request')",
      () {
        var result = ConditionalAppendCommentAttribute.parser.allMatches(
          '[StopBox16=123S1] Satellite panel-Touch screen-Start request',
        );
        result.length.should.be(1);
        result.first.should.beOfType<ConditionalAppendCommentAttribute>();
      },
    );
  });
}
