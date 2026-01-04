import 'package:flutter/material.dart';

class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!, style: theme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ],
    );
  }
}
