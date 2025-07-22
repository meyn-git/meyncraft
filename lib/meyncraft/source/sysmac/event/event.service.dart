import 'package:collection/collection.dart';
import 'package:meyncraft/meyncraft/logger/logger.infrastructure.dart';
import 'package:meyncraft/meyncraft/source/sysmac/event/event.domain.dart';
import 'package:meyncraft/meyncraft/source/sysmac/variable/variable.service.dart';

class EventService {
  final GlobalVariableService globalVariableService;

  static const String eventGlobalVariableName = 'EventGlobal';

  late final List<Event> events = _createEvents();

  EventService(this.globalVariableService);

  List<Event> _createEvents() {
    var eventGlobal = globalVariableService.variables.firstWhereOrNull(
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
