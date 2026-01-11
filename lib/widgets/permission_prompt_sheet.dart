import 'package:flutter/material.dart';

import '../access_catalog.dart';
import '../privacy_copy.dart';
import '../privacy_phase.dart';
import '../theme/theme.dart';

class PermissionPromptSheet extends StatelessWidget {
  final AccessItem item;
  final PrivacyPhase phase;
  final VoidCallback onAllow;
  final VoidCallback onDeny;

  const PermissionPromptSheet({
    super.key,
    required this.item,
    required this.phase,
    required this.onAllow,
    required this.onDeny,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 5,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: CozyTheme.muted.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          Text(
            PrivacyCopy.rationaleTitle(item.id, phase),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(item.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(
            PrivacyCopy.rationaleBody(item.id, phase),
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CozyTheme.lavender,
                    foregroundColor: CozyTheme.ink,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: onAllow,
                  child: const Text('Yes'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CozyTheme.muted,
                    side: BorderSide(color: CozyTheme.muted.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: onDeny,
                  child: const Text('Not right now'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
