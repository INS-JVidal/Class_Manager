import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Shows a confirmation dialog and returns true if the user confirms.
///
/// Example:
/// ```dart
/// final confirmed = await showConfirmDialog(
///   context,
///   title: l10n.deleteGroup,
///   content: l10n.deleteGroupConfirm(groupName),
/// );
/// if (confirmed) {
///   // Perform deletion
/// }
/// ```
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String content,
  String? confirmText,
  String? cancelText,
  bool isDestructive = false,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final theme = Theme.of(context);

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelText ?? l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: isDestructive
              ? FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                )
              : null,
          child: Text(confirmText ?? l10n.delete),
        ),
      ],
    ),
  );

  return result ?? false;
}

/// Shows an informational dialog with a single OK button.
Future<void> showInfoDialog(
  BuildContext context, {
  required String title,
  required String content,
  String? okText,
}) async {
  final l10n = AppLocalizations.of(context)!;

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(okText ?? l10n.ok),
        ),
      ],
    ),
  );
}
