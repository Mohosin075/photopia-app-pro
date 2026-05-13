import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photopia/controller/client/booking_controller.dart';
import 'package:photopia/core/constants/app_typography.dart';
import 'package:photopia/data/models/booking_model.dart' hide Provider;
import 'package:provider/provider.dart';
import 'package:photopia/features/client/widgets/auth_profile_image.dart';
import 'package:photopia/core/network/urls.dart';
import 'package:photopia/core/localization/app_localizations.dart';
import 'package:photopia/features/client/client_booking_details_screen.dart';
import 'package:photopia/core/services/translation_service.dart';
import 'package:photopia/core/widgets/app_refresher.dart';
import 'package:photopia/core/utils/app_transitions.dart';

class OrderHistoryScreen extends StatefulWidget {
  static const String name = '/order_history';
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late String _selectedFilter;
  late List<String> _filters;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l = context.l10n;
    _filters = [
      l.filterAllOrders,
      l.filterUpcoming,
      l.statusCompleted,
      l.statusCancelled,
    ];
    _selectedFilter = _filters[0];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingController>().getMyBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.l10n.orderHistoryTitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20.sp.clamp(20, 22),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: Consumer<BookingController>(
              builder: (context, controller, child) {
                if (controller.isLoading && controller.bookings.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredBookings = _getFilteredBookings(
                  controller.bookings,
                );

                if (filteredBookings.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async => await controller.getMyBookings(),
                    color: Theme.of(context).colorScheme.primary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: 400.h,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 60.sp,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.1),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              context.l10n.noOrdersFound,
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => await controller.getMyBookings(),
                  color: Theme.of(context).colorScheme.primary,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(20.w),
                    itemCount: filteredBookings.length,
                    itemBuilder: (context, index) {
                      return _buildOrderCard(filteredBookings[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 60.h,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 15.w),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 10.h),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Booking> _getFilteredBookings(List<Booking> bookings) {
    final l = context.l10n;
    if (_selectedFilter == l.filterAllOrders) return bookings;
    String apiStatus = 'upcoming';
    if (_selectedFilter == l.statusCompleted)
      apiStatus = 'completed';
    else if (_selectedFilter == l.statusCancelled)
      apiStatus = 'cancelled';
    else if (_selectedFilter == l.filterUpcoming)
      apiStatus = 'upcoming';
    return bookings.where((b) => b.status?.toLowerCase() == apiStatus).toList();
  }

  Widget _buildOrderCard(Booking booking) {
    String formattedDate = booking.bookingDate ?? '';
    if (formattedDate.contains('T')) {
      formattedDate = formattedDate.split('T')[0];
    }

    String coverUrl =
        booking.serviceId?.coverMedia ??
        booking.serviceId?.cover_media ??
        booking.serviceId?.cover_image ??
        '';
    debugPrint("🖼️ Service Title: ${booking.serviceId?.title}");
    debugPrint("🖼️ Raw Cover URL: $coverUrl");

    if (coverUrl.isNotEmpty && !coverUrl.startsWith('http')) {
      if (coverUrl.startsWith('/')) {
        coverUrl = '${Urls.baseUrl}$coverUrl';
      } else {
        coverUrl = '${Urls.baseUrl}/$coverUrl';
      }
    }
    debugPrint("🖼️ Final Cover URL: $coverUrl");

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          AppTransitions.createPremiumRoute(
            ClientBookingDetailsScreen(booking: booking),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.04,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: coverUrl.isNotEmpty
                      ? Image.network(
                          coverUrl,
                          width: 70.w,
                          height: 70.w,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildImagePlaceholder(context),
                        )
                      : _buildImagePlaceholder(context),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: TranslatedText(
                              booking.serviceId?.title ??
                                  context.l10n.serviceTitleDefault,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildStatusBadge(booking.status ?? 'PENDING'),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      TranslatedText(
                        booking.package?.name ??
                            context.l10n.standardPackageDefault,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Builder(
                            builder: (context) {
                              String? profileUrl = booking.providerId?.profile;
                              if (profileUrl != null &&
                                  !profileUrl.startsWith('http')) {
                                String path = profileUrl;
                                if (path.startsWith('uploads/')) {
                                  path = path.replaceFirst('uploads/', '');
                                } else if (path.startsWith('/uploads/')) {
                                  path = path.replaceFirst('/uploads/', '');
                                }

                                final String base = Urls.baseUrl.endsWith('/')
                                    ? Urls.baseUrl.substring(
                                        0,
                                        Urls.baseUrl.length - 1,
                                      )
                                    : Urls.baseUrl;
                                final String finalPath = path.startsWith('/')
                                    ? path
                                    : '/$path';
                                profileUrl = '$base$finalPath';
                              }
                              return AuthProfileImage(
                                imageUrl: profileUrl,
                                size: 18.w,
                              );
                            },
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            booking.providerId?.name ??
                                context.l10n.providerNameDefault,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).dividerColor.withOpacity(0.05),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                _buildInfoChip(
                  context,
                  Icons.calendar_today_outlined,
                  formattedDate,
                ),
                SizedBox(width: 12.w),
                _buildInfoChip(
                  context,
                  Icons.access_time,
                  booking.startTime ?? '00:00',
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14.sp,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    booking.serviceId?.location?.address ??
                        context.l10n.locationNotSet,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Builder(
                  builder: (context) {
                    String price = '0';
                    final pricing = booking.pricingDetails;

                    if (pricing != null &&
                        pricing.clientTotal != null &&
                        pricing.clientTotal != 0) {
                      price = pricing.clientTotal!.toStringAsFixed(0);
                    } else {
                      price = booking.totalPrice?.toStringAsFixed(0) ?? '0';
                    }

                    return Text(
                      '${(booking.currency == 'EUR') ? '€' : (booking.currency ?? '€')}$price',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  },
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    context.l10n.viewDetails,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (booking.customOptions != null &&
                booking.customOptions!.isNotEmpty &&
                (booking.paymentStatus?.toLowerCase() == 'paid' ||
                    booking.paymentStatus?.toLowerCase() == 'completed')) ...[
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                height: 36.h,
                child: ElevatedButton(
                  onPressed: () async {
                    final bookingController = Provider.of<BookingController>(
                      context,
                      listen: false,
                    );
                    final success = await bookingController.acceptModifiedOffer(
                      booking.sId ?? '',
                    );
                    if (success) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Offer Accepted Successfully!'),
                          ),
                        );
                        bookingController.getMyBookings(); // Refresh list
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    elevation: 0,
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    'Accept Modified Offer',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(BuildContext context) {
    return Container(
      width: 70.w,
      height: 70.w,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      child: Icon(
        Icons.image_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14.sp,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
        ),
        SizedBox(width: 6.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = const Color(0xFF4CAF50);
        break;
      case 'upcoming':
      case 'pending':
        color = const Color(0xFF2196F3);
        break;
      case 'cancelled':
        color = const Color(0xFFF44336);
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
