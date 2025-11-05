import 'package:meyncraft/meyncraft/sysmac/internal/base_type/base_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/data_type/data_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/variable/variable.domain.dart';

class Unit {
  /// the member inside the InterfaceGlobal variable
  /// that represents the unit interface to one or more equipments
  final VariableMember interfaceGlobalMember;

  /// the member inside the ConfigGlobal variable
  /// that represents the unit configuration
  final VariableMember configGlobalMember;
  final List<Equipment> equipments;

  Unit({
    required this.interfaceGlobalMember,
    required this.configGlobalMember,
    required this.equipments,
  });

  late final String name = interfaceGlobalMember.namePath.last;
}

class Equipment {
  /// the member inside the InterfaceGlobal variable
  /// that represents the equipment interface with a unit
  final VariableMember interfaceGlobalMember;

  /// the member inside the ConfigGlobal variable
  /// that represents a boolean whether this equipment is present
  final VariableMember configGlobalPresentMember;

  late final String name = interfaceGlobalMember.namePath.last;

  Equipment({
    required this.interfaceGlobalMember,
    required this.configGlobalPresentMember,
  });

  late final List<String> arrayValues = _arrayValues();

  ArrayRanges _arrayRanges() {
    var dataTypeBase = interfaceGlobalMember.dataTypeBase;
    if (dataTypeBase is DataType) {
      return dataTypeBase.baseType.arrayRanges;
    }
    return ArrayRanges();
  }

  List<String> _arrayValues() {
    var arrayRanges = _arrayRanges();
    if (arrayRanges.isEmpty) {
      return [''];
    }
    return arrayRanges.toStringList();
  }
}
