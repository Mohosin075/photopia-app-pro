import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photopya/controller/auth_controller.dart';
import 'package:photopya/core/localization/app_localizations.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  // Simulation of user preferences state
  final Map<String, Map<String, bool>> _preferences = {};

  @override
  void initState() {
    super.initState();
    _initializePreferences();
  }

  void _initializePreferences() {
    final bool isProvider = AuthController.activeRole == 'provider';
    final categories = isProvider ? _providerCategories : _clientCategories;

    for (var category in categories) {
      _preferences[category['id']] = {
        'push': true,
        'email': category['hasEmail'] ?? true,
        'sms': category['hasSMS'] ?? false,
      };
    }
  }

  final List<Map<String, dynamic>> _clientCategories = [
    {'id': 'bookings', 'name': 'Bookings & Orders', 'icon': Icons.shopping_bag_outlined, 'hasEmail': true, 'hasSMS': true},
    {'id': 'communication', 'name': 'Communication', 'icon': Icons.chat_bubble_outline, 'hasEmail': false, 'hasSMS': false},
    {'id': 'reminders', 'name': 'Reminders', 'icon': Icons.notifications_active_outlined, 'hasEmail': true, 'hasSMS': true},
    {'id': 'completion', 'name': 'Completion & Reviews', 'icon': Icons.star_outline, 'hasEmail': true, 'hasSMS': false},
    {'id': 'payments', 'name': 'Payments', 'icon': Icons.account_balance_wallet_outlined, 'hasEmail': true, 'hasSMS': false},
    {'id': 'security', 'name': 'Security & Alerts', 'icon': Icons.security_outlined, 'hasEmail': true, 'hasSMS': true},
    {'id': 'promotions', 'name': 'Promotions', 'icon': Icons.card_giftcard_outlined, 'hasEmail': true, 'hasSMS': false},
  ];

  final List<Map<String, dynamic>> _providerCategories = [
    {'id': 'requests', 'name': 'Requests & Bookings', 'icon': Icons.assignment_outlined, 'hasEmail': true, 'hasSMS': true},
    {'id': 'communication', 'name': 'Client Communication', 'icon': Icons.chat_bubble_outline, 'hasEmail': false, 'hasSMS': false},
    {'id': 'reminders', 'name': 'Service Reminders', 'icon': Icons.alarm_outlined, 'hasEmail': true, 'hasSMS': true},
    {'id': 'revenue', 'name': 'Payments & Revenue', 'icon': Icons.payments_outlined, 'hasEmail': true, 'hasSMS': false},
    {'id': 'reviews', 'name': 'Reviews & Reputation', 'icon': Icons.rate_review_outlined, 'hasEmail': true, 'hasSMS': false},
    {'id': 'listings', 'name': 'Listings & Performance', 'icon': Icons.bar_chart_outlined, 'hasEmail': true, 'hasSMS': false},
    {'id': 'calendar', 'name': 'Calendar & Availability', 'icon': Icons.calendar_month_outlined, 'hasEmail': true, 'hasSMS': false},
    {'id': 'security', 'name': 'Account & Security', 'icon': Icons.verified_user_outlined, 'hasEmail': true, 'hasSMS': true},
  ];

  @override
  Widget build(BuildContext context) {
    final bool isProvider = AuthController.activeRole == 'provider';
    final categories = isProvider ? _providerCategories : _clientCategories;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Notification Settings',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: EdgeInsets.all(20.w),
        children: [
          _buildHeaderSection(),
          SizedBox(height: 30.h),
          ...categories.map((cat) => _buildCategoryCard(cat)).toList(),
          SizedBox(height: 20.h),
          _buildGlobalOptions(),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_outlined, color: Colors.white, size: 28.sp),
              SizedBox(width: 12.w),
              Text(
                'Stay Connected',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Customize how and when you want to receive updates from Photopia.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13.sp,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final String id = category['id'];
    final prefs = _preferences[id]!;

    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    category['icon'],
                    color: Theme.of(context).colorScheme.primary,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Text(
                    category['name'],
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.05)),
          _buildChannelToggle(id, 'Push Notification', 'push', Icons.on_device_training),
          if (category['hasEmail'])
            _buildChannelToggle(id, 'Email Updates', 'email', Icons.alternate_email),
          if (category['hasSMS'])
            _buildChannelToggle(id, 'SMS Alerts', 'sms', Icons.sms_outlined),
        ],
      ),
    );
  }

  Widget _buildChannelToggle(String categoryId, String label, String channel, IconData icon) {
    final bool value = _preferences[categoryId]![channel]!;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: (val) {
                setState(() {
                  _preferences[categoryId]![channel] = val;
                });
              },
              activeColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
          child: Text(
            'SYSTEM PREFERENCES',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              letterSpacing: 1.2,
            ),
          ),
        ),
        _buildSystemTile(
          'Do Not Disturb',
          'Mute all notifications except urgent alerts.',
          Icons.do_not_disturb_on_outlined,
          false,
        ),
        SizedBox(height: 12.h),
        _buildSystemTile(
          'Daily Digest',
          'Get a summary of non-urgent updates once a day.',
          Icons.summarize_outlined,
          true,
        ),
      ],
    );
  }

  Widget _buildSystemTile(String title, String subtitle, IconData icon, bool value) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (val) {},
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
