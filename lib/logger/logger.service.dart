import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

/// A simple logger that notifies listeners when a new log is added.
/// TODO support hyperlinks in logs
class Logger extends ChangeNotifier {
  bool _completed = false;
  final List<Message> _messages = [];

  List<Message> get messages => _messages;

  void info(String message, {bool unique = false}) {
    if (unique &&
        _messages.any(
          (m) => m.messageType == MessageType.info && m.text == message,
        )) {
      return;
    }
    _messages.add(Message.info(message));
    notifyListeners();
  }

  void warning(String message, {bool unique = false}) {
    if (unique &&
        _messages.any(
          (m) => m.messageType == MessageType.warning && m.text == message,
        )) {
      return;
    }
    _messages.add(Message.warning(message));
    notifyListeners();
  }

  set completed(bool value) {
    if (_completed == value || value == false) return;
    _completed = true;
    info('Completed');
    notifyListeners();
  }

  bool get completed => _completed;

  void clear() {
    _messages.clear();
    _completed = false;
    notifyListeners();
  }
}

Logger logger = GetIt.I<Logger>();

class Message {
  final String text;
  final MessageType messageType;

  Message.info(this.text) : messageType = MessageType.info;

  Message.warning(this.text) : messageType = MessageType.warning;
}

enum MessageType {
  info(infoColor),
  warning(warningColor);

  final Color Function(ThemeData themeData) colorFunction;
  const MessageType(this.colorFunction);

  static Color infoColor(ThemeData theme) => theme.colorScheme.onSurface;

  static Color warningColor(ThemeData theme) => Colors.orange;
}
