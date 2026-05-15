import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photopya/core/localization/app_localizations.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.l10n.settingsTermsOfService,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Terms of Service",
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "Last updated: May 2026",
              style: TextStyle(
                fontSize: 12.sp,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            SizedBox(height: 24.h),
            _buildSection(
              context,
              title: "1. Acceptance of Terms",
              content: "By accessing and using Photopia, you accept and agree to be bound by the terms and provisions of this agreement. This platform connects professional photographers and videographers with clients.",
            ),
            _buildSection(
              context,
              title: "2. User Responsibilities",
              content: "You are responsible for maintaining the confidentiality of your account and password. You must provide accurate, current, and complete information during the registration process and update such information to keep it accurate.",
            ),
            _buildSection(
              context,
              title: "3. Professional Services",
              content: "Professionals on our platform offer photography and videography services. Photopia acts as a marketplace to connect clients and professionals but is not a party to the actual contract between them.",
            ),
            _buildSection(
              context,
              title: "4. Payments & Deposits",
              content: "All payments are processed securely through our verified payment partners. Users agree to pay all charges at the prices then in effect for their purchases.",
            ),
            _buildSection(
              context,
              title: "5. Cancellation & Refunds",
              content: "Cancellations must be made according to the professional's cancellation policy. Refunds are subject to the specific terms agreed upon at the time of booking.",
            ),
            _buildSection(
              context,
              title: "6. User Conduct",
              content: "You agree not to use the service for any unlawful purpose or in any way that interrupts, damages, impairs, or renders the service less efficient.",
            ),
            SizedBox(height: 30.h),
            Center(
              child: Text(
                "Thank you for using Photopia!",
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required String content}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            content,
            style: TextStyle(
              fontSize: 14.sp,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
