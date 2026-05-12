import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:photopia/controller/client/booking_controller.dart';
import 'package:photopia/core/localization/app_localizations.dart';
import 'package:photopia/core/network/urls.dart';
import 'package:photopia/core/widgets/custom_network_image.dart';
import 'package:photopia/data/models/booking_model.dart' hide Provider;
import 'package:photopia/features/client/widgets/auth_profile_image.dart';
import 'package:photopia/data/models/conversation_model.dart';
import 'package:photopia/data/models/chat_message_model.dart';
import 'package:photopia/features/client/chat_screen.dart';
import 'package:photopia/core/services/translation_service.dart';
import 'package:photopia/controller/client/payment_controller.dart';
import 'package:photopia/core/constants/app_sizes.dart';
import 'package:provider/provider.dart';

class ClientBookingDetailsScreen extends StatelessWidget {
  final Booking booking;

  const ClientBookingDetailsScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
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
          context.l10n.orderHistoryTitle, // Or a new key like 'Booking Details'
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18.sp.clamp(18, 20),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProviderInfo(context),
            SizedBox(height: 20.h),
            _buildServiceDetails(context),
            SizedBox(height: 30.h),
            if (booking.status?.toLowerCase() == 'pending' &&
                booking.paymentStatus?.toLowerCase() == 'pending') ...[
              _buildPayButton(context),
              SizedBox(height: 15.h),
            ],
            _buildContactButton(context),
            if (booking.paymentStatus?.toLowerCase() == 'paid' ||
                booking.paymentStatus?.toLowerCase() == 'fully_paid' ||
                booking.status?.toLowerCase() == 'completed') ...[
              SizedBox(height: 12.h),
              _buildDownloadInvoiceButton(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadInvoiceButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.fieldHeight,
      child: OutlinedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Downloading invoice...')),
          );
          // TODO: Implement actual invoice download logic
        },
        icon: Icon(
          Icons.download,
          size: 20.sp,
          color: Theme.of(context).colorScheme.primary,
        ),
        label: Text(
          'Download Invoice',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Theme.of(context).colorScheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          ),
        ),
      ),
    );
  }

  Widget _buildPayButton(BuildContext context) {
    return Consumer<PaymentController>(
      builder: (context, paymentController, child) {
        final hasModifications =
            booking.customOptions != null && booking.customOptions!.isNotEmpty;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          child: Column(
            children: [
              if (hasModifications)
                Padding(
                  padding: EdgeInsets.only(bottom: 15.h),
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.amber.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: Colors.amber[700],
                          size: 18.sp,
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: TranslatedText(
                            'The professional has updated the offer with new options.',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.amber[900],
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 45.h,
                      child: ElevatedButton(
                        onPressed: paymentController.isLoading
                            ? null
                            : () async {
                                if (hasModifications) {
                                  // Always just accept the offer if modified, payment happens at the end
                                  final bookingController =
                                      Provider.of<BookingController>(
                                        context,
                                        listen: false,
                                      );
                                  final success = await bookingController
                                      .acceptModifiedOffer(booking.sId ?? '');
                                  if (success) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Offer Accepted Successfully!',
                                          ),
                                        ),
                                      );
                                      Navigator.pop(context);
                                    }
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            bookingController.errorMessage ??
                                                'Failed to accept offer',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                } else {
                                  // Full payment for pending bookings
                                  final totalAmount =
                                      booking.pricingDetails?.clientTotal ??
                                      booking.totalPrice ??
                                      0;
                                  final dynamic result = await paymentController
                                      .initPaymentSheet(
                                        bookingId: booking.sId,
                                        amount: totalAmount,
                                        currency: booking.currency ?? 'EUR',
                                      );

                                  if (result != false) {
                                    // Check if already paid from response
                                    final String? status = result is Map
                                        ? result['status']?.toString().toLowerCase()
                                        : null;
                                    if (status == 'succeeded') {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Payment Successful!')),
                                        );
                                        Navigator.pop(context);
                                      }
                                    } else {
                                      final paymentSuccess =
                                          await paymentController.presentPaymentSheet();
                                      if (paymentSuccess && context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Payment Successful!')),
                                        );
                                        Navigator.pop(context);
                                      } else if (!paymentSuccess && context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              paymentController.errorMessage ?? 'Payment failed',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            paymentController.errorMessage ?? 'Payment failed',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF2E7D32,
                          ), // Premium Green
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 0,
                        ),
                        child: paymentController.isLoading
                            ? SizedBox(
                                height: 18.h,
                                width: 18.h,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : FittedBox(
                                child: TranslatedText(
                                  hasModifications
                                      ? 'Accept Offer'
                                      : 'Pay Now',
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                  if (hasModifications) ...[
                    SizedBox(width: 10.w),
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 45.h,
                        child: OutlinedButton(
                          onPressed: () => _showDeclineDialog(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.red.withOpacity(0.3),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: FittedBox(
                            child: TranslatedText(
                              'Decline',
                              style: TextStyle(
                                color: Colors.red[400],
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPayRemainingButton(BuildContext context) {
    return Consumer2<PaymentController, BookingController>(
      builder: (context, paymentController, bookingController, child) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          child: SizedBox(
            width: double.infinity,
            height: 45.h,
            child: ElevatedButton(
              onPressed:
                  paymentController.isLoading || bookingController.isLoading
                  ? null
                  : () async {
                      final paymentData = await bookingController.payBalance(
                        bookingId: booking.sId ?? '',
                      );

                      if (paymentData != null) {
                        final clientSecret =
                            paymentData['clientSecret'] ??
                            paymentData['client_secret'];
                        final ephemeralKey =
                            paymentData['ephemeralKey'] ??
                            paymentData['ephemeral_key'];
                        final customerId =
                            paymentData['customerId'] ??
                            paymentData['customer_id'];

                        if (clientSecret != null) {
                          await Stripe.instance.initPaymentSheet(
                            paymentSheetParameters: SetupPaymentSheetParameters(
                              paymentIntentClientSecret: clientSecret,
                              customerEphemeralKeySecret: ephemeralKey,
                              customerId: customerId,
                              merchantDisplayName: 'Photopia',
                              style: ThemeMode.light,
                            ),
                          );

                          final paymentSuccess = await paymentController
                              .presentPaymentSheet();
                          if (paymentSuccess) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Balance Paid Successfully!'),
                                ),
                              );
                              Navigator.pop(context);
                            }
                          }
                        } else if (paymentData['status'] == 'succeeded') {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Balance Paid Successfully!'),
                              ),
                            );
                            Navigator.pop(context);
                          }
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                bookingController.errorMessage ??
                                    'Failed to pay balance',
                              ),
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
              child: paymentController.isLoading || bookingController.isLoading
                  ? SizedBox(
                      height: 18.h,
                      width: 18.h,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : FittedBox(
                      child: TranslatedText(
                        'Pay Remaining',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  void _showDeclineDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: TranslatedText('Decline Modified Offer?'),
        content: TranslatedText(
          'Are you sure you want to decline this modified offer? You can contact the professional to negotiate further.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: TranslatedText('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: TranslatedText(
              'Decline',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderInfo(BuildContext context) {
    final provider = booking.providerId;
    final status = booking.status ?? 'pending';

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.02,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranslatedText(
                    'Professional Info',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 8.w),
              _buildStatusBadge(status),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Builder(
                builder: (context) {
                  String? profileUrl = provider?.profile;
                  if (profileUrl != null && !profileUrl.startsWith('http')) {
                    String path = profileUrl;
                    if (path.startsWith('uploads/')) {
                      path = path.replaceFirst('uploads/', '');
                    } else if (path.startsWith('/uploads/')) {
                      path = path.replaceFirst('/uploads/', '');
                    }

                    final String base = Urls.baseUrl.endsWith('/')
                        ? Urls.baseUrl.substring(0, Urls.baseUrl.length - 1)
                        : Urls.baseUrl;
                    final String finalPath = path.startsWith('/')
                        ? path
                        : '/$path';
                    profileUrl = '$base$finalPath';
                  }
                  return AuthProfileImage(imageUrl: profileUrl, size: 60.w);
                },
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TranslatedText(
                      provider?.name ?? 'Unknown Professional',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Booking ID: #${booking.bookingId ?? booking.sId?.substring(0, 8)}',
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDetails(BuildContext context) {
    final service = booking.serviceId;
    final package = booking.package;

    String coverUrl = service?.coverMedia ?? '';
    if (coverUrl.isNotEmpty && !coverUrl.startsWith('http')) {
      coverUrl = '${Urls.baseUrl}/$coverUrl';
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TranslatedText(
            'Service Details',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: CustomNetworkImage(
                  imageUrl: coverUrl,
                  width: 70.w,
                  height: 70.w,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TranslatedText(
                      service?.title ?? 'Service Name',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    TranslatedText(
                      package?.name ?? 'Standard Package',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          const Divider(),
          SizedBox(height: 16.h),
          _buildInfoRow(
            context,
            Icons.calendar_today_outlined,
            'Date',
            booking.bookingDate?.split('T')[0] ?? 'N/A',
          ),
          _buildInfoRow(
            context,
            Icons.access_time,
            'Time',
            '${booking.startTime ?? ''} - ${booking.endTime ?? ''}',
          ),
          _buildInfoRow(
            context,
            Icons.location_on_outlined,
            'Location',
            service?.location?.address ?? 'Location not set',
          ),
          if (booking.customOptions != null &&
              booking.customOptions!.isNotEmpty) ...[
            SizedBox(height: 16.h),
            const Divider(),
            SizedBox(height: 16.h),
            TranslatedText(
              'Add-ons',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8.h),
            ...booking.customOptions!
                .map(
                  (option) => Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TranslatedText(
                          option.name ?? '',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          '${(booking.currency == 'EUR') ? '€' : (booking.currency ?? '€')}${option.price?.toStringAsFixed(0) ?? '0'}',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ],
          SizedBox(height: 10.h),
          const Divider(),
          SizedBox(height: 16.h),
              Builder(
                builder: (context) {
                  final pricing = booking.pricingDetails;
                  double subtotal = pricing?.subtotal ?? 0;
                  double platformFee = (pricing?.clientTotal ?? 0) - subtotal;
                  if (platformFee < 0) platformFee = 0;
                  
                  double total = pricing?.clientTotal ?? booking.totalPrice ?? 0;
                  String currency = (booking.currency == 'EUR') ? '€' : (booking.currency ?? '€');

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TranslatedText(
                            'Subtotal',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                          Text(
                            '$currency${subtotal.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      if (platformFee > 0) ...[
                        SizedBox(height: 4.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TranslatedText(
                              'Platform Fee (10%)',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                            Text(
                              '$currency${platformFee.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                      SizedBox(height: 8.h),
                      const Divider(),
                      SizedBox(height: 8.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TranslatedText(
                            'Total Payable',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            '$currency${total.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
        const SizedBox(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16.sp,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: TranslatedText(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        break;
      case 'upcoming':
      case 'confirmed':
        color = Colors.blue;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildContactButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.fieldHeight,
      child: ElevatedButton(
        onPressed: () {
          final provider = booking.providerId;
          if (provider == null || provider.sId == null) return;

          final conversation = Conversation(
            id: '',
            name: provider.name ?? 'Professional',
            lastMessage: '',
            avatarUrl: provider.profile ?? '',
            lastMessageTime: DateTime.now(),
            unreadCount: 0,
            isOnline: false,
            status: MessageStatus.read,
            isTemporary: true,
            receiverId: provider.sId!,
          );

          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (context) => ChatScreen(conversation: conversation),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          ),
          elevation: 0,
        ),
        child: TranslatedText(
          'Contact Professional',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
