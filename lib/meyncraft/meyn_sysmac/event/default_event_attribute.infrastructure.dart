import 'package:meyncraft/meyncraft/meyn_sysmac/event/comment_attribute.domain.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/event/event.domain.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/event/event.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/base_type/base_type.domain.dart';

/// for now ignoring [oldDefaultCommentAttributes]
List<CommentAttribute> createDefaultAttributes(
  EventNode eventNode, {
  required bool oldStyle,
}) {
  var dataTypePath = createDataTypePath(eventNode);

  Map<String, List<CommentAttribute>> defaults = createDefaults(oldStyle);

  var attributes = defaults.entries
      .where((entry) => entry.key == dataTypePath)
      .map((entry) => entry.value)
      .expand((e) => e)
      .toList();

  return attributes;
}

Map<String, List<CommentAttribute>> createDefaults(bool oldStyle) {
  if (oldStyle) {
    return oldDefaultCommentAttributes;
  } else {
    // merge defaultCommentAttributes and oldDefaultCommentAttributes
    var defaults = {...defaultCommentAttributes};
    for (var entry in oldDefaultCommentAttributes.entries) {
      var attributes = entry.value
          .where((a) => a is! ComponentCodeOverrideLettersAttribute)
          .toList();
      if (defaults.containsKey(entry.key)) {
        defaults[entry.key] = [...defaults[entry.key]!, ...attributes];
      } else {
        defaults[entry.key] = attributes;
      }
    }
    return defaults;
  }
}

String? createDataTypePath(EventNode eventNode) {
  if (eventNode.baseType is! NxBool) {
    return null;
  }
  var parent = eventNode.parent;
  if (parent == null) {
    return null;
  }
  if (parent.baseType is! DataTypeReference) {
    return null;
  }
  return '${(parent.baseType as DataTypeReference).namePathWithBackSlashes}\\${eventNode.name}';
}

Map<String, List<CommentAttribute>> defaultCommentAttributes = {
  // Cm\MtrCtrl\sEventDol
  r'Cm\MtrCtrl\sEventDol\MtrSw': [IOAttribute('iMtrSwOk')],
  r'Cm\MtrCtrl\sEventDol\MtrProt': [IOAttribute('iMtrProtOk')],
  r'Cm\MtrCtrl\sEventDol\NotRunning': [
    IOAttribute('iRunningFwd'),
    IOAttribute('iRunningRev'),
  ],
  r'Cm\MtrCtrl\sEventDol\NotStopped': [
    IOAttribute('iRunningFwd'),
    IOAttribute('iRunningRev'),
  ],
  r'Cm\MtrCtrl\sEventDol\Interlocked': [
    IOAttribute('iEnableRunFwd'),
    IOAttribute('iEnableRunRev'),
  ],
  // Cm\MtrCtrl\sEventVfd
  r'Cm\MtrCtrl\sEventVfd\MtrSw': [
    IOAttribute(
      'iVfdAlarmWord',
      warningWhenInputCommentDoesNotContainComponentCode: true,
    ),
    //ComponentCodeOverrideLettersAttribute('S'),
  ],
  r'Cm\MtrCtrl\sEventVfd\MtrProt': [
    IOAttribute('iEventSuppress'),
    //ComponentCodeOverrideLettersAttribute('Q'),
  ],
  r'Cm\MtrCtrl\sEventVfd\Interlocked': [
    IOAttribute('iEnableRunFwd'),
    IOAttribute('iEnableRunRev'),
  ],
  r'Cm\MtrCtrl\sEventVfd\Tripped': [IOAttribute('iVfdStatusWord')],
  r'Cm\MtrCtrl\sEventVfd\DriveOff': [
    IOAttribute(
      'iVfdStatusWord',
      warningWhenInputCommentDoesNotContainComponentCode: true,
    ),
  ],
  r'Cm\MtrCtrl\sEventVfd\Warning': [IOAttribute('iVfdStatusWord')],
  r'Cm\MtrCtrl\sEventVfd\Low10V': [IOAttribute('iVfdStatusWord')],
  r'Cm\MtrCtrl\sEventVfd\MtrEtrOverTmp': [IOAttribute('iVfdAlarmWord')],
  r'Cm\MtrCtrl\sEventVfd\TorqueLimit': [IOAttribute('iVfdAlarmWord')],
  r'Cm\MtrCtrl\sEventVfd\OverCurr': [IOAttribute('iVfdAlarmWord')],
  r'Cm\MtrCtrl\sEventVfd\GroundFault': [IOAttribute('iVfdAlarmWord')],
  r'Cm\MtrCtrl\sEventVfd\ShortCircuit': [IOAttribute('iVfdAlarmWord')],
  r'Cm\MtrCtrl\sEventVfd\SafeStop': [IOAttribute('iVfdAlarmWord')],
  r'Cm\MtrCtrl\sEventVfd\FeedbackMonitor': [IOAttribute('iVfdAlarmWord')],
  r'Cm\MtrCtrl\sEventVfd\TrackingErr': [IOAttribute('iVfdAlarmWord')],
  r'Cm\MtrCtrl\sEventVfd\MtrSwDi': [IOAttribute('iMtrSwOk')],
};

/// TODO: This is temporarily until MeynCraft is common good
/// and the standard libraries contain [oldDefaultCommentAttributes],
/// then this Map can be removed
Map<String, List<CommentAttribute>> oldDefaultCommentAttributes = {
  // TODO add [ccl=S] in Cm\MtrCtrl\sEventDol and Cm\MtrCtrl\sEventVfd library structure comments and remove following line
  r'Cm\MtrCtrl\sEventDol\MtrSw': [ComponentCodeOverrideLettersAttribute('S')],
  r'Cm\MtrCtrl\sEventVfd\MtrSw': [ComponentCodeOverrideLettersAttribute('S')],

  // TODO add [ccl=Q] in Cm\MtrCtrl\sEventDol and Cm\MtrCtrl\sEventVfd library structure comments and remove following line
  r'Cm\MtrCtrl\sEventDol\MtrProt': [ComponentCodeOverrideLettersAttribute('Q')],
  r'Cm\MtrCtrl\sEventVfd\MtrProt': [ComponentCodeOverrideLettersAttribute('Q')],

  // TODO add [ccl=M] in Cm\MtrCtrl\sEventDol library structure comments and remove following lines
  r'Cm\MtrCtrl\sEventDol\NotRunning': [
    ComponentCodeOverrideLettersAttribute('M'),
  ],
  r'Cm\MtrCtrl\sEventDol\NotStopped': [
    ComponentCodeOverrideLettersAttribute('M'),
  ],
  r'Cm\MtrCtrl\sEventDol\Interlocked': [
    ComponentCodeOverrideLettersAttribute('M'),
  ],
  r'Cm\MtrCtrl\sEventVfd\Interlocked': [
    ComponentCodeOverrideLettersAttribute('M'),
  ],
  // TODO add [ccl=U] in Cm\MtrCtrl\sEventVfd
  r'Cm\MtrCtrl\sEventVfd\Tripped': [ComponentCodeOverrideLettersAttribute('U')],

  r'Cm\MtrCtrl\sEventVfd\DriveOff': [
    ComponentCodeOverrideLettersAttribute('U'),
  ],

  r'Cm\MtrCtrl\sEventVfd\DriveWarning': [
    ComponentCodeOverrideLettersAttribute('U'),
  ],

  r'Cm\MtrCtrl\sEventVfd\.Low10V': [ComponentCodeOverrideLettersAttribute('U')],

  r'Cm\MtrCtrl\sEventVfd\MtrEtrOverTmp': [
    ComponentCodeOverrideLettersAttribute('U'),
  ],

  r'Cm\MtrCtrl\sEventVfd\TorqueLimit': [
    ComponentCodeOverrideLettersAttribute('U'),
  ],

  r'Cm\MtrCtrl\sEventVfd\OverCurr': [
    ComponentCodeOverrideLettersAttribute('U'),
  ],

  r'Cm\MtrCtrl\sEventVfd\GroundFault': [
    ComponentCodeOverrideLettersAttribute('U'),
  ],
  r'Cm\MtrCtrl\sEventVfd\ShortCircuit': [
    ComponentCodeOverrideLettersAttribute('U'),
  ],

  r'Cm\MtrCtrl\sEventVfd\SafeStop': [
    ComponentCodeOverrideLettersAttribute('U'),
  ],

  r'Cm\MtrCtrl\sEventVfd\FeedbackMonitor': [
    ComponentCodeOverrideLettersAttribute('U'),
  ],

  r'Cm\MtrCtrl\sEventVfd\TrackingErr': [
    ComponentCodeOverrideLettersAttribute('U'),
  ],

  // TODO add [noAck] in Equipment\*Module\sEvent library structure comment and remove following line
  r'Equipment\*Module\sEvent\StopTimeOut': [AcknowledgeAttribute(false)],
  // TODO add [noAck][prio=info] in Safety\sEventInDualChannel\Reset library structure comment and remove following line
  r'Safety\sEventInDualChannel\Reset\RstReq': [
    AcknowledgeAttribute(false),
    PriorityAttribute(EventPriority.info),
  ],

  // TODO add [noAck][prio=info] in Safety\sEventInDualChannel\Activated library structure comment and remove following line
  r'Safety\sEventInDualChannel\Activated\Active': [
    AcknowledgeAttribute(false),
    PriorityAttribute(EventPriority.info),
  ],

  r'Safety\sEventInDualChannel\Activated\ActiveWarning': [
    AcknowledgeAttribute(false),
    PriorityAttribute(EventPriority.info),
  ],
  // TODO add [noAck][prio=info] in Cm\StartStopCtrl\sEvent library structure comment and remove following line
  r'Cm\StartStopCtrl\StopBox*': [
    AcknowledgeAttribute(false),
    PriorityAttribute(EventPriority.info),
  ],
};

// /// TODO: This is temporarily until MeynCraft is common good
// /// and the standard libraries contain ComponentCodeLettersAttributes',
// /// then this List can be removed
// List<CommentAttribute> conditionalAttributes = [
//   // TODO add [ccl=S] in Cm\MtrCtrl\sEventDol and Cm\MtrCtrl\sEventVfd library structure comments and remove following line
//   ConditionalAttribute('*.MtrSw', [
//     ComponentCodeOverrideLettersAttribute('S'),
//   ]),
//   // TODO add [ccl=Q] in Cm\MtrCtrl\sEventDol and Cm\MtrCtrl\sEventVfd library structure comments and remove following line
//   ConditionalAttribute('*.MtrProt', [
//     ComponentCodeOverrideLettersAttribute('Q'),
//   ]),
//   // TODO add [ccl=M] in Cm\MtrCtrl\sEventDol library structure comments and remove following lines
//   ConditionalAttribute('*.NotRunning', [
//     ComponentCodeOverrideLettersAttribute('M'),
//   ]),
//   ConditionalAttribute('*.NotStopped', [
//     ComponentCodeOverrideLettersAttribute('M'),
//   ]),
//   // following lines are commented because *.Interlocked is used be several structures
//   // ConditionalAttribute('*.Interlocked', [
//   //   ComponentCodeOverrideLettersAttribute('M'),
//   // ]),
//   // TODO add [ccl=U] in Cm\MtrCtrl\sEventVfd library structure comments and remove following lines
//   // following lines are commented because fuses als have .Tripped but must stay F
//   // ConditionalAttribute('*.Tripped', [
//   //   ComponentCodeOverrideLettersAttribute('U'),
//   // ]),
//   ConditionalAttribute('*.DriveOff', [
//     ComponentCodeOverrideLettersAttribute('U'),
//   ]),
//   ConditionalAttribute('*.DriveWarning', [
//     ComponentCodeOverrideLettersAttribute('U'),
//   ]),
//   ConditionalAttribute('*.Low10V', [
//     ComponentCodeOverrideLettersAttribute('U'),
//   ]),
//   ConditionalAttribute('*.MtrEtrOverTmp', [
//     ComponentCodeOverrideLettersAttribute('U'),
//   ]),
//   ConditionalAttribute('*.TorqueLimit', [
//     ComponentCodeOverrideLettersAttribute('U'),
//   ]),
//   ConditionalAttribute('*.OverCurr', [
//     ComponentCodeOverrideLettersAttribute('U'),
//   ]),
//   ConditionalAttribute('*.GroundFault', [
//     ComponentCodeOverrideLettersAttribute('U'),
//   ]),
//   ConditionalAttribute('*.ShortCircuit', [
//     ComponentCodeOverrideLettersAttribute('U'),
//   ]),
//   ConditionalAttribute('*.SafeStop', [
//     ComponentCodeOverrideLettersAttribute('U'),
//   ]),
//   ConditionalAttribute('*.FeedbackMonitor', [
//     ComponentCodeOverrideLettersAttribute('U'),
//   ]),
//   ConditionalAttribute('*.TrackingErr', [
//     ComponentCodeOverrideLettersAttribute('U'),
//   ]),

//   // TODO add [noAck] in Equipment\*Module\sEvent library structure comment and remove following line
//   ConditionalAttribute('*.StopTimeOut', [AcknowledgeAttribute(false)]),
//   // TODO add [noAck][prio=info] in Safety\sEventInDualChannel\Reset library structure comment and remove following line
//   ConditionalAttribute('*.RstReq', [
//     AcknowledgeAttribute(false),
//     PriorityAttribute(EventPriority.info),
//   ]),
//   // TODO add [noAck][prio=info] in Safety\sEventInDualChannel\Activated library structure comment and remove following line
//   ConditionalAttribute('*.Active', [
//     AcknowledgeAttribute(false),
//     PriorityAttribute(EventPriority.info),
//   ]),
//   ConditionalAttribute('*.ActiveWarning', [
//     AcknowledgeAttribute(false),
//     PriorityAttribute(EventPriority.info),
//   ]),
//   // TODO add [noAck][prio=info] in Cm\StartStopCtrl\sEvent library structure comment and remove following line
//   ConditionalAttribute('*.StopBox*', [
//     AcknowledgeAttribute(false),
//     PriorityAttribute(EventPriority.info),
//   ]),
// ];
