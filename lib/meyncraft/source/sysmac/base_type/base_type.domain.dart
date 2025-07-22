import 'package:collection/collection.dart';
import 'package:fluent_regex/fluent_regex.dart';

import '../data_type/data_type.domain.dart';

/// A [BaseType] is used in a [DataType] and refers to an internal type within
/// (Sysmac)[https://industrial.omron.eu/en/products/sysmac-platform]
abstract class BaseType {
  final arrayRanges = ArrayRanges();

  @override
  String toString() {
    if (arrayRanges.isEmpty) {
      return runtimeType.toString();
    } else {
      return 'ARRAY$arrayRanges OF $runtimeType';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BaseType &&
          runtimeType == other.runtimeType &&
          toString() == other.toString();

  @override
  int get hashCode => toString().hashCode;
}

class ArrayRanges extends DelegatingList<ArrayRange> {
  ArrayRanges() : super(<ArrayRange>[]);

  /// e.g.
  /// if [ArrayRArrayRanges] represents [ArrayRange(min:2, max:3)  ArrayRange(min:5, max:7)]
  /// then outputs: [[2,3] [5,6,7]]
  List<List<int>> toValueLists() => map(
    (range) => List.generate(range.max - range.min + 1, (i) => range.min + i),
  ).toList();

  /// e.g.
  /// if [ArrayRArrayRanges] represents [ArrayRange(min:2, max:3)  ArrayRange(min:5, max:7)]
  /// then outputs: ['[2,5]','[2,6]','[2,7]','[3,5]','[3,6]','[3,7]']
  List<String> toStringList() {
    final valueLists = toValueLists();
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
}

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

/// A [BaseType] that refers to an existing [DataType]:
class DataTypeReference extends BaseType {
  final DataType dataType;

  DataTypeReference({
    required this.dataType,
    required ArrayRanges arrayRanges,
  }) {
    this.arrayRanges.clear();
    this.arrayRanges.addAll(arrayRanges);
  }

  /// not showing data type in to String because the DataType is shown
  /// See: [DataType.children]
  // @override
  // String toString() {
  //   return super.toString() + '{$dataType}';
  // }
}

class UnknownBaseType extends BaseType {
  final String expression;

  UnknownBaseType(this.expression);

  @override
  String toString() {
    if (arrayRanges.isEmpty) {
      return expression;
    } else {
      return 'ARRAY$arrayRanges OF $expression';
    }
  }
}

class Struct extends BaseType {}

class EnumParent extends BaseType {
  EnumParent();
}

class EnumChild extends BaseType {
  final int index;
  EnumChild(this.index);
}

/// Nx PLC [BaseType] e.g.: a NJ PLC data type
/// See [https://www.myomron.com/index.php?action=kb&article=1628]
abstract class NxType extends BaseType {
  String get name =>
      runtimeType.toString().replaceFirst('Nx', '').toUpperCase();
}

/// true or false
class NxBool extends NxType {}

/// 8 bit signed
class NxSInt extends NxType {}

/// 8 bit un-signed, bit operation possible
class NxUSInt extends NxType {}

/// 16 bit signed
class NxByte extends NxType {}

/// 16 bit signed
class NxInt extends NxType {}

/// 16 bit un-signed
class NxUInt extends NxType {}

/// 16 bit un-signed, bit operation possible
class NxWord extends NxType {}

/// 32 bit signed
class NxDInt extends NxType {}

/// 32 bit un-signed
class NxUDInt extends NxType {}

/// 32 bit un-signed, bit operation possible
class NxDWord extends NxType {}

/// 32 bit floating point
class NxReal extends NxType {}

/// 64 bit signed
class NxLInt extends NxType {}

/// 64 bit un-signed
class NxULInt extends NxType {}

/// 64 bit un-signed, bit operation possible
class NxLWord extends NxType {}

/// 64 bit floating point
class NxLReal extends NxType {}

/// 8 bits per character
class NxString extends NxType {}

/// 64 bit
class NxTime extends NxType {}

/// 64 bit
class NxDate extends NxType {}

/// 64 bit
class NxDateAndTime extends NxType {
  @override
  String get name => 'DATE_AND_TIME';
}

/// 64 bit
class NxTimeOfDay extends NxType {
  @override
  String get name => 'TIME_OF_DAY';
}

/// A Visual Basic [BaseType] e.g.:a HMI data type
/// See [https://www.myomron.com/index.php?action=kb&article=1628]
abstract class VbType extends BaseType {
  String get name => runtimeType.toString().replaceFirst('Vb', '');
}

class VbBoolean extends VbType {}

/// 8 bit signed
class VbSByte extends VbType {}

/// 8 bit un-signed
class VbByte extends VbType {}

/// 16 bit signed
class VbShort extends VbType {}

/// 16 bit un-signed
class VbUShort extends VbType {}

/// 32 bit signed
class VbInteger extends VbType {}

/// 32 bit un-signed
class VbUInteger extends VbType {}

/// 32 bit floating point
class VbSingle extends VbType {}

/// 64 bit signed
class VbLong extends VbType {}

/// 64 bit un-signed
class VbULong extends VbType {}

/// 64 bit floating point
class VbDouble extends VbType {}

class VbDecimal extends VbType {}

class VbString extends VbType {}

class VbChar extends VbType {}

/// 64 bit
class VbDateTime extends VbType {}

/// 64 bit
class VbTimeSpan extends VbType {
  @override
  String get name => 'System.TimeSpan';
}
