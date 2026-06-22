import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photopya/core/constants/app_typography.dart';
import 'package:photopya/core/constants/app_sizes.dart';
import 'package:photopya/core/widgets/custom_network_image.dart';
import 'package:photopya/core/localization/app_localizations.dart';

class ProviderTransactionDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const ProviderTransactionDetailsScreen({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final type = transaction['type'];
    final isWithdrawal = type == 'withdrawal';
    final status = transaction['status']?.toString().toLowerCase() ?? 'pending';
    final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
    
    final dateRaw = transaction['date'] ?? '';
    final date = dateRaw.contains('T') ? dateRaw.split('T')[0] : dateRaw;

    final title = transaction['title'] ?? (isWithdrawal ? context.l10n.txWithdrawal : context.l10n.txServiceBooking);
    final transactionId = isWithdrawal 
        ? (transaction['id'] ?? 'N/A') 
        : (transaction['raw'] is Map && transaction['raw']['bookingId'] != null 
            ? transaction['raw']['bookingId'] 
            : transaction['id'] ?? 'N/A');

    // Status styling
    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.access_time_rounded;
    String statusText = context.l10n.txStatusPending;

    if (status == 'completed' || status == 'succeeded' || status == 'confirmed') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_rounded;
      statusText = context.l10n.txStatusCompleted;
    } else if (status == 'failed' || status == 'cancelled') {
      statusColor = Colors.red;
      statusIcon = Icons.cancel_rounded;
      statusText = status == 'failed' ? context.l10n.txStatusFailed : context.l10n.txStatusCancelled;
    }

    // Pricing details extraction
    double subtotal = amount;
    double platformFee = 0.0;
    double earnings = amount;

    if (!isWithdrawal && transaction['raw'] is Map) {
      final pricingDetails = transaction['raw']['pricingDetails'];
      if (pricingDetails is Map) {
        subtotal = (pricingDetails['subtotal'] as num?)?.toDouble() ?? amount;
        platformFee = (pricingDetails['platformCommissionProvider'] as num?)?.toDouble() ?? 0.0;
        earnings = (pricingDetails['providerEarnings'] as num?)?.toDouble() ?? amount;
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        title: Text(
          context.l10n.transactionDetailsTitle,
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
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(statusIcon, size: 14.sp, color: statusColor),
                SizedBox(width: 4.w),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: statusColor,
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
              isWithdrawal ? context.l10n.txPayoutId(transactionId.toString()) : context.l10n.txBookingId(transactionId.toString()),
              style: TextStyle(
                fontSize: AppTypography.bodySmall,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            SizedBox(height: 24.h),

            // Service Section
            Text(
              isWithdrawal ? context.l10n.txPayoutPurpose : context.l10n.txServiceLabel,
              style: TextStyle(
                fontSize: AppTypography.bodyMedium,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              title,
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
                  date,
                  style: TextStyle(fontSize: AppTypography.bodyMedium, color: Theme.of(context).colorScheme.onSurface),
                ),
                if (!isWithdrawal && transaction['raw'] is Map && transaction['raw']['startTime'] != null) ...[
                  SizedBox(width: 16.w),
                  Icon(Icons.access_time, size: 14.sp, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                  SizedBox(width: 6.w),
                  Text(
                    transaction['raw']['startTime']?.toString() ?? '',
                    style: TextStyle(fontSize: AppTypography.bodyMedium, color: Theme.of(context).colorScheme.onSurface),
                  ),
                ],
              ],
            ),
            SizedBox(height: 24.h),

            // Client / Destination Section
            Text(
              isWithdrawal ? context.l10n.txDestination : context.l10n.txClientLabel,
              style: TextStyle(
                fontSize: AppTypography.bodyMedium,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            SizedBox(height: 12.h),
            if (!isWithdrawal && transaction['raw'] is Map) ...[
              _buildClientSection(context, transaction['raw']['clientId']),
            ] else ...[
              _buildPayoutDestinationSection(context),
            ],
            
            SizedBox(height: 24.h),
            Divider(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
            SizedBox(height: 24.h),

            // Payment Breakdown
            Text(
              isWithdrawal ? context.l10n.txPayoutBreakdown : context.l10n.txPaymentBreakdown,
              style: TextStyle(
                fontSize: AppTypography.bodyLarge,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 16.h),
            if (!isWithdrawal) ...[
              _buildBreakdownItem(context, context.l10n.txSubtotal, '€${subtotal.toStringAsFixed(2)}', isBold: true),
              _buildBreakdownItem(
                context,
                context.l10n.txPlatformFee,
                '-€${platformFee.toStringAsFixed(2)}',
                valueColor: Colors.red,
              ),
              SizedBox(height: 8.h),
              Divider(color: Theme.of(context).dividerColor.withOpacity(0.1)),
              SizedBox(height: 8.h),
              _buildBreakdownItem(
                context,
                context.l10n.txYourEarnings,
                '€${earnings.toStringAsFixed(2)}',
                isBold: true,
                valueColor: Colors.green,
                fontSize: 18.sp,
              ),
            ] else ...[
              _buildBreakdownItem(context, context.l10n.txRequestedPayout, '€${amount.toStringAsFixed(2)}', isBold: true),
              _buildBreakdownItem(
                context,
                context.l10n.txProcessingFee,
                '€0.00',
                valueColor: Colors.grey,
              ),
              SizedBox(height: 8.h),
              Divider(color: Theme.of(context).dividerColor.withOpacity(0.1)),
              SizedBox(height: 8.h),
              _buildBreakdownItem(
                context,
                context.l10n.txTransferredAmount,
                '€${amount.toStringAsFixed(2)}',
                isBold: true,
                valueColor: Colors.green,
                fontSize: 18.sp,
              ),
            ],

            SizedBox(height: 32.h),

            // Additional Details
            _buildInfoRow(
              context, 
              context.l10n.txPaymentMethod, 
              isWithdrawal ? context.l10n.txStripeConnect : context.l10n.txStripeGateway
            ),
            if (!isWithdrawal && transaction['raw'] is Map && transaction['raw']['paymentStatus'] != null)
              _buildInfoRow(
                context, 
                context.l10n.txPaymentStatus, 
                transaction['raw']['paymentStatus']?.toString().toUpperCase() ?? '',
                valueColor: transaction['raw']['paymentStatus']?.toString().toLowerCase() == 'paid' ? Colors.green : Colors.orange
              ),
            _buildInfoRow(context, context.l10n.txStatus, statusText, valueColor: statusColor),

            SizedBox(height: 32.h),

            // Close Button
            SizedBox(
              width: double.infinity,
              height: AppSizes.fieldHeight,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.onSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                  ),
                ),
                child: Text(
                  context.l10n.close,
                  style: TextStyle(
                    fontSize: AppTypography.bodyLarge,
                    color: Theme.of(context).colorScheme.surface,
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

  Widget _buildClientSection(BuildContext context, dynamic clientData) {
    final client = clientData is Map ? clientData : {};
    final name = client['name'] ?? context.l10n.unknownClient;
    final email = client['email'] ?? context.l10n.txNoEmailShared;
    final imageUrl = client['profile'] ?? client['profileImage'] ?? client['image'] ?? client['avatar'] ?? '';

    return Row(
      children: [
        CustomNetworkImage(
          imageUrl: imageUrl,
          width: 40.r,
          height: 40.r,
          shape: BoxShape.circle,
          fit: BoxFit.cover,
        ),
        SizedBox(width: 12.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: AppTypography.bodyLarge,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              email,
              style: TextStyle(
                fontSize: AppTypography.bodySmall,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPayoutDestinationSection(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(Icons.account_balance, size: 24.sp, color: Theme.of(context).colorScheme.onSurface),
        ),
        SizedBox(width: 12.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.txStripeConnectAccount,
              style: TextStyle(
                fontSize: AppTypography.bodyLarge,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              context.l10n.txDirectBankTransfer,
              style: TextStyle(
                fontSize: AppTypography.bodySmall,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
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
