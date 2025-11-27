import 'package:meyncraft/meyncraft/meyn_sysmac/event/component_code.domain.dart';

class Event {
  final int number;
  final String namePath;
  final String group;
  final String message;

  /// global variables related to this Event
  /// so we can get component codes and hardware addresses
  final Iterable<String> ioVariableNamePaths;
  final List<ComponentCode> componentCodes;
  final Map<String, List<ComponentCode>> variableNameWithComponentCodes;
  final Map<String, String> variableNameWithHardwareAddress;
  final EventPriority priority;
  final bool acknowledgeRequired;

  Event({
    required this.number,
    required this.namePath,
    required this.group,
    required this.message,
    this.ioVariableNamePaths = const <String>[],
    this.componentCodes = const <ComponentCode>[],
    this.variableNameWithComponentCodes = const <String, List<ComponentCode>>{},
    this.variableNameWithHardwareAddress = const <String, String>{},
    required this.priority,
    required this.acknowledgeRequired,
  });

  String get componentCodesAndMessage =>
      [...componentCodes.map((c) => c.createCode()), message].join(' ');

  @override
  String
  toString() => // 'Event(number: $number, namePath: $namePath, group: $group, message: $message)';
      '${namePath.padRight(60)}  $componentCodesAndMessage ${priority.abbreviation} $acknowledgeRequired';
}

class Counter {
  int value = 0;
  int next() {
    value = value + 1;
    return value;
  }
}

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
enum EventPriority {
  fatal(
    name: 'Fatal',
    abbreviation: 'F',
    level: 1,
    description:
        'A fatal problem that prevents the system from working (fatal for system).',
    example:
        'An EtherCAT error, an important fuse of the control system, missing IO cards, critical IO card errors, etc.',
  ),
  critical(
    name: 'Critical',
    abbreviation: 'C',
    level: 2,
    description: 'A critical problem that stops the system.',
    example:
        'An emergency stop, a critical motor tripped, low hydraulic level, etc.',
  ),
  high(
    name: 'High',
    abbreviation: 'H',
    level: 3,
    description: 'A problem with major consequences, but system keeps running.',
    example: 'Direct action is needed, e.g.: an important motor tripped, etc.',
  ),
  mediumHigh(
    name: 'Medium High',
    abbreviation: 'MH',
    level: 4,
    description: 'A problem with moderate consequences.',
    example: 'Urgent action is required.',
  ),
  medium(
    name: 'Medium',
    abbreviation: 'M',
    level: 5,
    description: 'A problem with some consequences.',
    example:
        'Action within 5 minutes is required, e.g. when a low temperature is detected.',
  ),
  mediumLow(
    name: 'Medium Low',
    abbreviation: 'ML',
    level: 6,
    description: 'A problem with minor consequences.',
    example: 'Action within 15 minutes is required.',
  ),
  low(
    name: 'Low',
    abbreviation: 'L',
    level: 7,
    description: 'A problem with almost no consequences.',
    example: 'Eventually action is required, e.g. a tripped plucker motor.',
  ),
  info(
    name: 'Info',
    abbreviation: 'I',
    level: 9,
    description:
        'All events that are not an error, such as information for the operator',
    example: 'When a stop button is pressed, or external stop is activated.',
  );

  final String name;
  final String abbreviation;
  final int level;
  final String description;
  final String example;

  const EventPriority({
    required this.name,
    required this.abbreviation,
    required this.level,
    required this.description,
    required this.example,
  });
}
