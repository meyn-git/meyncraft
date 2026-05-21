import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/meyncraft/about/meyncraft_about_tab.presentation.dart';
import 'package:meyncraft/meyncraft/tab/tab.service.dart';
import 'package:meyncraft/template/generate/generator.service.dart';
import 'package:meyncraft/template/generate/generator_parameter_tab.presentation.dart';
import 'package:meyncraft/template/generate/generator_report.domain.dart';
import 'package:meyncraft/template/generate/generator_result_tab.presentation.dart';
import 'package:meyncraft/template/selected_templates.presentation.dart';
import 'package:meyncraft/template/selected_templates.service.dart';
import 'package:meyncraft/template/template.domain.dart';

abstract class Command extends Intent {
  SingleActivator? get hotKey;

  /// The name on the button and in the menu
  String get name;

  /// override this to provide a more detailed description, e.g. for tooltips
  String get description => name;

  /// Description with the hotkey for display in tooltips
  String get toolTip =>
      '$description${hotKey == null ? '' : ' (${hotKey!.toShortcutString()})'}';

  void Function() get action;
}

extension SingleActivatorX on SingleActivator {
  String toShortcutString() => <String>[
    if (control) 'Control',
    if (alt) 'Alt',
    if (meta) 'Meta',
    if (shift) 'Shift',
    _keyLabel(trigger),
  ].join('+');

  String _keyLabel(LogicalKeyboardKey key) {
    var specialKeys = {
      LogicalKeyboardKey.enter: 'Enter',
      LogicalKeyboardKey.escape: 'Esc',
      LogicalKeyboardKey.space: 'Space',
      LogicalKeyboardKey.tab: 'Tab',
      LogicalKeyboardKey.backspace: 'Backspace',
      LogicalKeyboardKey.delete: 'Del',
    };

    if (specialKeys.containsKey(key)) {
      return specialKeys[key]!;
    }

    // Prefer keyLabel if meaningful
    if (key.keyLabel.isNotEmpty) {
      return key.keyLabel.toUpperCase();
    }

    return key.keyId.toString();
  }
}

class SelectNextTab extends Command {
  @override
  final hotKey = const SingleActivator(LogicalKeyboardKey.tab, control: true);

  @override
  final name = 'Select next tab';

  @override
  void Function() get action => () {
    GetIt.I.get<TabService>().selectNextTab();
  };
}

class SelectPreviousTab extends Command {
  @override
  final hotKey = const SingleActivator(
    LogicalKeyboardKey.tab,
    control: true,
    shift: true,
  );

  @override
  final name = 'Select precious tab';

  @override
  void Function() get action => () {
    GetIt.I.get<TabService>().selectPreviousTab();
  };
}

class CloseCurrentTab extends Command {
  @override
  final hotKey = const SingleActivator(LogicalKeyboardKey.f4, control: true);

  @override
  final String name = 'Close';

  @override
  final String description = 'Close the current tab';

  @override
  void Function() get action => () {
    GetIt.I.get<TabService>().closeCurrentTab();
  };
}

class CloseAllTabs extends Command {
  @override
  final hotKey = const SingleActivator(
    LogicalKeyboardKey.f4,
    control: true,
    shift: true,
  );

  @override
  String get name => 'Close all tabs';

  @override
  void Function() get action => () {
    GetIt.I.get<TabService>().closeAllTabs();
  };
}

class Generate extends Command {
  @override
  final hotKey = const SingleActivator(LogicalKeyboardKey.keyG, control: true);

  @override
  final name = 'Generate';

  @override
  final String description = 'Generate using the selected templates';

  @override
  void Function() get action => () async {
    var selectedTemplateService = GetIt.I.get<SelectedTemplateService>();
    var selectedTemplates = selectedTemplateService.selectedTemplates;
    if (selectedTemplates.isEmpty) {
      return;
    }
    var parameters = selectedTemplates.expand((t) => t.parameters).toSet();
    if (parameters.isEmpty) {
      return;
    }
    if (parameters.length == 1 &&
        parameters.first.name == sysmacProjectFileParameter.name) {
      await selectSysmacFileAndGenerate(selectedTemplates);
    } else {
      var tabService = GetIt.I.get<TabService>();
      tabService.addTab(
        GeneratorParametersTab(templatesToGenerate: selectedTemplates),
      );
    }
  };
}

class ReGenerate extends Command {
  @override
  final hotKey = const SingleActivator(LogicalKeyboardKey.keyR, control: true);

  @override
  final name = 'Re-generate';

  @override
  final String description =
      'Re-generate the same templates with the same parameters';

  @override
  void Function() get action => () async {
    var tabService = GetIt.I.get<TabService>();
    var currentTab = tabService.currentTab();
    if (currentTab is! GeneratorResultTab) return;

    var previousGeneratorResultTab = currentTab;
    var selectedTemplates = previousGeneratorResultTab.selectedTemplates;
    var parameterValues = previousGeneratorResultTab.parameterValues;
    tabService.closeCurrentTab();

    var generatorResultTab = GeneratorResultTab(
      selectedTemplates,
      parameterValues,
    );
    tabService.addTab(generatorResultTab);

    await generate(
      selectedTemplates,
      parameterValues,
      generatorResultTab.content as GeneratorReport,
    );
  };
}

class OpenMeynAboutCraftTab extends Command {
  @override
  final hotKey = const SingleActivator(LogicalKeyboardKey.f1);

  @override
  final String name = 'About MeynCraft';

  @override
  final String description =
      'Open the MeynCraft about tab for more information.';

  @override
  void Function() get action => () async {
    var tabService = GetIt.I.get<TabService>();
    var aboutTab = await MeynCraftAboutTab.create();
    tabService.addOrSelectTab(aboutTab);
  };
}
