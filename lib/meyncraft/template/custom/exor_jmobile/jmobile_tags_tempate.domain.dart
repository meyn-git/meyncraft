import 'dart:async';
import 'dart:io';

import 'package:meyncraft/meyncraft/presentation/markdown_tab.presentation.dart';
import 'package:meyncraft/meyncraft/template/custom/exor_jmobile/exor_data_type.domain.dart';
import 'package:meyncraft/meyncraft/template/generate/generator.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/iec61131_10/iec61131_10.dart';
import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/base_type/base_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/data_type/data_type.domain.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/meyn_sysmac_project.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/variable/variable.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/node.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.domain.dart';
import 'package:meyncraft/meyncraft/template/template.domain.dart';
import 'package:xml/xml.dart';

class JMobileTagsTemplate implements Template {
  @override
  final String name = 'JMobileTags';
  @override
  final String description = 'Creates JMobile tags from a Sysmac project file.';

  @override
  final String? gitRepository = null;

  @override
  final String? documentation = null;

  @override
  final List<Parameter> parameters = [sysmacProjectFileParameter];

  @override
  final List<Generator> generators = [JMobileTagsGenerator()];

  @override
  List<String> tags = ['jmobile', 'exor', 'sysmac', 'tags'];
}

class JMobileTagsGenerator implements Generator {
  @override
  String get source => 'Dart code: $runtimeType';

  @override
  final String outputPath =
      '{{removeFileExtension(sysmacProjectFilePath)}}-JMobile-Tags.xml';

  @override
  final String? outputInstructions =
      'You can import the generated tag file in JMobile:\n'
      '* Open an existing JMobile project\n'
      '* In the "Project view" double click on Configuration \\ Tags\n'
      '* Select the "Ethernet/IP CIP prot1 Model Omron" form the existing tag list\n'
      '* Click on the "import dictionary button" in the toolbar\n'
      '* Select the "Tag editor exported xml" row from the import dialog and click ok\n'
      '* Select the generated file as the "watched dictionary file"\n'
      '* Click on "Ok"\n'
      '* In the "Project view" remove old dictionaries (but not dictionaries that contain internal tags)\n'
      '* Note that new tags in dictionaries will need to by added to the tags by finding them in the "Tags" view'
      ', selecting them and "Adding to tags" with a right click\n'
      '* Note that pages that use tags that no longer exist need to be fixed. '
      'These can be found with the project validator: Menu \\ Run \\ Run Project Validator. '
      'When these tags are no longer used you can remove them from the tags.\n';

  @override
  Future<DynamicMarkdownTabContent> generate(
    Template template,
    Map<String, dynamic> parameterValues,
    DynamicMarkdownTabContent outputReport,
  ) async {
    var sysmacProjectFilePath =
        parameterValues[sysmacProjectFileParameter.name];
    if (sysmacProjectFilePath == null) {
      throw Exception('Missing parameter: ${sysmacProjectFileParameter.name}');
    }
    var sysmacProject = await MeynSysmacProject.loadFromFile(
      File(sysmacProjectFilePath),
    );
    var generatedFiles = <File>[];
    try {
      generatedFiles = await writeJMobileTagsFile(sysmacProject, outputReport);
    } on Exception catch (e, stackTrace) {
      var errorLink = GenerationErrorLink(
        template: template,
        generator: this,
        message: 'Error generating JMobile tags file',
        stackTrace: stackTrace,
      );
      outputReport.append('* ${errorLink.toMarkdown()}');
    }
    if (generatedFiles.isEmpty) {
      outputReport.append('* No files generated');
    }
    outputReport.append(
      '* Generated ${generatedFiles.length} files. [Click here for instructions on how to use the generated files.](meyncraft://test)',
    );
    return outputReport;
  }

  /// creates an xml file with [ExorTag]s generated from a Sysmac project file
  /// to be imported by JMobile
  Future<List<File>> writeJMobileTagsFile(
    MeynSysmacProject sysmacProject,
    DynamicMarkdownTabContent outputReport,
  ) async {
    var tags = createTags(sysmacProject);
    outputReport.append('* Found ${tags.length} Exor-JMobile tags\n');
    String formattedXml = createFormattedTagsXml(tags);
    var outputFile = createOutputFile(
      sysmacProject,
      '-JMobileTags.xml',
    ); //TODO use target
    await outputFile.create();
    await outputFile.writeAsString(formattedXml);
    outputReport.append(
      '* Created file: [${outputFile.path}](${outputFile.uri})\n',
    );
    return [outputFile];
  }
}

class GenerationErrorLink {
  final Template template;
  final Generator generator;
  final String message;
  final StackTrace stackTrace;

  GenerationErrorLink({
    required this.template,
    required this.generator,
    required this.message,
    required this.stackTrace,
  });

  String toMarkdown() =>
      '[❌ **FAILED**: $message](meyncraft://generationerror?$parameters)';

  String get parameters => [
    'template=${Uri.encodeComponent(template.name)}',
    'source=${Uri.encodeComponent(generator.source)}',
    'message=${Uri.encodeComponent(message)})'
        'stackTrace=${Uri.encodeComponent(stackTrace.toString())}',
  ].join('&');
}

/// creates an xml file with [ExorTag]s generated from a Sysmac project file
/// to be imported by JMobile
@Deprecated('Use the JMobileTagsTemplate instead')
Future<void> writeJMobileTagsFile(MeynSysmacProject sysmacProject) async {
  var tags = createTags(sysmacProject);
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

String createFormattedTagsXml(Iterable<ExorTag> tags) {
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

Iterable<ExorTag> createTags(
  SysmacProject sysmacProject, {
  List<bool Function(String namePath)> skipRules = const [
    skipMeynConnect,
    skipVetInsp,
  ],
}) {
  var variables = sysmacProject.globalVariables;
  var publicVariables = variables
      .where((v) => v.networkPublish == NetworkPublish.publicationOnly)
      .toList();

  var tagPaths = publicVariables
      .findAllNodePaths<NodePathWithIndexes>(tagPathFinder())
      .where(
        (tagPath) => !skipRules.any(
          (skipRule) => skipRule(tagPath.toNamePath().join('.')),
        ),
      );
  var exorTags = tagPaths
      .map((tagPath) => _createExorTag(tagPath))
      .whereType<ExorTag>();
  return exorTags;
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

/// recursive function to find all [NodePathWithIndexes] within a node that represent an [ExorTag]
NodePathsFinder<NodePathWithIndexes> tagPathFinder({
  NodePathWithIndexes precedingPath = const NodePathWithIndexes.empty(),
}) => (Node node) {
  var tagPaths = _createTagPaths(precedingPath, node);

  if (_isLeafNode(node)) {
    if (_isExorTag(node)) {
      return tagPaths;
    } else {
      return [];
    }
  }

  var tagPathsFromChildren = <NodePathWithIndexes>[];
  for (var eventPath in tagPaths) {
    var finder = tagPathFinder(precedingPath: eventPath);
    for (var child in node.children) {
      var eventPathsFromChild = finder(child as Node);
      if (eventPathsFromChild.isNotEmpty) {
        tagPathsFromChildren.addAll(eventPathsFromChild);
      }
    }
  }
  return tagPathsFromChildren;
};

bool _isExorTag(Node node) =>
    node is! EnumerationMember && node is! UnknownBaseType;

bool _isLeafNode(Node node) => node.children.isEmpty || _isEnumeration(node);

bool _isEnumeration(Node node) =>
    (node is DataTypeMember) && baseTypeLeaf(node.baseType) is Enumeration;

List<NodePathWithIndexes> _createTagPaths(
  NodePathWithIndexes precedingPath,
  Node<Node<dynamic>> node,
) {
  var indexValues = _createIndexValues(node);
  if (indexValues.isEmpty) {
    return [
      NodePathWithIndexes(
        [...precedingPath, node],
        [...precedingPath.arrayIndexes, null],
      ),
    ];
  } else {
    return indexValues
        .map(
          (arrayIndexValue) => NodePathWithIndexes(
            [...precedingPath, node],
            [...precedingPath.arrayIndexes, arrayIndexValue],
          ),
        )
        .toList();
  }
}

List<String> _createIndexValues(Node<Node<dynamic>> node) {
  if (node is! DataTypeMember) {
    return [];
  }
  var baseType = node.baseType;
  if (baseType is ArrayType) {
    return baseType.arrayRanges.toStringList();
  } else {
    return [];
  }
}

bool _isSingleArrayRootNode(NodePathWithIndexes tagPath) {
  if (tagPath.isEmpty || tagPath.length > 1) {
    return false;
  }
  if (tagPath.first is! BaseTypeOwner) {
    return false;
  }
  var baseType = (tagPath.first as BaseTypeOwner).baseType;
  return baseType is ArrayType && baseType.arrayRanges.length == 1;
}

ExorTag? _createExorTag(NodePathWithIndexes tagPath) {
  if (tagPath.last is! BaseTypeOwner) {
    return null;
  }

  String namePath = tagPath.toNamePathWithArrayIndexes().join('/');
  var baseType = (tagPath.last as BaseTypeOwner).baseType;

  if (_isSingleArrayRootNode(tagPath)) {
    // an exception on the rule to reduce the number of tags:
    return _createExorTagForOneDimensionalArray(
      namePath,
      baseType as ArrayType,
    );
  }

  var nestedBaseType = baseTypeLeaf(baseType);
  var exorDataType = ExorDataType.findCompatibleType(nestedBaseType);
  if (exorDataType == null) {
    logger.warning(
      'No compatible Exor data type found for Omron base type: $namePath',
    );
    return null;
  }
  return ExorTag(name: namePath, exorDataType: exorDataType);
}

//FIX ME!!!!
// ExorDataType? findCompatibleTypeBugFix(BaseType nestedBaseType) {
// return (nestedBaseType.toString() ==
//         'UnknownBaseType(ARRAY[1..5] OF STRING[256])')
//     ? ExorOneDimensionalArray(
//         ExorString.withSize(256),
//         ArrayRange.minMax(1, 5),
//       )
//     : ExorDataType.findCompatibleType(nestedBaseType);
// }

ExorTag? _createExorTagForOneDimensionalArray(
  String namePath,
  ArrayType arrayType,
) {
  var compatibleType = ExorDataType.findCompatibleType(baseTypeLeaf(arrayType));
  if (compatibleType == null) {
    logger.warning(
      'No compatible Exor data type found for Omron base type: $namePath',
    );
    return null;
  }
  return ExorTag(
    name: namePath,
    exorDataType: ExorOneDimensionalArray(
      compatibleType,
      arrayType.arrayRanges.first,
    ),
  );
}
