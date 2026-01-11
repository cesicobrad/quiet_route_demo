import 'package:flutter/material.dart';

import '../theme/theme.dart';

class CozyTopBar extends StatelessWidget {
  final VoidCallback onSettings;
  final VoidCallback? onDestinations;

  const CozyTopBar({
    super.key,
    required this.onSettings,
    this.onDestinations,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quiet Route', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text('Choose calm over speed.', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          if (onDestinations != null) ...[
            TextButton.icon(
              onPressed: onDestinations,
              style: TextButton.styleFrom(
                foregroundColor: CozyTheme.ink,
                backgroundColor: CozyTheme.cream,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.search_rounded, size: 18),
              label: const Text('Destinations'),
            ),
            const SizedBox(width: 10),
          ],
          Container(
            decoration: BoxDecoration(
              color: CozyTheme.peach.withOpacity(0.6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              icon: const Icon(Icons.settings_rounded),
              color: CozyTheme.ink,
              onPressed: onSettings,
            ),
          ),
        ],
      ),
    );
  }
}
