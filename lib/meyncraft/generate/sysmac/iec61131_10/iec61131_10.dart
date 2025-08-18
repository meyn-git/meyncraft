import 'package:meyncraft/meyncraft/source/sysmac/variable/variable.service.dart';
import 'package:recase/recase.dart';
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
  AddData(XmlElement data) : super(XmlName('AddData'), [], [data]);
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
             AddData(
               Data(
                 GlobalVariableAdditionalProperties(
                   XmlAttribute(
                     XmlName('networkPublish'),
                     networkPublish.name.pascalCase,
                   ),
                 ),
               ),
             ),
           Type(variableType),
           if (address != null) Address(address),

           // TODO
           // <Documentation xsi:type="SimpleText">global_Variable1 Comment</Documentation>
           // <AddData>
           //   <Data name="https://www.ia.omron.com/Smc IEC61131_10_Ed1_0_SmcExt1_0_Spc1_0.xsd" handleUnknown="discard">
           //     <smcext:VariableComment>
           //       <smcext:Text id="2">global_Var1 SubComment (Comment2)</smcext:Text>
           //     </smcext:VariableComment>
           //   </Data>
           // </AddData>
           // <Type>
           //   <TypeName>BOOL</TypeName>
           // </Type>
           // <Address address="%d4" />
           //
           // OR
           //
           //   <AddData>
           //   <Data name="https://www.ia.omron.com/Smc IEC61131_10_Ed1_0_SmcExt1_0_Spc1_0.xsd" handleUnknown="discard">
           //     <smcext:GlobalVariableAdditionalProperties networkPublish="Input" />
           //   </Data>
           //   <Data name="https://www.ia.omron.com/Smc IEC61131_10_Ed1_0_SmcExt1_0_Spc1_0.xsd" handleUnknown="discard">
           //     <smcext:VariableComment>
           //       <smcext:ElementComment element="[0]">
           //         <smcext:Text id="1">global_Variable2[0] Comment</smcext:Text>
           //       </smcext:ElementComment>
           //     </smcext:VariableComment>
           //   </Data>
           // </AddData>
           // <Type>
           //   <TypeName>ARRAY[0..10] OF Bool</TypeName>
           // </Type>
           //
           // OR
           //
           //    <AddData>
           //   <Data name="https://www.ia.omron.com/Smc IEC61131_10_Ed1_0_SmcExt1_0_Spc1_0.xsd" handleUnknown="discard">
           //     <smcext:GlobalVariableAdditionalProperties networkPublish="PublishOnly" />
           //   </Data>
           // </AddData>
           // <Type>
           //   <TypeName>BYTE</TypeName>
           // </Type>
           // <InitialValue>
           //   <SimpleValue value="16#0" />
           // </InitialValue>
           //
           // OR
           //
           // <AddData>
           //   <Data name="https://www.ia.omron.com/Smc IEC61131_10_Ed1_0_SmcExt1_0_Spc1_0.xsd" handleUnknown="discard">
           //     <smcext:GlobalVariableAdditionalProperties networkPublish="Output" />
           //   </Data>
           //   <Data name="https://www.ia.omron.com/Smc IEC61131_10_Ed1_0_SmcExt1_0_Spc1_0.xsd" handleUnknown="discard">
           //     <smcext:VariableComment>
           //       <smcext:ElementComment element="Structure1_Member1">
           //         <smcext:Text id="1">global_Variable4 Structuer1_Member1 Comment</smcext:Text>
           //       </smcext:ElementComment>
           //     </smcext:VariableComment>
           //   </Data>
           // </AddData>
           // <Type>
           //   <TypeName>Structure1</TypeName>
           // </Type>
           // <InitialValue>
           //   <SimpleValue value="(Structure1_Member1 := True)" />
           // </InitialValue>
         ],
       );

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
  Program(
    String name,
    SmcExtPouInfo pouInfo,
    List<GlobalVariable> usedGlobalVariables,
    //TODO local variables
    MainBody mainBody,
  ) : super(
        XmlName('Program'),
        [XmlAttribute(XmlName('name'), name)],
        [
          Documentation('Program generated by MeynCraft'),
          AddData(Data(pouInfo)),
          ...createExternalVars(usedGlobalVariables),
          mainBody,
        ],
      );
}

List<XmlElement> createExternalVars(List<GlobalVariable> usedGlobalVariables) {
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
  Rung(int evaluationOrder, String? comment, List<LadderObject> ladderObjects)
    : super(
        XmlName('Rung'),
        [XmlAttribute(XmlName('evaluationOrder'), evaluationOrder.toString())],
        [if (comment != null) Comment(comment), ...ladderObjects],
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
  }) : super(
         includeSmcExtPrefixInName
             ? XmlName('ConnectionPointIn', 'smcext')
             : XmlName('ConnectionPointIn'),
         [],
         [
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
         [],
       );

  ConnectionPointOut copyWithSmcExtNamePrefix() =>
      ConnectionPointOut(connectionPointOutId, includeSmcExtPrefixInName: true);
}
