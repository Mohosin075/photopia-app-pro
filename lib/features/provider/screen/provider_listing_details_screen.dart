import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photopya/controller/client/service_list_controller.dart';
import 'package:photopya/controller/provider/my_listing_controller.dart';
import 'package:photopya/core/constants/app_typography.dart';
import 'package:photopya/core/widgets/custom_network_image.dart';
import 'package:photopya/core/widgets/my_loader.dart';
import 'package:photopya/core/widgets/video_player_screen.dart';
import 'package:photopya/features/provider/screen/provider_create_listing_screen.dart';
import 'package:provider/provider.dart';
import 'package:photopya/core/localization/app_localizations.dart';
import 'package:photopya/core/services/translation_service.dart';

class ProviderListingDetailsScreen extends StatefulWidget {
  final String listingId;

  const ProviderListingDetailsScreen({super.key, required this.listingId});

  @override
  State<ProviderListingDetailsScreen> createState() =>
      _ProviderListingDetailsScreenState();
}

class _ProviderListingDetailsScreenState
    extends State<ProviderListingDetailsScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use ServiceListController (same as client) — proven image loading
      context.read<ServiceListController>().getServiceById(widget.listingId);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _isVideo(String url) {
    final String lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Consumer<ServiceListController>(
        builder: (context, serviceCtrl, child) {
          if (serviceCtrl.isLoading) {
            return Center(child: MyLoader());
          }

          final detail = serviceCtrl.serviceDetail;

          // Build image list — identical to client service_details_screen
          final String coverMedia = detail?.coverMedia ?? '';
          final List<dynamic> gallery = detail?.gallery ?? [];
          final List<String> images = [];
          if (coverMedia.isNotEmpty) images.add(coverMedia);
          for (var item in gallery) {
            final String path = item.toString();
            if (path.isNotEmpty && !images.contains(path)) images.add(path);
          }

          final int safeIndex =
              _currentPage < images.length ? _currentPage : 0;

          return Stack(
            children: [
              // ── Main scrollable content (mirrors client layout) ──
              RefreshIndicator(
                onRefresh: () async {
                  await serviceCtrl.getServiceById(widget.listingId);
                },
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full-bleed image carousel
                      Stack(
                        children: [
                          SizedBox(
                            height: 380.h,
                            width: double.infinity,
                            child: images.isEmpty
                                ? Container(
                                    color: Colors.grey[200],
                                    child: Icon(Icons.image,
                                        size: 60.sp, color: Colors.grey[400]),
                                  )
                                : PageView.builder(
                                    controller: _pageController,
                                    onPageChanged: (index) =>
                                        setState(() => _currentPage = index),
                                    itemCount: images.length,
                                    itemBuilder: (context, index) {
                                      if (_isVideo(images[index])) {
                                        return GestureDetector(
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  VideoPlayerScreen(
                                                      videoUrl: images[index]),
                                            ),
                                          ),
                                          child: Container(
                                            color: Colors.black,
                                            child: Icon(
                                                Icons.play_circle_fill,
                                                color: Colors.white,
                                                size: 60.sp),
                                          ),
                                        );
                                      }
                                      return CustomNetworkImage(
                                        imageUrl: images[index],
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  ),
                          ),
                          // Back button overlay
                          Positioned(
                            top: MediaQuery.of(context).padding.top + 8.h,
                            left: 16.w,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.arrow_back,
                                    color: Colors.white, size: 20.sp),
                              ),
                            ),
                          ),
                          // Dot indicators
                          if (images.length > 1)
                            Positioned(
                              bottom: 16.h,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  images.length,
                                  (i) => AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 300),
                                    margin:
                                        EdgeInsets.symmetric(horizontal: 3.w),
                                    width: safeIndex == i ? 18.w : 6.w,
                                    height: 6.h,
                                    decoration: BoxDecoration(
                                      color: safeIndex == i
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.5),
                                      borderRadius:
                                          BorderRadius.circular(3.r),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          // Status badge overlay
                          if (detail?.status != null)
                            Positioned(
                              top: MediaQuery.of(context).padding.top + 8.h,
                              right: 16.w,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10.w, vertical: 5.h),
                                decoration: BoxDecoration(
                                  color: (detail!.status!.toLowerCase() ==
                                          'active')
                                      ? const Color(0xFF2E7D32)
                                      : Colors.orange,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  detail.status!.toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                      // ── Content section ──
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 20.w, vertical: 20.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            TranslatedText(
                              detail?.title ?? context.l10n.noTitle,
                              style: TextStyle(
                                fontSize: 22.sp.clamp(20, 24),
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface,
                              ),
                            ),
                            SizedBox(height: 8.h),

                            // Price & Duration
                            Row(
                              children: [
                                Text(
                                  '${detail?.currency ?? 'EUR'}${detail?.price ?? 0}',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                  ),
                                ),
                                if (detail?.duration != null) ...[
                                  Text(
                                    '  ·  ',
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.4)),
                                  ),
                                  Text(
                                    '${detail!.duration!.value} ${detail.duration!.unit}',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: 16.h),

                            // Category / SubCategory tag
                            if (detail?.category?.name != null ||
                                detail?.serviceType != null)
                              Wrap(
                                spacing: 8.w,
                                runSpacing: 6.h,
                                children: [
                                  if (detail?.serviceType != null)
                                    _buildChip(
                                        detail!.serviceType!
                                            .replaceAll('_', ' '),
                                        context),
                                  if (detail?.category?.name != null)
                                    _buildChip(
                                        detail!.category!.name!, context),
                                ],
                              ),
                            SizedBox(height: 24.h),

                            // Description
                            if (detail?.description != null &&
                                detail!.description!.isNotEmpty) ...[
                              Text(
                                context.l10n.description,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              TranslatedText(
                                detail!.description!,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7),
                                  height: 1.6,
                                ),
                              ),
                              SizedBox(height: 24.h),
                            ],

                            // Location
                            if (detail?.location != null) ...[
                              _buildSectionTitle(
                                  context.l10n.location, context),
                              SizedBox(height: 8.h),
                              _buildInfoCard(
                                context,
                                children: [
                                  _buildInfoRow(
                                    Icons.location_on_outlined,
                                    '${detail!.location!.city ?? ''}, ${detail.location!.country ?? ''}',
                                    context,
                                  ),
                                  if (detail.location!.type != null)
                                    _buildInfoRow(
                                      Icons.home_work_outlined,
                                      'Type: ${detail.location!.type!.replaceAll('_', ' ')}',
                                      context,
                                    ),
                                  if (detail.location!.serviceRadiusKm !=
                                      null)
                                    _buildInfoRow(
                                      Icons.radio_button_checked_outlined,
                                      'Service Radius: ${detail.location!.serviceRadiusKm} km',
                                      context,
                                    ),
                                ],
                              ),
                              SizedBox(height: 24.h),
                            ],

                            // Equipment
                            if (detail?.equipment != null &&
                                detail!.equipment!.isNotEmpty) ...[
                              _buildSectionTitle(
                                  context.l10n.equipmentUtilized, context),
                              SizedBox(height: 8.h),
                              Wrap(
                                spacing: 8.w,
                                runSpacing: 6.h,
                                children: detail!.equipment!
                                    .map((e) => _buildChip(e, context))
                                    .toList(),
                              ),
                              SizedBox(height: 24.h),
                            ],

                            // Tags
                            if (detail?.tags != null &&
                                detail!.tags!.isNotEmpty) ...[
                              _buildSectionTitle('Tags', context),
                              SizedBox(height: 8.h),
                              Wrap(
                                spacing: 8.w,
                                runSpacing: 6.h,
                                children: detail!.tags!
                                    .toSet()
                                    .map((t) => _buildChip(
                                        t.startsWith('#') ? t : '#$t',
                                        context))
                                    .toList(),
                              ),
                              SizedBox(height: 24.h),
                            ],

                            // Extra bottom padding for the action bar
                            SizedBox(height: 100.h),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Provider action bar (Edit / Delete / Toggle) ──
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Consumer<MyListingController>(
                  builder: (context, myCtrl, child) {
                    return Container(
                      padding: EdgeInsets.fromLTRB(
                          20.w,
                          12.h,
                          20.w,
                          MediaQuery.of(context).padding.bottom + 12.h),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Edit button
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await myCtrl
                                    .getSingleListing(widget.listingId);
                                if (!mounted) return;
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ProviderCreateListingScreen(
                                      existingListing:
                                          myCtrl.singleListingData,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  serviceCtrl
                                      .getServiceById(widget.listingId);
                                }
                              },
                              icon: Icon(Icons.edit_outlined, size: 16.sp),
                              label: Text(context.l10n.edit,
                                  style: TextStyle(fontSize: 13.sp)),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                side: BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.outline),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r)),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          // Delete button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _showDeleteDialog(context, myCtrl),
                              icon: Icon(Icons.delete_outline,
                                  size: 16.sp, color: Colors.white),
                              label: Text(context.l10n.settingsDelete,
                                  style: TextStyle(
                                      fontSize: 13.sp, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildChip(String label, BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade800
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context,
      {required List<Widget> children}) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 16.sp,
              color:
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, MyListingController myCtrl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(context.l10n.deleteListing,
            style: TextStyle(
                fontSize: 18.sp, fontWeight: FontWeight.bold)),
        content: Text(context.l10n.doYouWantToDelete,
            style: TextStyle(fontSize: 14.sp)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r))),
            onPressed: () async {
              Navigator.pop(ctx);
              final success =
                  await myCtrl.deleteListing(widget.listingId);
              if (success && mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(context.l10n.settingsDelete,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
