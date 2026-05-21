import 'package:flutter/material.dart';
import 'package:meyncraft/meyncraft/command.domain.dart';

class ElevatedCommandButton extends StatelessWidget {
  final Command command;

  const ElevatedCommandButton(this.command, {super.key});

  @override
  Widget build(BuildContext context) => Tooltip(
    message: command.toolTip,
    child: ElevatedButton(onPressed: command.action, child: Text(command.name)),
  );
}
