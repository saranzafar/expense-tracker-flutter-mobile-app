import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Small uppercase overline section label with an optional trailing action
/// (e.g. a "See all" button). One place so every section header matches.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.label, {super.key, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.overline.copyWith(color: context.inkSubtle),
        ),
        ?trailing,
      ],
    );
  }
}
