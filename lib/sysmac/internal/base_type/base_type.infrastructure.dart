import 'package:collection/collection.dart';
import 'package:fluent_regex/fluent_regex.dart';
import 'package:meyncraft/sysmac/internal/base_type/base_type.domain.dart';
import 'package:meyncraft/sysmac/internal/data_type/data_type.domain.dart';
import 'package:meyncraft/sysmac/node.domain.dart';

class BaseTypeFactory {
  late final List<BaseTypeSubFactory> baseTypeSubFactories;

  BaseTypeFactory.forIecTypes() {
    baseTypeSubFactories = [
      ArrayFactory(this),
      ...IecTypeFactories(),
      UnknownBaseTypeFactory(),
    ];
  }

  BaseTypeFactory.forVbTypes() {
    baseTypeSubFactories = [
      ArrayFactory(this),
      ...VbTypeFactories(),
      UnknownBaseTypeFactory(),
    ];
  }

  BaseType createFromExpression(String typeExpression) {
    var factory = baseTypeSubFactories.firstWhere(
      (factory) => factory.regex.hasMatch(typeExpression),
    );
    return factory.create(typeExpression);
  }

  void tryToResolveDataTypeBaseTypes(List<DataTypeBase> dataTypes) {
    var baseTypeOwners = dataTypes.descendants.whereType<BaseTypeOwner>();
    for (var baseTypeOwner in baseTypeOwners) {
      resolveBaseTypeOwnersRecursively(dataTypes, baseTypeOwner);
    }
  }

  /// References to DataTypes may not exist during the creation
  /// of [DataType]'s or [Variable]s and are therefore created as [UnknownBaseType]
  ///
  /// This method will try and replaces baseTypes that
  /// are an [UnknownBaseType] with a [DataTypeMember]
  /// This is done recursively: a baseType may also contain a baseType that needs resolving
  void resolveBaseTypeOwnersRecursively(
    List<DataTypeBase> dataTypes,
    BaseTypeOwner baseTypeOwner,
  ) {
    if (baseTypeOwner.baseType is UnknownBaseType) {
      var typeExpression =
          (baseTypeOwner.baseType as UnknownBaseType).typeExpression;
      // try to find a path for the data type reference
      var dataTypePath = dataTypes.findFirstNodePath(
        namePathFinder(typeExpression.split(r'\'), caseSensitive: false),
      );
      if (dataTypePath.isNotEmpty) {
        // replace baseType with a DataTypeReference
        var resolvedBaseType = DataTypeReference(dataTypePath: dataTypePath);
        baseTypeOwner.baseType = resolvedBaseType;
      }
    }
    if (baseTypeOwner.baseType is BaseTypeOwner) {
      // recursive call for nested BaseTypeOwner's
      resolveBaseTypeOwnersRecursively(
        dataTypes,
        (baseTypeOwner.baseType as BaseTypeOwner),
      );
    }
  }
}

abstract class BaseTypeSubFactory {
  RegExp get regex;

  BaseType create(String expression);
}

class UnknownBaseTypeFactory extends BaseTypeSubFactory {
  @override
  RegExp get regex => FluentRegex().anyCharacter(Quantity.oneOrMoreTimes());

  @override
  BaseType create(String expression) => UnknownBaseType(expression);
}

abstract interface class IecTypeFactoryBase implements BaseTypeSubFactory {}

class IecTypeFactory extends IecTypeFactoryBase {
  final IecType _iecType;
  final RegExp _regex;

  IecTypeFactory(this._iecType)
    : _regex = FluentRegex()
          .startOfLine()
          .literal(_iecType.name)
          .ignoreCase()
          .endOfLine();

  @override
  IecType create(String expression) => _iecType;

  @override
  RegExp get regex => _regex;
}

/// Creates a [IecString]
/// e.g. string, String[12] or STRING[123]
class IecStringFactory extends IecTypeFactoryBase {
  final RegExp _regex;
  static const String sizeGroupName = 'size';

  IecStringFactory()
    : _regex = FluentRegex()
          .startOfLine()
          .literal('STRING')
          .ignoreCase()
          .ignoreCase()
          .group(
            FluentRegex()
                .literal('[')
                .group(
                  FluentRegex().digit(Quantity.oneOrMoreTimes()),
                  type: GroupType.captureNamed(sizeGroupName),
                )
                .literal(']'),
            quantity: Quantity.zeroOrOneTime(),
          )
          .endOfLine();

  @override
  IecString create(String expression) {
    var result = _regex.firstMatch(expression);
    if (result == null) return IecString();
    var size = result.namedGroup(sizeGroupName);
    if (size == null) return IecString();
    return IecString(size: int.tryParse(size));
  }

  @override
  RegExp get regex => _regex;
}

class IecTypeFactories extends DelegatingList<IecTypeFactoryBase> {
  IecTypeFactories()
    : super([
        IecTypeFactory(IecInt()),
        IecTypeFactory(IecDInt()),
        IecTypeFactory(IecLInt()),
        IecTypeFactory(IecUInt()),
        IecTypeFactory(IecWord()),
        IecTypeFactory(IecUDInt()),
        IecTypeFactory(IecDWord()),
        IecTypeFactory(IecULInt()),
        IecTypeFactory(IecLWord()),
        IecTypeFactory(IecReal()),
        IecTypeFactory(IecLReal()),
        IecTypeFactory(IecBool()),
        IecStringFactory(),
        IecTypeFactory(IecSInt()),
        IecTypeFactory(IecUSInt()),
        IecTypeFactory(IecByte()),
        IecTypeFactory(IecTime()),
        IecTypeFactory(IecDate()),
        IecTypeFactory(IecDateAndTime()),
        IecTypeFactory(IecTimeOfDay()),
      ]);
}

abstract interface class VbTypeFactoryBase implements BaseTypeSubFactory {}

class VbTypeFactory implements VbTypeFactoryBase {
  final VbType _vbType;
  final RegExp _regex;

  VbTypeFactory(this._vbType)
    : _regex = FluentRegex()
          .startOfLine()
          .literal(_vbType.name)
          .ignoreCase()
          .endOfLine();

  @override
  VbType create(String expression) => _vbType;

  @override
  RegExp get regex => _regex;
}

/// Creates a [VbString]
/// e.g. string, String[12] or STRING[123]
class VbStringFactory implements VbTypeFactoryBase {
  final RegExp _regex;
  static const String sizeGroupName = 'size';

  VbStringFactory()
    : _regex = FluentRegex()
          .startOfLine()
          .literal('STRING')
          .ignoreCase()
          .ignoreCase()
          .group(
            FluentRegex()
                .literal('[')
                .group(
                  FluentRegex().digit(Quantity.oneOrMoreTimes()),
                  type: GroupType.captureNamed(sizeGroupName),
                )
                .literal(']'),
            quantity: Quantity.zeroOrOneTime(),
          )
          .endOfLine();

  @override
  VbString create(String expression) {
    var result = _regex.firstMatch(expression);
    if (result == null) return VbString();
    var size = result.namedGroup(sizeGroupName);
    if (size == null) return VbString();
    return VbString(size: int.tryParse(size));
  }

  @override
  RegExp get regex => _regex;
}

class VbTypeFactories extends DelegatingList<VbTypeFactoryBase> {
  VbTypeFactories()
    : super([
        VbTypeFactory(VbShort()),
        VbTypeFactory(VbInteger()),
        VbTypeFactory(VbLong()),
        VbTypeFactory(VbUShort()),
        VbTypeFactory(VbUInteger()),
        VbTypeFactory(VbULong()),
        VbTypeFactory(VbSingle()),
        VbTypeFactory(VbDouble()),
        VbTypeFactory(VbDecimal()),
        VbTypeFactory(VbBoolean()),
        VbStringFactory(),
        VbTypeFactory(VbChar()),
        VbTypeFactory(VbSByte()),
        VbTypeFactory(VbByte()),
        VbTypeFactory(VbDateTime()),
        VbTypeFactory(VbTimeSpan()),
      ]);
}

class ArrayFactory extends BaseTypeSubFactory {
  ArrayFactory(this.baseTypeFactory);

  final BaseTypeFactory baseTypeFactory;
  static final rangeName = 'range';
  static final typeName = 'type';
  static final RegExp _regex = FluentRegex()
      .ignoreCase(true)
      .startOfLine()
      .literal('ARRAY')
      .literal('[')
      .group(
        ArrayRange.regex,
        type: GroupType.captureNamed(rangeName),
        quantity: Quantity.oneOrMoreTimes(),
      )
      .literal(']')
      .group(
        FluentRegex()
            .ignoreCase(true)
            .literal(' OF ')
            .group(
              FluentRegex()
                  .letter(quantity: Quantity.oneTime())
                  .characterSet(
                    CharacterSet().addLetters().addDigits().addLiterals(
                      r'\.,_[]',
                    ),
                    Quantity.oneOrMoreTimes(),
                  ),
              type: GroupType.captureNamed(typeName),
            ),
        quantity:
            Quantity.zeroOrOneTime(), // Makes the " OF <type>" part optional
      )
      .endOfLine();

  @override
  BaseType create(String expression) {
    var baseType = _createBaseType(expression);
    var arrayRanges = _createArrayRanges(expression);
    return ArrayType(baseType: baseType, arrayRanges: arrayRanges);
  }

  BaseType _createBaseType(String expression) {
    var typeExpression = _regex.firstMatch(expression)!.namedGroup(typeName);
    if (typeExpression == null) {
      /// if nothing is specified, lets assume it is an array of bool
      return IecBool();
    }

    return baseTypeFactory.createFromExpression(typeExpression);
  }

  ArrayRanges _createArrayRanges(String expression) {
    var rangeExpressions = ArrayRange.regex.allMatches(expression);

    var ranges = rangeExpressions
        .map(
          (match) => ArrayRange(expression.substring(match.start, match.end)),
        )
        .toList();

    return ArrayRanges(ranges);
  }

  @override
  RegExp get regex => _regex;
}
