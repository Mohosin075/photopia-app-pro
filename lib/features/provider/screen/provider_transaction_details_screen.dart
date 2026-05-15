import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photopya/core/constants/app_typography.dart';
import 'package:photopya/core/constants/app_sizes.dart';
import 'package:photopya/features/provider/screen/provider_request_payout_screen.dart';

class ProviderTransactionDetailsScreen extends StatelessWidget {
  const ProviderTransactionDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,

        title: Text(
          'Transaction Details',
          style: TextStyle(
            fontSize: AppTypography.h1,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16.w),
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 14.sp, color: Colors.blue),
                SizedBox(width: 4.w),
                Text(
                  'Completed',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'INV-2024-001234',
              style: TextStyle(
                fontSize: AppTypography.bodySmall,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            SizedBox(height: 24.h),

            // Service Section
            Text(
              'Service',
              style: TextStyle(
                fontSize: AppTypography.bodyMedium,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Wedding Photography',
              style: TextStyle(
                fontSize: AppTypography.h2,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14.sp, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                SizedBox(width: 6.w),
                 Text(
                  '2024-12-01',
                  style: TextStyle(fontSize: AppTypography.bodyMedium, color: Theme.of(context).colorScheme.onSurface),
                ),
                SizedBox(width: 16.w),
                Icon(Icons.access_time, size: 14.sp, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                SizedBox(width: 6.w),
                 Text(
                  '8 hours',
                  style: TextStyle(fontSize: AppTypography.bodyMedium, color: Theme.of(context).colorScheme.onSurface),
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Client Section
            Text(
              'Client',
              style: TextStyle(
                fontSize: AppTypography.bodyMedium,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                CircleAvatar(
                  radius: 20.r,
                  backgroundImage: const AssetImage(
                    'assets/images/img6.png',
                  ),
                ),
                SizedBox(width: 12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text(
                      'Sarah Johnson',
                      style: TextStyle(
                        fontSize: AppTypography.bodyLarge,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'sarah.j@email.com',
                      style: TextStyle(
                        fontSize: AppTypography.bodySmall,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16.sp,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                SizedBox(width: 8.w),
                 Text(
                  '123 Garden Street, New York, NY',
                  style: TextStyle(fontSize: AppTypography.bodyMedium, color: Theme.of(context).colorScheme.onSurface),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            Divider(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
            SizedBox(height: 24.h),

            // Payment Breakdown
            Text(
              'Payment Breakdown',
              style: TextStyle(
                fontSize: AppTypography.bodyLarge,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 16.h),
            _buildBreakdownItem(context, 'Subtotal', '€1500.00', isBold: true),
            _buildBreakdownItem(
              context,
              'Platform Fee (5%)',
              '-€75.00',
              valueColor: Colors.red,
            ),
            SizedBox(height: 8.h),
            Divider(color: Theme.of(context).dividerColor.withOpacity(0.1)),
            SizedBox(height: 8.h),
            _buildBreakdownItem(
              context,
              'Your Earnings',
              '€1425.00',
              isBold: true,
              valueColor: Colors.green,
              fontSize: 18.sp,
            ),

            SizedBox(height: 32.h),

            // Additional Details
            _buildInfoRow(context, 'Payment Method', 'Bank Transfer'),
            _buildInfoRow(context, 'Expected Payout', '2024-12-15'),
            _buildInfoRow(context, 'Status', 'Processing', valueColor: Colors.blue),

            SizedBox(height: 32.h),

            // Buttons
            SizedBox(
              width: double.infinity,
              height: AppSizes.fieldHeight,
              child: ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.onSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                  ),
                ),
                icon: Icon(Icons.download, color: Theme.of(context).colorScheme.surface, size: 20.sp),
                label: Text(
                  'Download Invoice',
                  style: TextStyle(
                    fontSize: AppTypography.bodyLarge,
                    color: Theme.of(context).colorScheme.surface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              height: AppSizes.fieldHeight,
              child: OutlinedButton.icon(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                  ),
                ),
                icon: Icon(Icons.share, color: Theme.of(context).colorScheme.onSurface, size: 20.sp),
                label: Text(
                  'Share Invoice',
                  style: TextStyle(
                    fontSize: AppTypography.bodyLarge,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              height: AppSizes.fieldHeight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProviderRequestPayoutScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                  ),
                ),
                child: Text(
                  'Request Payout',
                  style: TextStyle(
                    fontSize: AppTypography.bodyLarge,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownItem(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
    double? fontSize,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 14.sp : 13.sp,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize ?? (isBold ? 14.sp : 13.sp),
              color: valueColor ?? Theme.of(context).colorScheme.onSurface,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.bodyMedium,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: AppTypography.bodyMedium,
              color: valueColor ?? Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
