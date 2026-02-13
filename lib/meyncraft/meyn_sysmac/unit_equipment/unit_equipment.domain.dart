import 'package:meyncraft/meyncraft/sysmac/internal/base_type/base_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/data_type/data_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/variable/variable.domain.dart';

class Unit {
  // TODO add functionBlock instance name and type?

  /// the member inside the InterfaceGlobal variable
  /// that represents the unit interface to one or more equipments
  final VariableMember interfaceGlobalMember;

  /// the member inside the ConfigGlobal variable
  /// that represents the unit configuration
  final VariableMember configGlobalMember;
  final List<EquipmentModule> equipmentModules;

  Unit({
    required this.interfaceGlobalMember,
    required this.configGlobalMember,
    required this.equipmentModules,
  });

  late final String name = interfaceGlobalMember.namePath.last;
}

class EquipmentModule {
  // TODO add functionBlock instance name and type?

  /// the member inside the InterfaceGlobal variable
  /// that represents the equipment interface with a unit
  final VariableMember interfaceGlobalMember;

  /// the member inside the ConfigGlobal variable
  /// that represents a boolean whether this equipment is present
  final VariableMember configGlobalPresentMember;
  final List<ControlModule> controlModules;
  late final String name = interfaceGlobalMember.namePath.last;

  EquipmentModule({
    required this.interfaceGlobalMember,
    required this.configGlobalPresentMember,
    required this.controlModules,
  });
}

class ControlModule {
  // TODO add functionBlock instance name and type?

  /// the member inside the InterfaceGlobal variable
  /// that represents the equipment interface with a unit
  final VariableMember interfaceGlobalMember;
  late final String name = interfaceGlobalMember.namePath.last;
  // late final ArrayRanges arrayRanges = _arrayRanges(interfaceGlobalMember);
  // late final List<String> arrayValues = _arrayValues(interfaceGlobalMember);

  ControlModule({required this.interfaceGlobalMember});
}

// ArrayRanges _arrayRanges(VariableMember variableName) {
//   var dataTypeBase = variableName.dataTypeBase;
//   if (dataTypeBase is DataType) {
//     return dataTypeBase.baseType.arrayRanges;
//   }
//   return ArrayRanges();
// }

// List<String> _arrayValues(VariableMember variableName) {
//   var arrayRanges = _arrayRanges(variableName);
//   if (arrayRanges.isEmpty) {
//     return [''];
//   }
//   return arrayRanges.toStringList();
// }
