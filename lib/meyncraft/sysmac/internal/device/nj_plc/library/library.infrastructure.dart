import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/function/function.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/function_block/function_block.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/library/library.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/nj_plc.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/program/program.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/project_index.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.domain.dart';
import 'package:xml/xml.dart';

List<Library> createLibraries(
  SysmacProject sysmacProject,
  XmlElement deviceElement,
) {
  var libraryElements = getFilteredDescendingElements(
    deviceElement,
    include: isLibraryElement,
  );

  var libraries = libraryElements
      .map((e) => createLibrary(sysmacProject, e))
      .toList();

  return libraries;
}

bool isLibraryElement(XmlElement e) =>
    e.name.local == entity && e.getAttribute(typeAttribute) == 'Library';

bool isNestedLibraryElement({
  required XmlElement rootElement,
  required XmlElement element,
}) => rootElement != element && isLibraryElement(element);

Library createLibrary(SysmacProject sysmacProject, XmlElement libraryElement) {
  var name = libraryElement.getAttribute(nameAttribute)!;
  var libraries = createLibraries(sysmacProject, libraryElement);
  var programs = createPrograms(sysmacProject, libraryElement);
  var functions = createFunctions(sysmacProject, libraryElement);
  var functionBlocks = createFunctionBlocks(sysmacProject, libraryElement);
  return Library(name, libraries, programs, functions, functionBlocks);
}
