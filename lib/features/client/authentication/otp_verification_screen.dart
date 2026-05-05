import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photopia/core/constants/app_typography.dart';
import 'package:photopia/features/client/authentication/widgets/auth_widgets.dart';
import 'package:provider/provider.dart';
import 'package:photopia/controller/client/verify_otp_controller.dart';
import 'package:photopia/core/widgets/custom_snacbar.dart';
import 'package:photopia/core/localization/app_localizations.dart';

class OtpVerificationScreen extends StatefulWidget {
  static const String name = '/otp_verification';
  final String email;
  final bool isForgotPassword;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.isForgotPassword = false,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  bool _isOtpComplete() {
    return _otpControllers.every((controller) => controller.text.isNotEmpty);
  }

  Future<void> _submitOtp() async {
    if (_isOtpComplete()) {
      String otp = _otpControllers.map((c) => c.text).join();
      final verifyOtpController = Provider.of<VerifyOtpController>(
        context,
        listen: false,
      );

      final result = await verifyOtpController.verifyOtp(widget.email, otp);

      if (result) {
        if (mounted) {
          CustomSnackBar.show(
            context: context,
            message: context.l10n.verificationSuccessful,
            isError: false,
          );
          if (widget.isForgotPassword) {
            Navigator.pushNamed(
              context,
              '/new_password',
              arguments: {
                'email': widget.email,
                'token': verifyOtpController.resetToken,
              },
            );
          } else {
            Navigator.pushReplacementNamed(context, '/log_in');
          }
        }
      } else {
        if (mounted) {
          CustomSnackBar.show(
            context: context,
            message: verifyOtpController.errorMessage ?? context.l10n.verificationFailed,
            isError: true,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16.h.clamp(16, 20)),

              // Back Button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.arrow_back,
                  size: 24.sp.clamp(24, 28),
                  color: theme.colorScheme.onSurface,
                ),
              ),

              SizedBox(height: 32.h.clamp(32, 40)),

              // Title
              Text(
                context.l10n.otpVerificationTitle,
                style: TextStyle(
                  fontSize: 24.sp.clamp(24, 28),
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),

              SizedBox(height: 12.h.clamp(12, 16)),

              // Subtitle
              Text(
                context.l10n.codeSubmit,
                style: TextStyle(
                  fontSize: 18.sp.clamp(18, 20),
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),

              SizedBox(height: 8.h.clamp(8, 12)),

              Text(
                context.l10n.enterCodeSentTo(widget.email),
                style: TextStyle(
                  fontSize: AppTypography.bodyMedium,
                  color: isDark ? Colors.white38 : Colors.grey.shade600,
                  height: 1.5,
                ),
              ),

              SizedBox(height: 32.h.clamp(32, 40)),

              // OTP Input Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) => _buildOtpBox(index)),
              ),

              SizedBox(height: 32.h.clamp(32, 40)),

              // Submit Button
              Consumer<VerifyOtpController>(
                builder: (context, controller, child) {
                  return AuthButton(
                    text: context.l10n.submitBtn,
                    isLoading: controller.inProgress,
                    onTap: _submitOtp,
                    isEnabled: _isOtpComplete() && !controller.inProgress,
                  );
                },
              ),

              SizedBox(height: 16.h.clamp(16, 20)),

              // Resend Link
              Center(
                child: GestureDetector(
                  onTap: () {
                    // TODO: Implement resend OTP logic
                  },
                  child: RichText(
                    text: TextSpan(
                      text: context.l10n.didntReceiveCode,
                      style: TextStyle(
                        fontSize: AppTypography.bodyMedium,
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                      children: [
                        TextSpan(
                          text: context.l10n.resendAgain,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 45.w.clamp(40, 60),
      height: 55.h.clamp(45, 65),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _otpControllers[index].text.isNotEmpty
              ? (isDark ? Colors.white : const Color(0xFF1A1A1A))
              : (isDark ? Colors.white10 : Colors.grey.shade300),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        cursorColor: theme.colorScheme.primary,
        style: TextStyle(
          fontSize: 24.sp.clamp(24, 28),
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
        ),
        onChanged: (value) {
          setState(() {});
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }
}
