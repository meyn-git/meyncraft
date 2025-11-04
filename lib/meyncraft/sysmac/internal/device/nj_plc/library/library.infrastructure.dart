import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/function/function.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/function/function.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/function_block/function_block.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/library/library.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/nj_plc.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/function_block/function_block.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/program/program.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/project_index.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.infrastructure.dart';
import 'package:xml/xml.dart';

List<Library> createLibraries(
  SysmacProjectArchive sysmacProjectArchive,
  XmlElement deviceElement,
) {
  var libraryElements = getFilteredDescendingElements(
    deviceElement,
    include: isLibraryElement,
    // exclude: (e) =>
    //     isNestedLibraryElement(rootElement: deviceElement, element: e),
  );

  var libraries = libraryElements
      .map((e) => createLibrary(sysmacProjectArchive, e))
      .toList();

  return libraries;
}

bool isLibraryElement(XmlElement e) =>
    e.name.local == entity && e.getAttribute(typeAttribute) == 'Library';

bool isNestedLibraryElement({
  required XmlElement rootElement,
  required XmlElement element,
}) => rootElement != element && isLibraryElement(element);

Library createLibrary(
  SysmacProjectArchive sysmacProjectArchive,
  XmlElement libraryElement,
) {
  var name = libraryElement.getAttribute(nameAttribute)!;
  var libraries = createLibraries(sysmacProjectArchive, libraryElement);
  var programs = createPrograms(sysmacProjectArchive, libraryElement);
  var functions = createFunctions(sysmacProjectArchive, libraryElement);
  var functionBlocks = createFunctionBlocks(
    sysmacProjectArchive,
    libraryElement,
  );
  return Library(name, libraries, programs, functions, functionBlocks);
}
