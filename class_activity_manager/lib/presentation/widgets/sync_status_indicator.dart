import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/cache_service.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';

/// Widget that displays the current sync status as a simple LED-style dot.
/// - Green: online
/// - Amber: offline
/// - Red: error
class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  static const double _dotSize = 10.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(cacheStatusProvider);

    return statusAsync.when(
      data: (status) => _buildDot(context, status),
      loading: () => _buildDot(context, null),
      error: (_, _) => _buildErrorDot(context),
    );
  }

  Widget _buildDot(BuildContext context, CacheStatus? status) {
    final l10n = AppLocalizations.of(context)!;
    final isOnline = status == CacheStatus.online;
    final color = isOnline ? Colors.green : Colors.amber;
    final label = isOnline ? l10n.syncStatusOnline : l10n.syncStatusOffline;

    return InkWell(
      onTap: () => _showOfflineInfo(context),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _dotSize,
              height: _dotSize,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorDot(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: () => _showOfflineInfo(context),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _dotSize,
              height: _dotSize,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              l10n.connectionError,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  void _showOfflineInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.cloud_off, color: Colors.orange),
            const SizedBox(width: 8),
            Text(l10n.offlineMode),
          ],
        ),
        content: Text(l10n.offlineModeMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.understood),
          ),
        ],
      ),
    );
  }
}
