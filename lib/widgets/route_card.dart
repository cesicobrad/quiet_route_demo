import 'package:flutter/material.dart';

import '../theme/theme.dart';

class RouteCard extends StatelessWidget {
  final String? destination;
  final int minutes;
  final int calmScore;
  final int consentCount;
  final bool isCalculating;
  final bool isPlaying;
  final VoidCallback onStart;

  const RouteCard({
    super.key,
    required this.destination,
    required this.minutes,
    required this.calmScore,
    required this.consentCount,
    required this.isCalculating,
    required this.isPlaying,
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
            if (isCalculating) ...[
              Text(
                'Calculating route…',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              const _ShimmerBar(),
            ] else if (destination != null && minutes > 0) ...[
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

class _ShimmerBar extends StatefulWidget {
  const _ShimmerBar();

  @override
  State<_ShimmerBar> createState() => _ShimmerBarState();
}

class _ShimmerBarState extends State<_ShimmerBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 8,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              color: CozyTheme.cream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Align(
                alignment: Alignment(-1 + (_controller.value * 2), 0),
                child: Container(
                  width: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        CozyTheme.lavender.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
