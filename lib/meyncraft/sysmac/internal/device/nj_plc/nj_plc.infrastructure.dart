import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/function/function.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/function_block/function_block.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/library/library.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/nj_plc.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/program/program.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/project_index.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.infrastructure.dart';
import 'package:xml/xml.dart';

NjPlc createNjPlc(
  SysmacProjectArchive sysmacProjectArchive,
  XmlElement deviceElement,
) {
  var name = deviceElement.getAttribute(nameAttribute)!;
  var type = deviceElement.getAttribute(subTypeAttribute)!;
  var libraries = createLibraries(sysmacProjectArchive, deviceElement);
  var programs = createPrograms(sysmacProjectArchive, deviceElement);
  var functions = createFunctions(sysmacProjectArchive, deviceElement);
  var functionBlocks = <FunctionBlock>[]; //TODO
  return NjPlc(
    name: name,
    type: type,
    libraries: libraries,
    programs: programs,
    functions: functions,
    functionBlocks: functionBlocks,
  );
}

/// Finds all descendingElements that match filter [include].
/// Note that:
/// * children of included elements are ignored
/// * elements that match [exclude] are ignored, including its subtree
List<XmlElement> getFilteredDescendingElements(
  XmlElement element, {
  required bool Function(XmlElement) include,
  bool Function(XmlElement) exclude = isNeverExcluded,
}) {
  List<XmlElement> found = [];
  for (final child in element.childElements) {
    if (exclude(child)) {
      continue; // Skip this child and its subtree
    }
    if (include(child)) {
      found.add(child);
    } else {
      found.addAll(
        //recursive call
        getFilteredDescendingElements(
          child,
          include: include,
          exclude: exclude,
        ),
      );
    }
  }

  return found;
}

bool isNeverExcluded(e) => false;
