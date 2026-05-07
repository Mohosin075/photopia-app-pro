import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photopia/core/constants/app_typography.dart';
import 'package:photopia/core/constants/app_sizes.dart';
import 'package:photopia/features/client/authentication/widgets/auth_widgets.dart';
import 'package:provider/provider.dart';
import 'package:photopia/controller/client/sign_in_controller.dart';
import 'package:photopia/controller/auth_controller.dart';
import 'package:photopia/core/widgets/custom_snacbar.dart';
import 'package:photopia/core/network/Api_service/network_caller.dart';
import 'package:photopia/core/network/urls.dart';
import 'package:photopia/core/notification/notification_service.dart';
import 'package:photopia/core/routes/app_routes.dart';
import 'package:photopia/core/localization/app_localizations.dart';

class LogInScreen extends StatefulWidget {
  static const String name = '/log_in';
  final String userRole; // 'client' or 'provider'

  const LogInScreen({super.key, this.userRole = 'client'});

  @override
  State<LogInScreen> createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isEmailValid = false;
  bool _isPasswordValid = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateEmail(String value) {
    setState(() {
      _isEmailValid = value.contains('@') && value.length > 3;
    });
  }

  void _validatePassword(String value) {
    setState(() {
      _isPasswordValid = value.length >= 6;
    });
  }

  void _clearControllers() {
    _emailController.clear();
    _passwordController.clear();
    setState(() {
      _isEmailValid = false;
      _isPasswordValid = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 32.h.clamp(32, 40)),
                // Logo
                Center(
                  child: Image.asset(
                    Theme.of(context).brightness == Brightness.dark
                        ? 'assets/images/app_name_dark.png'
                        : 'assets/images/app_name_light.png',
                    height: 40.h,
                    fit: BoxFit.contain,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                SizedBox(height: 40.h),
                // Title
                Text(
                  context.l10n.logInToContinue,
                  style: TextStyle(
                    fontSize: 24.sp.clamp(24, 28),
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),

                SizedBox(height: 32.h.clamp(32, 40)),

                // Email Field
                AuthTextField(
                  label: context.l10n.emailLabel,
                  controller: _emailController,
                  hintText: context.l10n.emailHint,
                  isValid: _isEmailValid,
                  onChanged: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                ),

                SizedBox(height: AppSizes.spacingMedium),

                // Password Field
                AuthTextField(
                  label: context.l10n.passwordLabel,
                  controller: _passwordController,
                  hintText: '••••••••••',
                  isValid: _isPasswordValid,
                  onChanged: _validatePassword,
                  isPassword: true,
                ),

                SizedBox(height: 12.h.clamp(12, 16)),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      debugPrint('➡️ Navigating to Forgot Password, clearing controllers');
                      _clearControllers();
                      Navigator.pushNamed(context, '/forgot_password');
                    },
                    child: Text(
                      context.l10n.forgotPassword,
                      style: TextStyle(
                        fontSize: AppTypography.bodyMedium,
                        color: const Color(0xFF2196F3),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: AppSizes.spacingLarge),

                // Login Button
                Consumer<SignInController>(
                  builder: (context, signInController, child) {
                    return AuthButton(
                      text: context.l10n.loginBtn,
                      isLoading: signInController.inProgress,
                      onTap: () async {
                        debugPrint('🚀 Login button clicked');
                        if (!_isEmailValid || !_isPasswordValid) {
                          debugPrint('⚠️ Validation failed: Email=$_isEmailValid, Password=$_isPasswordValid');
                          CustomSnackBar.show(
                            context: context,
                            message: context.l10n.validEmailPasswordRequired,
                            isError: true,
                          );
                          return;
                        }

                        debugPrint('📡 Calling signIn with: ${_emailController.text.trim()}');
                        final result = await signInController.signIn(
                          _emailController.text.trim(),
                          _passwordController.text,
                        );

                        debugPrint('🏁 Login result: $result');
                        if (result) {
                          if (mounted) {
                            debugPrint('✅ Login successful, preparing navigation...');
                            
                            // Determine active role immediately from AuthController
                            final activeRole = AuthController.activeRole ?? (widget.userRole == 'provider' ? 'professional' : 'user');
                            
                            CustomSnackBar.show(
                              context: context,
                              message: context.l10n.loginSuccessful,
                              isError: false,
                            );

                            // Navigate IMMEDIATELY
                            if (activeRole == 'professional') {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                AppRoutes.provider_bottom_navigation,
                                (route) => false,
                              );
                            } else {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                AppRoutes.bottom_navigation,
                                (route) => false,
                              );
                            }

                            // Perform background tasks after navigation start
                            Future.microtask(() async {
                              // 1. Sync FCM token
                              NotificationService.instance.getTokenAndSendToBackend();

                              // 2. Refresh profile in background to ensure role is up to date for next app launch
                              try {
                                final profileResp = await NetworkCaller.getRequest(url: Urls.userProfile);
                                if (profileResp.isSuccess && profileResp.body != null) {
                                  final resolvedRole = profileResp.body!['data']?['activeRole']?.toString() 
                                              ?? profileResp.body!['data']?['role']?.toString();
                                  if (resolvedRole != null) {
                                    await AuthController.saveUserRole(resolvedRole);
                                  }
                                }
                              } catch (e) {
                                debugPrint('⚠️ Background profile refresh failed: $e');
                              }
                            });
                          }
                        } else {
                          if (mounted) {
                            debugPrint('❌ Login failed: ${signInController.errorMessage}');
                            CustomSnackBar.show(
                              context: context,
                              message:
                                  signInController.errorMessage ??
                                  context.l10n.loginFailed,
                              isError: true,
                            );
                          }
                        }
                      },
                    );
                  },
                ),

                SizedBox(height: 24.h.clamp(24, 28)),

                // OR CONTINUE WITH
                Row(
                  children: [
                    Expanded(child: Divider(color: isDark ? Colors.white10 : Colors.grey.shade300)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text(
                        context.l10n.orContinueWith,
                        style: TextStyle(
                          fontSize: AppTypography.bodySmall,
                          color: isDark ? Colors.white38 : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: isDark ? Colors.white10 : Colors.grey.shade300)),
                  ],
                ),

                SizedBox(height: 24.h.clamp(24, 28)),

                // Social Login Buttons
                Row(
                  children: [
                    Expanded(
                      child: SocialButton(
                        icon: Icons.g_mobiledata,
                        label: 'Google',
                        onTap: () {
                          // TODO: Implement Google login
                        },
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: SocialButton(
                        icon: Icons.facebook,
                        label: 'Facebook',
                        onTap: () {
                          // TODO: Implement Facebook login
                        },
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 32.h.clamp(32, 40)),

                // Sign Up Link
                Center(
                  child: GestureDetector(
                    onTap: () {
                      debugPrint('➡️ Navigating to Sign Up, clearing controllers');
                      _clearControllers();
                      Navigator.pushNamed(
                        context,
                        '/sign_up',
                        arguments: widget.userRole,
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        text: context.l10n.noAccount,
                        style: TextStyle(
                          fontSize: AppTypography.bodyMedium,
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                        children: [
                          TextSpan(
                            text: context.l10n.signUpLink,
                            style: TextStyle(
                              fontSize: AppTypography.bodyMedium,
                              color: const Color(0xFF2196F3),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 24.h.clamp(24, 32)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
