import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_logo.dart';

class AuthScreenScaffold extends StatelessWidget {
  const AuthScreenScaffold({
    super.key,
    required this.child,
    this.showAppBar = false,
    this.logoTopSpacing = AppSpacing.lg,
    this.logoSize = 72,
  });

  final Widget child;
  final bool showAppBar;
  final double logoTopSpacing;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              automaticallyImplyLeading: false,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
            )
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final minHeight = showAppBar
                ? constraints.maxHeight - kToolbarHeight
                : constraints.maxHeight;
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: bottomInset + AppSpacing.lg,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: logoTopSpacing),
                    Center(child: AppLogo(size: logoSize)),
                    const SizedBox(height: AppSpacing.sm),
                    child,
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
