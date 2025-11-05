import 'package:flutter_test/flutter_test.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/event/comment_attribute.domain.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/event/component_code.domain.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/event/event.domain.dart';
import 'package:petitparser/petitparser.dart';
import 'package:shouldly/shouldly.dart';

void main() {
  group('commentParser', () {
    test("commentParser.parse('') should return the correct result", () {
      var result = commentPathParser.parse('');
      result.should.beOfType<Success<List>>();
      result.value.should.beOfType<List>();
      result.value.should.beEmpty();
    });
    test(
      "commentParser.parse('foo 20Q1 [noAck] bar') should return the correct result",
      () {
        var result = commentPathParser.parse('foo 20Q1 [noAck] bar');
        result.should.beOfType<Success<List>>();
        result.value.should.beOfType<List>();
        result.value.length.should.be(5);
        (result.value[0] as String).should.be('foo ');
        (result.value[1] as ComponentCode).toString().should.be('20Q1');
        (result.value[2] as String).should.be(' ');
        (result.value[3] as AcknowledgeAttribute).value.should.be(false);
        (result.value[4] as String).should.be(' bar');
      },
    );
  });

  group('commentAttributeParser', () {
    test(
      "commentAttributeParser.end().parse('[noAck]') should return a AcknowledgeAttribute",
      () {
        var result = commentAttributeParser.end().parse('[noAck]');
        result.should.beOfType<Success<CommentAttribute>>();
        result.value.should.beOfType<AcknowledgeAttribute>();
        (result.value as AcknowledgeAttribute).value.should.beFalse();
      },
    );
    test(
      "commentAttributeParser.end().parse('[*1*=foo]') should return a ConditionalAttribute",
      () {
        var result = commentAttributeParser.end().parse('[*1*=foo]');
        result.should.beOfType<Success<CommentAttribute>>();
        result.value.should.beOfType<ConditionalAttribute>();
        (result.value as ConditionalAttribute).values.should.contain('foo');
      },
    );
    test(
      "commentAttributeParser.end().parse('[invalid]') should return a UnknownAttribute",
      () {
        var result = commentAttributeParser.end().parse('[invalid]');
        result.should.beOfType<Success<CommentAttribute>>();
        result.value.should.beOfType<UnknownAttribute>();
        (result.value as UnknownAttribute).toString().should.be('[invalid]');
      },
    );
    test(
      "commentAttributeParser.end().parse('[noAck') should be in correct",
      () {
        var result = commentAttributeParser.end().parse('[noAck');
        result.should.beOfType<Failure>();
      },
    );
  });

  group('NameEqualsValueParser class', () {
    test(
      "NameEqualsValueParser(converter).end().parse(' foo=bar ]') should return correctly",
      () {
        converter({required String name, required String value}) =>
            UnknownAttribute('name=$name, value=$value');
        var result = NameEqualsValueParser(converter).end().parse(' foo=bar ');
        result.should.beOfType<Success<UnknownAttribute>>();
        result.value.should.beOfType<UnknownAttribute>();
        result.value.toString().should.be('[name= foo, value=bar ]');
      },
    );
  });

  group('AcknowledgeAttribute class', () {
    test(
      "AcknowledgeAttribute.parser.parse('invalid') should return a correct value",
      () {
        var result = AcknowledgeAttribute.parser.parse('invalid');
        result.should.beOfType<Failure>();
      },
    );

    test(
      "AcknowledgeAttribute.parser.parse('noAck') should return a correct value",
      () {
        var result = AcknowledgeAttribute.parser.parse('noAck');
        result.should.beOfType<Success<AcknowledgeAttribute>>();
        result.value.value.should.be(false);
      },
    );

    test(
      "AcknowledgeAttribute.parser.parse(' ack= false ') should return a correct value",
      () {
        var result = AcknowledgeAttribute.parser.parse(' ack= false ');
        result.should.beOfType<Success<AcknowledgeAttribute>>();
        result.value.value.should.be(false);
      },
    );

    test(
      "AcknowledgeAttribute.parser.parse(' ACK= y') should return a correct value",
      () {
        var result = AcknowledgeAttribute.parser.parse(' ACK= y');
        result.should.beOfType<Success<AcknowledgeAttribute>>();
        result.value.value.should.be(true);
      },
    );
  });

  group('ArrayAttribute class', () {
    test("ArrayAttribute.parser.parse('invalid') should return a Failure", () {
      var result = ArrayAttribute.parser.parse('invalid');
      result.should.beOfType<Failure>();
    });

    test(
      "ArrayAttribute.parser.parse('array(-4)') should return a Failure",
      () {
        var result = ArrayAttribute.parser.parse('array(-4)');
        result.should.beOfType<Failure>();
      },
    );

    group('first', () {
      test(
        "ArrayAttribute.parser.parse('array(first)') should return a correct ArrayAttribute",
        () {
          var result = ArrayAttribute.parser.parse('array(first)');
          result.should.beOfType<Success<ArrayAttribute>>();
          result.value.indexType.should.be(ArrayIndexType.first);
          result.value.offSet.should.be(0);
        },
      );

      test(
        "ArrayAttribute.parser.parse('array(first+17)') should return a correct ArrayAttribute",
        () {
          var result = ArrayAttribute.parser.parse('array(first+17)');
          result.should.beOfType<Success<ArrayAttribute>>();
          result.value.indexType.should.be(ArrayIndexType.first);
          result.value.offSet.should.be(17);
        },
      );

      test(
        "ArrayAttribute.parser.parse('array(first-3)') should return a Failure",
        () {
          var result = ArrayAttribute.parser.parse('array(first-3)');
          result.should.beOfType<Failure>();
        },
      );
    });

    group('number', () {
      test(
        "ArrayAttribute.parser.parse('array(0)') should return a correct ArrayAttribute",
        () {
          var result = ArrayAttribute.parser.parse('array(0)');
          result.should.beOfType<Success<ArrayAttribute>>();
          result.value.indexType.should.be(ArrayIndexType.first);
          result.value.offSet.should.be(0);
        },
      );

      test(
        "ArrayAttribute.parser.parse('array(123)') should return a correct ArrayAttribute",
        () {
          var result = ArrayAttribute.parser.parse('array(123)');
          result.should.beOfType<Success<ArrayAttribute>>();
          result.value.indexType.should.be(ArrayIndexType.first);
          result.value.offSet.should.be(123);
        },
      );

      test(
        "ArrayAttribute.parser.parse('array(-1)') should return a Failure",
        () {
          var result = ArrayAttribute.parser.parse('array(-1)');
          result.should.beOfType<Failure>();
        },
      );
    });

    group('last', () {
      test(
        "ArrayAttribute.parser.parse('array(last)') should return a correct ArrayAttribute",
        () {
          var result = ArrayAttribute.parser.parse('array(last)');
          result.should.beOfType<Success<ArrayAttribute>>();
          result.value.indexType.should.be(ArrayIndexType.last);
          result.value.offSet.should.be(0);
        },
      );

      test(
        "ArrayAttribute.parser.parse('array(last-8)') should return a correct ArrayAttribute",
        () {
          var result = ArrayAttribute.parser.parse('array(last-8)');
          result.should.beOfType<Success<ArrayAttribute>>();
          result.value.indexType.should.be(ArrayIndexType.last);
          result.value.offSet.should.be(-8);
        },
      );

      test(
        "ArrayAttribute.parser.parse('array(last+3)') should return a Failure",
        () {
          var result = ArrayAttribute.parser.parse('array(last+3)');
          result.should.beOfType<Failure>();
        },
      );
    });
  });

  group('PriorityAttribute class', () {
    test(
      "PriorityAttribute.parser.parse('invalid=1') should return a Failure",
      () {
        var result = PriorityAttribute.parser.parse('invalid=1');
        result.should.beOfType<Failure>();
      },
    );
    test(
      "PriorityAttribute.parser.parse('prio=invalid') should return a Failure",
      () {
        var result = PriorityAttribute.parser.parse('prio=invalid');
        result.should.beOfType<Failure>();
      },
    );
    test(
      "PriorityAttribute.parser.parse('prio=1') should return a correct PriorityAttribute",
      () {
        var result = PriorityAttribute.parser.parse('prio=1');
        result.should.beOfType<Success<PriorityAttribute>>();
        result.value.eventPriority.should.be(EventPriority.fatal);
      },
    );

    test(
      "PriorityAttribute.parser.parse(' prio = M') should return a correct PriorityAttribute",
      () {
        var result = PriorityAttribute.parser.parse(' prio = M');
        result.should.beOfType<Success<PriorityAttribute>>();
        result.value.eventPriority.should.be(EventPriority.medium);
      },
    );
    test(
      "PriorityAttribute.parser.parse(' PRIO = INFO ') should return a correct PriorityAttribute",
      () {
        var result = PriorityAttribute.parser.parse(' PRIO = INFO ');
        result.should.beOfType<Success<PriorityAttribute>>();
        result.value.eventPriority.should.be(EventPriority.info);
      },
    );
  });

  group('ComponentCodeColumnAttribute class', () {
    test(
      "ComponentCodeColumnAttribute.parser.parse('invalid=+12') should return a Failure",
      () {
        var result = ComponentCodeAddColumnsAttribute.parser.parse(
          'invalid=+12',
        );
        result.should.beOfType<Failure>();
      },
    );
    test(
      "ComponentCodeColumnAttribute.parser.parse('ccc=invalid') should return a Failure",
      () {
        var result = ComponentCodeAddColumnsAttribute.parser.parse(
          'ccc=invalid',
        );
        result.should.beOfType<Failure>();
      },
    );

    test(
      "ComponentCodeColumnAttribute.parser.parse('ccc=+12') should return a correct ComponentCodeColumnAttribute",
      () {
        var result = ComponentCodeAddColumnsAttribute.parser.parse('ccc=+12');
        result.should.beOfType<Success<ComponentCodeAddColumnsAttribute>>();
        result.value.numberOfColumnsToAdd.should.be(12);
      },
    );

    test(
      "ComponentCodeColumnAttribute.parser.parse('ccc=2') should return a correct ComponentCodeColumnAttribute",
      () {
        var result = ComponentCodeAddColumnsAttribute.parser.parse('ccc=2');
        result.should.beOfType<Success<ComponentCodeAddColumnsAttribute>>();
        result.value.numberOfColumnsToAdd.should.be(2);
      },
    );
  });

  group('ConditionalAttribute class', () {
    test(
      "ConditionalAttribute.parser.parse('*foo*=bar') should return a correct result",
      () {
        var result = ConditionalAttribute.parser.parse(' *foo* =bar');
        result.should.beOfType<Success<ConditionalAttribute>>();
        result.value.should.beOfType<ConditionalAttribute>();
        result.value.namePathValidator('bar').should.beFalse();
        result.value.namePathValidator('ffoof').should.beTrue();
        result.value.values.should.contain('bar');
      },
    );
  });

  group('ComponentCodeLettersAttribute class', () {
    test(
      "ComponentCodeLettersAttribute.parser.parse('invalid=q') should return a Failure",
      () {
        var result = ComponentCodeOverrideLettersAttribute.parser.parse(
          'invalid=q',
        );
        result.should.beOfType<Failure>();
      },
    );
    test(
      "ComponentCodeLettersAttribute.parser.parse('ccl=123') should return a Failure",
      () {
        var result = ComponentCodeOverrideLettersAttribute.parser.parse(
          'ccl=123',
        );
        result.should.beOfType<Failure>();
      },
    );

    test(
      "ComponentCodeLettersAttribute.parser.parse('ccl=jb') should return a correct ComponentCodeLettersAttribute",
      () {
        var result = ComponentCodeOverrideLettersAttribute.parser.parse(
          'ccl=jb',
        );
        result.should
            .beOfType<Success<ComponentCodeOverrideLettersAttribute>>();
        result.value.componentLetters.should.be('JB');
      },
    );

    test(
      "ComponentCodeLettersAttribute.parser.parse(' ccL = Q ') should return a correct ComponentCodeLettersAttribute",
      () {
        var result = ComponentCodeOverrideLettersAttribute.parser.parse(
          ' ccL = Q ',
        );
        result.should
            .beOfType<Success<ComponentCodeOverrideLettersAttribute>>();
        result.value.componentLetters.should.be('Q');
      },
    );
  });
}
