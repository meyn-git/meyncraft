//FIXME remove

// import 'dart:developer';

// import 'package:meyncraft/meyncraft/source/sysmac/data_type.domain.dart';
// import 'package:meyncraft/meyncraft/source/sysmac/event_component_code.domain.dart';
// import 'package:recase/recase.dart';
// import 'package:sysmac_generator/domain/base_type.dart';
// import 'package:sysmac_generator/domain/data_type.dart';
// import 'package:sysmac_generator/domain/event/event.dart';
// import 'package:sysmac_generator/domain/event/parser/acknowledge_parser.dart';
// import 'package:sysmac_generator/domain/event/parser/component_code_parser.dart';
// import 'package:sysmac_generator/domain/event/parser/counter_parser.dart';
// import 'package:sysmac_generator/domain/event/parser/derived_component_code_parser.dart';
// import 'package:sysmac_generator/domain/event/parser/event_parser.dart';
// import 'package:sysmac_generator/domain/event/parser/panel_nr_parser.dart';
// import 'package:sysmac_generator/domain/event/parser/priority_parser.dart';
// import 'package:sysmac_generator/domain/event/parser/site_nr_parser.dart';
// import 'package:sysmac_generator/domain/sysmac_project.dart';
// import 'package:sysmac_generator/util/sentence.dart';

// class EventService {
//   final Site site;
//   final ElectricPanel electricPanel;
//   final List<DataType> eventGlobalVariables;

//   EventService({
//     required this.site,
//     required this.electricPanel,
//     required this.eventGlobalVariables,
//   });

//   List<EventGroup> get eventGroups => EventGroupFactory(this).create();
// }

// class EventGroupFactory {
//   final EventService eventService;
//   final EventCounter eventCounter = EventCounter();
//   Set<String>? _cachedGroupNames;

//   EventGroupFactory(this.eventService);

//   List<EventGroup> create() {
//     List<EventOld> allEvents = [];
//     for (var eventGlobalVariable in eventService.eventGlobalVariables) {
//       allEvents.addAll(EventFactory(this, eventGlobalVariable).createAll());
//     }

//     List<EventGroup> eventGroups = [];
//     for (var groupName in groupNames) {
//       var eventGroup = EventGroup(groupName);
//       eventGroup.children
//           .addAll(allEvents.where((event) => event.groupName1 == groupName));
//       eventGroups.add(eventGroup);
//     }
//     return eventGroups;
//   }

//   Set<String> get groupNames {
//     if (_cachedGroupNames == null) {
//       List<String> allNames = [];
//       for (var eventGlobalVariable in eventService.eventGlobalVariables) {
//         allNames.addAll(eventGlobalVariable.children
//             .map((eventGlobalVariableChild) =>
//                 eventGlobalVariableChild.name.titleCase)
//             .toList());
//       }

//       allNames.sort((a, b) => a.compareTo(b));
//       _cachedGroupNames =
//           allNames.map((name) => _findUniqueName(name, allNames)).toSet();
//     }
//     return _cachedGroupNames!;
//   }

//   String _findUniqueName(String originalName, List<String> allNames) {
//     var words = originalName.titleCase.split(' ');
//     var uniqueName = originalName;
//     var matches = _startingWithTheSame(allNames, originalName).length;
//     while (words.isNotEmpty) {
//       var nameCandidate = words.join(' ');
//       var foundMatches = _startingWithTheSame(allNames, nameCandidate).length;
//       if (foundMatches > matches) {
//         matches = foundMatches;
//         uniqueName = nameCandidate;
//       }
//       words.removeAt(words.length - 1);
//     }
//     return uniqueName;
//   }

//   Iterable<String> _startingWithTheSame(
//           List<String> strings, String stringToMatch) =>
//       strings.where((string) =>
//           string.toLowerCase().startsWith(stringToMatch.toLowerCase()));
// }

// /// [EventFactory] wil recursively create all events of a EvenGlobalNode.
// /// It will contain all information necessary such as array counters
// class EventFactory {
//   static final _eventTagsParser = EventTagsParser();
//   late List<dynamic> parsedComments;
//   final EventGroupFactory eventGroupFactory;
//   final EventFactory? parentFactory;
//   final DataTypeBase eventGlobalNode;
//   ArrayValues arrayValues = NoArrayValues();
//   String arrayValue = '';

//   EventFactory(
//     this.eventGroupFactory,
//     this.eventGlobalNode, [
//     this.parentFactory,
//   ]) {
//     parsedComments = _parseComments();
//   }

//   List<DataTypeBase> get eventPath => parentFactory == null
//       ? [eventGlobalNode]
//       : [...parentFactory!.eventPath, eventGlobalNode];

//   static final _commentSeparator = ' ';

//   List<dynamic> _parseComments() {
//     var parsedComments = _eventTagsParser.parse(_commentToParse).value;
//     return [
//       if (parentFactory == null) SiteNumberTag(site.number),
//       if (parentFactory == null) PanelNumberTag(electricPanel.number),
//       if (parentFactory != null) ...parentFactory!.parsedComments,
//       ...parsedComments,
//     ];
//   }

//   String get _commentToParse {
//     var comment = eventGlobalNode.comment + _commentSeparator;
//     if (eventGlobalNode is DataType &&
//         (eventGlobalNode as DataType).baseType is DataTypeReference) {
//       var dataTypeReference =
//           (eventGlobalNode as DataType).baseType as DataTypeReference;
//       comment += dataTypeReference.dataType.comment + _commentSeparator;
//     }
//     return comment;
//   }

//   EventCounter get eventCounter => eventGroupFactory.eventCounter;

//   /// Recursively creates all events of a eventGlobalNode.
//   List<EventOld> createAll() {
//     List<EventOld> events = [];

//     arrayValues = ArrayValues(eventGlobalNode);
//     _initListeners();
//     while (arrayValues.moveNext()) {
//       arrayValue = arrayValues.current;
//       if (eventGlobalNode is DataType &&
//           (eventGlobalNode as DataType).baseType is VbBoolean) {
//         events.add(_createEvent());
//       } else {
//         for (var child in eventGlobalNode.children) {
//           events
//               .addAll(EventFactory(eventGroupFactory, child, this).createAll());
//         }
//       }
//     }
//     return events;
//   }

//   EventOld _createEvent() {
//     var groupName1 = _groupName();
//     var groupName2 = _groupName2(groupName1);
//     var priority = _priority();
//     // var componentCode = _componentCode();
//     var message = _message();
//     EventOld event = EventOld(
//       groupName1: groupName1,
//       groupName2: groupName2,
//       id: eventCounter.next,
//       componentCode: '',

//       ///componentCode == null ? '' : componentCode.toCode(),
//       expression: _expression,
//       priority: priority,
//       message: message,
//       // solution: _findSolution(componentCode),
//       acknowledge: _acknowledge(priority),
//     );
//     return event;
//   }

//   String get _expression {
//     if (parentFactory == null) {
//       return eventGlobalNode.name;
//     } else {
//       return '${parentFactory!._expression}.${eventGlobalNode.name}$arrayValue';
//     }
//   }

//   ElectricPanel get electricPanel =>
//       eventGroupFactory.eventService.electricPanel;

//   Site get site => eventGroupFactory.eventService.site;

//   String _message() {
//     String comments = '';
//     for (var parsedComment in parsedComments) {
//       if (parsedComment is String) {
//         comments += parsedComment;
//       } else if (parsedComment is EventCommentRenderer) {
//         comments += parsedComment.render();
//       }
//     }

//     return Sentence.normalize(comments);
//   }

//   // ComponentCode? _componentCode() {
//   //   var componentCodeTag = _findComponentCodeTag(eventPath);

//   //   if (componentCodeTag == null) {
//   //     return null;
//   //   } else {
//   //     return ComponentCode(
//   //       site: Site(_siteNumberTag.number),
//   //       electricPanel: ElectricPanel(
//   //           number: _panelNumberTag.number, name: electricPanel.name),
//   //       pageNumber: componentCodeTag.pageNumber,
//   //       letters: componentCodeTag.letters,
//   //       columnNumber: componentCodeTag.columnNumber,
//   //     );
//   //   }
//   // }

//   PanelNumberTag get _panelNumberTag =>
//       parsedComments.whereType<PanelNumberTag>().last;

//   SiteNumberTag get _siteNumberTag =>
//       parsedComments.whereType<SiteNumberTag>().last;

//   EventPriorityOld _priority() {
//     var priorityTags = parsedComments.whereType<PriorityTag>();
//     if (priorityTags.isEmpty) {
//       return EventPriorities.medium;
//     } else {
//       return priorityTags.last.priority;
//     }
//   }

//   bool _acknowledge(EventPriorityOld priority) {
//     var acknowledgeTags = parsedComments.whereType<AcknowledgeTag>();
//     if (acknowledgeTags.isEmpty) {
//       return priority != EventPriorities.info;
//     } else {
//       return acknowledgeTags.last.acknowledge;
//     }
//   }

//   String _groupName2(String groupName1) {
//     var groupName2 = _createEventGroupName();
//     if (groupName1 == groupName2) {
//       return '';
//     } else {
//       return groupName2.substring(groupName1.length).trim();
//     }
//   }

//   // String _findSolution(ComponentCode? componentCode) {
//   //   var solutionTexts = parsedComments
//   //       .whereType<SolutionTag>()
//   //       .map((solutionTag) => solutionTag.solution)
//   //       .toList();
//   //   if (componentCode != null) {
//   //     solutionTexts.add(
//   //         'See component ${componentCode.toCode()} on electric diagram ${componentCode.site.code}.${componentCode.electricPanel.code} on page ${componentCode.pageNumber} at column ${componentCode.columnNumber}.');
//   //   }
//   //   return solutionTexts.join(' ');
//   // }

//   String _groupName() {
//     var fullName = _createEventGroupName();
//     var groupNames = eventGroupFactory.groupNames;
//     return groupNames.firstWhere((groupName) => fullName.startsWith(groupName),
//         orElse: () => '');
//   }

//   String _eventPathString(List<DataTypeBase> eventPath) =>
//       eventPath.map((dataType) => dataType.name).join('.');

//   ComponentCodeTag? _findComponentCodeTag(List<DataTypeBase> eventPath) {
//     var componentCodeTags =
//         parsedComments.whereType<ComponentCodeTag>().toList();
//     var derivedComponentCodeTags =
//         parsedComments.whereType<DerivedComponentCodeTag>().toList();

//     if (derivedComponentCodeTags.isEmpty) {
//       if (componentCodeTags.isEmpty) {
//         return null;
//       } else {
//         return componentCodeTags.first;
//       }
//     } else {
//       return _createDerivedComponentCodeTag(
//           derivedComponentCodeTags, eventPath, componentCodeTags);
//     }
//   }

//   ComponentCodeTag? _createDerivedComponentCodeTag(
//       List<DerivedComponentCodeTag> derivedComponentCodeTags,
//       List<DataTypeBase> eventPath,
//       List<ComponentCodeTag> componentCodeTags) {
//     var derivedComponentCodeTag =
//         _findDerivedComponentCode(derivedComponentCodeTags, eventPath);
//     var componentCodeTagWithSameLetter = _findComponentCodeTagWithSameLetter(
//         derivedComponentCodeTag, componentCodeTags, eventPath);
//     if (componentCodeTagWithSameLetter == null) {
//       return null;
//     } else {
//       return ComponentCodeTag(
//           pageNumber: componentCodeTagWithSameLetter.pageNumber,
//           letters: derivedComponentCodeTag.letters,
//           columnNumber: componentCodeTagWithSameLetter.columnNumber);
//     }
//   }

//   DerivedComponentCodeTag _findDerivedComponentCode(
//       List<DerivedComponentCodeTag> derivedComponentCodeTags,
//       List<DataTypeBase> eventPath) {
//     if (derivedComponentCodeTags.length > 1) {
//       log('The following event path contains more then 1 '
//           '${DerivedComponentCodeTag}s: ${_eventPathString(eventPath)}');
//     }
//     return derivedComponentCodeTags.first;
//   }

//   ComponentCodeTag? _findComponentCodeTagWithSameLetter(
//       DerivedComponentCodeTag derivedComponentCodeTag,
//       List<ComponentCodeTag> componentCodeTags,
//       List<DataTypeBase> eventPath) {
//     if (componentCodeTags.isEmpty) {
//       log('The following event path contains a $DerivedComponentCodeTag '
//           'but no ${ComponentCodeTag}s": '
//           '${_eventPathString(eventPath)}');
//       return null;
//     }

//     var componentCodeTagsWithSameLetter = componentCodeTags
//         .where((componentCodeTag) =>
//             componentCodeTag.letters == derivedComponentCodeTag.letters)
//         .toList();
//     if (componentCodeTagsWithSameLetter.isEmpty) {
//       return componentCodeTags.first;
//     }

//     var index = derivedComponentCodeTag.indexNumber;
//     if (index < 1) {
//       log('The following event path contains a $DerivedComponentCodeTag '
//           'with an indexNumber <1: ${_eventPathString(eventPath)}');
//       return componentCodeTagsWithSameLetter.first;
//     }
//     if (index > componentCodeTagsWithSameLetter.length) {
//       log('The following event path contains a $DerivedComponentCodeTag '
//           'with indexNumber > the number of ${ComponentCodeTag}s '
//           'with the same letter: ${_eventPathString(eventPath)}');
//       return componentCodeTags.first;
//     }
//     return componentCodeTagsWithSameLetter[index - 1];
//   }

//   String _createEventGroupName() => eventPath.length == 1
//       ? eventPath[0].name.titleCase
//       : eventPath[1].name.titleCase;

//   void _initListeners() {
//     var counterTags = parsedComments
//         .where((parsedComment) =>
//             parentFactory == null ||
//             !parentFactory!.parsedComments.contains(parsedComment))
//         .whereType<CounterTag>()
//         .toList();
//     for (var counterTag in counterTags) {
//       counterTag.initListeners(this);
//     }
//   }

//   /// returns all the [ArrayCounter]s of this [EventFactory] and its parents,
//   /// starting with the last [ArrayCounter] of this [EventFactory],
//   /// followed by the preceding [ArrayCounter], etc, etc
//   List<ArrayCounter> get arrayCountersInReverseOrder => [
//         ...arrayValues.arrayCountersInReverseOrder,
//         if (parentFactory != null) ...parentFactory!.arrayCountersInReverseOrder
//       ];
// }

// // TODO remove? abstract class ArrayValues extends Iterable with Iterator<String> {
// //   final List<ArrayCounterOnNextListener> onNextListeners = [];
// //   final List<ArrayCounterOnResetListener> onResetListeners = [];

// //   ArrayValues._();

// //   factory ArrayValues(DataTypeBase eventGlobalNode) {
// //     if (eventGlobalNode is DataType) {
// //       var arrayRangesReversed = eventGlobalNode.baseType.arrayRanges.reversed;
// //       ArrayCounter? child;
// //       ArrayCounter? arrayCounter;
// //       for (var arrayRange in arrayRangesReversed) {
// //         arrayCounter = ArrayCounter(arrayRange: arrayRange, child: child);
// //         child = arrayCounter;
// //       }
// //       return arrayCounter ?? NoArrayValues();
// //     } else {
// //       return NoArrayValues();
// //     }
// //   }

// //   List<ArrayCounter> get arrayCountersInReverseOrder;

// //   void invokeOnNextListeners() {
// //     for (var listener in onNextListeners) {
// //       listener.onNext();
// //     }
// //   }

// //   void invokeOnResetListeners() {
// //     for (var listener in onResetListeners) {
// //       listener.onReset();
// //     }
// //   }
// // }

// abstract class ArrayValues extends Iterable<String>
//     implements Iterator<String> {
//   final List<ArrayCounterOnNextListener> onNextListeners = [];
//   final List<ArrayCounterOnResetListener> onResetListeners = [];

//   ArrayValues._();

//   factory ArrayValues(DataTypeBase eventGlobalNode) {
//     if (eventGlobalNode is DataType) {
//       var arrayRangesReversed = eventGlobalNode.baseType.arrayRanges.reversed;
//       ArrayCounter? child;
//       ArrayCounter? arrayCounter;
//       for (var arrayRange in arrayRangesReversed) {
//         arrayCounter = ArrayCounter(arrayRange: arrayRange, child: child);
//         child = arrayCounter;
//       }
//       return arrayCounter ?? NoArrayValues();
//     } else {
//       return NoArrayValues();
//     }
//   }

//   List<ArrayCounter> get arrayCountersInReverseOrder;

//   void invokeOnNextListeners() {
//     for (var listener in onNextListeners) {
//       listener.onNext();
//     }
//   }

//   void invokeOnResetListeners() {
//     for (var listener in onResetListeners) {
//       listener.onReset();
//     }
//   }

//   // Iterator implementation
//   @override
//   String get current;

//   @override
//   bool moveNext();
// }

// class ArrayCounter extends ArrayValues {
//   final ArrayRange arrayRange;
//   final ArrayCounter? child;
//   ArrayCounter? parent;
//   late int value;

//   ArrayCounter({
//     required this.arrayRange,
//     this.child,
//   }) : super._() {
//     if (child != null) {
//       child!.parent = this;
//     }
//     value = _startValue;
//   }

//   /// An [ArrayCounter] has at least one value.
//   /// Therefore the start value of the [leafArrayCounter] =arrayRange.min-1;
//   int get _startValue => arrayRange.min - 1;

//   /// Advances to the next element of this [ArrayCounter]
//   /// (comparable to an [Iterator]).
//   ///
//   /// Should be called before reading [value].
//   /// If the call to `moveNext` returns `true`,
//   /// then [value] will contain the next element of the iteration
//   /// until `moveNext` is called again.
//   /// If the call returns `false`, there are no further elements
//   /// and [value] should not be used any more.
//   ///
//   /// It is safe to call [goToNext] after it has already returned `false`,
//   /// but it must keep returning `false` and not have any other effect.
//   bool goToNext() {
//     if (value == _startValue && parent != null) {
//       //also initialize parent counters (recursively)
//       parent!.goToNext();
//     }
//     value++;
//     if (value > arrayRange.max) {
//       value = arrayRange.min;
//       invokeOnResetListeners();
//       return parent == null ? false : parent!.goToNext();
//     } else {
//       invokeOnNextListeners();
//       return true;
//     }
//   }

//   ArrayCounter get rootArrayCounter {
//     if (parent == null) {
//       return this;
//     } else {
//       return parent!.rootArrayCounter;
//     }
//   }

//   ArrayCounter get leafArrayCounter {
//     if (child == null) {
//       return this;
//     } else {
//       return child!.leafArrayCounter;
//     }
//   }

//   /// needed to iterate trough all values of the [ArrayCounter] tree.
//   @override
//   String get current => toString();

//   /// needed to iterate trough all values of the [ArrayCounter] tree.
//   @override
//   bool moveNext() {
//     return leafArrayCounter.goToNext();
//   }

//   @override
//   String toString() => '(${_toStringValues.join(',')})';

//   List<int> get _toStringValues {
//     List<int> values = [];
//     ArrayCounter? node = rootArrayCounter;
//     while (node != null) {
//       values.add(node.value);
//       node = node.child;
//     }
//     return values;
//   }

//   @override
//   Iterator<String> get iterator => this;

//   /// returns all the [ArrayCounter]s and its parents in reverse order
//   @override
//   List<ArrayCounter> get arrayCountersInReverseOrder {
//     List<ArrayCounter> result = [];
//     ArrayCounter? arrayCounter = leafArrayCounter;
//     do {
//       result.add(arrayCounter!);
//       arrayCounter = arrayCounter.parent;
//     } while (arrayCounter != null);
//     return result;
//   }
// }

// abstract class ArrayCounterOnNextListener {
//   void onNext();
// }

// abstract class ArrayCounterOnResetListener {
//   void onReset();
// }

// class NoArrayValues extends ArrayValues {
//   bool done = false;

//   NoArrayValues() : super._();

//   @override
//   String get current {
//     done = true;
//     return '';
//   }

//   @override
//   Iterator<String> get iterator => this;

//   @override
//   bool moveNext() {
//     invokeOnNextListeners();
//     return !done;
//   }

//   @override
//   get arrayCountersInReverseOrder => [];
// }

// class EventCounter {
//   int value = 1;

//   String get next => (value++).toString();
// }
