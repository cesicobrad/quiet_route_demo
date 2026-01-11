import 'package:flutter/material.dart';

import '../access_catalog.dart';
import '../privacy_copy.dart';
import '../privacy_phase.dart';
import '../theme/theme.dart';

class PermissionPromptSheet extends StatelessWidget {
  final AccessItem item;
  final PrivacyPhase phase;
  final VoidCallback onAllow;
  final VoidCallback onContinue;
  final VoidCallback onDismiss;

  const PermissionPromptSheet({
    super.key,
    required this.item,
    required this.phase,
    required this.onAllow,
    required this.onContinue,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.96),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: CozyTheme.ink.withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(0, 12),
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
                    PrivacyCopy.rationaleTitle(item.id, phase),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: CozyTheme.muted,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(item.title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text(
              PrivacyCopy.rationaleBody(item.id, phase),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CozyTheme.lavender,
                      foregroundColor: CozyTheme.ink,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: onAllow,
                    child: const Text('Allow'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CozyTheme.muted,
                      side: BorderSide(color: CozyTheme.muted.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: onContinue,
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
