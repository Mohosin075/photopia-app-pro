import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photopya/core/localization/app_localizations.dart';
import 'package:photopya/features/client/payment_methods_screen.dart';
import 'package:photopya/features/client/privacy_policy_screen.dart';
import 'package:provider/provider.dart';
import 'package:photopya/controller/theme_controller.dart';
import 'package:photopya/controller/client/delete_account_controller.dart';
import 'package:photopya/controller/auth_controller.dart';
import 'package:photopya/controller/client/change_password_controller.dart';
import 'package:photopya/controller/language_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:photopya/features/client/chat_screen.dart';
import 'package:photopya/data/models/conversation_model.dart';
import 'package:photopya/core/widgets/custom_snacbar.dart';
import 'package:photopya/controller/client/chat_controller.dart';
import 'package:photopya/features/client/terms_of_service_screen.dart';
import 'package:photopya/features/common/screens/notification_settings_screen.dart';
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
        backgroundColor: Theme.of(
          context,
        ).colorScheme.onSurface.withOpacity(0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
    );
  }

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
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
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
                          color: Theme.of(
                            context,
                          ).dividerColor.withOpacity(0.1),
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
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
            size: 22.sp,
          ),
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
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()),
              ),
            ),
            _divider(),
            _tile(
              icon: Icons.lock_reset_outlined,
              title: l.settingsChangePassword,
              onTap: _showChangePassword,
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

          // ── Notifications Section ─────────────────────────────────────────
          _sectionLabel(context.l10n.notifications),
          _card([
            _tile(
              icon: Icons.notifications_none_outlined,
              title: 'Notification Settings',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
              ),
            ),
          ]),

          SizedBox(height: 16.h),

          // ── Language Section ──────────────────────────────────────────────
          _sectionLabel(l.language),
          _card([
            Consumer<LanguageController>(
              builder: (context, langController, _) {
                return _tile(
                  icon: Icons.language_outlined,
                  title: l.selectLanguage,
                  trailing: Text(
                    langController.isFrench ? 'Français' : 'English',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                    ),
                  ),
                  onTap: () => _showLanguagePicker(langController),
                );
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
                );
              },
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
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 14.sp,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
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

          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  // ── Language Picker ────────────────────────────────────────────────────────

  void _showLanguagePicker(LanguageController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => Container(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.selectLanguage,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 20.h),
            _languageOption(
              label: 'English',
              isSelected: !controller.isFrench,
              onTap: () {
                controller.setEnglish();
                context.setLocale(const Locale('en'));
                Navigator.pop(ctx);
              },
            ),
            _languageOption(
              label: 'Français',
              isSelected: controller.isFrench,
              onTap: () {
                controller.setFrench();
                context.setLocale(const Locale('fr'));
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _languageOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      title: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
          : null,
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
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 20.h),
            _helpTile(
              icon: Icons.mail_outline,
              title: l.settingsContact,
              subtitle: l.settingsContactSubtitle,
              onTap: () async {
                Navigator.pop(ctx);
                final chatController = context.read<ChatController>();
                final chatId = await chatController.contactAdmin();

                if (chatId != null && context.mounted) {
                  Conversation? conversation;
                  try {
                    final chatRoom = chatController.chats.firstWhere(
                      (c) => c.sId == chatId,
                    );
                    conversation = chatRoom.toConversation(
                      AuthController.userId,
                    );
                  } catch (_) {
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
                }
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
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.onSurface,
                size: 20.sp,
              ),
            ),
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
                  SizedBox(height: 3.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
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

  // ── Small Builders ─────────────────────────────────────────────────────────

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
              color:
                  iconColor ??
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.3),
                ),
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
          Icon(
            icon,
            size: 22.sp,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
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
