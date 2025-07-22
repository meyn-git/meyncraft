import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:meyncraft/meyncraft/logger/logger.infrastructure.dart';
import 'package:meyncraft/meyncraft/meyncraft.presentation.dart';

void main(List<String> args) {
  GetIt.I.registerSingleton<Logger>(Logger());
  runApp(MeynCraft(args));
}
