import 'package:meyncraft/meyncraft/sysmac/internal/device/device.domain.dart';
import 'package:meyncraft/meyncraft/sysmac/internal/device/nj_plc/nj_plc.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/project_index.infrastructure.dart';
import 'package:meyncraft/meyncraft/sysmac/sysmac_project.infrastructure.dart';
import 'package:xml/xml.dart';

List<Device> createDevices(SysmacProjectArchive sysmacProjectArchive) =>
    sysmacProjectArchive.projectIndexXml.xmlDocument.descendantElements
        .where(
          (e) =>
              e.name.local == entity &&
              e.getAttribute(typeAttribute) == 'Device',
        )
        .map((e) => _createDevice(sysmacProjectArchive, e))
        .whereType<Device>() // remove nulls
        .toList();

Device? _createDevice(
  SysmacProjectArchive sysmacProjectArchive,
  XmlElement deviceElement,
) {
  var type = deviceElement.getAttribute(subTypeAttribute)!;
  if (type.startsWith('NJ')) {
    return createNjPlc(sysmacProjectArchive, deviceElement);
  }
  if (type == "NES") {
    return createNesSafetyPlc(deviceElement);
  }
  if (type == "NA") {
    return createNaHmi(deviceElement);
  }
  print('Unknown device type: $type');
  return null;
}

NesSafetyPlc createNesSafetyPlc(XmlElement deviceElement) {
  var name = deviceElement.getAttribute(nameAttribute)!;
  var type = deviceElement.getAttribute(subTypeAttribute)!;
  return NesSafetyPlc(name: name, type: type);
}

NaHmi createNaHmi(XmlElement deviceElement) {
  var name = deviceElement.getAttribute(nameAttribute)!;
  var type = deviceElement.getAttribute(subTypeAttribute)!;
  return NaHmi(name: name, type: type);
}
