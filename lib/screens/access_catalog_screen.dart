import 'package:flutter/material.dart';

import '../access_catalog.dart';
import '../privacy_copy.dart';
import '../state/demo_state.dart';
import '../theme/theme.dart';

class AccessCatalogScreen extends StatelessWidget {
  final DemoState demoState;

  const AccessCatalogScreen({
    super.key,
    required this.demoState,
  });

  @override
  Widget build(BuildContext context) {
    final total = AccessCatalog.items.length;
    final grantedCount = demoState.granted.length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Catalog'),
        backgroundColor: CozyTheme.cream,
        elevation: 0,
        foregroundColor: CozyTheme.ink,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Text(
                    'Collected signals: $grantedCount / $total',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: AccessCatalog.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = AccessCatalog.items[index];
                  final isGranted = demoState.granted.contains(item.id);
                  return Opacity(
                    opacity: isGranted ? 1 : 0.45,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: CozyTheme.ink.withOpacity(0.04),
                            blurRadius: 10,
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
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.shortDescription,
                                  style:
                                      Theme.of(context).textTheme.bodySmall,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Card(
                color: CozyTheme.peach.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    PrivacyCopy.patternFooter(demoState.currentPhase),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
