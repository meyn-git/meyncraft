import 'package:collection/collection.dart';
import 'package:fluent_regex/fluent_regex.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/base_type/base_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/data_type/data_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/node.domain.dart';

class BaseTypeFactory {
  final List<BaseTypeSubFactory> baseTypeSubFactories = [
    ArrayFactory(),
    ...NxTypeFactories(),
    ...VbTypeFactories(),
    UnknownBaseTypeFactory(),
  ];

  BaseType createFromExpression(String typeExpression) {
    var factory = baseTypeSubFactories.firstWhere(
      (factory) => factory.regex.hasMatch(typeExpression),
    );
    return factory.create(typeExpression);
  }

  BaseType tryToResolveDataTypeRefBaseType({
    required List<DataTypeBase> dataTypes,
    required String name,
    required String comment,
    required String typeExpression,
  }) {
    var baseType = createFromExpression(typeExpression);
    if (baseType is BasicType) {
      return DataTypeReference.forBasicType(
        name: name,
        comment: comment,
        basicType: baseType,
      );
    }
    // try to find a path for the data type reference
    var dataTypePath = dataTypes.findFirstNodePath(
      namePathFinder(typeExpression.split(r'\'), caseSensitive: false),
    );
    if (dataTypePath.isNotEmpty) {
      return DataTypeReference.forDataTypePath(
        name: name,
        comment: comment,
        dataTypePath: dataTypePath,
      );
    } else {
      return UnknownDataTypeBase(
        name: name,
        comment: comment,
        typeExpression: typeExpression,
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

class NxTypeFactory extends BaseTypeSubFactory {
  final IecType _nxType;
  final RegExp _regex;

  NxTypeFactory(this._nxType)
    : _regex = FluentRegex().startOfLine().literal(_nxType.name).endOfLine();

  /// e.g. STRING[123]
  NxTypeFactory.withOptionalLength(this._nxType)
    : _regex = FluentRegex()
          .startOfLine()
          .literal(_nxType.name)
          .group(
            FluentRegex()
                .literal('[')
                .digit(Quantity.oneOrMoreTimes())
                .literal(']'),
            quantity: Quantity.zeroOrOneTime(),
          )
          .endOfLine();

  @override
  IecType create(String expression) => _nxType;

  @override
  RegExp get regex => _regex;
}

class NxTypeFactories extends DelegatingList<NxTypeFactory> {
  NxTypeFactories()
    : super([
        NxTypeFactory(IecInt()),
        NxTypeFactory(IecDInt()),
        NxTypeFactory(IecLInt()),
        NxTypeFactory(IecUInt()),
        NxTypeFactory(IecWord()),
        NxTypeFactory(IecUDInt()),
        NxTypeFactory(IecDWord()),
        NxTypeFactory(IecULInt()),
        NxTypeFactory(IecLWord()),
        NxTypeFactory(IecReal()),
        NxTypeFactory(IecLReal()),
        NxTypeFactory(IecBool()),
        NxTypeFactory.withOptionalLength(IecString()),
        NxTypeFactory(IecSInt()),
        NxTypeFactory(IecUSInt()),
        NxTypeFactory(IecByte()),
        NxTypeFactory(IecTime()),
        NxTypeFactory(IecDate()),
        NxTypeFactory(IecDateAndTime()),
        NxTypeFactory(IecTimeOfDay()),
      ]);
}

class VbTypeFactory extends BaseTypeSubFactory {
  final VbType _vbType;
  final RegExp _regex;

  VbTypeFactory(this._vbType)
    : _regex = FluentRegex().startOfLine().literal(_vbType.name).endOfLine();

  VbTypeFactory.withOptionalLength(this._vbType)
    : _regex = FluentRegex()
          .startOfLine()
          .literal(_vbType.name)
          .group(
            FluentRegex()
                .literal('[')
                .digit(Quantity.oneOrMoreTimes())
                .literal(']'),
            quantity: Quantity.zeroOrOneTime(),
          )
          .endOfLine();

  @override
  VbType create(String expression) => _vbType;

  @override
  RegExp get regex => _regex;
}

class VbTypeFactories extends DelegatingList<VbTypeFactory> {
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
        VbTypeFactory.withOptionalLength(VbString()),
        VbTypeFactory(VbChar()),
        VbTypeFactory(VbSByte()),
        VbTypeFactory(VbByte()),
        VbTypeFactory(VbDateTime()),
        VbTypeFactory(VbTimeSpan()),
      ]);
}

class ArrayFactory extends BaseTypeSubFactory {
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
                    CharacterSet().addLetters().addDigits().addLiterals(r'\_'),
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

  late final baseTypeFactory = BaseTypeFactory();

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

/// Replaces all the [UnknownBaseType]s with [DataTypeReference]s
/// when the path can be found
void tryToResolveDataTypeRefBaseType(List<DataTypeBase> dataTypes) {
  var dataTypesWithUnresolvedChildren = dataTypes.descendants.where(
    (dataTypeBase) =>
        dataTypeBase is DataType &&
        dataTypeBase.children.any((child) => child is UnknownDataTypeBase),
  );
  for (var dataTypeWithUnresolvedChildren in dataTypesWithUnresolvedChildren) {
    for (
      var childIndex = 0;
      childIndex < dataTypeWithUnresolvedChildren.children.length;
      childIndex++
    ) {
      var child = dataTypeWithUnresolvedChildren.children[childIndex];
      if (child is UnknownDataTypeBase) {
        var possiblyResolvedDataTypeRef = _baseTypeFactory
            .tryToResolveDataTypeRefBaseType(
              dataTypes: dataTypes,
              name: child.name,
              comment: child.comment,
              typeExpression: child.typeExpression,
            );
        if (possiblyResolvedDataTypeRef is DataTypeReference) {
          // replace the UnknownDataTypeBase with the resolved DataTypeReference
          dataTypeWithUnresolvedChildren.children[childIndex] =
              possiblyResolvedDataTypeRef;
        }
      }
    }
  }
}

final _baseTypeFactory = BaseTypeFactory();
