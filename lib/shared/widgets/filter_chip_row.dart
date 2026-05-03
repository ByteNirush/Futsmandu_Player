import 'package:flutter/material.dart';

import 'package:futsmandu_design_system/futsmandu_design_system.dart';

class FilterChipRow extends StatefulWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const FilterChipRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  State<FilterChipRow> createState() => _FilterChipRowState();
}

class _FilterChipRowState extends State<FilterChipRow> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
      ),
      child: Row(
        children: widget.options.map((option) {
          final isSelected = option == widget.selected;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: GestureDetector(
              onTap: () => widget.onSelected(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs, // Use design system spacing
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.green : AppColors.bgElevated,
                  borderRadius: AppRadius.medium, // Use design system radius
                  border: Border.all(
                    color: isSelected ? AppColors.green : AppColors.borderClr,
                  ),
                ),
                child: Text(
                  option,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isSelected
                            ? AppColors.bgPrimary
                            : AppColors.txtPrimary,
                        fontWeight: isSelected
                            ? AppFontWeights.semiBold
                            : AppFontWeights.regular,
                      ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
