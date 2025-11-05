import 'package:collection/collection.dart';
import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/variable/variable.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/meyn/event/event.domain.dart';

class EventService {
  final List<Variable> globalVariables;

  static const String eventGlobalVariableName = 'EventGlobal';

  late final List<Event> events = _createEvents();

  EventService(this.globalVariables);

  List<Event> _createEvents() {
    var eventGlobal = globalVariables.firstWhereOrNull(
      (v) => v.name == eventGlobalVariableName,
    );
    if (eventGlobal == null) {
      throw Exception(
        'Expected the sysmac project to have 1 global variable of name "$eventGlobalVariableName"',
      );
    }
    var eventRootNode = EventNode.fromVariable(eventGlobal);
    var counter = Counter();
    var events = eventRootNode.createEvents(counter);
    logger.info('Found ${events.length} events');
    return events;
  }
}
