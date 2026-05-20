import 'dart:io';

import 'package:meyncraft/meyn_sysmac/meyn_sysmac_project.domain.dart';
import 'package:meyncraft/template/template.domain.dart';

/// Creates a [MeynSysmacProject] or returns a cached instance if the same file path is requested again.
class MeynSysmacProjectService {
  MeynSysmacProjectService._internal();

  static final MeynSysmacProjectService _instance =
      MeynSysmacProjectService._internal();

  factory MeynSysmacProjectService() => _instance;

  final Map<FileKey, MeynSysmacProject> _cache = {};

  Future<MeynSysmacProject> getProject(
    Map<String, dynamic> parameterValues,
  ) async {
    var sysmacProjectFilePath =
        parameterValues[sysmacProjectFileParameter.name];
    if (sysmacProjectFilePath == null ||
        sysmacProjectFilePath is! String ||
        sysmacProjectFilePath.isEmpty) {
      throw Exception('Missing parameter: ${sysmacProjectFileParameter.name}');
    }

    var file = File(sysmacProjectFilePath);
    var fileKey = FileKey.fromFile(file);

    if (_cache.containsKey(fileKey)) {
      return _cache[fileKey]!;
    } else {
      var projectFuture = await MeynSysmacProject.loadFromFile(file);
      _cache[fileKey] = projectFuture;
      return projectFuture;
    }
  }
}

class FileKey {
  final String path;
  final int size;
  final DateTime lastModified;

  const FileKey({
    required this.path,
    required this.size,
    required this.lastModified,
  });

  factory FileKey.fromFile(File file) {
    final stat = file.statSync();
    return FileKey(
      path: file.path,
      size: stat.size,
      lastModified: stat.modified,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FileKey &&
      path == other.path &&
      size == other.size &&
      lastModified == other.lastModified;

  @override
  int get hashCode => Object.hash(path, size, lastModified);
}
