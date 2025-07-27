import 'dart:io';

import 'package:petitparser/petitparser.dart';
import 'package:recase/recase.dart';

class SysmacProjectDetails {
  final File projectFile;
  final String? site;
  final String? electricPanel;
  final String? plcName;
  final SysmacProjectVersion? version;

  SysmacProjectDetails({
    required this.projectFile,
    required this.site,
    required this.electricPanel,
    required this.plcName,
    required this.version,
  });

  bool get isComplete =>
      site != null &&
      electricPanel != null &&
      plcName != null &&
      version != null;
}

class Site {
  /// Each known processing plant has a unique [number] (also called a Meyn layout number)
  /// e.g. 4321 = Maple Leaf - London - Canada
  final int number;

  /// [code] is the [number], minimum 4 digits long.
  final String code;

  // OPTION: final String city;
  // OPTION: final String country;

  Site(this.number) : code = number.toString().padLeft(4, '0');

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

  static final Parser<Site> parser = digit()
      .repeat(4)
      .flatten()
      .trim()
      .map((v) => Site(int.parse(v)));
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
      (stringIgnoreCase('de') & (digit().repeat(1)).flatten()).map(
        (values) => ElectricPanel(number: int.parse(values[1])),
      );
}

class PlcName {
  final String name;

  //TODO add dash but not end with dash and not consume version
  static final Parser<PlcName> parser = (letter().plus() & digit().star())
      .plus()
      .flatten()
      .map((v) => PlcName(v));

  PlcName(this.name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is PlcName &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => super.hashCode ^ name.hashCode;

  @override
  String toString() => name;
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
              char('-') &
              (letter() &
                      (letter() | digit() | char('-') | char('_').star())
                          .flatten())
                  .optional())
          .map(
            (values) => SysmacProjectVersion(
              standardVersion: values[0],
              customerVersion: values[2],
              installComment: values[4],
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
