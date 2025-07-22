import 'package:flutter/material.dart';
import 'package:meyncraft/meyncraft/logger/logger.infrastructure.dart';

class LogView extends StatefulWidget {
  const LogView({super.key});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  @override
  void initState() {
    super.initState();
    logger.addListener(_onLogUpdate);
  }

  @override
  void dispose() {
    logger.removeListener(_onLogUpdate);
    super.dispose();
  }

  void _onLogUpdate() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Expanded(
        child: Container(
          padding: EdgeInsets.all(8),
          child: Scrollbar(
            child: ListView.builder(
              itemCount: logger.logs.length,
              itemBuilder: (context, index) {
                return Text(
                  logger.logs[index],
                  style: TextStyle(fontFamily: 'monospace'),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
