import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/futsmandu_design_system.dart' as ds;

import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_spacing.dart';

class FutsCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const FutsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.borderRadius,
    this.backgroundColor,
    this.onTap,
  });

  @override
  State<FutsCard> createState() => _FutsCardState();
}

class _FutsCardState extends State<FutsCard> {
  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(AppRadius.lg);
    final padding = widget.padding ?? EdgeInsets.all(AppSpacing.cardPadding);

    final cardChild = widget.backgroundColor == null && widget.borderRadius == null
        ? ds.AppCard(
            onTap: null,
            padding: padding,
            child: widget.child,
          )
        : ds.AppContainer(
            padding: padding,
            backgroundColor: widget.backgroundColor,
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            useShadow: true,
            child: ClipRRect(
              borderRadius: radius,
              child: widget.child,
            ),
          );

    if (widget.onTap == null) {
      return cardChild;
    }

    return InkWell(
      onTap: widget.onTap,
      borderRadius: radius,
      child: cardChild,
    );
  }
}
