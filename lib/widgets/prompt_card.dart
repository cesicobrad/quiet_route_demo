import 'package:flutter/material.dart';

import '../theme/theme.dart';

class PromptCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String body;
  final String? responseLine;
  final int? requestsWaiting;
  final bool showActions;
  final bool buttonsEnabled;
  final VoidCallback? onYes;
  final VoidCallback? onMaybeLater;

  const PromptCard({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.responseLine,
    this.requestsWaiting,
    this.showActions = true,
    this.buttonsEnabled = true,
    this.onYes,
    this.onMaybeLater,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.97),
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
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  subtitle!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: CozyTheme.muted,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            Text(title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
            if (requestsWaiting != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Requests waiting: $requestsWaiting',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: CozyTheme.muted,
                  ),
                ),
              ),
            if (responseLine != null) ...[
              const SizedBox(height: 12),
              Text(
                responseLine!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: CozyTheme.muted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (showActions) ...[
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
                      onPressed: buttonsEnabled ? onYes : null,
                      child: const Text('Yes'),
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
                      onPressed: buttonsEnabled ? onMaybeLater : null,
                      child: const Text('Maybe later'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
