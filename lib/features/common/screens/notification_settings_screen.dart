import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photopya/controller/auth_controller.dart';
import 'package:photopya/controller/client/user_profile_controller.dart';
import 'package:photopya/core/widgets/custom_snacbar.dart';
import 'package:provider/provider.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _isLoading = false;
  bool _isSaving = false;

  // Local state mapped from/to UserSettings
  bool _pushNotification = true;
  bool _emailNotification = true;
  bool _smsNotification = true;
  bool _locationService = true;
  bool _dndMode = false;
  bool _quietHoursEnabled = true;
  String _quietHoursStart = '22:00';
  String _quietHoursEnd = '08:00';
  List<String> _disabledCategories = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserSettings();
    });
  }

  Future<void> _loadUserSettings() async {
    setState(() => _isLoading = true);
    final profileController = context.read<UserProfileController>();
    
    // Always fetch latest profile data to be fresh
    await profileController.getUserProfile();
    
    if (mounted) {
      final settings = profileController.userProfile?.settings;
      if (settings != null) {
        setState(() {
          _pushNotification = settings.pushNotification;
          _emailNotification = settings.emailNotification;
          _smsNotification = settings.smsNotification;
          _locationService = settings.locationService;
          _dndMode = settings.dndMode;
          _quietHoursEnabled = settings.quietHoursEnabled;
          _quietHoursStart = settings.quietHoursStart;
          _quietHoursEnd = settings.quietHoursEnd;
          _disabledCategories = List<String>.from(settings.disabledCategories);
        });
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    
    final payload = {
      'pushNotification': _pushNotification,
      'emailNotification': _emailNotification,
      'smsNotification': _smsNotification,
      'locationService': _locationService,
      'dndMode': _dndMode,
      'quietHoursEnabled': _quietHoursEnabled,
      'quietHoursStart': _quietHoursStart,
      'quietHoursEnd': _quietHoursEnd,
      'disabledCategories': _disabledCategories,
    };
    
    final controller = context.read<UserProfileController>();
    final success = await controller.updateNotificationSettings(payload);
    
    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        CustomSnackBar.show(
          context: context,
          message: 'Settings saved successfully!',
          isError: false,
        );
        Navigator.pop(context);
      } else {
        CustomSnackBar.show(
          context: context,
          message: controller.errorMessage ?? 'Failed to save settings',
          isError: true,
        );
      }
    }
  }

  final List<Map<String, dynamic>> _clientCategories = [
    {'id': 'bookings', 'name': 'Bookings & Orders', 'icon': Icons.shopping_bag_outlined},
    {'id': 'communication', 'name': 'Communication', 'icon': Icons.chat_bubble_outline},
    {'id': 'reminders', 'name': 'Reminders', 'icon': Icons.notifications_active_outlined},
    {'id': 'completion', 'name': 'Completion & Reviews', 'icon': Icons.star_outline},
    {'id': 'payments', 'name': 'Payments', 'icon': Icons.account_balance_wallet_outlined},
    {'id': 'security', 'name': 'Security & Alerts', 'icon': Icons.security_outlined},
    {'id': 'promotions', 'name': 'Promotions', 'icon': Icons.card_giftcard_outlined},
  ];

  final List<Map<String, dynamic>> _providerCategories = [
    {'id': 'requests', 'name': 'Requests & Bookings', 'icon': Icons.assignment_outlined},
    {'id': 'communication', 'name': 'Client Communication', 'icon': Icons.chat_bubble_outline},
    {'id': 'reminders', 'name': 'Service Reminders', 'icon': Icons.alarm_outlined},
    {'id': 'revenue', 'name': 'Payments & Revenue', 'icon': Icons.payments_outlined},
    {'id': 'reviews', 'name': 'Reviews & Reputation', 'icon': Icons.rate_review_outlined},
    {'id': 'listings', 'name': 'Listings & Performance', 'icon': Icons.bar_chart_outlined},
    {'id': 'calendar', 'name': 'Calendar & Availability', 'icon': Icons.calendar_month_outlined},
    {'id': 'security', 'name': 'Account & Security', 'icon': Icons.verified_user_outlined},
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
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveSettings,
              child: Text(
                'Save',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ),
          SizedBox(width: 10.w),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(20.w),
              children: [
                _buildHeaderSection(),
                SizedBox(height: 24.h),
                _buildGlobalChannelsSection(),
                SizedBox(height: 24.h),
                _buildAdvancedPreferencesSection(),
                SizedBox(height: 24.h),
                Padding(
                  padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
                  child: Text(
                    'CATEGORY SUBSCRIPTIONS',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                ...categories.map((cat) => _buildCategoryCard(cat)).toList(),
                SizedBox(height: 20.h),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    minimumSize: Size(double.infinity, 48.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save All Changes',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                SizedBox(height: 40.h),
              ],
            ),
    );
  }

  Widget _buildHeaderSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  theme.colorScheme.surface,
                  theme.colorScheme.surface.withOpacity(0.8),
                ]
              : [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.8),
                ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: isDark
            ? Border.all(
                color: theme.colorScheme.onSurface.withOpacity(0.08),
                width: 1,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : theme.colorScheme.primary.withOpacity(0.3),
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
              Icon(
                Icons.notifications_outlined,
                color: isDark ? theme.colorScheme.primary : Colors.white,
                size: 28.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Stay Connected',
                style: TextStyle(
                  color: isDark ? theme.colorScheme.onSurface : Colors.white,
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
              color: isDark
                  ? theme.colorScheme.onSurface.withOpacity(0.7)
                  : Colors.white.withOpacity(0.9),
              fontSize: 13.sp,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalChannelsSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NOTIFICATION CHANNELS',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 15.h),
          _buildChannelToggleRow(
            'Push Notifications',
            'Receive alerts directly on your device.',
            Icons.notifications_active_outlined,
            _pushNotification,
            (val) => setState(() => _pushNotification = val),
          ),
          const Divider(),
          _buildChannelToggleRow(
            'Email Notifications',
            'Receive transaction receipts and updates via email.',
            Icons.mail_outline,
            _emailNotification,
            (val) => setState(() => _emailNotification = val),
          ),
          const Divider(),
          _buildChannelToggleRow(
            'SMS Alerts',
            'Receive critical booking alerts via SMS.',
            Icons.sms_outlined,
            _smsNotification,
            (val) => setState(() => _smsNotification = val),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelToggleRow(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Icon(icon, size: 22.sp, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedPreferencesSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ADVANCED PREFERENCES',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 15.h),
          _buildChannelToggleRow(
            'Do Not Disturb (DND)',
            'Mute all notifications except urgent triggers.',
            Icons.do_not_disturb_on_outlined,
            _dndMode,
            (val) => setState(() => _dndMode = val),
          ),
          const Divider(),
          _buildChannelToggleRow(
            'Enable Quiet Hours',
            'Automatically suppress non-urgent alerts during selected hours.',
            Icons.nights_stay_outlined,
            _quietHoursEnabled,
            (val) => setState(() => _quietHoursEnabled = val),
          ),
          if (_quietHoursEnabled) ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _buildTimePickerButton('Start Time', _quietHoursStart, (time) {
                    setState(() => _quietHoursStart = time);
                  }),
                ),
                SizedBox(width: 15.w),
                Expanded(
                  child: _buildTimePickerButton('End Time', _quietHoursEnd, (time) {
                    setState(() => _quietHoursEnd = time);
                  }),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimePickerButton(String label, String value, Function(String) onSelected) {
    return GestureDetector(
      onTap: () async {
        final parts = value.split(':');
        final initialTime = TimeOfDay(
          hour: parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 22) : 22,
          minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
        );
        final time = await showTimePicker(
          context: context,
          initialTime: initialTime,
          builder: (BuildContext context, Widget? child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
              child: child!,
            );
          },
        );
        if (time != null) {
          final formatted = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
          onSelected(formatted);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.15)),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.access_time,
              size: 16.sp,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final String id = category['id'];
    final bool isEnabled = !_disabledCategories.contains(id);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
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
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: isEnabled,
                onChanged: (val) {
                  setState(() {
                    if (val) {
                      _disabledCategories.remove(id);
                    } else {
                      if (!_disabledCategories.contains(id)) {
                        _disabledCategories.add(id);
                      }
                    }
                  });
                },
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
