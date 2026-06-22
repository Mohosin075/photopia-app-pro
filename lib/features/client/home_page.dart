import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photopya/controller/client/service_list_controller.dart';
import 'package:photopya/controller/client/notification_controller.dart';
import 'package:photopya/controller/location_controller.dart';
import 'package:photopya/controller/client/home_controller.dart';
import 'package:photopya/data/models/category_model.dart';
import 'package:photopya/data/models/service_list_model.dart';
import 'package:photopya/data/models/home_data_model.dart';
import 'package:photopya/features/client/widgets/home_header.dart';
import 'package:photopya/features/client/widgets/category_bar.dart';
import 'package:photopya/features/client/widgets/service_card.dart';
import 'package:photopya/features/client/widgets/section_header.dart';
import 'package:photopya/features/client/widgets/horizontal_project_card.dart';
import 'package:photopya/features/client/category_details_screen.dart';
import 'package:photopya/features/client/service_details_screen.dart';
import 'package:photopya/features/client/search_result_screen.dart';
import 'package:photopya/features/client/search_screen.dart';
import 'package:photopya/features/client/home_see_all_locations_screen.dart';
import 'package:photopya/features/client/home_see_all_inspirations_screen.dart';
import 'package:photopya/features/client/home_see_all_categories_screen.dart';
import 'package:photopya/core/utils/category_icon_helper.dart';
import 'package:photopya/features/client/home_see_all_subcategories_screen.dart';
import 'package:photopya/features/client/home_see_all_screen.dart';
import 'package:photopya/features/client/home_see_all_pros_screen.dart';
import 'package:flutter/services.dart';
import 'package:photopya/features/client/widgets/shimmer_skeletons.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:photopya/controller/category_controller.dart';
import 'package:photopya/core/localization/app_localizations.dart';
import 'package:photopya/core/services/translation_service.dart';
import 'package:photopya/core/utils/app_transitions.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  static const String name = "/home-page";

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeController = context.read<HomeController>();
      if (homeController.homeData == null) {
        homeController.fetchHomeData();
      }
      context.read<CategoryController>().getAllCategories();
      context.read<LocationController>().determinePosition();
      context.read<NotificationController>().fetchNotificationStats();

      // Also fetch ServiceList in background to allow standard list tabs if needed
      context.read<ServiceListController>().getAllServices(refresh: false);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _navigateToCategoryDetails(BuildContext context) {
    Navigator.of(context).push(
      AppTransitions.createPremiumRoute(const CategoryDetailsScreen()),
    );
  }

  void _navigateToServiceDetails(BuildContext context, ServiceItem service) {
    Navigator.of(context, rootNavigator: true).push(
      AppTransitions.createPremiumRoute(ServiceDetailsScreen(service: service.toJson())),
    );
  }

  Widget _buildHorizontalServiceSection({
    required String title,
    required List<ServiceItem> items,
    bool showAvailability = false,
    VoidCallback? onSeeAll,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, onSeeAllTap: onSeeAll ?? () {}),
        SizedBox(
          height: 290.h,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                margin: EdgeInsets.only(right: 4.w),
                child: HorizontalProjectCard(
                  id: item.sId,
                  providerId: item.providerId?.sId,
                  imageUrl: item.coverMedia ?? '',
                  title: item.title ?? context.l10n.noTitle,
                  providerName: item.providerId?.name ?? context.l10n.unknownProvider,
                  rating: item.rating,
                  price: item.price,
                  tags: item.tags,
                  isAvailable: showAvailability && (item.isActive ?? false),
                  onTap: () => _navigateToServiceDetails(context, item),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentlyViewed(List<RecentlyViewedItem>? items) {
    if (items == null || items.isEmpty) return const SizedBox.shrink();

    // Extract services
    final validServices = items
        .where((i) => i.serviceId != null)
        .map((i) => i.serviceId!)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: context.l10n.recentlyViewed, 
          onSeeAllTap: () {
            Navigator.push(
              context,
              AppTransitions.createPremiumRoute(
                HomeSeeAllScreen(
                  title: context.l10n.recentlyViewed,
                  services: validServices,
                ),
              ),
            );
          },
        ),
        SizedBox(
          height: 280.h,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: validServices.length,
            itemBuilder: (context, index) {
              final item = validServices[index];
              return HorizontalProjectCard(
                id: item.sId,
                providerId: item.providerId?.sId,
                imageUrl: item.coverMedia ?? '',
                title: item.title ?? context.l10n.noTitle,
                providerName: item.providerId?.name ?? context.l10n.unknownProvider,
                rating: item.rating,
                price: item.price,
                tags: item.tags,
                isAvailable: false,
                onTap: () => _navigateToServiceDetails(context, item),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInspirations(List<Inspiration>? items) {
    if (items == null || items.isEmpty) return const SizedBox.shrink();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: context.l10n.ideasForProject, 
          onSeeAllTap: () {
            Navigator.push(
              context,
              AppTransitions.createPremiumRoute(
                HomeSeeAllInspirationsScreen(
                  title: context.l10n.ideasForProject,
                  inspirations: items,
                ),
              ),
            );
          }
        ),
        Padding(
          padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 5.h, bottom: 20.h),
          child: SizedBox(
            height: 220.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: items.length > 6 ? 6 : items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      AppTransitions.createPremiumRoute(
                        SearchResultScreen(
                          filters: {'theme': item.title},
                          title: context.l10n.translateCategory(item.title),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 280.w,
                    margin: EdgeInsets.only(right: 16.w),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(24.r),
                      image: item.image != null
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(item.image!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.15),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24.r),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.1),
                                    Colors.black.withOpacity(0.4),
                                    Colors.black.withOpacity(0.9),
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 16.h,
                            right: 16.w,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30.r),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: EdgeInsets.all(10.w),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    CategoryIconHelper.getIcon(item.title),
                                    size: 18.sp,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Padding(
                              padding: EdgeInsets.all(20.w),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.l10n.translateCategory(item.title),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22.sp,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 8.h),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.description ?? 'Explore premium packages',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.85),
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w400,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(width: 10.w),
                                      Container(
                                        padding: EdgeInsets.all(6.w),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.arrow_forward_ios,
                                          size: 12.sp,
                                          color: Theme.of(context).colorScheme.onPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdeaCard({
    required String question,
    required String actionText,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Text(
                        "→ ",
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade400,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          actionText,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black54,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.orange.shade400.withOpacity(0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12.sp,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectIdeasSection() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.02) : Colors.grey.shade50.withOpacity(0.3),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "💡",
                  style: TextStyle(fontSize: 18.sp),
                ),
                SizedBox(width: 8.w),
                Text(
                  context.l10n.ideasForProject.toUpperCase(),
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            _buildIdeaCard(
              question: "Are 💒 you planning a wedding?",
              actionText: "See our wedding packages",
              isDark: isDark,
              onTap: () {},
            ),
            _buildIdeaCard(
              question: "Launch 🚀 your brand?",
              actionText: "Visual Identity Packs",
              isDark: isDark,
              onTap: () {},
            ),
            _buildIdeaCard(
              question: "Need 📱 social content?",
              actionText: "Social Media Plans",
              isDark: isDark,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuperPros(List<SuperPro>? items) {
    if (items == null || items.isEmpty) return const SizedBox.shrink();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: context.l10n.superPros, 
          titleIcon: Icon(
            Icons.verified_outlined,
            color: Colors.orange.shade400,
            size: 20.sp,
          ),
          onSeeAllTap: () {
            Navigator.push(
              context,
              AppTransitions.createPremiumRoute(
                HomeSeeAllProsScreen(
                  title: context.l10n.superPros,
                  pros: items,
                ),
              ),
            );
          },
        ),
        SizedBox(
          height: 250.h,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final pro = items[index];
              return GestureDetector(
                onTap: () {
                  // Navigate to pro profile if needed
                },
                child: Container(
                  width: 200.w,
                  margin: EdgeInsets.only(right: 16.w, bottom: 10.h),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: isDark 
                            ? Colors.black.withOpacity(0.3) 
                            : Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                              child: CachedNetworkImage(
                                imageUrl: pro.user?.profile ?? '',
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                                  child: Icon(Icons.person, color: Colors.grey.shade400, size: 40.sp),
                                ),
                              ),
                            ),
                            if (pro.isSuperPro == true)
                              Positioned(
                                left: 10.w,
                                bottom: 10.h,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade400,
                                    borderRadius: BorderRadius.circular(6.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified, color: Colors.white, size: 10.sp),
                                      SizedBox(width: 4.w),
                                      Text(
                                        'SUPER PRO',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(12.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              pro.user?.name ?? 'Professional',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'Corporate Videographer', 
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 8.h),
                            Row(
                              children: [
                                Icon(Icons.star_rounded, color: Colors.orange.shade400, size: 14.sp),
                                SizedBox(width: 4.w),
                                Text(
                                  pro.rating?.toStringAsFixed(1) ?? '0.0',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Expanded(
                                  child: Text(
                                    '(124 reviews)', 
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStylesTags(BuildContext context, List<String>? styles) {
    if (styles == null || styles.isEmpty) return const SizedBox.shrink();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Text(
            context.l10n.findYourStyle,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        SizedBox(
          height: 180.h,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: styles.length,
            itemBuilder: (context, index) {
              final style = styles[index];
              
              // Map some styles to colors/placeholders if real images aren't in model yet
              Color cardColor = isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100;
              if (style.toUpperCase().contains('CINEMATIC')) cardColor = const Color(0xFF1A1A1A);
              if (style.toUpperCase().contains('NATURAL')) cardColor = const Color(0xFFE5C1A7);
              if (style.toUpperCase().contains('VINTAGE')) cardColor = const Color(0xFFD4C4A8);

              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    AppTransitions.createPremiumRoute(
                      SearchResultScreen(
                        filters: {'theme': style},
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 140.w,
                  margin: EdgeInsets.only(right: 12.w, bottom: 8.h),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.r),
                            child: Stack(
                              children: [
                                Center(
                                  child: Icon(
                                    CategoryIconHelper.getIcon(style),
                                    size: 40.sp,
                                    color: isDark ? Colors.white24 : Colors.black12,
                                  ),
                                ),
                                // Since we don't have style-specific images in the data yet, 
                                // we'll use a placeholder colored overlay to match the design
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.2),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        style,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPopularLocations(BuildContext context, List<PopularLocation>? locs) {
    if (locs == null || locs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: context.l10n.nearYou, 
          onSeeAllTap: () {
            Navigator.push(
              context,
              AppTransitions.createPremiumRoute(
                HomeSeeAllLocationsScreen(
                  title: context.l10n.nearYou,
                  locations: locs,
                ),
              ),
            );
          }
        ),
        SizedBox(
          height: 140.h,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: locs.length,
            itemBuilder: (context, index) {
              final loc = locs[index];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    AppTransitions.createPremiumRoute(
                      SearchResultScreen(
                        filters: {'city': loc.id},
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 140.w,
                  margin: EdgeInsets.only(right: 12.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    color: Colors.grey.shade200,
                    image: loc.image != null
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(loc.image!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.r),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                      ),
                    ),
                    padding: EdgeInsets.all(12.w),
                    alignment: Alignment.bottomLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.id ?? 'City',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${loc.count ?? 0} Pros',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingSubcategories(List<TrendingSubcategory>? items) {
    if (items == null || items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: context.l10n.trendingProjects, 
          onSeeAllTap: () {
            Navigator.push(
              context,
              AppTransitions.createPremiumRoute(
                HomeSeeAllSubcategoriesScreen(
                  title: context.l10n.trendingProjects,
                  subcategories: items,
                ),
              ),
            );
          }
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            children: items.take(2).map((item) {
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    AppTransitions.createPremiumRoute(
                      SearchResultScreen(
                        filters: {
                          'category': item.parent?['_id'],
                          'subCategory': item.sId,
                          'categoryName': item.name,
                        },
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 200.h,
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: Stack(
                      children: [
                        // Placeholder image or subcategory image if available
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.8),
                              ],
                            ),
                          ),
                        ),
                        // Top Badges
                        Positioned(
                          top: 12.h,
                          left: 12.w,
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFC62828), // Deep Red
                                  borderRadius: BorderRadius.circular(30.r),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'TRENDING',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.sp,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    Icon(Icons.whatshot, color: Colors.white, size: 10.sp),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00E5FF), // Bright Cyan
                                  borderRadius: BorderRadius.circular(30.r),
                                ),
                                child: Text(
                                  '+45% week',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Bottom Info
                        Positioned(
                          bottom: 16.h,
                          left: 16.w,
                          right: 16.w,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                context.l10n.translateCategory(item.name),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                item.parent?['name'] != null ? context.l10n.translateCategory(item.parent?['name']) : 'Maximize your organic reach',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableNow(List<ServiceItem>? items) {
    if (items == null || items.isEmpty) return const SizedBox.shrink();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: context.l10n.availableRightNow,
          onSeeAllTap: () {
            Navigator.push(
              context,
              AppTransitions.createPremiumRoute(
                HomeSeeAllScreen(
                  title: context.l10n.availableRightNow,
                  services: items,
                ),
              ),
            );
          },
        ),
        SizedBox(
          height: 100.h,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final provider = item.providerId;
              final bool isOnline = provider?.isOnline ?? false;

              return GestureDetector(
                onTap: () => _navigateToServiceDetails(context, item),
                child: Container(
                  width: 280.w,
                  margin: EdgeInsets.only(right: 12.w, bottom: 5.h),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    child: Row(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 60.w,
                              height: 60.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                                  width: 1,
                                ),
                              ),
                              child: ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: provider?.profile ?? '',
                                  width: 60.w,
                                  height: 60.w,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey.shade100,
                                    child: Icon(Icons.person, color: Colors.grey.shade400, size: 30.sp),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey.shade100,
                                    child: Icon(Icons.person, color: Colors.grey.shade400, size: 30.sp),
                                  ),
                                ),
                              ),
                            ),
                            if (isOnline)
                              Container(
                                width: 16.w,
                                height: 16.w,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00FFD1), // Cyan/Turquoise from image
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00FFD1).withOpacity(0.4),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                provider?.name ?? 'Professional',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                '${context.l10n.translateCategory(item.category?.name ?? 'Expert')} • ${Localizations.localeOf(context).languageCode == 'fr' ? 'Réponse < 30 min' : 'Response < 30min'}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16.sp,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMainCategories(List<CategoryModel>? items) {
    if (items == null || items.isEmpty) return const SizedBox.shrink();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: context.l10n.popularCategories, 
          onSeeAllTap: () {
            Navigator.push(
              context,
              AppTransitions.createPremiumRoute(
                HomeSeeAllCategoriesScreen(
                  title: context.l10n.popularCategories,
                  categories: items,
                ),
              ),
            );
          }
        ),
        SizedBox(
          height: 125.h,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];

              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    AppTransitions.createPremiumRoute(
                      SearchResultScreen(
                        filters: {
                          'category': item.id,
                          'categoryName': item.name,
                        },
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 85.w,
                  margin: EdgeInsets.only(right: 12.w),
                  child: Column(
                    children: [
                      Container(
                        width: 70.w,
                        height: 70.w,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            CategoryIconHelper.getIcon(item.name),
                            size: 32.sp,
                            color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        context.l10n.translateCategory(item.name),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            // Sticky Header Section with Shadow and Top Padding for Status Bar
            Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(15.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Consumer<ServiceListController>(
                builder: (context, serviceListController, child) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const HomeHeader(),
                      // Category Bar relies on ServiceListController for filtering
                      CategoryBar(
                        isLoading: serviceListController.isLoading,
                        selectedCategoryId: context
                            .watch<CategoryController>()
                            .selectedCategoryId,
                        onCategorySelected: (categoryId) {
                          final categoryController = context.read<CategoryController>();
                          categoryController.selectCategory(
                            categoryId,
                          );
                          
                          final Map<String, dynamic> filters = {};
                          if (categoryId != null) {
                            filters['category'] = categoryId;
                          } else if (categoryController.selectedTheme != null && 
                                     categoryController.selectedTheme != 'ALL') {
                            filters['theme'] = categoryController.selectedTheme;
                          }
                          
                          serviceListController.getAllServices(
                            filters: filters,
                          );
                        },
                      ),
                      SizedBox(height: 15.h),
                    ],
                  );
                },
              ),
            ),
            // Scrollable Dynamic Home Content
            Expanded(
              child: Consumer2<HomeController, CategoryController>(
                builder: (context, homeController, categoryController, child) {
                  final bool hasActiveFilter = (categoryController.selectedTheme != null && 
                                             categoryController.selectedTheme != 'ALL') || 
                                             categoryController.selectedCategoryId != null;

                  if (hasActiveFilter) {
                    return _buildFilteredResults();
                  }

                  if (homeController.isLoading &&
                      homeController.homeData == null) {
                    return const HomeShimmer();
                  }

                  if (homeController.errorMessage != null &&
                      homeController.homeData == null) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.wifi_off_rounded,
                              size: 60.sp,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              context.l10n.unableToLoadHome,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 24.h),
                            ElevatedButton(
                              onPressed: () => homeController.fetchHomeData(),
                              child: Text(context.l10n.tryAgain),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final data = homeController.homeData;
                  if (data == null) {
                    return Center(child: Text(context.l10n.noData));
                  }

                  return RefreshIndicator(
                    color: Theme.of(context).colorScheme.primary,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    onRefresh: () async {
                      await Future.wait([
                        homeController.fetchHomeData(),
                        context.read<CategoryController>().getAllCategories(),
                        context.read<ServiceListController>().getAllServices(),
                      ]);
                    },
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10.h),

                          // 1. Original Projects (Moved to Top)
                          if (data.originalProjects != null && data.originalProjects!.isNotEmpty)
                            Column(
                              children: [
                                _buildHorizontalServiceSection(
                                  title: context.l10n.originalProjects,
                                  items: data.originalProjects!,
                                  onSeeAll: () {
                                    Navigator.push(
                                      context,
                                      AppTransitions.createPremiumRoute(
                                        HomeSeeAllScreen(
                                          title: context.l10n.originalProjects,
                                          services: data.originalProjects!,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                SizedBox(height: 10.h),
                              ],
                            ),

                          // 2. Recently Viewed
                          if (data.recentlyViewed != null && data.recentlyViewed!.isNotEmpty)
                            Column(
                              children: [
                                _buildRecentlyViewed(data.recentlyViewed),
                                SizedBox(height: 10.h),
                              ],
                            ),

                          // 3. Main Categories (Added)
                          if (data.popularCategories != null && data.popularCategories!.isNotEmpty)
                            Column(
                              children: [
                                _buildMainCategories(data.popularCategories),
                                SizedBox(height: 10.h),
                              ],
                            ),

                          // 4. Trending This Week
                          if (data.trendingSubcategories != null && data.trendingSubcategories!.isNotEmpty)
                            Column(
                              children: [
                                _buildTrendingSubcategories(data.trendingSubcategories),
                                SizedBox(height: 10.h),
                              ],
                            ),

                          // 4. Available Now
                          if (data.availableNow != null && data.availableNow!.isNotEmpty)
                            Column(
                              children: [
                                _buildAvailableNow(data.availableNow),
                                SizedBox(height: 10.h),
                              ],
                            ),

                          // 5. Super Pros
                          if (data.superPros != null && data.superPros!.isNotEmpty)
                            Column(
                              children: [
                                _buildSuperPros(data.superPros),
                                SizedBox(height: 10.h),
                              ],
                            ),

                          // 6. Creative Styles
                          if (data.styles != null && data.styles!.isNotEmpty)
                            Column(
                              children: [
                                _buildStylesTags(context, data.styles),
                                SizedBox(height: 10.h),
                              ],
                            ),

                          // 7. Near You
                          if (data.popularLocations != null && data.popularLocations!.isNotEmpty)
                            Column(
                              children: [
                                _buildPopularLocations(context, data.popularLocations),
                                SizedBox(height: 10.h),
                              ],
                            ),

                          // 8. Ideas
                          _buildProjectIdeasSection(),
                          SizedBox(height: 20.h),

                          SizedBox(height: 100.h),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredResults() {
    return Consumer<ServiceListController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return GridView.builder(
            padding: EdgeInsets.all(16.w),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 20.h,
              childAspectRatio: 0.46,
            ),
            itemCount: 6,
            itemBuilder: (context, index) => const ServiceCardSkeleton(),
          );
        }

        if (controller.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60.sp, color: Colors.red.withOpacity(0.3)),
                SizedBox(height: 16.h),
                Text(controller.errorMessage!),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: () {
                    final categoryController = context.read<CategoryController>();
                    final Map<String, dynamic> filters = {};
                    if (categoryController.selectedCategoryId != null) {
                      filters['category'] = categoryController.selectedCategoryId;
                    } else if (categoryController.selectedTheme != null && categoryController.selectedTheme != 'ALL') {
                      filters['theme'] = categoryController.selectedTheme;
                    }
                    controller.getAllServices(filters: filters);
                  },
                  child: Text(context.l10n.tryAgain),
                ),
              ],
            ),
          );
        }

        final services = controller.services;

        if (services.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 80.sp, color: Colors.grey[300]),
                SizedBox(height: 16.h),
                Text(
                  context.l10n.noData,
                  style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: Theme.of(context).colorScheme.primary,
          onRefresh: () async {
            final categoryController = context.read<CategoryController>();
            final Map<String, dynamic> filters = {};
            if (categoryController.selectedCategoryId != null) {
              filters['category'] = categoryController.selectedCategoryId;
            } else if (categoryController.selectedTheme != null && categoryController.selectedTheme != 'ALL') {
              filters['theme'] = categoryController.selectedTheme;
            }
            await controller.getAllServices(filters: filters);
          },
          child: GridView.builder(
            padding: EdgeInsets.all(16.w),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 20.h,
              childAspectRatio: 0.46,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return ServiceCard(
                id: service.sId ?? '',
                title: service.title ?? '',
                subtitle: service.providerId?.name ?? 'Professional',
                imageUrl: service.coverMedia ?? '',
                rating: service.rating ?? 0.0,
                reviews: service.reviews ?? 0,
                price: service.price,
                currency: service.currency,
                providerId: service.providerId?.sId,
                isPremium: service.providerId?.isSubscribed ?? false,
                tags: service.tags ?? [],
              );
            },
          ),
        );
      },
    );
  }
}
