import 'package:meyncraft/meyncraft/source/sysmac/identity/identity.domain.dart';
import 'package:petitparser/petitparser.dart';

/// Each component has a [ComponentCode]:
/// * Each [ComponentCode] is unique within a Site (=processing plant)
/// * Each component has a label with the [ComponentCode] so that is can be identified.
/// * Each [ComponentCode] has a reference to the electrical diagram
/// * Each [ComponentCode] has  the following format:
///   e.g.: 4321.DE06.100U3.1 (= some PLC card)
///   * 4321=[site] (optional)
///   * DE06=[electricPanel] (optional)
///   * 100=[pageNumber]
///   * U=[letters]
///   * 3.1=[columnNumber]
class ComponentCode {
  final Site? site;
  final ElectricPanel? electricPanel;

  /// page number of the electrical diagram
  final int pageNumber;

  /// Several letter to indicate the type of component, e.g.:
  /// * B = Optical coupler
  /// * E = 230V Light
  /// * F = Fuse
  /// * H = Acoustic/ light signal
  /// * JB = Junction box
  /// * K = Relay
  /// * M = Motor
  /// * Q = Overload protection
  /// * R = Resistor
  /// * S = Switch
  /// * T = Transformer
  /// * U = Controller
  /// * V = Diode
  /// * W = Wire/cable
  /// * X = Connection terminal
  /// * Y = Valve
  final String letters;
  final ColumNumber columnNumber;

  ComponentCode({
    required this.site,
    required this.electricPanel,
    required this.pageNumber,
    required String letters,
    required this.columnNumber,
  }) : letters = letters.toUpperCase();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComponentCode &&
          runtimeType == other.runtimeType &&
          site == other.site &&
          electricPanel == other.electricPanel &&
          pageNumber == other.pageNumber &&
          letters == other.letters &&
          columnNumber == other.columnNumber;

  @override
  int get hashCode =>
      site.hashCode ^
      electricPanel.hashCode ^
      pageNumber.hashCode ^
      letters.hashCode ^
      columnNumber.hashCode;

  @override
  String toString() => _code;

  late final String _code = createCode();

  String createCode() {
    var code = StringBuffer();
    if (site != null) {
      code.write('${site!.code}.');
    }
    if (electricPanel != null) {
      code.write('${electricPanel!.code}.');
    }
    code.write('$pageNumber$letters$columnNumber');
    return code.toString();
  }
}

final Parser<int> _pageNumberParser = digit().plus().flatten().map(int.parse);

final Parser<String> _lettersParser = letter()
    .repeat(1, 4)
    .flatten()
    .map((String value) => value.toUpperCase());

final Parser<ComponentCode> componentCodeParser =
    ((Site.numberParser & string('.')).optional() &
            (ElectricPanel.parser & string('.')).optional() &
            _pageNumberParser &
            _lettersParser &
            ColumNumber.parser)
        .map(
          (values) => ComponentCode(
            site: values[0] is int ? Site(number: values[0]) : null,
            electricPanel: values[1] is ElectricPanel ? values[1] : null,
            pageNumber: values[2],
            letters: values[3],
            columnNumber: values[4] as ColumNumber,
          ),
        );

/// Refers to the column number of the electrical diagram e.g.:
/// * 3 = column 3
/// * 4.1 = column 4, most left component
class ColumNumber {
  final double value;

  late final String code = value.toString().replaceFirst('.0', '');

  static final parser = (pattern('1-8') & (char('.') & digit()).optional())
      .flatten()
      .map((v) => ColumNumber(double.parse(v)));

  ColumNumber(this.value);

  @override
  String toString() => code;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColumNumber &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}
