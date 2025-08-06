import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/source/sysmac/data_type/data_type.domain.dart';
import 'package:meyncraft/meyncraft/source/sysmac/event/component_code.domain.dart';
import 'package:meyncraft/meyncraft/source/sysmac/event/event.domain.dart';
import 'package:meyncraft/meyncraft/source/sysmac/variable/variable.service.dart';
import 'package:petitparser/petitparser.dart';

/// A [CommentAttribute]s is additional information that is placed inside Sysmac variable or structure comments.
/// This information is needed to generate events from the Sysmac comments.
///
/// A [CommentAttribute]:
/// * is text placed between square brackets e.g.":'[prio=9]'
/// * often have a [<name>=<value>] format
/// * A Sysmac variable or structure comment can have 0 or more [CommentAttribute]s
abstract class CommentAttribute {}

abstract class Replaceable {
  Object replacementValue(String namePath);
}

final Parser<String> remainingTextParser =
    ((commentAttributeParser | componentCodeParser).not() & any())
        .plus()
        .flatten();

/// parses commentPath's from [Variable]s and or [DataType]s
/// into a list of:
/// * [CommentAttribute]'s
/// * [ComponentCode]s
/// * [String]'s
final Parser<List> commentPathParser =
    (commentAttributeParser | componentCodeParser | remainingTextParser).star();

/// converts [...] texts to [CommentAttribute]s
Parser<CommentAttribute> commentAttributeParser =
    (char('[') & (any().plusLazy(char(']')).flatten().trim()) & char(']')).map(
      (values) => convertToCommentAttribute(values[1]),
    );

/// converts an expression (the text between []) to a [CommentAttribute]
CommentAttribute convertToCommentAttribute(String expression) {
  for (var parser in commentAttributeParsers) {
    var result = parser.parse(expression);
    if (result is Success) {
      return result.value;
    }
  }
  return UnknownAttribute(expression);
}

final commentAttributeParsers = <Parser<CommentAttribute>>[
  AcknowledgeAttribute.parser,
  ArrayAttribute.parser,
  PriorityAttribute.parser,
  ComponentCodeAddColumnsAttribute.parser,
  ComponentCodeOverrideLettersAttribute.parser,
  ConditionalAttribute.parser,
];

class NameEqualsValueParser<T extends CommentAttribute>
    extends DelegateParser<List, T> {
  final T Function({required String name, required String value})
  nameValueConverter;

  NameEqualsValueParser(this.nameValueConverter)
    : super(nameParser & char('=') & valueParser);

  static Parser<String> valueParser = any().star().flatten();

  static Parser<String> nameParser = any().starGreedy(char('=')).flatten();

  @override
  Parser<T> copy() => NameEqualsValueParser(nameValueConverter);

  @override
  Result<T> parseOn(Context context) {
    final result = delegate.parseOn(context);
    if (result is Success) {
      try {
        T commentAttribute = nameValueConverter(
          name: result.value[0],
          value: result.value[2],
        );
        return Success(result.buffer, result.position, commentAttribute);
      } on Exception catch (e) {
        return Failure(result.buffer, result.position, e.toString());
      }
    }
    return Failure(result.buffer, result.position, result.message);
  }
}

/// for expressions that could not be converted to an [CommentAttribute]
class UnknownAttribute implements CommentAttribute {
  final String expression;

  UnknownAttribute(this.expression);

  @override
  String toString() => '[$expression]';
}

class AcknowledgeAttribute implements CommentAttribute {
  final bool value;

  AcknowledgeAttribute(this.value);
  static Parser<AcknowledgeAttribute> noAckParser = (stringIgnoreCase(
    'noack',
  ).map((_) => AcknowledgeAttribute(false)));

  static Parser<AcknowledgeAttribute> parser =
      ChoiceParser<AcknowledgeAttribute>([
        noAckParser,
        NameEqualsValueParser<AcknowledgeAttribute>(nameValueConverter),
      ]);

  static final List<String> trueValues = ['t', 'true', 'y', 'yes'];
  static final List<String> falseValues = ['f', 'false', 'n', 'no'];

  static AcknowledgeAttribute nameValueConverter({
    required String name,
    required String value,
  }) {
    if (name.trim().toLowerCase() != 'ack') {
      throw Exception('invalid name');
    }
    var normalizedValue = value.trim().toLowerCase();
    if (trueValues.contains(normalizedValue)) {
      return AcknowledgeAttribute(true);
    }
    if (falseValues.contains(normalizedValue)) {
      return AcknowledgeAttribute(false);
    }
    throw Exception('invalid value');
  }

  static bool acknowledge(List eventValues) {
    var ackAttributes = eventValues.whereType<AcknowledgeAttribute>();
    if (ackAttributes.isEmpty) {
      return true;
    }
    return ackAttributes.last.value;
  }
}

enum ArrayIndexType { first, last }

/// An events is generated for each array value.
/// e.g.: a structure "Array[1..3] of MotorOverload" with comment "20Q7 Motor overload tripped" will generate the following alarms:
/// * 20Q7 Motor overload tripped
/// * 20Q8 Motor overload tripped
/// * 21Q1 Motor overload tripped
///
/// Add [array(expression)] if you need the array number in the event message:
/// e.g.: a structure "Array[1..3] of MotorOverload" with comment "20Q7 Motor [array(last)] overload tripped" will generate the following alarms:
/// * 20Q7 Motor 1 overload tripped
/// * 20Q8 Motor 2 overload tripped
/// * 21Q1 Motor 3 overload tripped
/// 
/// The expression defines which array value from the name path will be used
/// e.g. namePath=plucker[2,5].cabinet[1].row[3]
/// 
/// then:
/// * array(first)   or array(0) or array(last-3) returns 2
/// * array(first+1) or array(1) or array(last-2) returns 5
/// * array(first+2) or array(2) or array(last-1) returns 1
/// * array(first+3) or array(3) or array(last)   returns 3

class ArrayAttribute implements CommentAttribute, Replaceable {
  final ArrayIndexType indexType;
  final int offSet;

  static Parser<ArrayAttribute> parser =
      (stringIgnoreCase('array') & char('(') & expressionParser & char(')'))
          .map((values) => values[2]);

  static Parser<ArrayAttribute> expressionParser = ChoiceParser<ArrayAttribute>(
    [firstExpressionParser, numberExpressionParser, lastExpressionParser],
  );

  static Parser<ArrayAttribute> firstExpressionParser =
      (stringIgnoreCase('first') & (char('+') & intParser).optional()).map(
        (values) => values.last == null
            ? ArrayAttribute(ArrayIndexType.first, 0)
            : ArrayAttribute(ArrayIndexType.first, values.last.last),
      );

  static Parser<ArrayAttribute> numberExpressionParser = intParser.map(
    (value) => ArrayAttribute(ArrayIndexType.first, value),
  );
  static Parser<ArrayAttribute> lastExpressionParser =
      (stringIgnoreCase('last') & (char('-') & intParser).optional()).map(
        (values) => values.last == null
            ? ArrayAttribute(ArrayIndexType.last, 0)
            : ArrayAttribute(ArrayIndexType.last, -values.last.last),
      );

  ArrayAttribute(this.indexType, this.offSet);

  @override
  int replacementValue(String namePath) {
    var arrayValues = getArrayValues(namePath);
    var arrayIndex = indexType == ArrayIndexType.first
        ? offSet
        : arrayValues.length - 1 + offSet;
    if (arrayIndex < 0) {
      logger.warning('Invalid array index: $arrayIndex for event: "$namePath"');
      return 0;
    }
    if (arrayIndex > arrayValues.length - 1) {
      logger.warning('Invalid array index: $arrayIndex for event: "$namePath"');
      return 0;
    }
    return arrayValues[arrayIndex];
  }

  static Parser<int> intParser = digit().plus().flatten().map(int.parse);

  /// gets the number values between square parentheses using petite parser(s)
  /// e.g. plucker[2,5].cabinet[1].row[3] returns [2,5,1,3]
  List<int> getArrayValues(String namePath) {
    final Parser<List<int>> valuesBetweenBracketParser = char('[')
        .seq(intParser.plusSeparated(char(',')))
        .seq(char(']'))
        .map((value) => value[1].elements); // Extract the list of ints

    final matches = valuesBetweenBracketParser.allMatches(namePath);
    return matches.expand((list) => list).toList();
  }
}

/// Event priorities indicate to an operator on what to focus on first.
/// Events get a medium priority by default.
/// Add [pri=<abbreviation>] to the comments if an event needs a different priority.
/// See [EventPriority].
class PriorityAttribute implements CommentAttribute {
  static Parser<PriorityAttribute> parser =
      NameEqualsValueParser<PriorityAttribute>(nameValueConverter);

  final EventPriority eventPriority;

  PriorityAttribute(this.eventPriority);

  static PriorityAttribute nameValueConverter({
    required String name,
    required String value,
  }) {
    if (name.trim().toLowerCase() != 'prio') {
      throw Exception('invalid name');
    }
    var normalizedValue = value.trim().toLowerCase();
    for (var prio in EventPriority.values) {
      if (prio.name.toLowerCase() == normalizedValue ||
          prio.abbreviation.toLowerCase() == normalizedValue ||
          prio.level.toString() == normalizedValue) {
        return PriorityAttribute(prio);
      }
    }
    throw Exception('invalid value');
  }

  static EventPriority priority(List eventValues) {
    var prioAttributes = eventValues.whereType<PriorityAttribute>();
    if (prioAttributes.isEmpty) {
      return EventPriority.medium;
    }
    return prioAttributes.last.eventPriority;
  }
}

/// An event is generated for each array value.
/// e.g.: a structure "Array[1..3] of MotorOverload" with comment "20Q7 Motor overload tripped" will generate the following alarms:
/// * 20Q7 Motor overload tripped
/// * 20Q8 Motor overload tripped
/// * 21Q1 Motor overload tripped
///
/// Add [ccc=+2] if the components codes skip columns. e.g.:
/// * [ccc=+0.1] the next component code will be 0.1 columns higher, e.g. 100U3.1, 100U4, 100U4.1, 100U5 etc
/// * [ccc=+2] the next component code will be 2 columns higher
/// * [ccc=+3] the next component code will be 3 columns higher
/// * [ccc=+4] the next component code will be 4 columns higher
/// * etc
///
/// e.g.: a structure "Array[1..3] of MotorOverload" with comment "20Q5 [ccc=+4] Motor overload tripped" will generate the following alarms:
/// * 20Q5 Motor overload tripped
/// * 21Q1 Motor overload tripped
/// * 21Q5 Motor overload tripped
class ComponentCodeAddColumnsAttribute implements CommentAttribute {
  static Parser<ComponentCodeAddColumnsAttribute> parser =
      NameEqualsValueParser<ComponentCodeAddColumnsAttribute>(
        nameValueConverter,
      );

  final double numberOfColumnsToAdd;
  ComponentCodeAddColumnsAttribute(this.numberOfColumnsToAdd);
  static ComponentCodeAddColumnsAttribute nameValueConverter({
    required String name,
    required String value,
  }) {
    if (name.trim().toLowerCase() != 'ccc') {
      throw Exception('invalid name');
    }
    var numberOfColumnsToAdd = double.parse(value.trim());
    return ComponentCodeAddColumnsAttribute(numberOfColumnsToAdd);
  }

  static const int numberOfColumnsOnPage = 8;
  ComponentCode componentCode(ComponentCode componentCode, String namePath) {
    var arrayValue = ArrayAttribute(
      ArrayIndexType.last,
      0,
    ).replacementValue(namePath);
    var newUnboundedColumnNumber =
        changeDecimalsTo(componentCode.columnNumber.value, 0.5) +
        ((arrayValue - 1) * changeDecimalsTo(numberOfColumnsToAdd, 0.5));
    var pagesToAdd = newUnboundedColumnNumber ~/ numberOfColumnsOnPage;
    var newPageNumber = componentCode.pageNumber + pagesToAdd;
    var newColumnNumber = changeDecimalsTo(
      newUnboundedColumnNumber - (pagesToAdd * numberOfColumnsOnPage),
      0.1,
    );
    return componentCode.copyWith(
      pageNumber: newPageNumber,
      columnNumber: ColumNumber(newColumnNumber),
    );
  }

  // if [value] has NO decimals (ends with .0) then the value is returned
  // if [value] does have decimals (ends with > .0) then the value with given decimals is returned
  // This is for calculation convenience: 100U3.1, 100U4, 100U4.1, 100U5 etc
  double changeDecimalsTo(double value, double decimals) {
    if (value > value.truncate()) {
      return value.truncate() + decimals;
    }
    return value;
  }
}

/// Overrides [ComponentCode.letters] 
/// e.g.: if the comment is "20Q5 [ccl=S] Motor switched off" 
/// then the event will be generated with component code "20S1 Motor switched off"
class ComponentCodeOverrideLettersAttribute implements CommentAttribute {
  static Parser<ComponentCodeOverrideLettersAttribute> parser =
      NameEqualsValueParser<ComponentCodeOverrideLettersAttribute>(
        nameValueConverter,
      );

  static RegExp allLetters = RegExp(r'^[A-Z]+$');

  final String componentLetters;
  ComponentCodeOverrideLettersAttribute(this.componentLetters);
  static ComponentCodeOverrideLettersAttribute nameValueConverter({
    required String name,
    required String value,
  }) {
    if (name.trim().toLowerCase() != 'ccl') {
      throw Exception('invalid name');
    }
    var letters = value.trim().toUpperCase();
    if (!allLetters.hasMatch(letters)) {
      throw Exception('invalid value');
    }
    return ComponentCodeOverrideLettersAttribute(letters);
  }

  ComponentCode componentCode(ComponentCode componentCode) =>
      componentCode.copyWith(letters: componentLetters);
}

/// You can conditionally add information to an event based on the name path of the event.
/// [namePathExpression=valuesToBeAdded]
/// * namePathExpression:
///   a partial namePath combined with an leading wildcard * and or trailing wildcard *
///   e.g. EventGlobal.MyEvents* or *.MyEvent or *My*
/// * valuesToBeAdded: Can be any combination of [CommentAttribute]s, [ComponentCode]s, or comments
class ConditionalAttribute implements CommentAttribute, Replaceable {
  static Parser<ConditionalAttribute> parser =
      NameEqualsValueParser<ConditionalAttribute>(nameValueConverter);

  final bool Function(String expression) namePathValidator;
  final List values;
  ConditionalAttribute(String expression, this.values)
    : namePathValidator = createNamePathValidator(expression);

  static ConditionalAttribute nameValueConverter({
    required String name,
    required String value,
  }) {
    var result = commentPathParser.parse(value.trim());
    if (result is Failure) {
      throw Exception('Invalid value: $result');
    }
    return ConditionalAttribute(name.trim(), result.value);
  }

  static bool Function(String namePath) createNamePathValidator(
    String expression,
  ) {
    if (expression.startsWith('*') && expression.endsWith('*')) {
      var partial = expression.substring(1, expression.length - 1);
      return (String namePath) => namePath.contains(partial);
    }
    if (expression.endsWith('*')) {
      var partial = expression.substring(0, expression.length - 1);
      return (String namePath) => namePath.startsWith(partial);
    }
    if (expression.startsWith('*')) {
      var partial = expression.substring(1);
      return (String namePath) => namePath.endsWith(partial);
    }
    throw Exception('invalid name');
  }

  @override
  List replacementValue(String namePath) {
    if (namePathValidator(namePath)) {
      return values;
    }
    return [];
  }
}


