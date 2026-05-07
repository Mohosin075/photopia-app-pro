import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photopia/data/models/home_data_model.dart';
import 'package:photopia/core/localization/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photopia/core/services/translation_service.dart';
import 'package:photopia/features/provider/screen/provider_profile_screen.dart'; // Add navigation if possible later

class HomeSeeAllProsScreen extends StatelessWidget {
  final String title;
  final List<SuperPro> pros;

  const HomeSeeAllProsScreen({
    super.key,
    required this.title,
    required this.pros,
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
      body: pros.isEmpty
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
                crossAxisSpacing: 16.w,
                mainAxisSpacing: 16.h,
                childAspectRatio: 0.8,
              ),
              itemCount: pros.length,
              itemBuilder: (context, index) {
                final pro = pros[index];
                return GestureDetector(
                  onTap: () {
                     // Optionally navigate to provider profile if implemented
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: isDark 
                              ? Colors.black.withOpacity(0.2) 
                              : Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(12.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 40.r,
                              backgroundColor: Theme.of(context).dividerColor.withOpacity(0.05),
                              backgroundImage: pro.user?.profile != null
                                  ? CachedNetworkImageProvider(pro.user!.profile!)
                                  : null,
                              child: pro.user?.profile == null
                                  ? Icon(Icons.person, size: 40.sp, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3))
                                  : null,
                            ),
                            if (pro.isSuperPro == true)
                              Container(
                                padding: EdgeInsets.all(4.w),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
                                ),
                                child: Icon(
                                  Icons.star,
                                  color: Colors.white,
                                  size: 12.sp,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        TranslatedText(
                          pro.user?.name ?? 'Pro',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 6.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: Colors.orange,
                              size: 16.sp,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              pro.rating?.toStringAsFixed(1) ?? '5.0',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
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
