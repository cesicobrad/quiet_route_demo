import 'package:flutter/material.dart';

import 'theme/theme.dart';

class ScreenPinnedGpsPip extends StatefulWidget {
  const ScreenPinnedGpsPip({super.key});

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
        final pulse = Curves.easeInOut.transform(_controller.value);
        final haloSize = 52 + (pulse * 10);
        final shimmerOpacity = 0.35 + (0.2 * (1 - pulse));
        return SizedBox(
          width: haloSize,
          height: haloSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: haloSize,
                height: haloSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CozyTheme.lavender.withOpacity(shimmerOpacity),
                  boxShadow: [
                    BoxShadow(
                      color: CozyTheme.mint.withOpacity(0.35),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
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
                      color: CozyTheme.ink.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
