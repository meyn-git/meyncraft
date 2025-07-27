import 'dart:io';

import 'package:collection/collection.dart';
import 'package:meyncraft/meyncraft/logger/logger.infrastructure.dart';
import 'package:meyncraft/meyncraft/source/sysmac/detail/detail.domain.dart';
import 'package:petitparser/petitparser.dart';

SysmacProjectDetails createDetails(File sysmacProjectFile) {
  var parseResult = _parseFileName(sysmacProjectFile.path);
  var site = parseResult.firstWhereOrNull((v) => v is Site);
  var electricPanel = parseResult.firstWhereOrNull((v) => v is ElectricPanel);
  var plcName = parseResult.firstWhereOrNull((v) => v is PlcName);
  var version = parseResult.firstWhereOrNull((v) => v is SysmacProjectVersion);
  return SysmacProjectDetails(
    projectFile: sysmacProjectFile,
    site: site,
    electricPanel: electricPanel,
    plcName: plcName,
    version: version,
  );
}

List<dynamic> _parseFileName(String sysmacProjectFilepath) {
  var result = _fileNameParser.parse(sysmacProjectFilepath);
  if (result is Failure) {
    logger.warning(
      'Invalid file format: "$sysmacProjectFilepath". Expected it to be something like 4321DE06-Evisceration1-001-005-toBeInstalled.smc2',
    );
  }
  return result.value;
}

final ChoiceParser _pathSeparatorParser = char('\\') | char('/');

final Parser<String?> _pathParser =
    (any().starGreedy(_pathSeparatorParser) & _pathSeparatorParser)
        .flatten()
        .optional();

final Parser _dashParser = char('-');

final Parser<String?> _extensionParser = stringIgnoreCase('.smc2').end();

final _fileNameParser =
    _pathParser.optional() &
    Site.parser.optional() &
    _dashParser.optional() &
    ElectricPanel.parser.optional() &
    _dashParser.optional() &
    PlcName.parser.optional() &
    _dashParser.optional() &
    SysmacProjectVersion.parser.optional() &
    _extensionParser.optional() &
    endOfInput();
