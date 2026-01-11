import 'package:flutter/material.dart';

import '../theme/theme.dart';

class RouteCard extends StatelessWidget {
  final String? destination;
  final int minutes;
  final int calmScore;
  final int consentCount;
  final bool isCalculating;
  final bool isPlaying;
  final String? statusText;
  final VoidCallback onStart;

  const RouteCard({
    super.key,
    required this.destination,
    required this.minutes,
    required this.calmScore,
    required this.consentCount,
    required this.isCalculating,
    required this.isPlaying,
    required this.statusText,
    required this.onStart,
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Quiet Route', style: theme.textTheme.titleMedium),
                ),
                _ConsentChip(value: consentCount),
              ],
            ),
            const SizedBox(height: 8),
            if (destination != null && minutes > 0) ...[
              Text(destination!, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(label: '$minutes min', color: CozyTheme.mint),
                  _InfoChip(label: 'Calm $calmScore', color: CozyTheme.lavender),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Quiet Route • $minutes min • Calm $calmScore',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: CozyTheme.muted,
                ),
              ),
            ] else ...[
              Text(
                'Plan a quiet path across the city.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 10),
            _StatusLine(text: statusText, showSpinner: isCalculating),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: CozyTheme.ink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: isPlaying ? null : onStart,
                child: Text(isPlaying ? 'Running' : 'Start route'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  final String? text;
  final bool showSpinner;

  const _StatusLine({
    required this.text,
    required this.showSpinner,
  });

  @override
  Widget build(BuildContext context) {
    if (text == null && !showSpinner) {
      return const SizedBox(height: 18);
    }
    return Row(
      children: [
        if (showSpinner)
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        if (showSpinner) const SizedBox(width: 8),
        Expanded(
          child: Text(
            text ?? 'Updating route…',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: CozyTheme.muted),
          ),
        ),
      ],
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

class _ConsentChip extends StatelessWidget {
  final int value;

  const _ConsentChip({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: CozyTheme.cream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'Consent: $value/∞',
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: CozyTheme.ink),
      ),
    );
  }
}
