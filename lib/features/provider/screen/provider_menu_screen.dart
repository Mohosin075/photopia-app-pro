import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:photopya/features/provider/screen/provider_wallet_screen.dart';
import 'package:photopya/features/common/mode_transition_screen.dart';
import 'package:photopya/core/routes/app_routes.dart';
import 'package:photopya/features/provider/screen/provider_subscription_screen.dart';
import 'package:photopya/controller/provider/provider_profile_controller.dart';
import 'package:photopya/controller/auth_controller.dart';
import 'package:photopya/controller/client/log_out_controller.dart';
import 'package:photopya/features/client/widgets/auth_profile_image.dart';
import 'package:photopya/features/provider/screen/provider_statistics_screen.dart';
import 'package:photopya/features/provider/screen/provider_notification_screen.dart';
import 'package:photopya/features/provider/screen/provider_profile_screen.dart';
import 'package:photopya/core/widgets/subscription_badge.dart';
import 'package:photopya/controller/client/chat_controller.dart';
import 'package:photopya/features/client/chat_screen.dart';
import 'package:photopya/core/widgets/custom_snacbar.dart';
import 'package:photopya/data/models/conversation_model.dart';
import 'package:photopya/core/localization/app_localizations.dart';

import 'package:photopya/features/client/settings_screen.dart';
import 'package:photopya/features/client/payment_methods_screen.dart';

class ProviderMenuScreen extends StatefulWidget {
  const ProviderMenuScreen({super.key});

  @override
  State<ProviderMenuScreen> createState() => _ProviderMenuScreenState();
}

class _ProviderMenuScreenState extends State<ProviderMenuScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderProfileController>().getProviderProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Consumer<ProviderProfileController>(
            builder: (context, controller, child) {
              return Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: [
                    // Profile Section
                    _buildProfileSection(context, controller),
                    SizedBox(height: 16.h.clamp(12, 20)),

                    // Stats Grid
                    _buildStatsGrid(controller),
                    SizedBox(height: 16.h.clamp(12, 20)),

                    // Premium Member Card (Show only if NOT subscribed)
                    if (!(controller.userProfile?.isPremium ?? false)) ...[
                      _buildPremiumCard(context),
                      SizedBox(height: 16.h.clamp(12, 20)),
                    ],

                    // Menu Items
                    _buildMenuItem(
                      icon: Icons.payment,
                      title: context.l10n.paymentsTransactions,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProviderWalletScreen(),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 12.h.clamp(8, 16)),

                    _buildMenuItem(
                      icon: Icons.bar_chart,
                      title: context.l10n.detailedStatistics,
                      showBadge: true,
                      isSubscribed: controller.userProfile?.isPremium ?? false,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ProviderStatisticsScreen(),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 12.h.clamp(8, 16)),

                    // TODO: Extra Feature - Professional Site
                    // 1/ Custom Dates and Exceptions
                    // 2/ Auto Block Duration
                    // 3/ Advanced Booking Rules
                    // 4/ Price and Rates
                    _buildMenuItem(
                      icon: Icons.notifications_outlined,
                      title: context.l10n.notifications,
                      hasNotification: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ProviderNotificationScreen(),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 12.h.clamp(8, 16)),

                    _buildMenuItem(
                      icon: Icons.settings_outlined,
                      title: context.l10n.settings,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 12.h.clamp(8, 16)),

                    _buildMenuItem(
                      icon: Icons.help_outline,
                      title: context.l10n.helpAndSupport,
                      onTap: () async {
                        final chatController = context.read<ChatController>();
                        final chatId = await chatController.contactAdmin();

                        if (chatId != null && mounted) {
                          // Try to find the real conversation from the updated list
                          Conversation? conversation;
                          try {
                            final chatRoom = chatController.chats.firstWhere(
                              (c) => c.sId == chatId,
                            );
                            conversation = chatRoom.toConversation(
                              AuthController.userId,
                            );
                          } catch (_) {
                            // Fallback if not found yet (race condition)
                            conversation = Conversation(
                              id: chatId,
                              name: 'Admin Support',
                              lastMessage: '',
                              avatarUrl: '',
                              lastMessageTime: DateTime.now(),
                            );
                          }

                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  ChatScreen(conversation: conversation!),
                            ),
                          );
                        } else if (mounted) {
                          CustomSnackBar.show(
                            context: context,
                            message: chatController.errorMessage.isNotEmpty
                                ? chatController.errorMessage
                                : context.l10n.failedToContactAdmin,
                            isError: true,
                          );
                        }
                      },
                    ),
                    SizedBox(height: 12.h.clamp(8, 16)),

                    // Switch to Client Button
                    _buildSwitchButton(context),
                    SizedBox(height: 12.h.clamp(8, 16)),

                    // Sign Out Button
                    _buildSignOutButton(context),
                    SizedBox(height: 16.h.clamp(12, 20)),

                    // App Version
                    Text(
                      'Photopya Pro v1.0.4',
                      style: TextStyle(
                        fontSize: 12.sp.clamp(11, 13),
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(
    BuildContext context,
    ProviderProfileController controller,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Profile Image - Larger and Circular
              AuthProfileImage(
                imageUrl: controller.profileImage,
                size: 60.w.clamp(55, 65),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.name,
                      style: TextStyle(
                        fontSize: 17.sp.clamp(16, 18),
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      controller.profileTagline,
                      style: TextStyle(
                        fontSize: 13.sp.clamp(12, 14),
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),
                    SubscriptionBadge(
                      isSubscribed: controller.userProfile?.isPremium ?? false,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h.clamp(12, 16)),
          SizedBox(
            width: double.infinity,
            height: 48.h.clamp(44, 52),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProviderProfileScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                elevation: 0,
              ),
              child: Text(
                context.l10n.viewPublicProfile,
                style: TextStyle(
                  fontSize: 15.sp.clamp(14, 16),
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(ProviderProfileController controller) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.calendar_today,
                label: context.l10n.bookingsTitle,
                value: controller.bookingsCount.toString(),
                subtitle: context.l10n.bookingsThisWeek(
                  controller.bookingsThisWeek,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildStatCard(
                icon: Icons.euro,
                label: context.l10n.revenueTitle,
                value: '€${_formatLargeNumber(controller.revenueAmount)}',
                subtitle: context.l10n.revenueVsLastMonth(
                  controller.revenueChange,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h.clamp(10, 14)),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.trending_up,
                label: context.l10n.profileViewsTitle,
                value: _formatLargeNumber(controller.profileViews.toDouble()),
                subtitle: context
                    .l10n
                    .thisWeek, // API doesn't have weekly views % yet
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildStatCard(
                icon: Icons.star,
                label: context.l10n.rating,
                value: controller.rating.toStringAsFixed(1),
                subtitle: context.l10n.reviewCount(controller.reviewCount),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatLargeNumber(double number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toInt().toString();
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16.sp.clamp(14, 18),
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp.clamp(11, 13),
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h.clamp(6, 10)),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp.clamp(18, 22),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11.sp.clamp(10, 12),
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium, color: Colors.amber, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                context.l10n.premiumMember,
                style: TextStyle(
                  fontSize: 14.sp.clamp(13, 15),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                context.l10n.premiumPrice,
                style: TextStyle(
                  fontSize: 13.sp.clamp(12, 14),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h.clamp(10, 14)),
          Text(
            context.l10n.premiumBenefits,
            style: TextStyle(
              fontSize: 12.sp.clamp(11, 13),
              color: Colors.grey[400],
              height: 1.4,
            ),
          ),
          SizedBox(height: 12.h.clamp(10, 14)),
          SizedBox(
            width: double.infinity,
            height: 48.h.clamp(44, 52),
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProviderSubscriptionScreen(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                context.l10n.manageSubscription,
                style: TextStyle(
                  fontSize: 13.sp.clamp(12, 14),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    bool showBadge = false,
    bool isSubscribed = false,
    bool hasNotification = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22.sp.clamp(20, 24),
              color: Theme.of(context).colorScheme.onSurface,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp.clamp(13, 15),
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (showBadge)
              SubscriptionBadge(
                isSubscribed: isSubscribed,
                fontSize: 10.sp.clamp(9, 11),
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              ),
            if (hasNotification)
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            SizedBox(width: 8.w),
            Icon(
              Icons.arrow_forward_ios,
              size: 14.sp.clamp(12, 16),
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (context) => const ModeTransitionScreen(
              targetRole: 'user',
              targetRoute: AppRoutes.bottom_navigation,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 46.h,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12).r,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 18.sp,
            ),
            SizedBox(width: 10.w),
            Text(
              context.l10n.switchToClient,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return Consumer<LogOutController>(
      builder: (context, logOutController, child) {
        return GestureDetector(
          onTap: logOutController.inProgress
              ? null
              : () async {
                  // Show confirmation dialog first
                  final confirmed = await showDialog<bool>(
                    context: context,
                    barrierDismissible: true,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      surfaceTintColor: Theme.of(context).colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      contentPadding: EdgeInsets.fromLTRB(
                        24.w,
                        16.h,
                        24.w,
                        8.h,
                      ),
                      actionsPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                      title: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(14.w),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).dividerColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.logout_rounded,
                              color: Theme.of(context).colorScheme.onSurface,
                              size: 26.sp,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            context.l10n.logOut,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      content: Text(
                        context.l10n.logOutConfirm,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                          height: 1.4,
                        ),
                      ),
                      actions: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                  side: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).dividerColor.withOpacity(0.1),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                ),
                                child: Text(
                                  context.l10n.cancel,
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.7),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.sp,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.error,
                                  foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.onError,
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                ),
                                child: Text(
                                  context.l10n.logOut,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );

                  if (confirmed != true) return;

                  debugPrint('🚪 Provider Logout confirmed...');

                  // 1. Attempt API logout
                  final result = await logOutController.logOut();

                  if (!result) {
                    debugPrint(
                      '⚠️ Server logout failed, but clearing local state.',
                    );
                  }

                  // 2. ALWAYS clear local state and navigate to home
                  await AuthController.forceLogout();
                },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 10.h),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12).r,
              border: Border.all(
                color: Theme.of(context).colorScheme.error.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (logOutController.inProgress)
                  SizedBox(
                    height: 20.h,
                    width: 20.h,
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.error,
                      strokeWidth: 2,
                    ),
                  )
                else ...[
                  Icon(
                    Icons.logout,
                    color: Theme.of(context).colorScheme.error,
                    size: 20.sp,
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    context.l10n.logOut,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
