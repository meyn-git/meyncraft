import 'package:collection/collection.dart';
import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/base_type/base_type.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/data_type/data_type.domain.dart';
import 'package:meyncraft/meyncraft/meyn_sysmac/unit_equipment/unit_equipment.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/variable/variable.domain.dart';

List<Unit> createMeynUnitsAndEquipments(SysmacProject sysmacProject) {
  VariableMember? interfaceGlobalVar = findGlobalVariableMember(
    sysmacProject,
    interfaceGlobalVariableName,
  );
  if (interfaceGlobalVar == null) return [];
  VariableMember? configGlobalVar = findGlobalVariableMember(
    sysmacProject,
    configGlobalVariableName,
  );
  if (configGlobalVar == null) return [];

  var units = _createUnits(interfaceGlobalVar, configGlobalVar);
  return units;
}

VariableMember? findGlobalVariableMember(
  SysmacProject sysmacProject,
  String nameToFind,
) {
  var variable = sysmacProject.globalVariables.firstWhereOrNull(
    (v) => v.name == nameToFind,
  );
  if (variable == null) {
    logger.warning(
      '  Expected the sysmac project to have 1 global variable of name "$nameToFind"',
    );
    return null;
  }
  var variableType = variable.baseType;
  if (variableType is! DataTypeReference) {
    logger.warning('Expected "$nameToFind" to be a DataType');
    return null;
  }
  return VariableMember(variable, variableType.dataType, []);
}

const String interfaceGlobalVariableName = 'InterfaceGlobal';
const String configGlobalVariableName = 'ConfigGlobal';

List<Unit> _createUnits(
  VariableMember interfaceGlobalVar,
  VariableMember configGlobalVar,
) {
  List<VariableMember> unitInterfaces = interfaceGlobalVar.find(
    _unitInterfacesToEquipmentsFilter,
  );
  if (unitInterfaces.isEmpty) {
    logger.warning(
      '    Could not find any unit interfaces in the ${interfaceGlobalVar.expression} variable',
    );
  }
  logger.info('    Found: ${unitInterfaces.length} unit interfaces');
  List<VariableMember> equipmentInterfaces = interfaceGlobalVar.find(
    _equipmentInterfacesToUnitFilter,
  );
  var equipmentInterfacesWithoutUnit = [...equipmentInterfaces];
  if (unitInterfaces.isEmpty) {
    logger.warning(
      '    Could not find any equipment interfaces in the ${interfaceGlobalVar.expression} variable',
    );
  }
  logger.info('    Found: ${equipmentInterfaces.length} equipment interfaces');

  var units = <Unit>[];
  for (var unitInterface in unitInterfaces) {
    var unitName = unitInterface.namePath.last;
    var unitConfigs = configGlobalVar.find(
      (d) => _configMemberForUnitFilter(d, unitName),
    );
    if (unitConfigs.length != 1) {
      logger.warning(
        '    Expected variable ${configGlobalVar.expression} to have a member for unit $unitName',
      );
      break;
    }
    var unitConfig = unitConfigs.first;
    var equipments = <Equipment>[];
    for (var equipmentInterface in equipmentInterfaces) {
      var nameToFind = '${equipmentInterface.namePath.last}Present';
      var equipmentPresentConfigs = unitConfig.find(
        (d) => d.name == nameToFind && d is DataType && d.baseType is NxBool,
      );
      if (equipmentPresentConfigs.isNotEmpty) {
        equipments.add(
          Equipment(
            interfaceGlobalMember: equipmentInterface,
            configGlobalPresentMember: equipmentPresentConfigs.first,
          ),
        );
        equipmentInterfacesWithoutUnit.remove(equipmentInterface);
      }
    }
    if (equipments.isEmpty) {
      logger.warning(
        '    Expected variable ${unitConfig.expression} to have EquipmentPresent booleans',
      );
    }
    var unit = Unit(
      interfaceGlobalMember: unitInterface,
      configGlobalMember: unitConfigs.first,
      equipments: equipments,
    );
    units.add(unit);
  }

  for (var equipmentInterfaceWithoutUnit in equipmentInterfacesWithoutUnit) {
    logger.warning(
      '    Could not find a ${configGlobalVar.expression}.<UnitName>.'
      '${equipmentInterfaceWithoutUnit.namePath.last}Present as '
      '${arrayRanges(equipmentInterfaceWithoutUnit.dataTypeBase).toTypeExpression()}BOOL'
      ', and therefor could not generate code to link it to a Unit!',
    );
  }

  return units;
}

ArrayRanges arrayRanges(DataTypeBase dataTypeBase) {
  if (dataTypeBase is DataType) {
    return (dataTypeBase).baseType.arrayRanges;
  }
  return ArrayRanges();
}

bool _unitInterfacesToEquipmentsFilter(DataTypeBase base) =>
    base is DataType &&
    (base.baseType) is DataTypeReference &&
    (base.baseType as DataTypeReference).dataType.children.any(
      (c) => _matches(c, name: 'PackML', type: r'Generic\Unit\sPackML'),
    );

bool _equipmentInterfacesToUnitFilter(DataTypeBase base) =>
    base is DataType &&
    (base.baseType) is DataTypeReference &&
    (base.baseType as DataTypeReference).dataType.children.any(
      (c) => _matches(c, name: 'Unit', type: r'Generic\Equipment\sInterface'),
    ) &&
    (base.baseType as DataTypeReference).dataType.children.any(
      (c) => _matches(c, name: 'PackML', type: r'Generic\Equipment\sPackML'),
    );

bool _configMemberForUnitFilter(DataTypeBase base, String unitName) =>
    base is DataType && base.name == unitName;

bool _matches(
  DataTypeBase base, {
  required String name,
  required String type,
}) =>
    base.name == name &&
    base is DataType &&
    base.baseType is DataTypeReference &&
    (base.baseType as DataTypeReference).namePathWithBackSlashes
            .toLowerCase() ==
        type.toLowerCase();
