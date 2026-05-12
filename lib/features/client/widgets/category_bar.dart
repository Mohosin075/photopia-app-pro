import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photopia/features/client/widgets/shimmer_skeletons.dart';

import 'package:photopia/data/models/category_model.dart';
import 'package:provider/provider.dart';
import 'package:photopia/controller/category_controller.dart';

class CategoryBar extends StatelessWidget {
  final bool isLoading;
  final String? selectedCategoryId;
  final Function(String?)? onCategorySelected;

  const CategoryBar({
    super.key,
    this.isLoading = false,
    this.selectedCategoryId,
    this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final categoryController = context.watch<CategoryController>();
    final themes = ['ALL', ...categoryController.themes];

    return SizedBox(
      height: 34.h.clamp(32, 38),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        scrollDirection: Axis.horizontal,
        itemCount: isLoading || categoryController.isLoading ? 5 : themes.length,
        itemBuilder: (context, index) {
          if (isLoading || categoryController.isLoading) {
            return Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: const CategoryChipSkeleton(),
            );
          }

          final String theme = themes[index];
          final bool isAll = theme == 'ALL';
          final String label = isAll ? 'All' : theme;
          final bool isSelected = categoryController.selectedTheme == theme || 
                                 (isAll && (categoryController.selectedTheme == null || categoryController.selectedTheme == 'ALL'));

          return GestureDetector(
            onTap: () {
              categoryController.loadCategories(theme: isAll ? 'ALL' : theme);
              if (onCategorySelected != null) {
                onCategorySelected!(null); // Reset category selection when theme changes
              }
            },
            child: Container(
              margin: EdgeInsets.only(right: 12.w),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(25).r,
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isAll ? Icons.grid_view_outlined : Icons.palette_outlined,
                    size: 18.sp.clamp(18, 20),
                    color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.sp.clamp(14, 15),
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
