class Warning {
  final String message;

  Warning(this.message);

  Warning.fromException(Exception exception) : message = exception.toString();
}
