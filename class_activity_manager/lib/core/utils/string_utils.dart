/// Utility extensions for String operations.
extension StringUtils on String? {
  /// Returns the trimmed string if non-empty, or null otherwise.
  ///
  /// Useful for form validation where empty strings should be treated as null.
  /// Example:
  /// ```dart
  /// final notes = notesController.text.trimOrNull();
  /// // Returns null if text is empty or whitespace-only
  /// ```
  String? trimOrNull() {
    if (this == null) return null;
    final trimmed = this!.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

extension NonNullStringUtils on String {
  /// Returns the trimmed string if non-empty, or null otherwise.
  String? trimOrNullIfEmpty() {
    final trimmed = trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
