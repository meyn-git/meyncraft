import 'package:desktop_window/desktop_window.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyn_sysmac/meyn_sysmac_project.service.dart';
import 'package:meyncraft/meyncraft/meyncraft.presentation.dart';
import 'package:meyncraft/meyncraft/about/meyncraft_about_tab.presentation.dart';
import 'package:meyncraft/template/selected_templates.service.dart';
import 'package:meyncraft/meyncraft/tab/tab.service.dart';
import 'package:window_manager/window_manager.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  // // Must add this line.
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = WindowOptions(
    //size: Size(1200, 600),
    //fullScreen: true,
    windowButtonVisibility: true,
    //center: true,
    title: 'MeynCraft',
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await DesktopWindow.setFullScreen(true); //Best option for maximizing window
    /// Maximize the window on start see: https://stackoverflow.com/questions/66149486/set-desktop-flutter-to-run-in-maximized-size-at-startup (replace SW_SHOWNORMAL with SW_SHOWMAXIMIZED) in win32_window.cpp
  });

  final getIt = GetIt.instance;
  getIt.registerSingleton<Logger>(Logger());
  getIt.registerSingleton<SelectedTemplateService>(SelectedTemplateService());
  getIt.registerSingleton<MeynSysmacProjectService>(MeynSysmacProjectService());
  getIt.registerSingleton<TabService>(TabService());
  // TODO add later when there are many templates getIt.get<TabService>().addTab(AllTemplatesTab());
  final aboutTab = await MeynCraftAboutTab.create();
  getIt.get<TabService>().addTab(aboutTab);
  getIt.get<TabService>().selectTab(0);
  runApp(MeynCraft(args));
}
