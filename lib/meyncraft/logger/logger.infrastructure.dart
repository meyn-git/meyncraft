import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

/// A simple logger that notifies listeners when a new log is added.
/// TODO support hyperlinks in logs
/// TODO support colors in logs
class Logger extends ChangeNotifier {
  final List<String> _logs = [];

  List<String> get logs => _logs;

  void info(String message) {
    _logs.add(message);
    notifyListeners();
  }
}

Logger logger = GetIt.I<Logger>();
