import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:photopya/controller/client/notification_controller.dart';
import 'package:photopya/data/models/notification_model.dart';
import 'package:photopya/features/common/screens/notification_settings_screen.dart';

class ProviderNotificationScreen extends StatefulWidget {
  const ProviderNotificationScreen({super.key});
  static const String name = "provider-notification";

  @override
  State<ProviderNotificationScreen> createState() => _ProviderNotificationScreenState();
}

class _ProviderNotificationScreenState extends State<ProviderNotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationController>().fetchMyNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 60.h,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Padding(
          padding: EdgeInsets.only(top: 10.h),
          child: Consumer<NotificationController>(
            builder: (context, controller, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Notifications',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 20.sp.clamp(20, 22),
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${controller.unreadCount} unread',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 14.sp.clamp(14, 16),
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: Theme.of(context).colorScheme.onSurface, size: 20.sp),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
            ),
          ),
          SizedBox(width: 5.w),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50.h),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.05),
                  width: 1,
                ),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Consumer<NotificationController>(
              builder: (context, controller, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IntrinsicWidth(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            child: Text(
                              'All (${controller.notifications.length})',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 14.sp.clamp(14, 16),
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Container(
                            height: 2.h,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 6.h),
                      child: TextButton(
                        onPressed: () {
                          context.read<NotificationController>().markAllAsRead();
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 0),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Mark all as read',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 13.sp.clamp(13, 14),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      body: Consumer<NotificationController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null && controller.notifications.isEmpty) {
            return Center(child: Text(controller.errorMessage!));
          }

          if (controller.notifications.isEmpty) {
            return Center(
              child: Text(
                "No notifications available.",
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 16.sp),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 16.w),
            itemCount: controller.notifications.length,
            itemBuilder: (context, index) {
              final notification = controller.notifications[index];
              return GestureDetector(
                onTap: () =>
                    _showNotificationDialog(context, notification, controller),
                child: _buildNotificationCard(notification, index, controller),
              );
            },
          );
        },
      ),
    );
  }

  void _showNotificationDialog(
    BuildContext context,
    NotificationModel notification,
    NotificationController controller,
  ) {
    // Mark as read immediately when clicked
    if (!notification.isRead) {
      controller.markSingleAsRead(notification.id);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20).r,
        ),
        title: Row(
          children: [
            Icon(
              controller.getIconForType(notification.type),
              color: Theme.of(context).colorScheme.onSurface,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                notification.title,
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.content,
              style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                height: 1.5,
              ),
            ),
            SizedBox(height: 15.h),
            Text(
              controller.formatTime(notification.createdAt),
              style: TextStyle(fontSize: 12.sp, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification, int index, NotificationController controller) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15).r,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15).r,
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Unread Indicator
              if (!notification.isRead)
                Container(
                  width: 4.w,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(15.w),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          controller.getIconForType(notification.type),
                          size: 20.sp.clamp(20, 22),
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(width: 15.w),
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    notification.title,
                                    style: TextStyle(
                                      fontSize: 15.sp.clamp(15, 17),
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                GestureDetector(
                                  onTap: () {
                                    controller.removeNotification(index);
                                  },
                                  child: Icon(
                                    Icons.close,
                                    size: 16.sp.clamp(16, 18),
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 5.h),
                            Text(
                              notification.content,
                              style: TextStyle(
                                fontSize: 13.sp.clamp(13, 15),
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                height: 1.3,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              controller.formatTime(notification.createdAt),
                              style: TextStyle(
                                fontSize: 12.sp.clamp(12, 14),
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                              ),
                            ),
                          ],
                        ),
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
  }
}
