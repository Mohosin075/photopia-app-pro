import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import 'package:photopya/features/client/book_now_SelectPackage_screen.dart';
import 'package:photopya/features/client/book_now_confirmation_screen.dart';
import 'package:photopya/features/client/provider_profile_screen.dart';
import 'package:photopya/core/widgets/custom_network_image.dart';
import 'package:photopya/controller/auth_controller.dart';
import 'package:photopya/core/utils/guest_dialog_helper.dart';
import 'package:provider/provider.dart';
import 'package:photopya/controller/client/favorites_controller.dart';
import 'package:photopya/controller/client/service_list_controller.dart';
import 'package:photopya/core/widgets/video_player_screen.dart';
import 'package:photopya/data/models/conversation_model.dart';
import 'package:photopya/data/models/chat_message_model.dart';
import 'package:photopya/core/widgets/subscription_badge.dart';
import 'package:photopya/features/client/chat_screen.dart';
import 'package:photopya/features/client/search_result_screen.dart';
import 'package:photopya/core/localization/app_localizations.dart';
import 'package:photopya/core/services/translation_service.dart';
import 'package:photopya/features/client/widgets/auth_profile_image.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> service;

  const ServiceDetailsScreen({super.key, required this.service});

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = widget.service['id'] ?? widget.service['_id'];
      if (id != null) {
        context.read<ServiceListController>().getServiceById(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Main Scrollable Content
          Consumer<ServiceListController>(
            builder: (context, controller, child) {
              final serviceDetail = controller.serviceDetail;
              final isLoading = controller.isLoading;

              final String title = serviceDetail?.title ?? widget.service['title'] ?? context.l10n.serviceDetailsTitle;
              final String description = serviceDetail?.description ?? context.l10n.noDescriptionAvailable;
              final List<String> equipment = serviceDetail?.equipment ?? [];
              final List<dynamic> gallery = serviceDetail?.gallery ?? [];
              final String coverMedia = serviceDetail?.coverMedia ?? widget.service['coverMedia'] ?? widget.service['imageUrl'] ?? '';
              final String _rawProviderName = serviceDetail?.providerId?.name ?? widget.service['subtitle'] ?? context.l10n.professional;
              final String providerName = _rawProviderName.trim().split(' ').first;
              final String providerAvatar = serviceDetail?.providerId?.profile ?? '';
              final double rating = serviceDetail?.rating ?? (widget.service['rating'] ?? 0.0).toDouble();
              final int reviews = serviceDetail?.reviews ?? widget.service['reviews'] ?? 0;
              final List<String> customTags = (serviceDetail?.tags != null && serviceDetail!.tags!.isNotEmpty)
                  ? serviceDetail.tags!
                  : (widget.service['tags'] is List ? List<String>.from(widget.service['tags']) : []);
              final bool isPremiumProvider = serviceDetail?.providerId?.isSubscribed ?? widget.service['isPremium'] == true;

              return Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: () async {
                      final id = widget.service['id'] ?? widget.service['_id'];
                      if (id != null) {
                        await controller.getServiceById(id.toString());
                      }
                    },
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTopMedia(coverMedia, gallery, isLoading),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 20.h),
                                TranslatedText(title, style: TextStyle(fontSize: 20.sp.clamp(20, 22), fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                                SizedBox(height: 20.h),
                                Text(context.l10n.providerLabel, style: TextStyle(fontSize: 14.sp.clamp(14, 16), fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                                SizedBox(height: 12.h),
                               _buildProviderCard(providerName, providerAvatar, rating, reviews, isPremiumProvider),

                                SizedBox(height: 20.h),
                                _buildStatsRow(
                                  responseTime: serviceDetail?.responseTime ?? widget.service['responseTime']?.toString(),
                                  completedProjects: serviceDetail?.completedProjects ?? widget.service['completedProjects'],
                                ),
                                SizedBox(height: 25.h),
                                _buildSectionTitle(context.l10n.aboutLabel),
                                SizedBox(height: 8.h),
                                TranslatedText(description, style: TextStyle(fontSize: 13.sp.clamp(13, 14), color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8), height: 1.5)),
                                 if (serviceDetail != null && serviceDetail.otherServices != null && serviceDetail.otherServices!.isNotEmpty) ...[
                                   SizedBox(height: 25.h),
                                   Row(
                                     children: [
                                       Icon(Icons.add_task_outlined, size: 20.sp, color: Theme.of(context).colorScheme.onSurface),
                                       SizedBox(width: 8.w),
                                       _buildSectionTitle("Other Services Offered"),
                                     ],
                                   ),
                                   SizedBox(height: 12.h),
                                   Wrap(
                                     spacing: 8.w,
                                     runSpacing: 8.h,
                                     children: serviceDetail.otherServices!.map((serviceName) {
                                       return Container(
                                         padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                         decoration: BoxDecoration(
                                           color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                           borderRadius: BorderRadius.circular(20.r),
                                           border: Border.all(
                                             color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                                             width: 1,
                                           ),
                                         ),
                                         child: Text(
                                           serviceName,
                                           style: TextStyle(
                                             color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                                             fontWeight: FontWeight.w600,
                                             fontSize: 12.sp,
                                           ),
                                         ),
                                       );
                                     }).toList(),
                                   ),
                                 ],
                                 if (equipment.isNotEmpty) ...[
                                  SizedBox(height: 25.h),
                                  Row(children: [Icon(Icons.camera_alt_outlined, size: 20.sp, color: Theme.of(context).colorScheme.onSurface), SizedBox(width: 8.w), _buildSectionTitle(context.l10n.equipmentLabel)]),
                                  SizedBox(height: 12.h),
                                  _buildEquipmentTags(equipment),
                                ],
                                if (gallery.isNotEmpty) ...[
                                  SizedBox(height: 25.h),
                                  _buildSectionTitle(context.l10n.portfolioTitle),
                                  SizedBox(height: 12.h),
                                  _buildPortfolioGrid(gallery),
                                ],
                                if (customTags.isNotEmpty) ...[
                                  SizedBox(height: 25.h),
                                  _buildSectionTitle('Tags'),
                                  SizedBox(height: 12.h),
                                  _buildBottomTags(customTags),
                                ],
                                SizedBox(height: 120.h),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildBottomBar(
                      providerId: serviceDetail?.providerId?.sId ?? (widget.service['providerId'] is Map ? widget.service['providerId']['_id'] : widget.service['providerId'])?.toString() ?? '',
                      name: providerName,
                      avatar: providerAvatar,
                      fullService: serviceDetail?.toJson() ?? widget.service,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  bool _isVideo(String url) {
    final String lower = url.toLowerCase();
    return lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.avi') || lower.endsWith('.mkv') || lower.endsWith('.webm');
  }

  Widget _buildTopMedia(String coverMedia, List<dynamic> gallery, bool isLoading) {
    final List<String> images = [];
    if (coverMedia.isNotEmpty) images.add(coverMedia);
    for (var item in gallery) {
      final String path = item.toString();
      if (path.isNotEmpty && !images.contains(path)) images.add(path);
    }
    final int safeIndex = _currentPage < images.length ? _currentPage : 0;

    return Stack(
      children: [
        Container(
          height: 380.h,
          width: double.infinity,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: images.length,
            itemBuilder: (context, index) => CustomNetworkImage(imageUrl: images[index], fit: BoxFit.cover),
          ),
        ),
        if (images.isNotEmpty && _isVideo(images[safeIndex]))
          Positioned.fill(
            child: Center(
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => VideoPlayerScreen(videoUrl: images[safeIndex]))),
                child: Container(padding: EdgeInsets.all(12.w), decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle), child: Icon(Icons.play_arrow, color: Colors.white, size: 30.sp)),
              ),
            ),
          ),
        Positioned(
          bottom: 20.h,
          left: 0,
          right: 0,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(images.length, (index) => Container(margin: EdgeInsets.symmetric(horizontal: 4.w), width: 8.w, height: 8.w, decoration: BoxDecoration(shape: BoxShape.circle, color: _currentPage == index ? Colors.white : Colors.white.withOpacity(0.5))))),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 10.h,
          left: 20.w,
          right: 20.w,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(padding: EdgeInsets.all(8.w), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, shape: BoxShape.circle), child: Icon(Icons.arrow_back, size: 20.sp, color: Theme.of(context).colorScheme.onSurface)),
              ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          final String title = widget.service['title'] ?? 'Service';
                          final String provider = widget.service['subtitle'] ?? 'Professional';
                          Share.share('Check out this service: $title by $provider on Photopya!');
                        },
                        child: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, shape: BoxShape.circle),
                          child: Icon(Icons.share_outlined, size: 20.sp, color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Consumer<FavoritesController>(
                        builder: (context, controller, child) {
                          bool isFavorite = controller.isPostFavorite(widget.service['_id'] ?? widget.service['id']);
                          return GestureDetector(
                            onTap: () {
                              if (!AuthController.isLoggedIn) {
                                GuestDialogHelper.showGuestDialog(context);
                                return;
                              }
                              controller.toggleFavorite(serviceId: widget.service['_id'] ?? widget.service['id'], optimisticData: widget.service);
                            },
                            child: Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, shape: BoxShape.circle),
                              child: Icon(isFavorite ? Icons.bookmark : Icons.bookmark_border, size: 20.sp, color: Theme.of(context).colorScheme.onSurface),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProviderCard(String name, String avatar, double rating, int reviews, bool isPremium) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
                final providerIdField = widget.service['providerId'];
                final Map<String, dynamic> providerMap;
                if (providerIdField is Map<String, dynamic>) {
                  // providerId is a full user object: { _id: userId, name, profile, ... }
                  // Top-level _id = userId, so ProviderProfileScreen fallback (step 3) works correctly.
                  providerMap = {
                    ...providerIdField,
                    'name': name,
                    'profile': avatar,
                  };
                } else {
                  providerMap = {
                    '_id': providerIdField?.toString(),
                    'id': providerIdField?.toString(),
                    'name': name,
                    'profile': avatar,
                  };
                }
                return ProviderProfileScreen(provider: providerMap);
              }
          ),
        );
      },
      child: Row(
        children: [
          AuthProfileImage(
            imageUrl: avatar,
            size: 50.r,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: TextStyle(fontSize: 15.sp.clamp(15, 16), fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                    SizedBox(width: 8.w),
                    SubscriptionBadge(
                      isSubscribed: isPremium,
                      iconSize: 10.sp,
                      fontSize: 10.sp.clamp(10, 11),
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    ),
                  ],
                ),
                Row(children: [Icon(Icons.star, color: Colors.orange, size: 14.sp), SizedBox(width: 4.w), Text(context.l10n.reviewsCount(reviews, rating), style: TextStyle(fontSize: 12.sp.clamp(12, 13), color: Colors.grey))]),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildStatsRow({String? responseTime, dynamic completedProjects}) {
    return Row(
      children: [
        Expanded(child: _buildStatBox(context.l10n.responseTimeLabel, responseTime != null && responseTime.isNotEmpty ? responseTime : context.l10n.notAvailable)),
        SizedBox(width: 12.w),
        Expanded(child: _buildStatBox(context.l10n.completedProjectsLabel, completedProjects != null ? completedProjects.toString() : context.l10n.notAvailable)),
      ],
    );
  }

  Widget _buildStatBox(String label, String value) {
    return Container(padding: EdgeInsets.all(15.w), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12).r, border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: 11.sp.clamp(11, 12), color: Colors.grey)), SizedBox(height: 4.h), Text(value, style: TextStyle(fontSize: 14.sp.clamp(14, 16), fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface))]));
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: TextStyle(fontSize: 16.sp.clamp(16, 18), fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface));
  }

  Widget _buildEquipmentTags(List<String> tags) {
    return Wrap(spacing: 8.w, runSpacing: 8.h, children: tags.map((tag) => Container(padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)), borderRadius: BorderRadius.circular(8).r), child: Text(tag, style: TextStyle(fontSize: 11.sp.clamp(11, 12), color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500)))).toList());
  }

  Widget _buildPortfolioGrid(List<dynamic> images) {
    return GridView.builder(padding: EdgeInsets.zero, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12.h, crossAxisSpacing: 12.w, childAspectRatio: 1), itemCount: images.length, itemBuilder: (context, index) => CustomNetworkImage(imageUrl: images[index].toString(), fit: BoxFit.cover, borderRadius: BorderRadius.circular(12).r));
  }

  Widget _buildBottomTags(List<String> tags) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: tags.map((tag) {
        final formattedTag = tag.startsWith('#') ? tag : '#$tag';
        return GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => SearchResultScreen(
                                        filters: {'searchTerm': formattedTag},
                                        title: formattedTag,
                                      ),
                                    ),
                                  );
                                },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20).r,
              border: Border.all(color: Colors.blue.withOpacity(0.1)),
            ),
            child: Text(
              formattedTag,
              style: TextStyle(
                fontSize: 12.sp.clamp(12, 13),
                color: Colors.blue[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar({required String providerId, required String name, required String avatar, required Map<String, dynamic> fullService}) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 15.h, 20.w, 20.h),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, boxShadow: [BoxShadow(color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, -4))]),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (!AuthController.isLoggedIn) {
                GuestDialogHelper.showGuestDialog(context);
                return;
              }
              final conversation = Conversation(
                id: '',
                name: name,
                lastMessage: '',
                avatarUrl: avatar,
                lastMessageTime: DateTime.now(),
                unreadCount: 0,
                isOnline: false,
                status: MessageStatus.read,
                isTemporary: true,
                receiverId: providerId,
              );

              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (context) => ChatScreen(conversation: conversation),
                ),
              );
            },
            child: Container(padding: EdgeInsets.all(12.w), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)), borderRadius: BorderRadius.circular(12).r), child: Image.asset('assets/images/message_icon.png', width: 24.sp.clamp(24, 24), height: 24.sp.clamp(24, 24), fit: BoxFit.contain, color: Theme.of(context).colorScheme.onSurface)),
          ),
          SizedBox(width: 15.w),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!AuthController.isLoggedIn) {
                  GuestDialogHelper.showGuestDialog(context);
                  return;
                }
                final String pricingType = fullService['pricingType'] ?? fullService['pricingModel']?['type'] ?? '';
                debugPrint("NAVIGATING: pricingType='$pricingType', fullService: $fullService");
                if (pricingType == 'PACKAGE' || pricingType.toUpperCase() == 'PACKAGE') {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => SelectPackageScreen(service: fullService)));
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => BookingConfirmationScreen(service: fullService)));
                }
              },
              child: Container(height: 50.h, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(12).r), child: Center(child: Text(context.l10n.bookNowBtn, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 14.sp.clamp(14, 16), fontWeight: FontWeight.bold)))),
            ),
          ),
        ],
      ),
    );
  }
}
