import 'dart:io';

import 'package:meyncraft/meyncraft/generate/xor_jmobile/data_type.dart';
import 'package:meyncraft/meyncraft/logger/logger.infrastructure.dart';
import 'package:meyncraft/meyncraft/source/sysmac/base_type/base_type.domain.dart';
import 'package:meyncraft/meyncraft/source/sysmac/data_type/data_type.domain.dart';
import 'package:meyncraft/meyncraft/source/sysmac/sysmac_project.domain.dart';
import 'package:meyncraft/meyncraft/source/sysmac/variable/variable.service.dart';
import 'package:xml/xml.dart';

/// creates an xml file with [XorTag]s generated from a Sysmac project file
/// to be imported by JMobile
/// TODO make async
void writeJMobileTagsFile(SysmacProject sysmacProject) {
  var variables = sysmacProject.globalVariableService.variables;
  List<XorTag> tags = createTags(variables);
  logger.info('Found ${tags.length} Xor-JMobile tags');
  String formattedXml = createFormattedTagsXml(tags);
  var outputFile = createOutputFile(sysmacProject, '-JMobileTags.xml');
  outputFile.createSync();
  outputFile.writeAsStringSync(formattedXml);
  logger.info('Created: ${outputFile.path})');
}

File createOutputFile(SysmacProject sysmacProject, String suffix) {
  var sysmacFile = sysmacProject.archive.file;
  var directory = sysmacFile.parent.path;
  var filename = sysmacFile.uri.pathSegments.last;
  var nameWithoutExtension = filename.split('.').first;
  var outputPath =
      '$directory${Platform.pathSeparator}$nameWithoutExtension$suffix';
  var outputFile = File(outputPath);
  return outputFile;
}

String createFormattedTagsXml(List<XorTag> tags) {
  var document = XmlDocument([
    XmlComment('This code was generated with MeynCraft on ${DateTime.now()}.'),
    XmlComment(
      'For more information see: https://github.com/meyn-git/meyncraft (scroll down for documentation)',
    ),
    XmlElement(XmlName('tags'), [], tags.map((tag) => tag.toXml())),
  ]);
  final formattedXml = document.toXmlString(pretty: true, indent: '  ');
  return formattedXml;
}

List<XorTag> createTags(List<Variable> variables) {
  var publicVariables = variables
      .where((v) => v.networkPublish == NetworkPublish.publicationOnly)
      .toList();
  var tags = <XorTag>[];
  for (var variable in publicVariables) {
    var tagNode = XorTagNode.fromVariable(variable);
    tags.addAll(tagNode.createTags());
  }
  return tags;
}

/// Represents a tag (reference to some variable in the PLC) for a Xor HMI touch screen
/// So that it can be imported by JMobile (IDE of Xor HMI)
class XorTag {
  final XorDataType xorDataType;
  final String name;
  late final String tagLocator = 'Ethernet/IP CIP:prot1:uid0:$name';

  XorTag(this.name, this.xorDataType);

  @override
  String toString() => 'XorTag(name: $name, xorDataType: $xorDataType)';

  XmlElement toXml() => XmlElement(XmlName('tag'), [], [
    XmlElement(XmlName('name'), [], [XmlText(name)]),
    XmlElement(XmlName('group')),
    createResourceLocator(),
    XmlElement(XmlName('encoding'), [], []),
    XmlElement(XmlName('refreshTime'), [], [XmlText('500')]),
    XmlElement(XmlName('accessMode'), [], [XmlText('READ-WRITE')]),
    XmlElement(XmlName('active'), [], [XmlText('false')]),
    XmlElement(XmlName('TAGLOCATOR'), [], [XmlText(tagLocator)]),
    XmlElement(XmlName('comment'), [], [
      XmlText(''),
    ]), //TODO later: get comment from constructor?
    createSimulator(),
    createScaling(),
    createDecimalDigits(),
    XmlElement(XmlName('castType'), [], []),
    XmlElement(XmlName('default'), [], []),
    XmlElement(XmlName('min'), [], [XmlText(xorDataType.min)]),
    XmlElement(XmlName('max'), [], [XmlText(xorDataType.max)]),
    XmlElement(XmlName('statesText'), [], []),
  ]);

  XmlElement createResourceLocator() => XmlElement(
    XmlName('resourceLocator'),
    [],
    [
      XmlElement(XmlName('protocolName'), [], [XmlText('ETIP')]),
      XmlElement(XmlName('slave_id'), [], [XmlText('0')]),
      XmlElement(XmlName('memory_type'), [], [
        XmlText(xorDataType.iecTypeName),
      ]),
      XmlElement(XmlName('arrayindex'), [], [XmlText('0')]),
      XmlElement(XmlName('subindex'), [], []),
      XmlElement(XmlName('data_type'), [], [XmlText(xorDataType.xorTypeName)]),
      XmlElement(XmlName('arraysize'), [], [XmlText(xorDataType.arraySize)]),
      XmlElement(XmlName('conversion'), [], []),
      XmlElement(XmlName('folder_name'), [], []),
      XmlElement(XmlName('structure_name'), [], []),
      XmlElement(XmlName('tag_name'), [], [XmlText(name)]),
    ],
  );

  XmlElement createSimulator() => XmlElement(XmlName('simulator'), [], [
    XmlElement(XmlName('DataSimulator'), [], [XmlText('Variables')]),
    XmlElement(XmlName('Amplitude'), [], []),
    XmlElement(XmlName('Simulator_offset'), [], []),
    XmlElement(XmlName('Period'), [], []),
  ]);

  XmlElement createScaling() => XmlElement(XmlName('scaling'), [], [
    XmlElement(XmlName('enableScaling'), [], [XmlText('false')]),
    XmlElement(XmlName('scalingType'), [], [XmlText('byFormula')]),
    XmlElement(XmlName('enableLimits'), [], [XmlText('false')]),
    createScalingFactors(),
    createScalingLimits(),
  ]);

  XmlElement createScalingFactors() => XmlElement(XmlName('factors'), [], [
    XmlElement(XmlName('s1'), [], [XmlText('1')]),
    XmlElement(XmlName('s2'), [], [XmlText('1')]),
    XmlElement(XmlName('tagS1'), [], []),
    XmlElement(XmlName('tagS2'), [], []),
    XmlElement(XmlName('tagS3'), [], []),
  ]);

  XmlElement createScalingLimits() => XmlElement(XmlName('limits'), [], [
    XmlElement(XmlName('eumin'), [], [XmlText('0')]),
    XmlElement(XmlName('eumax'), [], [XmlText('100')]),
    XmlElement(XmlName('elmin'), [], []),
    XmlElement(XmlName('elmax'), [], []),
  ]);

  XmlElement createDecimalDigits() => XmlElement(XmlName('decimalDigits'), [], [
    XmlElement(XmlName('ddTag'), [], []),
    XmlElement(XmlName('ddDigits'), [], []),
  ]);
}

class XorTagNode {
  final String name;
  final BaseType baseType;
  final List<XorTagNode> children;

  XorTagNode.fromVariable(Variable variable)
    : name = variable.name,
      baseType = variable.baseType,
      children = createChildren(variable.baseType);

  XorTagNode.fromDataType(DataType dataType)
    : name = dataType.name,
      baseType = dataType.baseType,
      children = createChildren(dataType.baseType);

  static List<XorTagNode> createChildren(BaseType baseType) =>
      baseType is DataTypeReference
      ? baseType.dataType.children
            .map((c) => c as DataType)
            .map((child) => XorTagNode.fromDataType(child))
            .toList()
      : [];

  static bool skip(BaseType baseType) =>
      baseType is EnumChild ||
      baseType is UnknownBaseType ||
      baseType is DataTypeReference;

  List<XorTag> createTags([String parentNamePath = '']) {
    var tags = <XorTag>[];
    if (children.isEmpty) {
      if (skip(baseType)) {
        return [];
      }

      // an exception on the rule to reduce the number of tags:
      if (singleArrayRootNode(parentNamePath, baseType)) {
        // create a single XorTag for the whole array so that
        // we do not have to make tags for each individual array value.
        // This reduces the number of tags significantly
        return [
          XorTag(name, XorDataType.findCompatibleTypeWithSingleArray(baseType)),
        ];
      }
      var namePaths = createNamePaths(parentNamePath);
      var xorDataType = XorDataType.findCompatibleType(baseType);
      tags.addAll(namePaths.map((namePath) => XorTag(namePath, xorDataType)));
    } else {
      var namePaths = createNamePaths(parentNamePath);
      for (var namePath in namePaths) {
        for (var child in children) {
          tags.addAll(child.createTags(createNamePath(namePath)));
        }
      }
    }
    return tags;
  }

  /// creates a name path of this node.
  /// returns a list with:
  /// * one path if there is no array.
  /// * or a path for each array value
  List<String> createNamePaths(String preceedingPath) {
    var path = createNamePath(preceedingPath);
    var arrayValues = baseType.arrayRanges.toStringList();
    if (arrayValues.isEmpty) {
      return <String>[path];
    } else {
      return arrayValues.map((arrayValue) => path + arrayValue).toList();
    }
  }

  /// creates a name path for this node without array values
  String createNamePath(String preceedingPath) =>
      preceedingPath.isEmpty ? name : [preceedingPath, name].join('/');

  /// an exception on the rule: to reduce the number of tags
  bool singleArrayRootNode(String preceedingPath, BaseType baseType) =>
      preceedingPath.isEmpty && baseType.arrayRanges.length == 1;
}
