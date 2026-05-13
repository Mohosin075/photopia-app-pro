import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photopia/data/models/category_model.dart';
import 'package:photopia/core/localization/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photopia/controller/category_controller.dart';
import 'package:photopia/controller/client/service_list_controller.dart';
import 'package:provider/provider.dart';

import 'package:photopia/core/utils/category_icon_helper.dart';
import 'package:photopia/core/utils/app_transitions.dart';
import 'package:photopia/features/client/search_result_screen.dart';

class HomeSeeAllCategoriesScreen extends StatelessWidget {
  final String title;
  final List<CategoryModel> categories;

  const HomeSeeAllCategoriesScreen({
    super.key,
    required this.title,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: categories.isEmpty
          ? Center(
              child: Text(
                context.l10n.noData,
                style: TextStyle(fontSize: 16.sp, color: Colors.grey),
              ),
            )
          : GridView.builder(
              padding: EdgeInsets.all(16.w),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 24.h,
                childAspectRatio: 0.85,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final item = categories[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      AppTransitions.createPremiumRoute(
                        SearchResultScreen(
                          filters: {
                            'category': item.id,
                            'categoryName': item.name,
                          },
                        ),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 85.w,
                        height: 85.w,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            CategoryIconHelper.getIcon(item.name),
                            size: 36.sp,
                            color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        item.name ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
