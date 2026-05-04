import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photopia/core/localization/app_localizations.dart';
import 'package:photopia/features/client/privacy_policy_screen.dart';
import 'package:provider/provider.dart';
import 'package:photopia/controller/theme_controller.dart';

class SettingsScreen extends StatefulWidget {
  static const String name = '/settings';
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature – ${context.l10n.comingSoon}'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      ),
    );
  }

  void _confirmDangerAction({
    required String title,
    required String body,
    required String confirmLabel,
    required Color confirmColor,
    required VoidCallback onConfirmed,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        contentPadding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 8.h),
        actionsPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
        title: Text(
          title,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          body,
          style: TextStyle(fontSize: 13.sp, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), height: 1.4),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: Text(
                    context.l10n.cancelBtn,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontWeight: FontWeight.w600, fontSize: 13.sp),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onConfirmed();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: Text(
                    confirmLabel,
                    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final themeController = Provider.of<ThemeController>(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface, size: 22.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l.settings,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
        children: [

          // ── Account Section ───────────────────────────────────────────────
          _sectionLabel(l.settingsAccount),
          _card([
            _tile(
              icon: Icons.credit_card_outlined,
              title: l.settingsPaymentMethod,
              onTap: () => _showComingSoon(l.settingsPaymentMethod),
            ),
            _divider(),
            _tile(
              icon: Icons.lock_reset_outlined,
              title: l.settingsChangePassword,
              onTap: () => _showComingSoon(l.settingsChangePassword),
            ),
          ]),

          SizedBox(height: 16.h),

          // ── Appearance Section ────────────────────────────────────────────
          _sectionLabel(l.settingsAppearance),
          _card([
            _toggleTile(
              icon: Icons.dark_mode_outlined,
              title: l.settingsDarkMode,
              value: themeController.isDarkMode,
              onChanged: (val) {
                themeController.toggleTheme();
              },
            ),
          ]),

          SizedBox(height: 16.h),

          // ── Legal & Help Section ──────────────────────────────────────────
          _sectionLabel(l.settingsLegal),
          _card([
            _tile(
              icon: Icons.description_outlined,
              title: l.settingsTermsOfService,
              onTap: () => _showComingSoon(l.settingsTermsOfService),
            ),
            _divider(),
            _tile(
              icon: Icons.privacy_tip_outlined,
              title: l.privacyPolicy,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              ),
            ),
            _divider(),
            _tile(
              icon: Icons.help_outline,
              title: l.settingsHelpSupport,
              trailing: Icon(Icons.arrow_forward_ios, size: 14.sp, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
              onTap: () => _showHelpSheet(),
            ),
          ]),

          SizedBox(height: 16.h),

          // ── Data & Privacy Section ────────────────────────────────────────
          _sectionLabel(l.settingsData),
          _card([
            _tile(
              icon: Icons.download_outlined,
              title: l.settingsDownloadData,
              onTap: () => _showComingSoon(l.settingsDownloadData),
            ),
          ]),

          SizedBox(height: 16.h),

          // ── Danger Zone ───────────────────────────────────────────────────
          _sectionLabel(l.settingsDangerZone),
          _card([
            _tile(
              icon: Icons.person_off_outlined,
              title: l.settingsDeactivateAccount,
              textColor: Colors.orange[700]!,
              iconColor: Colors.orange[700]!,
              onTap: () => _confirmDangerAction(
                title: l.settingsDeactivateAccount,
                body: l.settingsDeactivateConfirm,
                confirmLabel: l.settingsDeactivate,
                confirmColor: Colors.orange[700]!,
                onConfirmed: () => _showComingSoon(l.settingsDeactivateAccount),
              ),
            ),
            _divider(),
            _tile(
              icon: Icons.delete_outline,
              title: l.settingsDeleteAccount,
              textColor: Colors.red,
              iconColor: Colors.red,
              onTap: () => _confirmDangerAction(
                title: l.settingsDeleteAccount,
                body: l.settingsDeleteConfirm,
                confirmLabel: l.settingsDelete,
                confirmColor: Colors.red,
                onConfirmed: () => _showComingSoon(l.settingsDeleteAccount),
              ),
            ),
          ]),

          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  // ── Help & Support Bottom Sheet ────────────────────────────────────────────

  void _showHelpSheet() {
    final l = context.l10n;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              l.settingsHelpSupport,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
            ),
            SizedBox(height: 20.h),
            _helpTile(
              icon: Icons.mail_outline,
              title: l.settingsContact,
              subtitle: l.settingsContactSubtitle,
              onTap: () {
                Navigator.pop(ctx);
                _showComingSoon(l.settingsContact);
              },
            ),
            SizedBox(height: 12.h),
            _helpTile(
              icon: Icons.quiz_outlined,
              title: l.settingsFaq,
              subtitle: l.settingsFaqSubtitle,
              onTap: () {
                Navigator.pop(ctx);
                _showComingSoon(l.settingsFaq);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _helpTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 20.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                  SizedBox(height: 3.h),
                  Text(subtitle, style: TextStyle(fontSize: 12.sp, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14.sp, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }

  // ── Small Builders ─────────────────────────────────────────────────────────

  Widget _sectionLabel(String label) => Padding(
        padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), letterSpacing: 0.8),
        ),
      );

  Widget _card(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(children: children),
      );

  Widget _divider() => const Divider(height: 1, indent: 52);

  Widget _tile({
    required IconData icon,
    required String title,
    Color? textColor,
    Color? iconColor,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
        child: Row(
          children: [
            Icon(icon, size: 22.sp, color: iconColor ?? const Color(0xFF374151)),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: textColor ?? Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            trailing ?? Icon(Icons.arrow_forward_ios, size: 14.sp, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }

  Widget _toggleTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          Icon(icon, size: 22.sp, color: const Color(0xFF374151)),
          SizedBox(width: 14.w),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
