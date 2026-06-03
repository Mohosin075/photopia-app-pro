import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photopya/core/localization/app_localizations.dart';
import 'package:photopya/features/client/privacy_policy_screen.dart';
import 'package:photopya/features/client/settings_screen.dart';
import 'package:photopya/features/client/authentication/forgot_password_screen.dart';
import 'package:photopya/controller/client/change_password_controller.dart';
import 'package:photopya/controller/client/delete_account_controller.dart';
import 'package:photopya/controller/auth_controller.dart';
import 'package:photopya/core/widgets/custom_snacbar.dart';
import 'package:photopya/features/common/screens/notification_settings_screen.dart';
import 'package:provider/provider.dart';

class PrivacySecurityScreen extends StatefulWidget {
  static const String name = '/privacy_security';
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  void _showChangePassword() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Text(
            context.l10n.settingsChangePassword,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: oldPasswordController,
                    obscureText: obscureOld,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      suffixIcon: IconButton(
                        icon: Icon(obscureOld ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setDialogState(() => obscureOld = !obscureOld),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  SizedBox(height: 16.h),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: obscureNew,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                  ),
                  SizedBox(height: 16.h),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirm,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                      ),
                    ),
                    validator: (v) => v != newPasswordController.text ? 'Passwords do not match' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.cancelBtn),
            ),
            Consumer<ChangePasswordController>(
              builder: (context, controller, _) {
                return ElevatedButton(
                  onPressed: controller.isLoading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            final success = await controller.changePassword(
                              oldPassword: oldPasswordController.text,
                              newPassword: newPasswordController.text,
                            );
                            if (success && mounted) {
                              Navigator.pop(ctx);
                              CustomSnackBar.show(
                                context: context,
                                message: 'Password changed successfully',
                                isError: false,
                              );
                            } else if (mounted) {
                              CustomSnackBar.show(
                                context: context,
                                message: controller.errorMessage ?? 'Failed to change password',
                                isError: true,
                              );
                            }
                          }
                        },
                  child: controller.isLoading
                      ? SizedBox(
                          height: 20.h,
                          width: 20.h,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Update'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDangerAction({
    required String title,
    required String body,
    required String confirmLabel,
    required Color confirmColor,
    required VoidCallback onConfirmed,
    bool showPasswordField = false,
    Future<void> Function(String, BuildContext)? onConfirmedWithPasswordCallback,
  }) {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          contentPadding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 8.h),
          actionsPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    height: 1.4,
                  ),
                ),
                if (showPasswordField) ...[
                  SizedBox(height: 20.h),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      hintStyle: TextStyle(fontSize: 13.sp),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: Theme.of(context).dividerColor.withOpacity(0.1),
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      side: BorderSide(
                        color: Theme.of(context).dividerColor.withOpacity(0.1),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      context.l10n.cancelBtn,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Consumer<DeleteAccountController>(
                    builder: (context, controller, child) {
                      return ElevatedButton(
                        onPressed: controller.isLoading
                            ? null
                            : () {
                                if (showPasswordField && onConfirmedWithPasswordCallback != null) {
                                  if (formKey.currentState!.validate()) {
                                    onConfirmedWithPasswordCallback(
                                      passwordController.text,
                                      ctx,
                                    );
                                  }
                                } else {
                                  Navigator.pop(ctx);
                                  onConfirmed();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: confirmColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: controller.isLoading
                            ? SizedBox(
                                height: 16.h,
                                width: 16.h,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                confirmLabel,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDeleteAccount(
    String password,
    BuildContext dialogContext,
  ) async {
    final controller = context.read<DeleteAccountController>();
    final success = await controller.deleteAccount(password);

    if (success) {
      if (mounted) {
        Navigator.pop(dialogContext);
        CustomSnackBar.show(
          context: context,
          message: 'Account deleted successfully',
          isError: false,
        );
        await AuthController.forceLogout();
      }
    } else {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: controller.errorMessage ?? 'Failed to delete account',
          isError: true,
        );
      }
    }
  }

  Future<void> _handleDeactivateAccount(
    String password,
    BuildContext dialogContext,
  ) async {
    final controller = context.read<DeleteAccountController>();
    final success = await controller.deactivateAccount(password);

    if (success) {
      if (mounted) {
        Navigator.pop(dialogContext);
        CustomSnackBar.show(
          context: context,
          message: 'Account deactivated successfully',
          isError: false,
        );
        await AuthController.forceLogout();
      }
    } else {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: controller.errorMessage ?? 'Failed to deactivate account',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.colorScheme.onSurface,
            size: 22.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy & Security',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
        children: [
          // ── Privacy Section ──
          _sectionLabel('PRIVACY'),
          _card([
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
              icon: Icons.notifications_none_outlined,
              title: 'Notification Settings',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
              ),
            ),
          ]),

          SizedBox(height: 20.h),

          // ── Security Section ──
          _sectionLabel('SECURITY'),
          _card([
            _tile(
              icon: Icons.lock_reset_outlined,
              title: l.settingsChangePassword,
              onTap: _showChangePassword,
            ),
          ]),

          SizedBox(height: 20.h),

          // ── Danger Zone ──
          _sectionLabel('DANGER ZONE'),
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
                showPasswordField: true,
                onConfirmed: () {},
                onConfirmedWithPasswordCallback: _handleDeactivateAccount,
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
                showPasswordField: true,
                onConfirmed: () {},
                onConfirmedWithPasswordCallback: _handleDeleteAccount,
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
        padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            letterSpacing: 0.8,
          ),
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
            Icon(
              icon,
              size: 22.sp,
              color: iconColor ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
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
            trailing ??
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14.sp,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                ),
          ],
        ),
      ),
    );
  }
}
