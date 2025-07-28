import 'dart:io';

import 'package:collection/collection.dart';
import 'package:meyncraft/meyncraft/logger/logger.infrastructure.dart';
import 'package:meyncraft/meyncraft/source/sysmac/identity/identity.domain.dart';
import 'package:petitparser/petitparser.dart';

SysmacProjectIdentity createIdentity(File sysmacProjectFile) {
  var path = sysmacProjectFile.parent.path;
  var site = parseSysmacFilePath(path);

  var fileName = sysmacProjectFile.uri.pathSegments.last;
  var parseResults = _parseSysmacProjectFilePath(fileName);
  int? siteNrFromFileName = parseResults.firstWhereOrNull((v) => v is int);
  if (siteNrFromFileName != null &&
      (site == null || site.number != siteNrFromFileName)) {
    site = Site(number: siteNrFromFileName);
  }
  var electricPanel = parseResults.firstWhereOrNull((v) => v is ElectricPanel);
  var plcName = parseResults.firstWhereOrNull((v) => v is String && v != '-');
  var version = parseResults.firstWhereOrNull((v) => v is SysmacProjectVersion);
  var identity = SysmacProjectIdentity(
    projectFile: sysmacProjectFile,
    site: site,
    electricPanel: electricPanel,
    plcName: plcName,
    version: version,
  );
  var missingValues = identity.missingValues();
  if (missingValues.isNotEmpty) {
    logger.warning(
      '${missingValues.join(', ')} ${missingValues.length == 1 ? 'is' : 'are'} '
      'missing in file name: "${sysmacProjectFile.uri.pathSegments.last}". '
      'Expected it to be something like 4321DE06-EviscerationLine1-019-002.smc2',
    );
  }

  return identity;
}

/// Try to find [Site] information in the file path
/// As projects are stored in the BESTURINGSTECHNIEK folder:
/// 4321-Maple Leaf-London-Canada
Site? parseSysmacFilePath(String path) {
  var matches = _sysmacProjectFilePathParser.allMatches(path);
  if (matches.isEmpty) {
    return null;
  }
  return matches.first;
}

/// Try to find [Site], [ElectricPanel], plcName and [SysmacProjectVersion]
/// in the file name e.g.:
/// 4321-DE06-Eviseration Line1-019-003
List _parseSysmacProjectFilePath(String fileName) {
  var result = _sysmacProjectFileNameParser.parse(fileName);
  if (result is Failure) {
    return [];
  }
  return result.value;
}

// final ChoiceParser _pathSeparatorParser = char('\\') | char('/');

// final Parser<String?> _pathParser =
//     (any().starGreedy(_pathSeparatorParser) & _pathSeparatorParser)
//         .flatten()
//         .optional();

final Parser _dashParser = char('-');

final Parser<String> nameParser =
    (letter().times(1) & (letter() | digit() | char('_') | char(' ')).star())
        .flatten()
        .trim();

// final Parser<String?> _extensionParser = stringIgnoreCase('.smc2');

/// Tries to get [Site] information from the sysmac file path
final Parser<Site> _sysmacProjectFilePathParser =
    (Site.numberParser &
            _dashParser.optional() &
            nameParser.optional() &
            _dashParser.optional() &
            nameParser.optional() &
            _dashParser.optional() &
            nameParser.optional())
        .map(
          (values) => Site(
            number: values[0],
            companyName: values.length >= 3 ? values[2] : null,
            city: values.length >= 5 ? values[4] : null,
            country: values.length >= 7 ? values[6] : null,
          ),
        );

/// Tries to get all identity information the sysmac file name
final Parser _sysmacProjectFileNameParser =
    Site.numberParser.optional() &
    _dashParser.optional() &
    ElectricPanel.parser.optional() &
    _dashParser.optional() &
    nameParser.optional() &
    _dashParser.optional() &
    SysmacProjectVersion.parser.optional();
