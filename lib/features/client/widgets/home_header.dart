import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:photopya/controller/client/notification_controller.dart';
import 'package:photopya/controller/location_controller.dart';
import 'package:photopya/features/client/notification_screen.dart';
import 'package:photopya/features/client/widgets/shimmer_skeletons.dart';
import 'package:provider/provider.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Image.asset(
            isDark ? 'assets/images/photopya_dark.png' : 'assets/images/photopya_light.png',
            height: 28.h,
            fit: BoxFit.contain,
          ),
          SizedBox(height: 10.h),
          // Location + Notification row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Consumer<LocationController>(
                builder: (context, controller, _) {
                  final String location = controller.currentAddress;
                  return Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14.sp.clamp(14, 16),
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      SizedBox(width: 4.w),
                      if (controller.isLoading)
                        Container(
                          width: 100.w,
                          height: 12.h,
                          decoration: BoxDecoration(
                            color: Theme.of(context).dividerColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(4).r,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4).r,
                            child: const ShimmerSkeleton(
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                        )
                      else
                        Text(
                          location,
                          style: TextStyle(
                            fontSize: 12.sp.clamp(12, 14),
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  );
                },
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationScreen(),
                    ),
                  );
                },
                child: Consumer<NotificationController>(
                  builder: (context, controller, child) {
                    final bool hasUnread = controller.unreadCount > 0;
                    return Stack(
                      children: [
                        Icon(Icons.notifications_outlined, size: 20.sp, color: Theme.of(context).colorScheme.onSurface),
                        if (hasUnread)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 8.w,
                              height: 8.w,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
