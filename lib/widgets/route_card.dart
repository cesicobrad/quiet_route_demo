import 'package:flutter/material.dart';

import '../theme/theme.dart';

class RouteCard extends StatelessWidget {
  final String destination;
  final int minutes;
  final int calmScore;

  const RouteCard({
    super.key,
    required this.destination,
    required this.minutes,
    required this.calmScore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quiet Route', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(destination, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(label: '$minutes min', color: CozyTheme.mint),
                const SizedBox(width: 8),
                _InfoChip(label: 'Calm $calmScore', color: CozyTheme.lavender),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Avoids busy crossings and leans toward quieter streets.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: CozyTheme.ink, fontWeight: FontWeight.w600),
      ),
    );
  }
}
