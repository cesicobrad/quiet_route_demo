import 'dart:math';

import 'package:flutter/material.dart';

import '../access_catalog.dart';
import '../privacy_copy.dart';
import '../state/demo_state.dart';
import '../theme/theme.dart';

class AccessCatalogScreen extends StatelessWidget {
  final DemoState demoState;
  final VoidCallback onClose;

  const AccessCatalogScreen({
    super.key,
    required this.demoState,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final total = AccessCatalog.items.length;
    final grantedCount = demoState.granted.length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = min(constraints.maxHeight * 0.75, 520.0);
        return Container(
          height: height,
          margin: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          decoration: BoxDecoration(
            color: CozyTheme.cream.withOpacity(0.97),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: CozyTheme.ink.withOpacity(0.18),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'System Overview',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded),
                    color: CozyTheme.muted,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Collected signals: $grantedCount / $total',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  itemCount: AccessCatalog.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = AccessCatalog.items[index];
                    final isGranted = demoState.granted.contains(item.id);
                    return Opacity(
                      opacity: isGranted ? 1 : 0.5,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: CozyTheme.ink.withOpacity(0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isGranted
                                    ? CozyTheme.mint.withOpacity(0.4)
                                    : CozyTheme.lavender.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isGranted
                                    ? Icons.check_rounded
                                    : Icons.lock_outline_rounded,
                                color: CozyTheme.ink,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.shortDescription,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  PrivacyCopy.patternFooter(demoState.currentPhase),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
