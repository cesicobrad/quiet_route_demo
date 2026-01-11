import 'package:flutter/material.dart';

import '../theme/theme.dart';

class TopBar extends StatelessWidget {
  final VoidCallback onSystemOverview;
  final VoidCallback onDestinations;

  const TopBar({
    super.key,
    required this.onSystemOverview,
    required this.onDestinations,
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
          Container(
            decoration: BoxDecoration(
              color: CozyTheme.peach.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: CozyTheme.ink.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.tune_rounded),
              color: CozyTheme.ink,
              onPressed: onSystemOverview,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: CozyTheme.ink.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: CozyTheme.ink,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              icon: const Icon(Icons.place_outlined, size: 18),
              onPressed: onDestinations,
              label: const Text('Destinations'),
            ),
          ),
        ],
      ),
    );
  }
}
