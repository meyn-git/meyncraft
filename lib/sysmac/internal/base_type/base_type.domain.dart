import 'package:fluent_regex/fluent_regex.dart';
import 'package:map_converter/map_converter.dart';

import '../data_type/data_type.domain.dart';

/// Base for all IEC 61131-3 data types
///
/// Hierarchy:
/// * BaseType
///   * [UnknownBaseType]
///   * [BasicType]
///     * [ArrayType]
///     * [IecType]
///     * [VbType]
///   * [CustomType]
///     * [DataTypeBase]
///       * [NameSpace]
///       * [DataType]
///         * [DataTypeMember]
///         * [Structure]
///         * [Enumeration]
///         * [Union]
///   * [DataTypeReference]
/// See [https://www.myomron.com/index.php?action=kb&article=1628] for Omron's list of "Basic Data Types"
///
@MapConverter(
  generateOptions: GenerateOptions.toMap + GenerateOptions.schema,
  includeSubClasses: {
    ArrayType,
    IecType,
    VbType,
    DataTypeBase,
    DataTypeReference,
  },
)
abstract interface class BaseType {}

class UnknownBaseType extends BaseType {
  final String typeExpression;

  UnknownBaseType(this.typeExpression);

  @override
  String toString() => 'UnknownBaseType($typeExpression)';
}

/// Variables and some BaseTypes have a baseType
/// Note that [baseType] is not final because when it is an [UnknownBaseType]
/// it might need to be replaced with a  [DataTypeMember] in a later stage.
/// See [BaseTypeFactory.]
abstract interface class BaseTypeOwner {
  BaseType get baseType;
  set baseType(BaseType baseType);
}

/// Finds the last baseType in a baseType tree
BaseType baseTypeLeaf(BaseType baseType) {
  if (baseType is BaseTypeOwner) {
    /// recursively get last baseType in tree
    return baseTypeLeaf((baseType as BaseTypeOwner).baseType);
  } else {
    return baseType;
  }
}

/// All built‑in types supported by Sysmac Studio.
/// Omron explicitly lists these as “Basic Data Types.”
abstract interface class BasicType implements BaseType {}

/// Wraps a [BaseType] in an [ArrayType] with the given [arrayRanges]
@MapConverter(
  generateOptions: GenerateOptions.toMap + GenerateOptions.schema,
)
class ArrayType implements BasicType, BaseTypeOwner {
  @override
  BaseType baseType;
  final List<ArrayRange> arrayRanges;

  ArrayType({required this.baseType, required this.arrayRanges});

  @override
  String toString() {
    return 'ARRAY$arrayRanges OF $baseType';
  }
}

extension ArrayRanges on List<ArrayRange> {
  //ArrayRanges([super.arrayRanges = const <ArrayRange>[]]);

  /// e.g.
  /// if [ArrayRanges] represents [ArrayRange(min:2, max:3), ArrayRange(min:5, max:7)]
  /// then outputs: [[2,3], [5,6,7]]
  List<List<int>> toIntLists() => map(
    (range) => List.generate(range.max - range.min + 1, (i) => range.min + i),
  ).toList();

  /// e.g.
  /// if [ArrayRanges] represents [ArrayRange(min:2, max:3), ArrayRange(min:5, max:7)]
  /// then outputs: ['[2,5]','[2,6]','[2,7]','[3,5]','[3,6]','[3,7]']
  List<String> toStringList() {
    final valueLists = toIntLists();
    final combinations = _cartesianProduct(valueLists);
    return combinations.map((combo) => '[${combo.join(',')}]').toList();
  }

  /// Helper to compute the cartesian product of a list of lists
  List<List<int>> _cartesianProduct(List<List<int>> lists) {
    if (lists.isEmpty) return [];

    List<List<int>> result = [[]];
    for (var list in lists) {
      result = [
        for (var prefix in result)
          for (var item in list) [...prefix, item],
      ];
    }
    return result;
  }

  String toTypeExpression() {
    if (isEmpty) {
      return '';
    }
    var expression = StringBuffer();
    expression.write('ARRAY[');
    for (var arrayRange in this) {
      if (expression.length > 6) {
        expression.write(', ');
      }
      expression.write(arrayRange.min);
      expression.write('..');
      expression.write(arrayRange.max);
    }
    expression.write('] OF ');
    return expression.toString();
  }

  // @override
  // String toString() {
  //   if (isEmpty) return '';
  //   return super.toString();
  // }
}

@MapConverter()
class ArrayRange {
  static final minName = 'min';
  static final maxName = 'max';
  static final FluentRegex _numberRegex = FluentRegex().digit(
    Quantity.oneOrMoreTimes(),
  );
  static final FluentRegex regex = FluentRegex()
      .group(_numberRegex, type: GroupType.captureNamed(minName))
      .literal('..')
      .group(_numberRegex, type: GroupType.captureNamed(maxName))
      .literal(',', Quantity.zeroOrOneTime());

  final int min;
  final int max;
  late final int size = (max - min) + 1;

  ArrayRange(String expression)
    : min = _numberFromExpression(expression, minName),
      max = _numberFromExpression(expression, maxName);

  ArrayRange.minMax(this.min, this.max);

  @override
  String toString() {
    return '$min..$max';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArrayRange &&
          runtimeType == other.runtimeType &&
          min == other.min &&
          max == other.max;

  @override
  int get hashCode => min.hashCode ^ max.hashCode;

  static int _numberFromExpression(String expression, String groupName) {
    var value = regex.firstMatch(expression)!.namedGroup(groupName)!;
    return int.parse(value);
  }
}

/// These are the built‑in types defined by IEC 61131‑3 and directly supported by Sysmac Studio.
/// See [https://www.myomron.com/index.php?action=kb&article=1628]
@MapConverter(
  includeSubClasses: {
    IecBool,
    IecSInt,
    IecUSInt,
    IecByte,
    IecInt,
    IecUInt,
    IecWord,
    IecDInt,
    IecUDInt,
    IecDWord,
    IecReal,
    IecLInt,
    IecULInt,
    IecLWord,
    IecLReal,
    IecString,
    IecTime,
    IecDate,
    IecDateAndTime,
    IecTimeOfDay,
  },
)
abstract class IecType extends BasicType {
  String get name =>
      runtimeType.toString().replaceFirst('Iec', '').toUpperCase();
}

/// true or false
@MapConverter()
class IecBool extends IecType {}

/// 8 bit signed
@MapConverter()
class IecSInt extends IecType {}

/// 8 bit un-signed, bit operation possible
@MapConverter()
class IecUSInt extends IecType {}

/// 16 bit signed
@MapConverter()
class IecByte extends IecType {}

/// 16 bit signed
@MapConverter()
class IecInt extends IecType {}

/// 16 bit un-signed
@MapConverter()
class IecUInt extends IecType {}

/// 16 bit un-signed, bit operation possible
@MapConverter()
class IecWord extends IecType {}

/// 32 bit signed
@MapConverter()
class IecDInt extends IecType {}

/// 32 bit un-signed
@MapConverter()
class IecUDInt extends IecType {}

/// 32 bit un-signed, bit operation possible
@MapConverter()
class IecDWord extends IecType {}

/// 32 bit floating point
@MapConverter()
class IecReal extends IecType {}

/// 64 bit signed
@MapConverter()
class IecLInt extends IecType {}

/// 64 bit un-signed
@MapConverter()
class IecULInt extends IecType {}

/// 64 bit un-signed, bit operation possible
@MapConverter()
class IecLWord extends IecType {}

/// 64 bit floating point
@MapConverter()
class IecLReal extends IecType {}

/// 8 bits per character
@MapConverter()
class IecString extends IecType {
  final int? size;

  IecString({this.size});
}

/// 64 bit
@MapConverter()
class IecTime extends IecType {}

/// 64 bit
@MapConverter()
class IecDate extends IecType {}

/// 64 bit
@MapConverter()
class IecDateAndTime extends IecType {
  @override
  String get name => 'DATE_AND_TIME';
}

/// 64 bit
@MapConverter()
class IecTimeOfDay extends IecType {
  @override
  String get name => 'TIME_OF_DAY';
}

/// A Visual Basic [BaseType] e.g.:a HMI data type
/// See [https://www.myomron.com/index.php?action=kb&article=1628]
@MapConverter(
  includeSubClasses: {
    VbBoolean,
    VbSByte,
    VbByte,
    VbShort,
    VbUShort,
    VbInteger,
    VbUInteger,
    VbSingle,
    VbLong,
    VbULong,
    VbDouble,
    VbDecimal,
    VbString,
    VbChar,
    VbDateTime,
    VbTimeSpan,
  },
)
abstract class VbType extends BasicType {
  String get name => runtimeType.toString().replaceFirst('Vb', '');
}

@MapConverter()
class VbBoolean extends VbType {}

/// 8 bit signed
@MapConverter()
class VbSByte extends VbType {}

/// 8 bit un-signed
@MapConverter()
class VbByte extends VbType {}

/// 16 bit signed
@MapConverter()
class VbShort extends VbType {}

/// 16 bit un-signed
@MapConverter()
class VbUShort extends VbType {}

/// 32 bit signed
@MapConverter()
class VbInteger extends VbType {}

/// 32 bit un-signed
@MapConverter()
class VbUInteger extends VbType {}

/// 32 bit floating point
@MapConverter()
class VbSingle extends VbType {}

/// 64 bit signed
@MapConverter()
class VbLong extends VbType {}

/// 64 bit un-signed
@MapConverter()
class VbULong extends VbType {}

/// 64 bit floating point
@MapConverter()
class VbDouble extends VbType {}

@MapConverter()
class VbDecimal extends VbType {}

@MapConverter()
class VbString extends VbType {
  final int? size;

  VbString({this.size});
}

@MapConverter()
class VbChar extends VbType {}

/// 64 bit
@MapConverter()
class VbDateTime extends VbType {}

/// 64 bit
@MapConverter()
class VbTimeSpan extends VbType {
  @override
  String get name => 'System.TimeSpan';
}
