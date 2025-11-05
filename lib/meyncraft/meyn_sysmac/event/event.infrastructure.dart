import 'package:collection/collection.dart';
import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/event/event.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.domain.dart';

const String eventGlobalVariableName = 'EventGlobal';

List<Event> createEvents(SysmacProject sysmacProject) {
  var eventGlobal = sysmacProject.globalVariables.firstWhereOrNull(
    (v) => v.name == eventGlobalVariableName,
  );
  if (eventGlobal == null) {
    logger.warning('Could not find a global variable with name: $eventGlobal');
    return [];
  }
  var eventRootNode = EventNode.fromVariable(eventGlobal);
  var counter = Counter();
  var events = eventRootNode.createEvents(counter);
  logger.info('Found ${events.length} events');
  return events;
}
