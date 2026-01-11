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
    final activeItems = AccessCatalog.byPhase(demoState.currentPhase);
    final nextPhase = demoState.currentPhase.next();
    final nextItems = AccessCatalog.byPhase(nextPhase)
        .where((item) => !activeItems.contains(item))
        .toList();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: CozyTheme.cream.withOpacity(0.97),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: CozyTheme.ink.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            'A quiet summary of the signals currently shaping your calm.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          _MetricRow(grantedCount: grantedCount, total: total),
          const SizedBox(height: 16),
          _SignalCard(
            title: 'Active signals',
            subtitle:
                'Phase ${demoState.currentPhase.phaseNumber} · ${activeItems.length} threads',
            chips: _itemsToChips(activeItems),
          ),
          const SizedBox(height: 12),
          _SignalCard(
            title: 'Next gentle unlocks',
            subtitle:
                'Phase ${nextPhase.phaseNumber} · ${nextItems.length} soon',
            chips: _itemsToChips(nextItems.take(6).toList()),
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
  }

  List<String> _itemsToChips(List<AccessItem> items) {
    return items.map((item) => item.title).toList();
  }
}

class _MetricRow extends StatelessWidget {
  final int grantedCount;
  final int total;

  const _MetricRow({
    required this.grantedCount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: 'Signals trusted',
            value: '$grantedCount',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            label: 'Catalog size',
            value: '$total',
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;

  const _MetricCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: CozyTheme.ink.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class _SignalCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> chips;

  const _SignalCard({
    required this.title,
    required this.subtitle,
    required this.chips,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips.isEmpty
                ? [
                    Text(
                      'No new signals yet.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ]
                : chips
                    .map(
                      (chip) => Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: CozyTheme.mint.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          chip,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: CozyTheme.ink),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }
}
