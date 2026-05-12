import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photopia/core/constants/app_typography.dart';
import 'package:photopia/core/constants/app_sizes.dart';

/// Reusable custom text field for authentication screens
class AuthTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  final bool isValid;
  final Function(String) onChanged;
  final bool isPassword;
  final TextInputType keyboardType;
  final bool showValidationIcon;

  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    required this.isValid,
    required this.onChanged,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.showValidationIcon = true,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: AppTypography.bodyMedium,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: AppSizes.spacingSmall),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            obscureText: widget.isPassword ? _obscureText : false,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            textAlignVertical: TextAlignVertical.center,
            cursorColor: theme.colorScheme.primary,
            style: TextStyle(
              fontSize: AppTypography.bodyMedium,
              color: theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                fontSize: AppTypography.bodyMedium,
                color: isDark ? Colors.white38 : Colors.grey.shade400,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 12.h,
              ),
              suffixIcon: widget.isPassword
                  ? IconButton(
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                      icon: Icon(
                        _obscureText
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: isDark ? Colors.white38 : Colors.grey.shade500,
                        size: 20.sp.clamp(20, 24),
                      ),
                      splashRadius: 20,
                    )
                  : (widget.showValidationIcon && widget.controller.text.isNotEmpty
                      ? Icon(
                          widget.isValid ? Icons.check : null,
                          color: isDark ? Colors.white38 : Colors.grey.shade400,
                          size: 20.sp.clamp(20, 24),
                        )
                      : null),
            ),
          ),
        ),
      ],
    );
  }
}

/// Reusable primary button for authentication screens
class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool isEnabled;
  final bool isLoading;

  const AuthButton({
    super.key,
    required this.text,
    required this.onTap,
    this.isEnabled = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: (isEnabled && !isLoading) ? onTap : null,
      child: Container(
        width: double.infinity,
        height: AppSizes.fieldHeight,
        decoration: BoxDecoration(
          color: isEnabled 
              ? (isDark ? Colors.white : const Color(0xFF1A1A1A)) 
              : (isDark ? Colors.white10 : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? SizedBox(
                height: 20.h,
                width: 20.h,
                child: CircularProgressIndicator(
                  color: isDark ? Colors.black : Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  color: isEnabled 
                      ? (isDark ? Colors.black : Colors.white) 
                      : (isDark ? Colors.white24 : Colors.grey.shade500),
                  fontSize: AppTypography.bodyLarge,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

/// Reusable social login/signup button
class SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const SocialButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: AppSizes.fieldHeight,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24.sp.clamp(24, 28),
              color: icon == Icons.g_mobiledata 
                  ? const Color(0xFFDB4437) 
                  : const Color(0xFF1877F2),
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                fontSize: AppTypography.bodyMedium,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
