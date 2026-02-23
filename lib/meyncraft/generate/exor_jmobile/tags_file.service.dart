import 'dart:io';

import 'package:meyncraft/meyncraft/generate/exor_jmobile/data_type.dart';
import 'package:meyncraft/meyncraft/sysmac/iec61131_10/iec61131_10.dart';
import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/base_type/base_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/data_type/data_type.domain.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/meyn_sysmac_project.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/variable/variable.domain.dart';
import 'package:xml/xml.dart';

/// creates an xml file with [ExorTag]s generated from a Sysmac project file
/// to be imported by JMobile
Future<void> writeJMobileTagsFile(MeynSysmacProject sysmacProject) async {
  var variables = sysmacProject.globalVariables;
  List<ExorTag> tags = createTags(variables);
  logger.info('Found ${tags.length} Exor-JMobile tags');
  String formattedXml = createFormattedTagsXml(tags);
  var outputFile = createOutputFile(sysmacProject, '-JMobileTags.xml');
  await outputFile.create();
  await outputFile.writeAsString(formattedXml);
  logger.info('Created: ${outputFile.path})');
  logger.info('     You can import the tags in JMobile:');
  logger.info('     * Open an existing JMobile project');
  logger.info(
    '     * Open the tags window from the left menu Configuration \\ Tags',
  );
  logger.info(
    '     * Select the "Ethernet/IP CIP prot1 Model Omron" form the existing tag list',
  );
  logger.info('     * Click on the "import dictionary button" in the toolbar');
  logger.info(
    '     * Select the "Tag editor exported xml" row from the import dialog and click ok',
  );
  logger.info('     * Select the generated ${outputFile.path} file');
}

File createOutputFile(MeynSysmacProject sysmacProject, String suffix) {
  var sysmacFile = sysmacProject.identity.projectFile;
  var directory = sysmacFile.parent.path;
  var filename = sysmacFile.uri.pathSegments.last;
  var nameWithoutExtension = filename.split('.').first;
  var outputPath =
      '$directory${Platform.pathSeparator}$nameWithoutExtension$suffix';
  var outputFile = File(outputPath);
  return outputFile;
}

String createFormattedTagsXml(List<ExorTag> tags) {
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

List<ExorTag> createTags(List<Variable> variables) {
  var publicVariables = variables
      .where((v) => v.networkPublish == NetworkPublish.publicationOnly)
      .toList();
  var tags = <ExorTag>[];
  for (var variable in publicVariables) {
    var tagNode = ExorTagNode.fromVariable(variable);
    var createdTags = tagNode.createTags(
      skipRules: [skipMeynConnect, skipVetInsp],
    );
    tags.addAll(createdTags);
  }
  return tags;
}

bool skipMeynConnect(String namePath) => namePath.startsWith(RegExp(r'L\d_'));
bool skipVetInsp(String namePath) => namePath.contains('VET');

/// Represents a tag (reference to some variable in the PLC) for a Exor HMI touch screen
/// So that it can be imported by JMobile (IDE of Exor HMI)
class ExorTag {
  final ExorDataType exorDataType;
  final String name;
  final String comment;
  late final String tagLocator = 'Ethernet/IP CIP:prot1:uid0:$name';

  ExorTag({required this.name, this.comment = '', required this.exorDataType});

  @override
  String toString() => 'ExorTag(name: $name, ExorDataType: $exorDataType)';

  XmlElement toXml() => XmlElement(XmlName('tag'), [], [
    XmlElement(XmlName('name'), [], [XmlText(name)]),
    XmlElement(XmlName('group')),
    createResourceLocator(),
    XmlElement(XmlName('encoding'), [], []),
    XmlElement(XmlName('refreshTime'), [], [XmlText('500')]),
    XmlElement(XmlName('accessMode'), [], [XmlText('READ-WRITE')]),
    XmlElement(XmlName('active'), [], [XmlText('false')]),
    XmlElement(XmlName('TAGLOCATOR'), [], [XmlText(tagLocator)]),
    XmlElement(XmlName('comment'), [], [XmlText(comment)]),
    createSimulator(),
    createScaling(),
    createDecimalDigits(),
    XmlElement(XmlName('castType'), [], [XmlText(exorDataType.castType)]),
    XmlElement(XmlName('default'), [], []),
    XmlElement(XmlName('min'), [], [XmlText(exorDataType.min)]),
    XmlElement(XmlName('max'), [], [XmlText(exorDataType.max)]),
    XmlElement(XmlName('statesText'), [], []),
  ]);

  XmlElement createResourceLocator() =>
      XmlElement(XmlName('resourceLocator'), [], [
        XmlElement(XmlName('protocolName'), [], [XmlText('ETIP')]),
        XmlElement(XmlName('slave_id'), [], [XmlText('0')]),
        XmlElement(XmlName('memory_type'), [], [
          XmlText(exorDataType.iecTypeName),
        ]),
        XmlElement(XmlName('arrayindex'), [], [XmlText('0')]),
        XmlElement(XmlName('subindex'), [], []),
        XmlElement(XmlName('data_type'), [], [
          XmlText(exorDataType.exorTypeName),
        ]),
        XmlElement(XmlName('arraysize'), [], [XmlText(exorDataType.arraySize)]),
        XmlElement(XmlName('conversion'), [], []),
        XmlElement(XmlName('folder_name'), [], []),
        XmlElement(XmlName('structure_name'), [], []),
        XmlElement(XmlName('tag_name'), [], [XmlText(name)]),
      ]);

  XmlElement createSimulator() => XmlElement(XmlName('simulator'), [], [
    XmlElement(XmlName('DataSimulator'), [], [XmlText('Variables')]),
    XmlElement(XmlName('Amplitude'), [], []),
    XmlElement(XmlName('Simulator_offset'), [], []),
    XmlElement(XmlName('Period'), [], []),
  ]);

  XmlElement createScaling() => XmlElement(XmlName('scaling'), [], [
    XmlElement(XmlName('enableScaling'), [], [
      XmlText(exorDataType.enableScaling.toString().toLowerCase()),
    ]),
    XmlElement(XmlName('scalingType'), [], [XmlText('byFormula')]),
    XmlElement(XmlName('enableLimits'), [], [XmlText('false')]),
    createScalingFactors(),
    createScalingLimits(),
  ]);

  XmlElement createScalingFactors() => XmlElement(XmlName('factors'), [], [
    XmlElement(XmlName('s1'), [], [XmlText(exorDataType.s1)]),
    XmlElement(XmlName('s2'), [], [XmlText(exorDataType.s2)]),
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

///TODO investigate if we can use DataTypeBase.findPaths instead of using ExorTagNode.
class ExorTagNode {
  final String name;
  final String comment;
  final BaseType baseType;
  final List<ExorTagNode> children;

  ExorTagNode.fromVariable(Variable variable)
    : name = variable.name,
      comment = variable.comment,
      baseType = variable.baseType,
      children = createChildren(variable.baseType);

  ExorTagNode.fromDataTypeMember(DataTypeMember dataTypeMember)
    : name = dataTypeMember.name,
      comment = dataTypeMember.comment,
      baseType = dataTypeMember.baseType,
      children = createChildren(dataTypeMember.baseType);

  static List<ExorTagNode> createChildren(BaseType baseType) {
    var nestedBaseType = baseTypeLeaf(baseType);
    if (nestedBaseType is DataType) {
      return nestedBaseType.children
          .whereType<DataTypeMember>()
          .map(
            (dataTypeMember) => ExorTagNode.fromDataTypeMember(dataTypeMember),
          )
          .toList();
    }
    // baseType has no children
    return [];
  }

  static bool isNoTag(BaseType baseType) {
    var nestedBaseType = baseTypeLeaf(baseType);
    return nestedBaseType is EnumerationMember ||
        nestedBaseType is UnknownBaseType ||
        nestedBaseType is DataTypeMember;
  }

  List<ExorTag> createTags({
    String parentNamePath = '',
    List<bool Function(String namePath)> skipRules = const [],
  }) {
    String namePath = createNamePath(parentNamePath);
    if (isLeafNode) {
      if (isNoTag(baseType) || skipRules.any((rule) => rule(namePath))) {
        return [];
      }
      // an exception on the rule to reduce the number of tags:
      if (singleArrayRootNode(parentNamePath, baseType)) {
        return _createExorTagForOneDimensionalArray(namePath);
      }
      return _createExorTags(parentNamePath, namePath);
    } else {
      var tags = <ExorTag>[];
      var namePaths = createNamePaths(parentNamePath);
      for (var namePath in namePaths) {
        for (var child in children) {
          tags.addAll(
            child.createTags(parentNamePath: namePath, skipRules: skipRules),
          );
        }
      }
      return tags;
    }
  }

  List<ExorTag> _createExorTags(String parentNamePath, String namePath) {
    var namePaths = createNamePaths(parentNamePath);
    var nestedBaseType = baseTypeLeaf(baseType);
    var exorDataType = ExorDataType.findCompatibleType(nestedBaseType);
    if (exorDataType == null) {
      logger.warning(
        'No compatible Exor data type found for Omron base type: $namePath',
      );
      return [];
    }
    return namePaths
        .map((namePath) => ExorTag(name: namePath, exorDataType: exorDataType))
        .toList();
  }

  List<ExorTag> _createExorTagForOneDimensionalArray(String namePath) {
    var compatibleType = ExorDataType.findCompatibleType(
      (baseType as ArrayType).baseType,
    );
    if (compatibleType == null) {
      logger.warning(
        'No compatible Exor data type found for Omron base type: $namePath',
      );
      return [];
    }
    return [
      ExorTag(
        name: namePath,
        exorDataType: ExorOneDimensionalArray(
          compatibleType,
          (baseType as ArrayType).arrayRanges.first,
        ),
      ),
    ];
  }

  /// creates a name path of this node.
  /// returns a list with:
  /// * one path if there is no array.
  /// * or a path for each array value
  List<String> createNamePaths(String preceedingPath) {
    var path = createNamePath(preceedingPath);
    if (baseType is ArrayType) {
      var arrayIndexes = (baseType as ArrayType).arrayRanges.toStringList();
      return arrayIndexes.map((arrayValue) => path + arrayValue).toList();
    } else {
      return [path];
    }
  }

  /// creates a name path for this node without array values
  String createNamePath(String preceedingPath) =>
      preceedingPath.isEmpty ? name : [preceedingPath, name].join('/');

  /// an exception on the rule: to reduce the number of tags
  bool singleArrayRootNode(String preceedingPath, BaseType baseType) =>
      preceedingPath.isEmpty &&
      baseType is ArrayType &&
      baseType.arrayRanges.length == 1;

  bool get isLeafNode => children.isEmpty;
}
