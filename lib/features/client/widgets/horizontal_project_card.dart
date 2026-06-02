import 'package:photopya/core/network/Api_service/network_caller.dart';
import 'package:photopya/core/network/urls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:photopya/controller/client/favorites_controller.dart';
import 'package:photopya/controller/auth_controller.dart';
import 'package:photopya/core/utils/guest_dialog_helper.dart';
import 'package:photopya/core/widgets/custom_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:photopya/features/client/widgets/service_card.dart';
import 'package:photopya/features/client/search_result_screen.dart';
import 'package:photopya/core/services/translation_service.dart';
import 'dart:ui';

class HorizontalProjectCard extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String providerName;
  final double? rating;
  final num? price;
  final bool isAvailable;
  final dynamic id;
  final dynamic providerId;
  final List<String>? tags;
  final VoidCallback? onTap;

  const HorizontalProjectCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.providerName,
    this.rating,
    this.price,
    this.isAvailable = false,
    this.id,
    this.providerId,
    this.tags,
    this.onTap,
  });

  @override
  State<HorizontalProjectCard> createState() => _HorizontalProjectCardState();
}

class _HorizontalProjectCardState extends State<HorizontalProjectCard> {
  late Future<NetworkResponse> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = NetworkCaller.getRequest(
      url: Urls.getSingleList(widget.id),
      requireAuth: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 140.w,
        margin: EdgeInsets.only(right: 8.w, bottom: 2.h),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.black.withOpacity(0.3) 
                  : Colors.black.withOpacity(0.04),
              blurRadius: 6,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(12.r),
                  ),
                  child: (widget.imageUrl != null && widget.imageUrl.isNotEmpty)
                      ? CustomNetworkImage(
                          imageUrl: widget.imageUrl,
                          width: 140.w,
                          height: 125.h,
                          fit: BoxFit.cover,
                        )
                      : FutureBuilder<NetworkResponse>(
                          future: _imageFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Container(
                                width: 140.w,
                                height: 125.h,
                                child: Shimmer.fromColors(
                                  baseColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[300]!,
                                  highlightColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[100]!,
                                  child: Container(color: Theme.of(context).colorScheme.surface),
                                ),
                              );
                            }
                            String? fetchedUrl;
                            if (snapshot.hasData &&
                                snapshot.data!.isSuccess &&
                                snapshot.data!.body != null) {
                              final data = snapshot.data!.body!['data'];
                              if (data != null) {
                                fetchedUrl =
                                    data['coverMedia'] ??
                                    (data['gallery'] != null &&
                                            (data['gallery'] as List).isNotEmpty
                                        ? (data['gallery'] as List).first
                                        : null);
                              }
                            }
                            if (fetchedUrl != null && fetchedUrl.isNotEmpty) {
                              return CustomNetworkImage(
                                imageUrl: fetchedUrl,
                                width: 140.w,
                                height: 125.h,
                                fit: BoxFit.cover,
                              );
                            } else {
                              return CustomNetworkImage(
                                imageUrl: '',
                                width: 140.w,
                                height: 125.h,
                                fit: BoxFit.cover,
                              ); // Default grey placeholder without const
                            }
                          },
                        ),
                ),
                // Availability Badge
                if (widget.isAvailable)
                  Positioned(
                    top: 8.h,
                    left: 8.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bookmark_outline,
                            size: 10.sp,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          SizedBox(width: 4.w),
                          TranslatedText(
                            'Available',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Favorite Toggle Badge
                Positioned(
                  top: 8.h,
                  right: 8.w,
                  child: Consumer<FavoritesController>(
                    builder: (context, controller, child) {
                      bool isFavorite = controller.isPostFavorite(widget.id);
                      return GestureDetector(
                        onTap: () {
                          if (!AuthController.isLoggedIn) {
                            GuestDialogHelper.showGuestDialog(context);
                            return;
                          }
                          controller.toggleFavorite(
                            serviceId: widget.id,
                            optimisticData: {
                              '_id': widget.id,
                              'id': widget.id,
                              'title': widget.title,
                              'providerName': widget.providerName,
                              'imageUrl': widget.imageUrl,
                              'rating': widget.rating,
                            },
                          );
                        },
                        child: ClipOval(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding: EdgeInsets.all(4.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 0.5,
                                ),
                              ),
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: Colors.red,
                                size: 16.sp,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            // Content Section
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(8.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TranslatedText(
                      widget.title,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 12.sp,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: TranslatedText(
                            widget.providerName,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Tags in the middle as requested
                    if (widget.tags != null && widget.tags!.isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Wrap(
                        spacing: 4.w,
                        runSpacing: 4.h,
                        children: widget.tags!.take(3).map((tag) {
                          return GestureDetector(
                            onTap: () {
                              final formattedTag = tag.startsWith('#') ? tag : '#$tag';
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SearchResultScreen(
                                    filters: {'searchTerm': formattedTag},
                                    title: formattedTag,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.grey.shade800 
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                '#$tag',
                                style: TextStyle(
                                  fontSize: 9.sp, 
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    // Spacer to push price and ratings to the bottom
                    const Spacer(),
                    if (widget.rating != null || widget.price != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RatingInfoWidget(
                            providerId: widget.providerId?.toString(),
                            initialRating: widget.rating ?? 0.0,
                            initialReviews: 0,
                            starSize: 12.sp,
                            fontSize: 11.sp,
                          ),
                          if (widget.price != null)
                            Text(
                              '€${widget.price}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
