import 'dart:io';

class TestResource {
  final File file;

  TestResource(String pathRelativeToTest) : file = findFile(pathRelativeToTest);

  static File findFile(String pathRelativeToTestDirectory) {
    String path =
        "${findProjectRootDirectory().path}${Platform.pathSeparator}test${Platform.pathSeparator}$pathRelativeToTestDirectory";
    return File(path);
  }

  static Directory findProjectRootDirectory() {
    var directory = Directory.current;
    while (true) {
      if (_containsPubSpec(directory)) {
        return directory;
      }
      var parent = directory.parent;
      if (directory == parent) {
        throw Exception('Could not find project root directory.');
      }
      directory = parent;
    }
  }

  static bool _containsPubSpec(Directory directory) =>
      directory.listSync().any((FileSystemEntity entity) =>
          entity is File && entity.path.endsWith('pubspec.yaml'));
}

class SysmacProjectTestResource extends TestResource {
  SysmacProjectTestResource()
      : super('4321DE06-Evisceration-001-005_not_installed.smc2');
}
