import 'dart:io';

import 'package:collection/collection.dart';
import 'package:meyncraft/meyncraft/logger/logger.infrastructure.dart';
import 'package:meyncraft/meyncraft/source/sysmac/detail/detail.domain.dart';
import 'package:petitparser/petitparser.dart';

SysmacProjectDetails createDetails(File sysmacProjectFile) {
  var parseResults = _parseSysmacProjectFilePath(sysmacProjectFile.path);
  var site = parseResults.firstWhereOrNull((v) => v is Site)?.code;
  var electricPanel = parseResults
      .firstWhereOrNull((v) => v is ElectricPanel)
      ?.code;
  var plcName = parseResults.firstWhereOrNull((v) => v is PlcName)?.name;
  var version = parseResults.firstWhereOrNull((v) => v is SysmacProjectVersion);
  var details = SysmacProjectDetails(
    projectFile: sysmacProjectFile,
    site: site,
    electricPanel: electricPanel,
    plcName: plcName,
    version: version,
  );
  if (!details.isComplete) {
    logger.warning(
      'Invalid file format: "${sysmacProjectFile.path}". Expected it to be something like 4321DE06-Evisceration1-001-005-toBeInstalled.smc2',
    );
  }
  return details;
}

List _parseSysmacProjectFilePath(String path) {
  var result = _sysmacProjectFilePathParser.parse(path);
  if (result is Failure) {
    return [];
  }
  return result.value;
}

final ChoiceParser _pathSeparatorParser = char('\\') | char('/');

final Parser<String?> _pathParser =
    (any().starGreedy(_pathSeparatorParser) & _pathSeparatorParser)
        .flatten()
        .optional();

final Parser _dashParser = char('-');

final Parser<String?> _extensionParser = stringIgnoreCase('.smc2');

final _sysmacProjectFilePathParser =
    _pathParser.optional() &
    Site.parser.optional() &
    _dashParser.optional() &
    ElectricPanel.parser.optional() &
    _dashParser.optional() &
    PlcName.parser.optional() &
    _dashParser.optional() &
    SysmacProjectVersion.parser.optional() &
    _extensionParser;
