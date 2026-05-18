import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/meyncraft/about/meyncraft_about_tab.presentation.dart';
import 'package:meyncraft/meyncraft/tab/markdown_tab.presentation.dart';
import 'package:meyncraft/meyncraft/tab/tab.service.dart';
import 'package:meyncraft/template/generate/generator.service.dart';
import 'package:meyncraft/template/generate/generator_parameter_tab.presentation.dart';
import 'package:meyncraft/template/generate/generator_result_tab.presentation.dart';
import 'package:meyncraft/template/selected_templates.presentation.dart';
import 'package:meyncraft/template/selected_templates.service.dart';
import 'package:meyncraft/template/template.domain.dart';

abstract class Command extends Intent {
  const Command();

  SingleActivator? get hotKey;
  String? get hotKeyText =>
      hotKey?.debugDescribeKeys().replaceAll(' ', '').replaceAll('Key', '');

  String get text;

  String get descriptionWithHotkey =>
      '$text${hotKey == null ? '' : ' ($hotKeyText)'}';

  void Function() get action;
}

class SelectNextTab extends Command {
  const SelectNextTab();

  @override
  final hotKey = const SingleActivator(LogicalKeyboardKey.tab, control: true);

  @override
  final text = 'Select next tab';

  @override
  void Function() get action => () {
    GetIt.I.get<TabService>().selectNextTab();
  };
}

class SelectPreviousTab extends Command {
  const SelectPreviousTab();

  @override
  final hotKey = const SingleActivator(
    LogicalKeyboardKey.tab,
    control: true,
    shift: true,
  );

  @override
  final text = 'Select precious tab';

  @override
  void Function() get action => () {
    GetIt.I.get<TabService>().selectPreviousTab();
  };
}

class CloseCurrentTab extends Command {
  const CloseCurrentTab();

  @override
  final hotKey = const SingleActivator(LogicalKeyboardKey.f4, control: true);

  @override
  String get text => 'Close tab';
  @override
  void Function() get action => () {
    GetIt.I.get<TabService>().closeCurrentTab();
  };
}

class CloseAllTabs extends Command {
  const CloseAllTabs();

  @override
  final hotKey = const SingleActivator(
    LogicalKeyboardKey.f4,
    control: true,
    shift: true,
  );

  @override
  String get text => 'Close all tabs';
  @override
  void Function() get action => () {
    GetIt.I.get<TabService>().closeAllTabs();
  };
}

class Generate extends Command {
  const Generate();
  @override
  final hotKey = const SingleActivator(LogicalKeyboardKey.keyG, control: true);

  @override
  final text = 'Generate';

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
  const ReGenerate();
  @override
  final hotKey = const SingleActivator(LogicalKeyboardKey.keyR, control: true);

  @override
  final text = 'Re-generate';

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
      generatorResultTab.content as DynamicMarkdownTabContent,
    );
  };
}

class OpenMeynAboutCraftTab extends Command {
  const OpenMeynAboutCraftTab();
  @override
  void Function() get action => () {
    var tabService = GetIt.I.get<TabService>();
    tabService.addOrSelectTab(MeynCraftAboutTab());
  };

  @override
  final hotKey = const SingleActivator(LogicalKeyboardKey.f1);

  @override
  final String text = 'Open MeynCraft about tab';
}
