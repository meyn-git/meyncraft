import 'package:meyncraft/meyncraft/source/sysmac/event/event.service.dart';
import 'package:meyncraft/meyncraft/source/sysmac/sysmac_project.infrastructure.dart';
import 'package:meyncraft/meyncraft/source/sysmac/variable/variable.service.dart';
import 'package:recase/recase.dart';
import 'data_type/data_type.domain.dart';
import 'node.domain.dart';

/// Represents a physical Sysmac project file,
/// which is actually a zip [Archive] containing [ArchiveFile]s
class SysmacProject {
  final SysmacProjectArchive archive;
  final Site site;
  final ElectricPanel electricPanel;
  final SysmacProjectVersion sysmacProjectVersion;

  final DataTypeTree dataTypeTree;
  final GlobalVariableService globalVariableService;
  final EventService eventService;

  SysmacProject({
    required this.archive,
    required this.site,
    required this.electricPanel,
    required this.sysmacProjectVersion,
    required this.dataTypeTree,
    required this.globalVariableService,
    required this.eventService,
  });
}

// OPTION: class Organization extends NameSpace

class Site extends LeafNode<Site> {
  /// Each known processing plant has a unique [number] (also called a Meyn layout number)
  /// e.g. 4321 = Maple Leaf - London - Canada
  final int number;

  /// [code] is the [number], minimum 4 digits long.
  final String code;

  // OPTION: final String city;
  // OPTION: final String country;

  Site(this.number)
    : code = _withLeadingZeros(number, minNumberOfDigits: 4),
      super(_withLeadingZeros(number, minNumberOfDigits: 4));

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
}

class ElectricPanel extends LeafNode<ElectricPanel> {
  /// Each electric panel within a site has a unique [number]
  /// In this case it is the electric panel number that contains the PLC.
  /// e.g. 6 = Evisceration line (at site 4321 = Maple Leaf - London - Canada)
  final int number;

  /// [code] is DE + the [number], minimum 2 digits long.
  /// e.g. DE06 = Evisceration line (at site 4321 = Maple Leaf - London - Canada)
  final String code;

  ElectricPanel({required this.number, required String name})
    : code = 'DE${_withLeadingZeros(number, minNumberOfDigits: 2)}',
      super(name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is ElectricPanel &&
          runtimeType == other.runtimeType &&
          number == other.number &&
          name == other.name;

  @override
  int get hashCode => super.hashCode ^ number.hashCode ^ name.hashCode;

  @override
  String toString() {
    return 'ElectricPanel{number: $number, code: $code, name: $name}';
  }
}

String _withLeadingZeros(int number, {required int minNumberOfDigits}) {
  int leadingZeros = number.toString().length < minNumberOfDigits
      ? minNumberOfDigits - number.toString().length
      : 0;
  return '0' * leadingZeros + number.toString();
}

class SysmacProjectVersion extends LeafNode<SysmacProjectVersion> {
  final int standardVersion;
  final int customerVersion;
  final String notInstalledComment;

  SysmacProjectVersion({
    required this.standardVersion,
    required this.customerVersion,
    String? notInstalledComment,
  }) : notInstalledComment = notInstalledComment == null
           ? ''
           : notInstalledComment.sentenceCase,
       super('$standardVersion-$customerVersion-$notInstalledComment');

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
