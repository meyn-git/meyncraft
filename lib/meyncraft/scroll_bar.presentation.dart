import 'package:flutter/material.dart';

class ScrollbarAlwaysVisible extends StatefulWidget {
  final Widget child;

  const ScrollbarAlwaysVisible({super.key, required this.child});

  @override
  State<ScrollbarAlwaysVisible> createState() => _ScrollbarAlwaysVisibleState();
}

class _ScrollbarAlwaysVisibleState extends State<ScrollbarAlwaysVisible> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose(); // avoid memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _controller,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _controller,
        child: widget.child,
      ),
    );
  }
}
