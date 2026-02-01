import 'dart:ui';

/// Utility extension for color conversion from hex strings.
extension HexColorExtension on String {
  /// Converts a hex color string (e.g., '#4CAF50' or '4CAF50') to a Color.
  ///
  /// Supports 6-character hex codes (RGB) and 8-character codes (ARGB).
  /// For 6-character codes, full opacity (FF) is assumed.
  Color toColor() {
    final buffer = StringBuffer();
    final hex = replaceFirst('#', '');
    if (hex.length == 6) buffer.write('FF');
    buffer.write(hex);
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

/// Standalone function for hex to color conversion.
///
/// Use this when you need a function reference or prefer not to use extensions.
Color hexToColor(String hex) => hex.toColor();
