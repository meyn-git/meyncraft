import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/meyncraft/logger/logger.service.dart';
import 'package:meyncraft/meyncraft/meyncraft.presentation.dart';
import 'package:window_manager/window_manager.dart';


void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  // Must add this line.
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = WindowOptions(
    size: Size(1200, 600),
    center: true,
    title: 'MeynCraft',
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
        /// Maximize the window on start see: https://stackoverflow.com/questions/66149486/set-desktop-flutter-to-run-in-maximized-size-at-startup (replace SW_SHOWNORMAL with SW_SHOWMAXIMIZED) in win32_window.cpp
  });

  GetIt.I.registerSingleton<Logger>(Logger());
  runApp(MeynCraft(args));
}
