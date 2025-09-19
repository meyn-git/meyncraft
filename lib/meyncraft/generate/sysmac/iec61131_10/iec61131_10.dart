import 'package:collection/collection.dart';
import 'package:meyncraft/meyncraft/source/sysmac/variable/variable.service.dart';
import 'package:xml/xml.dart';

String createNowInSysmacXmlFormat() =>
    DateTime.now().toIso8601String().split('.').first;

class Project extends XmlElement {
  Project(List<GlobalNamespaceType> types, List<GlobalVariable> variables)
    : super(
        XmlName('Project'),
        [
          XmlAttribute(
            XmlName('xmlns:xsi'),
            'http://www.w3.org/2001/XMLSchema-instance',
          ),
          XmlAttribute(XmlName('xmlns:smcext'), 'https://www.ia.omron.com/Smc'),
          XmlAttribute(
            XmlName('xsi:schemaLocation'),
            'https://www.ia.omron.com/Smc IEC61131_10_Ed1_0_SmcExt1_0_Spc1_0.xsd',
          ),
          XmlAttribute(XmlName('schemaVersion'), '1'),
          XmlAttribute(XmlName('xmlns'), 'www.iec.ch/public/TC65SC65BWG7TF10'),
        ],
        [FileHeader(), ContentHeader(), Types(types), Instances(variables)],
      );
}

class FileHeader extends XmlElement {
  FileHeader()
    : super(XmlName('FileHeader'), [
        XmlAttribute(XmlName('companyName'), 'OMRON Corporation'),
        XmlAttribute(XmlName('productName'), 'Sysmac Studio'),
        XmlAttribute(XmlName('productVersion'), '1.30.0.0'),
      ], []);
}

class ContentHeader extends XmlElement {
  ContentHeader()
    : super(
        XmlName('ContentHeader'),
        [
          XmlAttribute(XmlName('name'), 'GeneratedByMeyncraft'),
          XmlAttribute(
            XmlName('creationDateTime'),
            createNowInSysmacXmlFormat(),
          ),
        ],
        [
          AddDataInfo(),
          //AddData(),
        ],
      );
}

class AddDataInfo extends XmlElement {
  AddDataInfo() : super(XmlName('AddDataInfo'), [], [Info()]);
}

class Info extends XmlElement {
  Info()
    : super(XmlName('Info'), [
        XmlAttribute(
          XmlName('name'),
          'https://www.ia.omron.com/Smc IEC61131_10_Ed1_0_SmcExt1_0_Spc1_0.xsd',
        ),
        XmlAttribute(XmlName('vendor'), 'https://www.ia.omron.com/Smc'),
      ], []);
}

class AddData extends XmlElement {
  AddData(XmlElement dataElement)
    : super(XmlName('AddData'), [], [dataElement]);
}

class Data extends XmlElement {
  Data(DataChild child)
    : super(
        XmlName('Data'),
        [
          XmlAttribute(
            XmlName('name'),
            'https://www.ia.omron.com/Smc IEC61131_10_Ed1_0_SmcExt1_0_Spc1_0.xsd',
          ),
          XmlAttribute(XmlName('handleUnknown'), 'discard'),
        ],
        [child],
      );
}

abstract class DataChild extends XmlElement {
  DataChild(super.name, super.attributes, super.children);
}

class SmcExtDeviceInfo extends DataChild {
  SmcExtDeviceInfo()
    : super(XmlName('DeviceInfo', 'smcext'), [
        XmlAttribute(XmlName('modelName'), 'NJ501-1500'),
        XmlAttribute(XmlName('version'), '1.40'),
      ], []);
}

class SmcExtConnectionPointInOrder extends DataChild {
  SmcExtConnectionPointInOrder(int order)
    : super(XmlName('ConnectionPointInOrder', 'smcext'), [
        XmlAttribute(XmlName('order'), order.toString()),
      ], []);
}

class SmcExtConnectionPointOutOrder extends DataChild {
  SmcExtConnectionPointOutOrder(int order)
    : super(XmlName('ConnectionPointOutOrder', 'smcext'), [
        XmlAttribute(XmlName('order'), order.toString()),
      ], []);
}

/// Base of:
/// * DataTypeDecl
/// * Program
/// * Function
/// * FunctionBlock
/// * NamespaceDecl
abstract class GlobalNamespaceType extends XmlElement {
  GlobalNamespaceType(super.name, super.attributes, super.children);
}

class Types extends XmlElement {
  Types(List<GlobalNamespaceType> types)
    : super(XmlName('Types'), [], [GlobalNamespace(types)]);
}

class GlobalNamespace extends XmlElement {
  GlobalNamespace(List<GlobalNamespaceType> types)
    : super(XmlName('GlobalNamespace'), [], types);
}

class GlobalVariable extends XmlElement {
  final Variable2 variable;
  final bool constant;
  final bool retain;

  GlobalVariable(this.variable, {this.constant = false, this.retain = false})
    : super(
        XmlName('GlobalVars'),
        [
          if (constant) XmlAttribute(XmlName('constant'), 'true'),
          if (retain) XmlAttribute(XmlName('retain'), 'true'),
        ],
        [variable],
      );
}

/// The name Variable could not be used so we use Variable2
class Variable2 extends XmlElement {
  final String variableName;
  final String variableType;
  Variable2({
    required this.variableName,
    required this.variableType,
    String? comment,
    NetworkPublish networkPublish = NetworkPublish.doNotPublish,
    String? address,
  }) : super(
         XmlName('Variable'),
         [XmlAttribute(XmlName('name'), variableName)],
         [
           if (comment != null) Documentation(comment),
           if (networkPublish != NetworkPublish.doNotPublish)
             _createNetworkPublishElement(networkPublish),
           Type(variableType),
           if (address != null) Address(address),
         ],
       );

  static AddData _createNetworkPublishElement(NetworkPublish networkPublish) {
    return AddData(
      Data(
        GlobalVariableAdditionalProperties(
          XmlAttribute(
            XmlName('networkPublish'),
            _createNetworkPublishValue(networkPublish),
          ),
        ),
      ),
    );
  }

  static String _createNetworkPublishValue(NetworkPublish networkPublish) {
    switch (networkPublish) {
      case NetworkPublish.publicationOnly:
        return 'PublishOnly';
      case NetworkPublish.input:
        return 'Input';
      case NetworkPublish.output:
        return 'Output';
      default:
        throw Exception('Unknown value: ${networkPublish.name}');
    }
  }

  Variable2 copyAsReference() =>
      Variable2(variableName: variableName, variableType: variableType);
}

class GlobalVariableAdditionalProperties extends DataChild {
  GlobalVariableAdditionalProperties(XmlAttribute attribute)
    : super(XmlName('GlobalVariableAdditionalProperties', 'smcext'), [
        attribute,
      ], []);
}

/// See Address in a GlobalVariable in a existing Sysmac project.
/// e.g.: IOBus://unit#1/SfoDcoPackConvSafeStop or %d4
class Address extends XmlElement {
  Address(String address)
    : super(XmlName('Address'), [XmlAttribute(XmlName('address'), address)]);
}

/// creates a Type like : BOOL, BYTE, INT or ARRAY[0..10] OF BOOL
/// See IEC61131-10 standard documentation on the internet.
class Type extends XmlElement {
  Type(String type)
    : super(XmlName('Type'), [], [
        XmlElement(XmlName('TypeName'), [], [XmlText(type)]),
      ]);
}

class Instances extends XmlElement {
  Instances(List<GlobalVariable> variables)
    : super(XmlName('Instances'), [], [Configuration(variables)]);
}

class Configuration extends XmlElement {
  Configuration(List<GlobalVariable> variables)
    : super(
        XmlName('Configuration'),
        [XmlAttribute(XmlName('name'), 'ConfigurationName')],
        [Resource(variables)],
      );
}

class Resource extends XmlElement {
  Resource(List<GlobalVariable> variables)
    : super(XmlName('Resource'), [
        XmlAttribute(XmlName('name'), "ResourceName"),
        XmlAttribute(XmlName('resourceTypeName'), ""),
      ], variables);
}

class SmcExtPouInfo extends DataChild {
  SmcExtPouInfo({required String version, required String author})
    : super(XmlName('PouInfo', 'smcext'), [
        XmlAttribute(XmlName('version'), version),
        XmlAttribute(XmlName('author'), author),
        XmlAttribute(XmlName('creationDateTime'), createNowInSysmacXmlFormat()),
        XmlAttribute(
          XmlName('modificationDateTime'),
          createNowInSysmacXmlFormat(),
        ),
      ], []);
}

class Program extends GlobalNamespaceType {
  final String programName;

  Program({
    required this.programName,
    required SmcExtPouInfo pouInfo,
    List<GlobalVariable> globalVariables = const [],
    List<Variable2> internalVariables = const [],
    required MainBody mainBody,
  }) : super(
         XmlName('Program'),
         [XmlAttribute(XmlName('name'), programName)],
         [
           Documentation('Program generated by MeynCraft'),
           AddData(Data(pouInfo)),
           ..._createExternalVars(globalVariables),
           Vars(internalVariables, accessSpecifier: 'private'),
           mainBody,
         ],
       );
}

class Vars extends XmlElement {
  Vars(List<Variable2> variables, {String? accessSpecifier})
    : super(XmlName('Vars'), [
        if (accessSpecifier != null)
          XmlAttribute(XmlName('accessSpecifier'), accessSpecifier),
      ], variables);
}

List<XmlElement> _createExternalVars(List<GlobalVariable> usedGlobalVariables) {
  var elements = <XmlElement>[];
  var constantGlobalVariables = usedGlobalVariables.where((gv) => gv.constant);
  if (constantGlobalVariables.isNotEmpty) {
    elements.add(ExternalVars(constantGlobalVariables, constant: true));
  }

  var noneConstantGlobalVariables = usedGlobalVariables.where(
    (gv) => !gv.constant,
  );
  if (noneConstantGlobalVariables.isNotEmpty) {
    elements.add(ExternalVars(noneConstantGlobalVariables, constant: false));
  }

  return elements;
}

class ExternalVars extends XmlElement {
  ExternalVars(
    Iterable<GlobalVariable> usedGlobalVariables, {
    bool constant = false,
  }) : super(
         XmlName('ExternalVars'),
         [if (constant) XmlAttribute(XmlName('constant'), 'true')],
         usedGlobalVariables.map((gv) => gv.variable.copyAsReference()),
       );
}

// <Documentation xsi:type="SimpleText">Program0 Comment</Documentation>
class Documentation extends XmlElement {
  Documentation(String comment)
    : super(
        XmlName('Documentation'),
        [XmlAttribute(XmlName('type', 'xsi'), "SimpleText")],
        [XmlText(comment)],
      );
}

class MainBody extends XmlElement {
  MainBody.structuredTextSection(String structuredText)
    : this._([StructuredTextSection(structuredText)]);

  MainBody.ladderSection(List<LadderSection> sections) : this._(sections);

  MainBody._(List<XmlElement> children)
    : super(XmlName('MainBody'), [], children);
}

abstract class BodyContent extends XmlElement {
  BodyContent(List<XmlAttribute> attributes, List<XmlElement> elements)
    : super(XmlName('BodyContent'), attributes, elements);

  // You can add other constructors for different section types if needed.
}

class LadderSection extends BodyContent {
  LadderSection({
    required String name,
    required int evaluationOrder,
    required List<Rung> rungs,
  }) : super([
         XmlAttribute(XmlName('xsi:type'), 'smcext:LdSection'),
         XmlAttribute(XmlName('name'), name),
         XmlAttribute(XmlName('evaluationOrder'), evaluationOrder.toString()),
       ], rungs);
}

class StructuredTextSection extends BodyContent {
  StructuredTextSection(String structuredText)
    : super(
        [XmlAttribute(XmlName('xsi:type'), 'ST')],
        [
          XmlElement(XmlName('ST'), [], [XmlText(structuredText)]),
        ],
      );
}

class Rung extends XmlElement {
  Rung(int evaluationOrder, String? comment, List<XmlElement> elements)
    : super(
        XmlName('Rung'),
        [XmlAttribute(XmlName('evaluationOrder'), evaluationOrder.toString())],
        [if (comment != null) Comment(comment), ...elements],
      );

  // creates a [Rung] containing structured text
  Rung.structuredText({
    required int evaluationOrder,
    String? comment,
    required String structuredText,
  }) : this(evaluationOrder, comment, [
         LadderObject.leftPowerRail([ConnectionPointOut(1)]),
         LadderObject.inLineStructuredText(
           structuredText,
           ConnectionPointIn([1]),
           ConnectionPointOut(2),
         ),
         LadderObject.rightPowerRail([
           ConnectionPointIn([2]),
         ]),
       ]);

  Rung.comment(int evaluationOrder, String comment)
    : this(evaluationOrder, comment, [
        LadderObject.leftPowerRail([ConnectionPointOut(1)]),
        LadderObject.rightPowerRail([
          ConnectionPointIn([1]),
        ]),
      ]);
}

class FunctionBlockWithSourcesAndSinks extends DelegatingList<XmlElement> {
  FunctionBlockWithSourcesAndSinks._(super.elements, this.enoOutId);
  final int enoOutId;
  factory FunctionBlockWithSourcesAndSinks(
    String functionTypeName,
    List<FunctionLink> inOuts,
    List<FunctionLink> ins,
    List<FunctionLink> outs, {
    // Required when it is a FunctionBlock, null if it is a function
    String? instanceName,

    /// the current latest connectionPointId.
    /// This number is increased every time an ConnectionPointOutId is used.
    /// ConnectionPointOutIn s refer to these number to connect objects
    /// It normally is the ConnectionPointOutId of the ladder element that is
    /// linked to the EN input of the function block
    /// (often the connectionPointOutId of the LeftPowerRail)
    required int currentConnectionPointId,
  }) {
    var enableIn = instanceName == null
        ? 'EN'
        : 'ENI'; //Not to sure about this. So far found that PackMl functions use EN and fbUnitInterface uses ENI
    var enableOut = 'ENO';
    var inIds = <String, int>{
      enableIn: currentConnectionPointId++,
      for (var inOut in inOuts)
        inOut.functionVariableName: currentConnectionPointId++,
      for (var inputs in ins)
        inputs.functionVariableName: currentConnectionPointId++,
    };
    var outIds = <String, int>{
      enableOut: currentConnectionPointId++,
      for (var inOut in inOuts)
        inOut.functionVariableName: currentConnectionPointId++,
      for (var out in outs)
        out.functionVariableName: currentConnectionPointId++,
    };
    var elements = <XmlElement>[];
    for (var inOut in inOuts) {
      elements.add(
        FunctionBlockDataSource(
          inOut.variableName,
          inIds[inOut.functionVariableName]!,
        ),
      );
    }
    for (var input in ins) {
      elements.add(
        FunctionBlockDataSource(
          input.variableName,
          inIds[input.functionVariableName]!,
        ),
      );
    }

    int connectionPointInOrder = 2; // 1= ENI
    int connectionPointOutOrder = 2 + inOuts.length; // 1= ENO

    elements.add(
      FunctionBlockDataObject(
        [
          XmlAttribute(XmlName('xsi:type'), 'Block'),
          XmlAttribute(XmlName('typeName'), functionTypeName),
          if (instanceName != null)
            XmlAttribute(XmlName('instanceName'), instanceName),
        ],
        [
          InOutVariables([
            for (var inOut in inOuts)
              InOutVariable(
                name: inOut.functionVariableName,
                connectionPointInRef: inIds[inOut.functionVariableName]!,
                connectionPointOutRef: outIds[inOut.functionVariableName]!,
                connectionPointOrder: connectionPointInOrder++,
              ),
          ]),
          InputVariables([
            InputVariable(
              name: enableIn,
              connectionPointInRef: inIds[enableIn]!,
              connectionPointInOrder: 1,
            ),
            for (var input in ins)
              InputVariable(
                name: input.functionVariableName,
                connectionPointInRef: inIds[input.functionVariableName]!,
                connectionPointInOrder: connectionPointInOrder++,
              ),
          ]),
          OutputVariables([
            OutputVariable(
              name: enableOut,
              connectionPointOutRef: outIds[enableOut]!,
              connectionPointOutOrder: 1,
            ),
            for (var out in outs)
              OutputVariable(
                name: out.functionVariableName,
                connectionPointOutRef: outIds[out.functionVariableName]!,
                connectionPointOutOrder: connectionPointOutOrder++,
              ),
          ]),
        ],
      ),
    );

    for (var inOut in inOuts) {
      elements.add(
        FunctionBlockDataSink(
          inOut.variableName,
          outIds[inOut.functionVariableName]!,
        ),
      );
    }
    for (var out in outs) {
      elements.add(
        FunctionBlockDataSink(
          out.variableName,
          outIds[out.functionVariableName]!,
        ),
      );
    }

    return FunctionBlockWithSourcesAndSinks._(elements, outIds[enableOut]!);
  }
}

class FunctionLink {
  // e.g.InterfaceGlobal.Evisceration.PackML or TRUE or "" when not connected
  final String variableName;
  // can be an empty string
  final String functionVariableName;

  FunctionLink({
    required this.variableName,
    required this.functionVariableName,
  });
}

class InOutVariables extends XmlElement {
  InOutVariables(List<InOutVariable> inOutVariables)
    : super(XmlName('InOutVariables'), [], inOutVariables);
}

class InOutVariable extends XmlElement {
  InOutVariable({
    required String name,
    required int connectionPointOrder,
    required int connectionPointInRef,
    required int connectionPointOutRef,
  }) : super(
         XmlName('InOutVariable'),
         [XmlAttribute(XmlName('parameterName'), name)],
         [
           ConnectionPointIn([
             connectionPointInRef,
           ], connectionPointInOrder: connectionPointOrder),
           ConnectionPointOut(
             connectionPointOutRef,
             connectionPointOutOrder: connectionPointOrder,
           ),
         ],
       );
}

class InputVariables extends XmlElement {
  InputVariables(List<InputVariable> inputVariables)
    : super(XmlName('InputVariables'), [], inputVariables);
}

class InputVariable extends XmlElement {
  InputVariable({
    required String name,
    required int connectionPointInRef,
    required int connectionPointInOrder,
  }) : super(
         XmlName('InputVariable'),
         [XmlAttribute(XmlName('parameterName'), name)],
         [
           ConnectionPointIn([
             connectionPointInRef,
           ], connectionPointInOrder: connectionPointInOrder),
         ],
       );
}

class OutputVariables extends XmlElement {
  OutputVariables(List<OutputVariable> outputVariables)
    : super(XmlName('OutputVariables'), [], outputVariables);
}

class OutputVariable extends XmlElement {
  OutputVariable({
    required String name,
    required int connectionPointOutRef,
    required int connectionPointOutOrder,
  }) : super(
         XmlName('OutputVariable'),
         [XmlAttribute(XmlName('parameterName'), name)],
         [
           ConnectionPointOut(
             connectionPointOutRef,
             connectionPointOutOrder: connectionPointOutOrder,
           ),
         ],
       );
}

class FunctionBlockDataSink extends FunctionBlockDataObject {
  FunctionBlockDataSink(String variableName, int connectionPointOutId)
    : super(
        [
          XmlAttribute(XmlName('xsi:type'), 'DataSink'),
          XmlAttribute(XmlName('identifier'), variableName),
        ],
        [
          ConnectionPointIn([connectionPointOutId]),
        ],
      );
}

class FunctionBlockDataSource extends FunctionBlockDataObject {
  FunctionBlockDataSource(String variableName, int connectionPointOutId)
    : super(
        [
          XmlAttribute(XmlName('xsi:type'), 'DataSource'),
          XmlAttribute(XmlName('identifier'), variableName),
        ],

        [ConnectionPointOut(connectionPointOutId)],
      );
}

class FunctionBlockDataObject extends XmlElement {
  FunctionBlockDataObject(List<XmlAttribute> attributes, List<XmlNode> elements)
    : super(XmlName('FbdObject'), attributes, elements);
}

class CommonObject extends XmlElement {
  CommonObject(List<XmlAttribute> attributes, List<XmlNode> elements)
    : super(XmlName('CommonObject'), attributes, elements);
}

class Comment extends CommonObject {
  Comment(String comment)
    : super(
        [XmlAttribute(XmlName('xsi:type'), 'Comment')],
        [SimpleText(comment)],
      );
}

class Content extends XmlElement {
  Content(List<XmlAttribute> attributes, List<XmlNode> elements)
    : super(XmlName('Content'), attributes, elements);
}

class SimpleText extends Content {
  SimpleText(String simpleText)
    : super(
        [XmlAttribute(XmlName('xsi:type'), 'SimpleText')],
        [XmlText(simpleText)],
      );
}

class LadderObject extends XmlElement {
  LadderObject._({
    List<XmlAttribute> attributes = const [],
    List<XmlNode> children = const [],
  }) : super(XmlName('LdObject'), attributes, children);

  LadderObject.leftPowerRail(List<ConnectionPointOut> connectionPointsOut)
    : this._(
        attributes: [createTypeAttribute('LeftPowerRail')],
        children: connectionPointsOut,
      );

  LadderObject.contact(
    String operand,
    Edge? edge,
    ConnectionPointIn connectionPointIn,
    ConnectionPointOut connectionPointOut,
  ) : this._(
        attributes: [
          createTypeAttribute('Contact'),
          XmlAttribute(XmlName('operand'), operand),
          if (edge != null) XmlAttribute(XmlName('edge'), edge.toString()),
        ],
        children: [connectionPointIn, connectionPointOut],
      );

  LadderObject.coil(
    String operand,
    Edge? edge,
    ConnectionPointIn connectionPointIn,
    ConnectionPointOut connectionPointOut, [
    bool negated = false,
  ]) : this._(
         attributes: [
           createTypeAttribute('Coil'),
           XmlAttribute(XmlName('operand'), operand),
           if (edge != null) XmlAttribute(XmlName('edge'), edge.toString()),
           if (negated) XmlAttribute(XmlName('negated'), 'negated'),
         ],
         children: [connectionPointIn, connectionPointOut],
       );

  LadderObject.rightPowerRail(List<ConnectionPointIn> connectionPointsIn)
    : this._(
        attributes: [createTypeAttribute('RightPowerRail')],
        children: connectionPointsIn,
      );

  LadderObject.inLineStructuredText(
    String structuredText,
    ConnectionPointIn connectionPointIn,
    ConnectionPointOut connectionPointOut, {
    int? width,
    int? height,
  }) : this._(
         attributes: [createTypeAttribute('smcext:InlineST')],
         children: [
           AddData(
             Data(SmcExtSmcSize(width: width ?? 600, height: height ?? 200)),
           ),
           connectionPointIn.copyWithSmcExtNamePrefix(),
           connectionPointOut.copyWithSmcExtNamePrefix(),
           XmlElement(XmlName('ST', 'smcext'), [], [
             XmlElement(XmlName('ST'), [], [XmlText(structuredText)]),
           ]),
         ],
       );

  static XmlAttribute createTypeAttribute(String typeName) =>
      XmlAttribute(XmlName('xsi:type'), typeName);
}

class SmcExtSmcSize extends DataChild {
  SmcExtSmcSize({required int width, required int height})
    : super(XmlName('SmcSize', 'smcext'), [
        XmlAttribute(XmlName('width'), width.toString()),
        XmlAttribute(XmlName('height'), height.toString()),
      ], []);
}

enum Edge { rising, falling }

class ConnectionPointIn extends XmlElement {
  final List<int> refConnectionPointOutIds;
  ConnectionPointIn(
    this.refConnectionPointOutIds, {
    bool includeSmcExtPrefixInName = false,
    int? connectionPointInOrder,
  }) : super(
         includeSmcExtPrefixInName
             ? XmlName('ConnectionPointIn', 'smcext')
             : XmlName('ConnectionPointIn'),
         [],
         [
           if (connectionPointInOrder != null)
             AddData(
               Data(SmcExtConnectionPointInOrder(connectionPointInOrder)),
             ),

           for (var refConnectionPointOutId in refConnectionPointOutIds)
             XmlElement(XmlName('Connection'), [
               XmlAttribute(
                 XmlName('refConnectionPointOutId'),
                 refConnectionPointOutId.toString(),
               ),
             ], []),
         ],
       );

  ConnectionPointIn copyWithSmcExtNamePrefix() => ConnectionPointIn(
    refConnectionPointOutIds,
    includeSmcExtPrefixInName: true,
  );
}

class ConnectionPointOut extends XmlElement {
  final int connectionPointOutId;
  ConnectionPointOut(
    this.connectionPointOutId, {
    bool includeSmcExtPrefixInName = false,
    int? connectionPointOutOrder,
  }) : super(
         includeSmcExtPrefixInName
             ? XmlName('ConnectionPointOut', 'smcext')
             : XmlName('ConnectionPointOut'),
         [
           XmlAttribute(
             XmlName('connectionPointOutId'),
             connectionPointOutId.toString(),
           ),
         ],
         [
           if (connectionPointOutOrder != null)
             AddData(
               Data(SmcExtConnectionPointOutOrder(connectionPointOutOrder)),
             ),

           //  XmlElement(XmlName('Connection'), [
           //    XmlAttribute(
           //      XmlName('refConnectionPointOutId'),
           //      connectionPointOutId.toString(),
           //    ),
           //  ], []),
         ],
       );

  ConnectionPointOut copyWithSmcExtNamePrefix() =>
      ConnectionPointOut(connectionPointOutId, includeSmcExtPrefixInName: true);
}
