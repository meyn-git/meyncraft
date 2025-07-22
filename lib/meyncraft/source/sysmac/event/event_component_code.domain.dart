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

class ComponentCodeParser extends DelegateParser {
  static final _pageNumberParser = digit().plus().flatten().map(int.parse);

  static final _lettersParser = letter()
      .repeat(1, 4)
      .flatten()
      .map((String value) => value.toUpperCase());

  ComponentCodeParser()
    : super(
        ((Site.parser & string('.')).optional() &
                (ElectricPanel.parser & string('.')).optional() &
                _pageNumberParser &
                _lettersParser &
                ColumNumber.parser)
            .map(
              (values) => ComponentCode(
                site: values[0] is Site ? values[0] : null,
                electricPanel: values[1] is ElectricPanel ? values[1] : null,
                pageNumber: values[2],
                letters: values[3],
                columnNumber: values[4] as ColumNumber,
              ),
            ),
      );

  @override
  Parser copy() => ComponentCodeParser();

  @override
  Result parseOn(Context context) => delegate.parseOn(context);
}

/// Each known processing plant has a unique [number] (also called a Meyn layout number)
/// e.g. 4321 = Maple Leaf - London - Canada
class Site {
  final int number;

  /// [code] is the [number], minimum 4 digits long.
  late final String code = number.toString().padLeft(4, '0');

  static final parser = digit()
      .repeat(4)
      .flatten()
      .map((String value) => Site(int.parse(value)));

  // OPTION: final String name;
  // OPTION: final String city;
  // OPTION: final String country;

  Site(this.number);

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
  String toString() => code;
}

/// Each electric panel within a site has a unique [number] starting with DE.
/// In this case it is the electric panel that contains the PLC.
/// e.g. DE06 = Evisceration line (at site 4321 = Maple Leaf - London - Canada)
class ElectricPanel {
  final int number;

  /// [code] is DE + the [number], minimum 2 digits long.
  /// e.g. DE06 = Evisceration line (at site 4321 = Maple Leaf - London - Canada)
  late final String code = 'DE${number.toString().padLeft(2)}';

  static final parser =
      (string('DE') &
              (digit().plus().flatten().map(
                (String value) => int.parse(value),
              )))
          .map((values) => ElectricPanel(values[1]));

  ElectricPanel(this.number);

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
  String toString() => code;
}

/// Refers to the column number of the electrical diagram e.g.:
/// * 3 = column 3
/// * 4.1 = column 4, 1st component
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
