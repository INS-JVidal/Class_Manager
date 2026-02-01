import 'package:flutter/material.dart';

/// A card widget displaying an empty or informational state.
///
/// Use this for consistent "no data" or informational messages across the app.
///
/// Example:
/// ```dart
/// if (items.isEmpty)
///   EmptyStateCard(
///     message: l10n.noItems,
///     icon: Icons.inbox_outlined,
///   )
/// ```
class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.action,
    this.actionLabel,
    this.onAction,
  });

  /// The message to display.
  final String message;

  /// The icon to display (defaults to info_outline).
  final IconData icon;

  /// Optional widget to display as an action (e.g., a button).
  final Widget? action;

  /// Optional action button label. If provided along with [onAction],
  /// a default TextButton will be rendered.
  final String? actionLabel;

  /// Callback for the action button.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
            if (action != null) action!,
            if (action == null && actionLabel != null && onAction != null)
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ),
      ),
    );
  }
}

/// A centered empty state for full-page or expanded areas.
///
/// Example:
/// ```dart
/// Expanded(
///   child: EmptyStatePlaceholder(
///     icon: Icons.event_available,
///     message: l10n.noSessionsScheduled,
///   ),
/// )
/// ```
class EmptyStatePlaceholder extends StatelessWidget {
  const EmptyStatePlaceholder({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.iconSize = 48,
  });

  final String message;
  final IconData icon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: theme.colorScheme.outline),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
