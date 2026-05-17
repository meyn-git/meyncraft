import 'package:package_info_plus/package_info_plus.dart';

Future<String> applicationVersion() async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
}

String aboutMeynCraftMarkdown({String? version}) {
  final markDown = StringBuffer();

  markDown.writeln('# MeynCraft');
  markDown.writeln();
  if (version != null) {
    markDown.writeln('Version: $version');
    markDown.writeln();
  }
  markDown.writeln(
    meynCraftCurrentDescription,
    //TODO use meynCraftFutureDescription when it is implemented as a template engine,
  );
  markDown.writeln();
  markDown.writeln('## More information');

  markDown.writeln(
    '* Documentation: '
    'https://github.com/meyn-git/meyncraft/blob/main/README.md',
  );
  markDown.writeln('* Project: https://github.com/meyn-git/meyncraft');
  markDown.writeln();
  return markDown.toString();
}

String get meynCraftCurrentDescription =>
    'MeynCraft is a file generator, that generates files based on a Sysmac project file.';

String get meynCraftFutureDescription =>
    'MeynCraft is a '
    '[template engine](https://en.wikipedia.org/wiki/Template_processor) '
    'that combines template files with input data to generate output files.\n'
    '\n'
    'Examples of input data:\n'
    '* Parameters provided by the user\n'
    '* Omron Sysmac project files\n'
    '* CSV files\n'
    '* JSON files\n'
    '* XML files\n'
    '\n'
    'Example of generated files:\n'
    '* Source code in any programming language\n'
    '* Configuration files\n'
    '* Documentation\n'
    '\n'
    'You are free to create (and share)your own templates and use MeynCraft to generate any kind of files you need. ';
