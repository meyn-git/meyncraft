import 'dart:io';

import 'package:meyncraft/meyncraft/source/sysmac/identity/identity.service.dart';
import 'package:petitparser/petitparser.dart';
import 'package:recase/recase.dart';

/// All information needed to identify the sysmac project
/// It answers where and what
class SysmacProjectIdentity {
  final File projectFile;
  final Site? site;
  final ElectricPanel? electricPanel;
  final String? plcName;
  final SysmacProjectVersion? version;

  SysmacProjectIdentity({
    required this.projectFile,
    required this.site,
    required this.electricPanel,
    required this.plcName,
    required this.version,
  });

  List<String> missingValues() => [
    if (site == null) 'site (e.g. 4321)',
    if (electricPanel == null) 'electricalPanel (e.g. DE06)',
    if (plcName == null) 'plcName (e.g. EviscerationLine1)',
    if (version == null) 'version (e.g. 019-002 or 019-002-toBeInstalled)',
  ];
}

class Site {
  /// Each known processing plant has a unique [number] (also called a Meyn layout number)
  /// e.g. 4321 = Maple Leaf - London - Canada
  final int number;
  final String? companyName;
  final String? city;
  final String? country;

  /// [code] is the [number], minimum 4 digits long.
  final String code;

  // OPTION: final String city;
  // OPTION: final String country;

  Site({required this.number, this.companyName, this.city, this.country})
    : code = number.toString().padLeft(4, '0');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is Site &&
          runtimeType == other.runtimeType &&
          number == other.number;

  @override
  int get hashCode => super.hashCode ^ number.hashCode;

  @override
  String toString() {
    return 'Site{number: $number, code: $code}';
  }

  static final Parser<int> numberParser = digit()
      .repeat(4)
      .flatten()
      .trim()
      .map(int.parse);
}

class ElectricPanel {
  /// Each electric panel within a site has a unique [number]
  /// In this case it is the electric panel number that contains the PLC.
  /// e.g. 6 = Evisceration line (at site 4321 = Maple Leaf - London - Canada)
  final int number;

  /// [code] is DE + the [number], minimum 2 digits long.
  /// e.g. DE06 = Evisceration line (at site 4321 = Maple Leaf - London - Canada)
  final String code;

  ElectricPanel({required this.number})
    : code = 'DE${number.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is ElectricPanel &&
          runtimeType == other.runtimeType &&
          number == other.number;

  @override
  int get hashCode => super.hashCode ^ number.hashCode;

  @override
  String toString() {
    return 'ElectricPanel{number: $number, code: $code}';
  }

  static final Parser<ElectricPanel> parser =
      (stringIgnoreCase('de') & (digit().plus()).flatten()).map(
        (values) => ElectricPanel(number: int.parse(values[1])),
      );
}

class SysmacProjectVersion {
  final int standardVersion;
  final int customerVersion;
  final String notInstalledComment;

  static final Parser<int> _intParser = digit().plus().flatten().map(int.parse);
  static final Parser<SysmacProjectVersion> parser =
      (_intParser &
              char('-') &
              _intParser &
              ((char('-') & nameParser).map(
                ((values) => values[1]),
              )).optional())
          .map(
            (values) => SysmacProjectVersion(
              standardVersion: values[0],
              customerVersion: values[2],
              installComment: values[3],
            ),
          );

  SysmacProjectVersion({
    required this.standardVersion,
    required this.customerVersion,

    /// a comment for any program that is not installed. e.g.:
    /// * toBeInstalled
    /// * toBeCompleted
    /// * doNotInstall
    String? installComment,
  }) : notInstalledComment = installComment == null
           ? ''
           : installComment.sentenceCase;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is SysmacProjectVersion &&
          runtimeType == other.runtimeType &&
          standardVersion == other.standardVersion &&
          customerVersion == other.customerVersion &&
          notInstalledComment == other.notInstalledComment;

  @override
  int get hashCode =>
      super.hashCode ^
      standardVersion.hashCode ^
      customerVersion.hashCode ^
      notInstalledComment.hashCode;

  @override
  String toString() {
    return 'SysmacProjectVersion{standardVersion: $standardVersion, customerVersion: $customerVersion, notInstalledComment: $notInstalledComment}';
  }
}
