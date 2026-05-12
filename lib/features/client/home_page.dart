import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photopia/controller/client/service_list_controller.dart';
import 'package:photopia/controller/client/notification_controller.dart';
import 'package:photopia/controller/location_controller.dart';
import 'package:photopia/controller/client/home_controller.dart';
import 'package:photopia/data/models/service_list_model.dart';
import 'package:photopia/data/models/home_data_model.dart';
import 'package:photopia/features/client/widgets/home_header.dart';
import 'package:photopia/features/client/widgets/category_bar.dart';
import 'package:photopia/features/client/widgets/section_header.dart';
import 'package:photopia/features/client/widgets/horizontal_project_card.dart';
import 'package:photopia/features/client/category_details_screen.dart';
import 'package:photopia/features/client/service_details_screen.dart';
import 'package:photopia/features/client/search_result_screen.dart';
import 'package:photopia/features/client/home_see_all_screen.dart';
import 'package:photopia/features/client/home_see_all_pros_screen.dart';
import 'package:flutter/services.dart';
import 'package:photopia/features/client/widgets/shimmer_skeletons.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:photopia/controller/category_controller.dart';
import 'package:photopia/core/localization/app_localizations.dart';
import 'package:photopia/core/services/translation_service.dart';
import 'package:photopia/core/utils/app_transitions.dart';
import 'package:photopia/core/widgets/app_refresher.dart';

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
          height: 280.h,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return HorizontalProjectCard(
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
        SectionHeader(title: context.l10n.getInspired, onSeeAllTap: () {}),
        SizedBox(
          height: 120.h,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                width: 200.w,
                margin: EdgeInsets.only(right: 12.w),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark 
                      ? [Theme.of(context).colorScheme.surface, Theme.of(context).colorScheme.surface.withOpacity(0.8)]
                      : [Colors.black87, Colors.black54],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.icon ?? '💡', style: TextStyle(fontSize: 24.sp)),
                    SizedBox(height: 8.h),
                    TranslatedText(
                      item.title ?? 'Idea',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                      TranslatedText(
                      item.description ?? '',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7) 
                            : Colors.white70, 
                        fontSize: 12.sp
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
  }

  Widget _buildSuperPros(List<SuperPro>? items) {
    if (items == null || items.isEmpty) return const SizedBox.shrink();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: context.l10n.superPros, 
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
          height: 140.h,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final pro = items[index];
              return Container(
                width: 110.w,
                margin: EdgeInsets.only(right: 12.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: isDark 
                          ? Colors.black.withOpacity(0.2) 
                          : Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(12.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 30.r,
                          backgroundColor: Theme.of(context).dividerColor.withOpacity(0.05),
                          backgroundImage: pro.user?.profile != null
                              ? CachedNetworkImageProvider(pro.user!.profile!)
                              : null,
                          child: pro.user?.profile == null
                              ? Icon(Icons.person, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3))
                              : null,
                        ),
                        if (pro.isSuperPro == true)
                          Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                              border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
                            ),
                            child: Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 10.sp,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    TranslatedText(
                      pro.user?.name ?? 'Pro',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: Colors.orange,
                          size: 14.sp,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          pro.rating?.toStringAsFixed(1) ?? '5.0',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
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

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explore Styles',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: styles.map((style) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20.r),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SearchResultScreen(
                          filters: {'theme': style},
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.15) : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      style,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularLocations(BuildContext context, List<PopularLocation>? locs) {
    if (locs == null || locs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Top Cities', onSeeAllTap: () {}),
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
                    MaterialPageRoute(
                      builder: (context) => SearchResultScreen(
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Trending Right Now', onSeeAllTap: () {}),
        SizedBox(
          height: 100.h,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                width: 160.w,
                margin: EdgeInsets.only(right: 12.w, bottom: 8.h),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -10.w,
                        top: -10.h,
                        child: Icon(
                          Icons.trending_up_rounded,
                          size: 60.sp,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(12.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (item.trendingBadge != null)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text(
                                  item.trendingBadge!,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 8.sp,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            SizedBox(height: 6.h),
                            Text(
                              item.name ?? '',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item.parent?['name'] != null)
                              Text(
                                item.parent!['name'],
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                ),
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
          height: 180.h,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final provider = item.providerId;
              final isOnline = provider?.isOnline ?? false;

              return GestureDetector(
                onTap: () => _navigateToServiceDetails(context, item),
                child: Container(
                  width: 260.w,
                  margin: EdgeInsets.only(right: 16.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isOnline 
                          ? Colors.green.withOpacity(0.3) 
                          : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isOnline 
                            ? Colors.green.withOpacity(0.05) 
                            : Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: Stack(
                            children: [
                              CachedNetworkImage(
                                imageUrl: item.coverMedia ?? '',
                                width: 80.w,
                                height: 80.w,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey.shade100,
                                  child: Icon(Icons.image, color: Colors.grey.shade400),
                                ),
                              ),
                              if (isOnline)
                                Positioned(
                                  top: 4.h,
                                  left: 4.w,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    child: Text(
                                      'LIVE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item.title ?? '',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 8.r,
                                    backgroundImage: provider?.profile != null
                                        ? CachedNetworkImageProvider(provider!.profile!)
                                        : null,
                                    child: provider?.profile == null
                                        ? Icon(Icons.person, size: 8.sp)
                                        : null,
                                  ),
                                  SizedBox(width: 6.w),
                                  Expanded(
                                    child: Text(
                                      provider?.name ?? '',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              Row(
                                children: [
                                  Text(
                                    '${item.currency ?? '€'}${item.price?.toStringAsFixed(0) ?? '0'}',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w900,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (isOnline)
                                    Row(
                                      children: [
                                        Container(
                                          width: 6.w,
                                          height: 6.w,
                                          decoration: const BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          'Online',
                                          style: TextStyle(
                                            fontSize: 10.sp,
                                            color: Colors.green,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
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
                    color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
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
                          context.read<CategoryController>().selectCategory(
                            categoryId,
                          );
                          serviceListController.getAllServices(
                            filters: {'category': categoryId},
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
              child: Consumer<HomeController>(
                builder: (context, homeController, child) {
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

                  return AppRefresher(
                    color: Theme.of(context).colorScheme.primary,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    onRefresh: () async {
                      await homeController.fetchHomeData();
                      context.read<CategoryController>().getAllCategories();
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

                          // Original Projects (Category 1)
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

                          // Recently Viewed (Category 2)
                          if (data.recentlyViewed != null &&
                              data.recentlyViewed!.isNotEmpty)
                            Column(
                              children: [
                                _buildRecentlyViewed(data.recentlyViewed),
                                SizedBox(height: 10.h),
                              ],
                            ),

                          // Inspirations
                          if (data.inspirations != null &&
                              data.inspirations!.isNotEmpty)
                            Column(
                              children: [
                                _buildInspirations(data.inspirations),
                                SizedBox(height: 20.h),
                              ],
                            ),

                          // Trending Subcategories (New Design)
                          if (data.trendingSubcategories != null &&
                              data.trendingSubcategories!.isNotEmpty)
                            Column(
                              children: [
                                _buildTrendingSubcategories(data.trendingSubcategories),
                                SizedBox(height: 20.h),
                              ],
                            ),

                          // Available Right Now (New Design)
                          if (data.availableNow != null && data.availableNow!.isNotEmpty)
                            Column(
                              children: [
                                _buildAvailableNow(data.availableNow),
                                SizedBox(height: 20.h),
                              ],
                            ),

                          // Super Pros
                          if (data.superPros != null &&
                              data.superPros!.isNotEmpty)
                            Column(
                              children: [
                                _buildSuperPros(data.superPros),
                                SizedBox(height: 10.h),
                              ],
                            ),

                          // Explore Styles
                          if (data.styles != null && data.styles!.isNotEmpty)
                            Column(
                              children: [
                                _buildStylesTags(context, data.styles),
                                SizedBox(height: 10.h),
                              ],
                            ),

                          // Popular Locations
                          if (data.popularLocations != null &&
                              data.popularLocations!.isNotEmpty)
                            Column(
                              children: [
                                _buildPopularLocations(context, data.popularLocations),
                                SizedBox(height: 10.h),
                              ],
                            ),

                          SizedBox(
                            height: 100.h,
                          ), // Bottom padding for navigation bar
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
}
