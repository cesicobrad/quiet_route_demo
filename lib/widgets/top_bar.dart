import 'package:flutter/material.dart';

import '../theme/theme.dart';

class TopBar extends StatelessWidget {
  final VoidCallback onSystemPressed;
  final VoidCallback onDestinations;
  final int collectedSignals;

  const TopBar({
    super.key,
    required this.onSystemPressed,
    required this.onDestinations,
    required this.collectedSignals,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Text('Quiet Route', style: theme.textTheme.titleLarge),
          ),
          _IconButton(
            icon: Icons.place_outlined,
            onPressed: onDestinations,
          ),
          const SizedBox(width: 10),
          _BadgeIconButton(
            icon: Icons.tune_rounded,
            onPressed: onSystemPressed,
            badgeValue: collectedSignals,
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _IconButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: IconButton(
        icon: Icon(icon),
        color: CozyTheme.ink,
        onPressed: onPressed,
      ),
    );
  }
}

class _BadgeIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final int badgeValue;

  const _BadgeIconButton({
    required this.icon,
    required this.onPressed,
    required this.badgeValue,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _IconButton(icon: icon, onPressed: onPressed),
        if (badgeValue > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: CozyTheme.peach,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: CozyTheme.ink.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                badgeValue.toString(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: CozyTheme.ink,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}
