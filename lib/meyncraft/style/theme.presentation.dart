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
      useMaterial3: true,
      colorScheme:
          ColorScheme.fromSwatch(
            primarySwatch: meynPrimary,
            accentColor: meynAccent,
            brightness: brightness,
          ).copyWith(
            surface: brightness == Brightness.light
                ? Colors.white
                : Colors.black,
          ),
    ).copyWith(
      // make focus more apparent
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.all(
            Colors.white.withValues(alpha: 0.3),
          ), // Ripple effect color
        ),
      ),
      
    );
