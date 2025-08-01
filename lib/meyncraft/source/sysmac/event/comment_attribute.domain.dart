import 'package:meyncraft/meyncraft/source/sysmac/event/component_code.domain.dart';
import 'package:meyncraft/meyncraft/source/sysmac/event/event.domain.dart';
import 'package:petitparser/petitparser.dart';

/// A [CommentAttribute]s is additional information that is placed inside Sysmac variable or structure comments.
/// This information is needed to generate events from the Sysmac comments.
///
/// A [CommentAttribute]:
/// * is text placed between square brackets e.g.":'[prio=9]'
/// * often have a [<name>=<value>] format
/// * A Sysmac variable or structure comment can have 0 or more [CommentAttribute]s
abstract class CommentAttribute {}

/// Events need to be acknowledged by default.
/// Add '[noAck]' to the comments if an event is only informational
/// and therefore does not have to be acknowledged by the operator.
class NoAcknowledgeCommentAttribute implements CommentAttribute {
  /// TODO replace for parser
  static bool valueOf(String commentPath) {
    String comment = commentPath.trim().toLowerCase();
    return comment.contains('[noAck]') ||
        // TODO add [noAck][prio=m] in Equipment\MtrModule\sEvent library structure comment and remove following line
        comment.endsWith('stop time out') ||
        // TODO add [noAck][prio=i] in Safety\sEventInDualChannel\Reset library structure comment and remove following line
        comment.contains('-reset request') ||
        // TODO add [noAck][prio=i] in Safety\sEventInDualChannel\Activated library structure comment and remove following line
        comment.contains('-activated') ||
        // TODO add [noAck][prio=i] in Cm\StartStopCtrl\sEvent library structure comment and remove following line
        comment.contains('start request start/stop') ||
        // TODO add [noAck][prio=i] in Cm\StartStopCtrl\sEvent library structure comment and remove following line
        comment.contains('start request satellite panel');
  }
}

/// Event priorities indicate to an operator on what to focus on first.
/// Events get a medium priority by default.
/// Add [pri=<abbreviation>] to the comments if an event needs a different priority.
/// See table below.
///
/// Priority definition:
/// | Name        | Abbreviation | Level | Description                                                                 | Example                                                                                      |
/// |-------------|--------------|-------|-----------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
/// | Fatal       | F            | 1     | A fatal problem that prevents the system from working (fatal for system).   | An EtherCAT error, an important fuse of the control system, missing IO cards, critical IO card errors, etc. |
/// | Critical    | C            | 2     | A critical problem that stops the system.                                   | An emergency stop, a critical motor tripped, low hydraulic level, etc.                      |
/// | High        | H            | 3     | A problem with major consequences, but system keeps running.                | Direct action is needed, e.g.: an important motor tripped, etc.                             |
/// | Medium High | MH           | 4     | A problem with moderate consequences.                                       | Urgent action is required.                                                                  |
/// | Medium      | M            | 5     | A problem with some consequences.                                           | Action within 5 minutes is required, e.g. when a low temperature is detected.               |
/// | Medium Low  | ML           | 6     | A problem with minor consequences.                                          | Action within 15 minutes is required.                                                       |
/// | Low         | L            | 7     | A problem with almost no consequences.                                      | Eventually action is required, e.g. a tripped plucker motor.                                |
/// | Info        | I            | 9     | All events that are not an error, such as information for the operator.     | When a stop button is pressed, or external stop is activated.                               |

class EventPriorityCommentAttribute implements CommentAttribute {
  /// finds [prio=l] [PRIO=mL] [PRIO=M] etc.
  /// TODO replace with petite parser
  static RegExp get regExp => RegExp(
    '\\[prio=(${EventPriority.values.map((v) => v.abbreviation).join('|')})\\]',
    caseSensitive: false,
  );

  //TODO replace with a parser
  static EventPriority valueOf(String commentPath) {
    final matches = regExp.allMatches(commentPath);
    if (matches.isEmpty) {
      return EventPriority.medium;
    }
    final abbreviation = matches.first.group(1)!.trim().toUpperCase();
    for (var value in EventPriority.values) {
      if (value.abbreviation == abbreviation) {
        return value;
      }
    }
    return EventPriority.medium;
  }
}

/// You can override add a [ComponentCode] or comment using an [ConditionalAppendCommentAttribute]
/// [suffix=value]
/// if the event name path ends with the given suffix it will append the [ComponentCode](s) and or comments (value)
class ConditionalAppendCommentAttribute implements CommentAttribute {
  static final Parser<String> suffixParser =
      //TODO as not other CommentAttributes
      (letter() | digit() | char('.')).plus().flatten();

  static Parser<ConditionalAppendCommentAttribute> parser =
      (char('[') &
              suffixParser &
              char('=') &
              componentCodeParser
              //TODO and/or comments
              &
              char(']'))
          .map(
            (values) => ConditionalAppendCommentAttribute(values[1], values[3]),
          );

  final String namePathSuffix;
  //TODO change to List<ComponentCode> componentCodesToAdd
  final ComponentCode componentCode;
  // TODO add comments

  ConditionalAppendCommentAttribute(this.namePathSuffix, this.componentCode);

  @override
  String toString() => '$namePathSuffix $componentCode';

  static List<ComponentCode> componentsForNamePath(
    Iterable<ConditionalAppendCommentAttribute> overrides,
    String namePath,
  ) => overrides
      .where((override) => namePath.endsWith(override.namePathSuffix))
      .map((override) => override.componentCode)
      .toList();

  static List<ConditionalAppendCommentAttribute> attributesFromCommentPath(
    String commentPath,
  ) => parser.allMatches(commentPath).toList();
}

/// An events is generated for each array value.
/// e.g.: a structure "Array[1..3] of MotorOverload" with comment "20Q7 Motor overload tripped" will generate the following alarms:
/// * 20Q7 Motor overload tripped
/// * 20Q8 Motor overload tripped
/// * 21Q1 Motor overload tripped
///
/// Add [arrayNr] if you need the array number in the event message:
/// e.g.: a structure "Array[1..3] of MotorOverload" with comment "20Q7 Motor[arrayNr] overload tripped" will generate the following alarms:
/// * 20Q7 Motor1 overload tripped
/// * 20Q8 Motor2 overload tripped
/// * 21Q1 Motor3 overload tripped
///
/// Note that the array value of the last array in the structure can be used.
/// TODO [arrayNr=first] or [arrayNr=first+2] or [arrayNr=last] or [arrayNr=last-1]
class ArrayNumberCommentAttribute {
  /// TODO change to petite parser
  static final parser = RegExp(r'\[arrayNr\]', caseSensitive: false);

  static String valueOf(List<List<int>> arrayValues) =>
      arrayValues.lastOrNull?.lastOrNull?.toString() ?? '';
}

/// An event is generated for each array value.
/// e.g.: a structure "Array[1..3] of MotorOverload" with comment "20Q7 Motor overload tripped" will generate the following alarms:
/// * 20Q7 Motor overload tripped
/// * 20Q8 Motor overload tripped
/// * 21Q1 Motor overload tripped
///
/// Add [ccc=+2] if the components codes skip columns. e.g.:
/// * [ccc=+2] the next component code will be 2 columns higher
/// * [ccc=+3] the next component code will be 3 columns higher
/// * [ccc=+4] the next component code will be 4 columns higher
/// * etc
///
/// e.g.: a structure "Array[1..3] of MotorOverload" with comment "20Q5 [ccc=+4] Motor overload tripped" will generate the following alarms:
/// * 20Q5 Motor overload tripped
/// * 21Q1 Motor overload tripped
/// * 21Q5 Motor overload tripped
class ComponentCodeColumnCommentAttribute {
  final int numberOfColumnsToAdd;

  ComponentCodeColumnCommentAttribute(this.numberOfColumnsToAdd);

  static Parser<ComponentCodeColumnCommentAttribute> parser =
      (stringIgnoreCase('[ccc=') &
              (char('+').optional() & digit().plus()).flatten().map(int.parse) &
              char(']'))
          .map((values) => ComponentCodeColumnCommentAttribute(values[1]));
}

/// TODO add ComponentCodeLetterCommentAttribute
