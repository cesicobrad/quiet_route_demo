import 'package:flutter/material.dart';

import '../theme/theme.dart';

class ScreenPinnedGpsPip extends StatefulWidget {
  final bool showTwin;
  final double twinOpacity;

  const ScreenPinnedGpsPip({
    super.key,
    required this.showTwin,
    required this.twinOpacity,
  });

  @override
  State<ScreenPinnedGpsPip> createState() => _ScreenPinnedGpsPipState();
}

class _ScreenPinnedGpsPipState extends State<ScreenPinnedGpsPip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final pulse = 1 + (_controller.value * 0.25);
        final opacity = 0.2 + (_controller.value * 0.2);
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: pulse,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CozyTheme.mint.withOpacity(opacity),
                ),
              ),
            ),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CozyTheme.mint,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: CozyTheme.ink.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
            if (widget.showTwin)
              Positioned(
                left: 18,
                top: -34,
                child: Opacity(
                  opacity: widget.twinOpacity,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: CozyTheme.ink.withOpacity(0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_outline, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Twin',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
