/// Utility extensions for List operations.
extension ListUtils<T> on List<T> {
  /// Returns the first element matching [test], or null if none found.
  ///
  /// Unlike [firstWhere], this does not throw if no element matches.
  /// Example:
  /// ```dart
  /// final user = users.firstWhereOrNull((u) => u.id == targetId);
  /// ```
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }

  /// Returns the single element matching [test], or null if none or multiple found.
  T? singleWhereOrNull(bool Function(T) test) {
    T? result;
    for (final element in this) {
      if (test(element)) {
        if (result != null) return null; // Multiple matches
        result = element;
      }
    }
    return result;
  }
}

extension IterableUtils<T> on Iterable<T> {
  /// Returns the first element matching [test], or null if none found.
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
