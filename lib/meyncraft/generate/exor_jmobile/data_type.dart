import 'package:meyncraft/meyncraft/sysmac/internal/base_type/base_type.domain.dart';

/// | Memory Space         | NX/NJ Data Type  | NA Data Type     | JMobile        | JMobile Limits               |
/// |----------------------|------------------|------------------|----------------|------------------------------|
/// | 1 bit                | BOOL             | Boolean          | boolean        | 0..1                         |
/// | 8 bit                | SINT             | SByte            | byte           | -128..127                    |
/// | 8 bit                | USINT            | Byte*1           | unsignedByte   | 0..255                       |
/// | 8 bit                | BYTE *3          | Byte*1           | unsignedByte   | 0..255                       |
/// | 16 bit               | INT              | Short            | short          | -32768..32767                |
/// | 16 bit               | UINT             | UShort*1         | unsignedShort  | 0..65535                     |
/// | 16 bit               | WORD *3          | UShort*1         | unsignedShort  | 0..65535                     |
/// | 32 bit               | DINT             | Integer          | int            | -2.1e9..2.1e9                |
/// | 32 bit               | UDINT            | UInteger*1       | unsignedInt    | 0..4.2e9                     |
/// | 32 bit               | DWORD *3         | UInteger*1       | unsignedInt    | 0..4.2e9                     |
/// | 32 bit               | REAL             | Single           | float          | 1.17e-38..3.40e38            |
/// | 64 bit               | LINT             | Long             | int64          | -9.2e18..9.2e18              |
/// | 64 bit               | ULINT            | ULong*1          | usint64        | 0..1.8e19                    |
/// | 64 bit               | LWORD *3         | ULong*1          | usint64        | 0..1.8e19                    |
/// | 64 bit               | LREAL            | Double           | double         | 2.2e-308..1.79e308           |
/// | 64 bit               | TIME             | TimeSpan*2       |                |                              |
/// | 64 bit               | DATE             | Date             |                |                              |
/// | 64 bit               | DATE_AND_TIME
///
/// Notes:
/// *1	VB.Net does not have a BCD data type. However unsigned BCD data types values can be represented by unsigned integer data types
/// *2	TIME has no direct equivalent data type and in VB.Net is represented by the TimeSpan structure. TimeSpans cannot be used in numeric inputs/displays,.
/// *3	Bitwise operation possible
///
/// Source:
/// * Omron source:	https://store.omron.com.au/knowledge-base/nxnj-to-na-data-types?srsltid:AfmBOoqIPj1s4ivQTDKOUYhCdUXpw4Qu2o-3vx0MKSpkXmf1Snzd5Dsn
/// * Exor source:	https://www.Exorint.com/faq/2017/06/14/can-you-explain-data-type-supported-on-jmobile-tag-editor

abstract class ExorDataType {
  final String exorTypeName;
  final String iecTypeName;
  final List<Type> comparableOmronTypes;
  final String min;
  final String max;
  final String arraySize;

  const ExorDataType({
    required this.exorTypeName,
    required this.iecTypeName,
    required this.comparableOmronTypes,
    required this.min,
    required this.max,
    this.arraySize = '',
  });

  static final List<ExorDataType> _allTypes = [
    ExorBoolean(),
    ExorByte(),
    ExorUnsignedByte(),
    ExorShort(),
    ExorUnsignedShort(),
    ExorInt(),
    UnsignedInt(),
    ExorFloat(),
    ExorInt64(),
    ExorUnsignedInt64(),
    ExorDouble(),
    ExorString(),
    ExorDateTime(),
  ];

  static ExorDataType findCompatibleType(BaseType omronBaseType) {
    return _allTypes.firstWhere(
      (type) => type.comparableOmronTypes.contains(omronBaseType.runtimeType),
      orElse: () => throw Exception(
        'Omron data type: $omronBaseType could not be converted to a Exor data type',
      ),
    );
  }

  static ExorDataType findCompatibleTypeWithOneDimensionalArray(
    BaseType baseType,
  ) {
    var compatibleType = findCompatibleType(baseType);
    return ExorOneDimensionalArray(compatibleType, baseType.arrayRanges.first);
  }
}

class ExorEnum extends ExorDataType {
  ExorEnum()
    : super(
        exorTypeName: 'int',
        iecTypeName: 'DINT',
        comparableOmronTypes: [EnumParent],
        min: '-32768',
        max: '32767',
      );
}

/// Wraps a [ExorDataType] and overrides the arraySize  fields to make it a one dimensional array
class ExorOneDimensionalArray extends ExorDataType {
  ExorOneDimensionalArray(ExorDataType compatibleType, ArrayRange arrayRange)
    : super(
        exorTypeName: '${compatibleType.exorTypeName} []',
        iecTypeName: compatibleType.exorTypeName,
        comparableOmronTypes: compatibleType.comparableOmronTypes,
        min: compatibleType.min,
        max: compatibleType.max,
        arraySize: arrayRange.size.toString(),
      );
}

// Concrete implementations
class ExorBoolean extends ExorDataType {
  ExorBoolean()
    : super(
        exorTypeName: 'boolean',
        iecTypeName: 'BOOL',
        comparableOmronTypes: [VbBoolean, NxBool],
        min: '0',
        max: '1',
      );
}

class ExorByte extends ExorDataType {
  ExorByte()
    : super(
        exorTypeName: 'byte',
        iecTypeName: 'SINT',
        comparableOmronTypes: [NxSInt, VbSByte],
        min: '-128',
        max: '127',
      );
}

class ExorUnsignedByte extends ExorDataType {
  ExorUnsignedByte()
    : super(
        exorTypeName: 'unsignedByte',
        iecTypeName: 'USINT',
        comparableOmronTypes: [NxUSInt, NxByte, VbByte],
        min: '0',
        max: '255',
      );
}

class ExorShort extends ExorDataType {
  ExorShort()
    : super(
        exorTypeName: 'short',
        iecTypeName: 'INT',
        comparableOmronTypes: [NxInt, VbShort],
        min: '-32768',
        max: '32767',
      );
}

class ExorUnsignedShort extends ExorDataType {
  ExorUnsignedShort()
    : super(
        exorTypeName: 'unsignedShort',
        iecTypeName: 'UINT',
        comparableOmronTypes: [NxUInt, NxWord, VbUShort],
        min: '0',
        max: '65535',
      );
}

class ExorInt extends ExorDataType {
  ExorInt()
    : super(
        exorTypeName: 'int',
        iecTypeName: 'DINT',
        comparableOmronTypes: [NxDInt, VbInteger],
        min: '-2147483648',
        max: '2147483647',
      );
}

class UnsignedInt extends ExorDataType {
  UnsignedInt()
    : super(
        exorTypeName: 'unsignedInt',
        iecTypeName: 'UDINT',
        comparableOmronTypes: [NxUDInt, NxDWord, VbUInteger],
        min: '0',
        max: '4294967295',
      );
}

class ExorFloat extends ExorDataType {
  ExorFloat()
    : super(
        exorTypeName: 'float',
        iecTypeName: 'REAL',
        comparableOmronTypes: [NxReal, VbSingle],
        min: '-3.40282e+38',
        max: '3.40282e+38',
      );
}

class ExorInt64 extends ExorDataType {
  ExorInt64()
    : super(
        exorTypeName: 'int64',
        iecTypeName: 'LINT',
        comparableOmronTypes: [NxLInt, VbLong],
        min: '-9.2e18',
        max: '9.2e18',
      );
}

class ExorUnsignedInt64 extends ExorDataType {
  ExorUnsignedInt64()
    : super(
        exorTypeName: 'uint64',
        iecTypeName: 'ULINT',
        comparableOmronTypes: [NxULInt, NxLWord, VbULong],
        min: '0',
        max: '1.8e19',
      );
}

// These values where copied from the standard Evisceration J mobile project. not sure they are correct:
// class ExorReal extends ExorDataType {
//   ExorReal()
//     : super(
//         ExorTypeName: 'real',
//         iecTypeName: 'LREAL',
//         comparableOmronTypes: [NxLReal, VbDouble],
//         min: '-3.40282e+38',
//         max: '3.40282e+38',
//       );
// }

class ExorDouble extends ExorDataType {
  ExorDouble()
    : super(
        exorTypeName: 'double',
        iecTypeName: 'LREAL',
        comparableOmronTypes: [NxLReal, VbDouble],
        min: '2.2e-308',
        max: '1.79e308',
      );
}

class ExorString extends ExorDataType {
  ExorString()
    : super(
        exorTypeName: 'string',
        iecTypeName: 'STRING',
        comparableOmronTypes: [NxString, VbString],
        min: '',
        max: '',
        arraySize: '255',
      );
}

class ExorDateTime extends ExorDataType {
  ExorDateTime()
    : super(
        exorTypeName: 'uint64',
        iecTypeName: 'DATE_AND_TIME',
        comparableOmronTypes: [NxTime, NxDateAndTime],
        min: '0',
        max: '18446744073709551615',
      );
}
