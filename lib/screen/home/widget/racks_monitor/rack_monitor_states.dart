import 'package:flutter/material.dart';

import 'rack_list_filter.dart';

class RackEmptyState extends StatelessWidget {
  const RackEmptyState({
    required this.mode,
    required this.onRefresh,
    super.key,
  });

  final RackListFilter mode;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    late final Color accent;
    late final IconData icon;
    late final String title;
    late final String subtitle;

    switch (mode) {
      case RackListFilter.all:
        accent = const Color(0xFF1E88E5);
        icon = Icons.storage_rounded;
        title = 'No racks to show';
        subtitle =
            'Try adjusting the filters or refresh to pull the latest rack status.';
        break;
      case RackListFilter.online:
        accent = const Color(0xFF20C25D);
        icon = Icons.cloud_done_rounded;
        title = 'No online racks';
        subtitle =
            'All racks that match your filters are currently offline.';
        break;
      case RackListFilter.offline:
        accent = const Color(0xFFE53935);
        icon = Icons.cloud_off_rounded;
        title = 'No offline racks';
        subtitle =
            'Great! Every rack that matches your filters is online right now.';
        break;
    }

    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accent.withOpacity(0.35)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 52, color: accent),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RackErrorState extends StatelessWidget {
  const RackErrorState({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  'Unable to load racks',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
