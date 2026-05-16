import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SubscriptionBadge extends StatelessWidget {
  final bool isSubscribed;
  final double? fontSize;
  final double? iconSize;
  final EdgeInsetsGeometry? padding;

  const SubscriptionBadge({
    super.key,
    required this.isSubscribed,
    this.fontSize,
    this.iconSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (!isSubscribed) return const SizedBox.shrink();

    return Container(
      padding: padding ?? EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD4A017), Color(0xFFF5C842)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4A017).withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            color: Colors.white,
            size: iconSize ?? 12.sp,
          ),
          SizedBox(width: 4.w),
          Text(
            'Premium',
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize ?? 10.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
