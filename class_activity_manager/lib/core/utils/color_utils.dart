import 'dart:ui';

/// Regex that matches valid 6 or 8 character hex color strings.
final _hexPattern = RegExp(r'^#?([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$');

/// Utility extension for color conversion from hex strings.
extension HexColorExtension on String {
  /// Converts a hex color string (e.g., '#4CAF50' or '4CAF50') to a Color.
  ///
  /// Supports 6-character hex codes (RGB) and 8-character codes (ARGB).
  /// For 6-character codes, full opacity (FF) is assumed.
  /// Returns a fallback color (grey) if the input is not a valid hex string.
  Color toColor([Color fallback = const Color(0xFF9E9E9E)]) {
    final hex = replaceFirst('#', '');
    if (!_hexPattern.hasMatch(this)) return fallback;
    final buffer = StringBuffer();
    if (hex.length == 6) buffer.write('FF');
    buffer.write(hex);
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

/// Standalone function for hex to color conversion.
///
/// Use this when you need a function reference or prefer not to use extensions.
Color hexToColor(String hex) => hex.toColor();
