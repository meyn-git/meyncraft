import 'package:flutter/material.dart';

const MaterialColor meynPrimary = MaterialColor(
  0xFF00B207, // RGB(0, 178, 7)
  <int, Color>{
    50: Color(0xFFE6F7E6),
    100: Color(0xFFCCF0CD),
    200: Color(0xFF99E09C),
    300: Color(0xFF66D16A),
    400: Color(0xFF33C139),
    500: Color(0xFF00B207),
    600: Color(0xFF00A006),
    700: Color(0xFF008E06),
    800: Color(0xFF007D05),
    900: Color(0xFF006B04),
  },
);

const Color meynAccent = Color(0xFFFF00BF);

ThemeData meynTheme(Brightness brightness) =>
    ThemeData.from(
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: meynPrimary,
        accentColor: meynAccent,
        brightness: brightness,
      ),
    ).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: meynPrimary, // Use your primary color here
        foregroundColor: Colors.white, // Optional: sets text/icon color
      ),
    );
