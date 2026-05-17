import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class MeynMarkdownStyleSheet extends MarkdownStyleSheet {
  MeynMarkdownStyleSheet(BuildContext context)
    : super(
        h1Padding: EdgeInsets.fromLTRB(0, 12, 0, 6),
        h2Padding: EdgeInsets.fromLTRB(0, 12, 0, 0),
        h1: Theme.of(context).textTheme.headlineLarge,
        h2: Theme.of(context).textTheme.headlineMedium,
        a: TextStyle(color: Theme.of(context).colorScheme.secondary),
      );
}
