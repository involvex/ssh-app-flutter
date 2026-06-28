import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:xterm/xterm.dart';

import '../providers/settings_provider.dart';

class TerminalStyleBuilder {
  static TextStyle buildTextStyle(SettingsProvider settings) {
    final fontWeight = switch (settings.terminalFontWeight) {
      TerminalFontWeight.normal => FontWeight.normal,
      TerminalFontWeight.medium => FontWeight.w500,
      TerminalFontWeight.semiBold => FontWeight.w600,
      TerminalFontWeight.bold => FontWeight.bold,
    };
    final fontStyle = settings.terminalFontStyle == TerminalFontStyle.italic
        ? FontStyle.italic
        : FontStyle.normal;

    final useGoogleFonts =
        settings.terminalFontWeight != TerminalFontWeight.normal ||
            settings.terminalFontStyle == TerminalFontStyle.italic;

    if (useGoogleFonts) {
      return GoogleFonts.jetBrainsMono(
        fontSize: settings.terminalFontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
      );
    }

    final fontFamily = switch (settings.terminalFontFamily) {
      TerminalFontFamily.monospace => 'monospace',
      TerminalFontFamily.courierNew => 'Courier New',
      TerminalFontFamily.consolas => 'Consolas',
      TerminalFontFamily.menlo => 'Menlo',
    };

    return TextStyle(
      fontSize: settings.terminalFontSize,
      fontFamily: fontFamily,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
    );
  }

  static TerminalStyle buildTerminalStyle(SettingsProvider settings) {
    final textStyle = buildTextStyle(settings);
    return TerminalStyle.fromTextStyle(textStyle);
  }
}
