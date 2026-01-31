import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/cache_service.dart';
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
    final isOnline = status == CacheStatus.online;
    final color = isOnline ? Colors.green : Colors.amber;
    final label = isOnline ? 'online' : 'local';

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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorDot(BuildContext context) {
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
              'error',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOfflineInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud_off, color: Colors.orange),
            SizedBox(width: 8),
            Text('Mode offline'),
          ],
        ),
        content: const Text(
          'L\'aplicació funciona sense connexió a MongoDB.\n\n'
          'Els canvis es guarden localment i es sincronitzaran '
          'automàticament quan es restableixi la connexió.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entesos'),
          ),
        ],
      ),
    );
  }
}
