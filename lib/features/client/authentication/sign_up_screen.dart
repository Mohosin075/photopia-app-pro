import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:photopya/core/constants/app_typography.dart';
import 'package:photopya/core/constants/app_sizes.dart';
import 'package:photopya/features/client/authentication/widgets/auth_widgets.dart';
import 'package:provider/provider.dart';
import 'package:photopya/controller/client/sign_up_controller.dart';
import 'package:photopya/core/widgets/custom_snacbar.dart';
import 'package:photopya/core/localization/app_localizations.dart';

class SignUpScreen extends StatefulWidget {
  static const String name = '/sign_up';
  final String userRole; // 'client' or 'provider'

  const SignUpScreen({super.key, this.userRole = 'client'});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isNameValid = false;
  bool _isEmailValid = false;
  bool _isPasswordValid = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateName(String value) {
    setState(() {
      _isNameValid = value.length >= 2;
    });
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

                // Title
                Text(
                  context.l10n.createAccount,
                  style: TextStyle(
                    fontSize: 24.sp.clamp(24, 28),
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),

                SizedBox(height: 32.h.clamp(32, 40)),

                // Name Field
                AuthTextField(
                  label: context.l10n.nameLabel,
                  controller: _nameController,
                  hintText: 'Photopia',
                  isValid: _isNameValid,
                  onChanged: _validateName,
                ),

                SizedBox(height: AppSizes.spacingMedium),

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

                SizedBox(height: AppSizes.spacingLarge),

                // Sign Up Button
                Consumer<SignUpController>(
                  builder: (context, signUpController, child) {
                    return AuthButton(
                      text: context.l10n.signUpBtn,
                      isLoading: signUpController.inProgress,
                      onTap: () async {
                        if (!_isNameValid ||
                            !_isEmailValid ||
                            !_isPasswordValid) {
                          CustomSnackBar.show(
                            context: context,
                            message: context.l10n.fillAllFields,
                            isError: true,
                          );
                          return;
                        }

                        final result = await signUpController.signUp(
                          _emailController.text.trim(),
                          _nameController.text.trim(),
                          _passwordController.text,
                        );

                        if (result) {
                          if (mounted) {
                            Navigator.pushNamed(
                              context,
                              '/otp_verification',
                              arguments: {
                                'email': _emailController.text.trim(),
                                'isForgotPassword': false,
                              },
                            );
                          }
                        } else {
                          if (mounted) {
                            final errorMessage =
                                signUpController.errorMessage ?? '';
                            if (errorMessage.toLowerCase().contains(
                              'already exist',
                            )) {
                              CustomSnackBar.show(
                                context: context,
                                message: context.l10n.accountAlreadyExists,
                              );
                              Navigator.pushNamed(
                                context,
                                '/otp_verification',
                                arguments: {
                                  'email': _emailController.text.trim(),
                                  'isForgotPassword': false,
                                },
                              );
                            } else {
                              CustomSnackBar.show(
                                context: context,
                                message:
                                    signUpController.errorMessage ??
                                    context.l10n.registrationFailed,
                                isError: true,
                              );
                            }
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
                    Expanded(
                      child: Divider(
                        color: isDark ? Colors.white10 : Colors.grey.shade300,
                      ),
                    ),
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
                    Expanded(
                      child: Divider(
                        color: isDark ? Colors.white10 : Colors.grey.shade300,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24.h.clamp(24, 28)),

                // Social Sign Up Buttons
                Row(
                  children: [
                    Expanded(
                      child: SocialButton(
                        icon: Icons.g_mobiledata,
                        label: 'Google',
                        onTap: () {
                          // TODO: Implement Google sign up
                        },
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: SocialButton(
                        icon: Icons.facebook,
                        label: 'Facebook',
                        onTap: () {
                          // TODO: Implement Facebook sign up
                        },
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 32.h.clamp(32, 40)),

                // Log In Link
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: RichText(
                      text: TextSpan(
                        text: context.l10n.alreadyHaveAccount,
                        style: TextStyle(
                          fontSize: AppTypography.bodyMedium,
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                        children: [
                          TextSpan(
                            text: context.l10n.logInLink,
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
