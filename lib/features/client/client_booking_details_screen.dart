import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photopia/core/localization/app_localizations.dart';
import 'package:photopia/core/network/urls.dart';
import 'package:photopia/core/widgets/custom_network_image.dart';
import 'package:photopia/data/models/booking_model.dart';
import 'package:photopia/features/client/widgets/auth_profile_image.dart';
import 'package:photopia/data/models/conversation_model.dart';
import 'package:photopia/data/models/chat_message_model.dart';
import 'package:photopia/features/client/chat_screen.dart';
import 'package:photopia/core/services/translation_service.dart';

class ClientBookingDetailsScreen extends StatelessWidget {
  final Booking booking;

  const ClientBookingDetailsScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.l10n.orderHistoryTitle, // Or a new key like 'Booking Details'
          style: TextStyle(
            color: Colors.black,
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
            _buildContactButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderInfo(BuildContext context) {
    final provider = booking.providerId;
    final status = booking.status ?? 'pending';

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
              Expanded(
                child: TranslatedText(
                  'Professional Info',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
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
                    profileUrl = '${Urls.baseUrl}$profileUrl';
                  }
                  return AuthProfileImage(
                    imageUrl: profileUrl,
                    size: 60.w,
                  );
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
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Booking ID: #${booking.bookingId ?? booking.sId?.substring(0, 8)}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[500],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TranslatedText(
            'Service Details',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
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
                      ),
                    ),
                    SizedBox(height: 4.h),
                    TranslatedText(
                      package?.name ?? 'Standard Package',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey[600],
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
          _buildInfoRow(Icons.calendar_today_outlined, 'Date', booking.bookingDate?.split('T')[0] ?? 'N/A'),
          _buildInfoRow(Icons.access_time, 'Time', '${booking.startTime ?? ''} - ${booking.endTime ?? ''}'),
          _buildInfoRow(Icons.location_on_outlined, 'Location', service?.location?.address ?? 'Location not set'),
          SizedBox(height: 10.h),
          const Divider(),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TranslatedText(
                'Total Amount',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '${booking.currency ?? '€'}${booking.totalPrice?.toStringAsFixed(0) ?? '0'}',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Icon(icon, size: 16.sp, color: Colors.grey[400]),
          SizedBox(width: 12.w),
          Expanded(
            child: TranslatedText(
              label,
              style: TextStyle(fontSize: 13.sp, color: Colors.grey[500]),
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
                color: Colors.black,
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
      height: 55.h,
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
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.r),
          ),
          elevation: 0,
        ),
        child: TranslatedText(
          'Contact Professional',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
