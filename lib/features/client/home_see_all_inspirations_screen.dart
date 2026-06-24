import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photopya/data/models/home_data_model.dart';
import 'package:photopya/core/localization/app_localizations.dart';
import 'package:photopya/core/utils/category_icon_helper.dart';
import 'package:photopya/features/client/search_result_screen.dart';

import 'package:photopya/core/utils/app_transitions.dart';

class HomeSeeAllInspirationsScreen extends StatelessWidget {
  final String title;
  final List<Inspiration> inspirations;

  const HomeSeeAllInspirationsScreen({
    super.key,
    required this.title,
    required this.inspirations,
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
      body: inspirations.isEmpty
          ? Center(
              child: Text(
                context.l10n.noData,
                style: TextStyle(fontSize: 16.sp, color: Colors.grey),
              ),
            )
          : GridView.builder(
              padding: EdgeInsets.all(16.w),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
                childAspectRatio: 0.75,
              ),
              itemCount: inspirations.length,
              itemBuilder: (context, index) {
                final item = inspirations[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      AppTransitions.createPremiumRoute(
                        SearchResultScreen(
                          filters: {
                            'subCategory': item.subCategoryId,
                            'isActive': 'true',
                            'status': 'ACTIVE',
                          },
                          title: item.subCategoryName ?? item.title,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(16.r),
                      image: item.image != null
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(item.image!),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                Colors.black.withOpacity(0.3),
                                BlendMode.darken,
                              ),
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.9),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Corner Icon
                          Positioned(
                            top: 10.h,
                            right: 10.w,
                            child: Container(
                              padding: EdgeInsets.all(6.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                CategoryIconHelper.getIcon(item.title),
                                size: 14.sp,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          // Content
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Padding(
                              padding: EdgeInsets.all(12.w),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.l10n.translateCategory(item.title),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 6.h),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.description ?? 'View packages',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.8),
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(width: 4.w),
                                      Icon(
                                        Icons.arrow_forward,
                                        size: 10.sp,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
