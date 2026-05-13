import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photopia/features/client/category_details_screen.dart';
import 'package:photopia/core/constants/app_typography.dart';
import 'package:photopia/features/client/widgets/category_bar.dart';
import 'package:photopia/features/client/widgets/search_header.dart';
import 'package:photopia/features/client/search_result_screen.dart';
import 'package:photopia/features/client/widgets/service_card.dart';
import 'package:photopia/features/client/widgets/shimmer_skeletons.dart';
import 'package:provider/provider.dart';
import 'package:photopia/controller/client/service_list_controller.dart';
import 'package:photopia/controller/category_controller.dart';
import 'package:photopia/controller/client/search_history_controller.dart';
import 'package:photopia/data/models/category_model.dart';
import 'package:photopia/core/localization/app_localizations.dart';
import 'package:photopia/core/widgets/app_refresher.dart';

class SearchScreen extends StatefulWidget {
  static const String name = '/search';
  final String? initialSearchTerm;
  const SearchScreen({super.key, this.initialSearchTerm});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String? _selectedCategoryId;
  bool _isSearching = false;
  bool _isFieldFocused = false;
  Map<String, dynamic> _currentFilters = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryController>().getAllCategories();
      
      if (widget.initialSearchTerm != null && widget.initialSearchTerm!.isNotEmpty) {
        _onSearch({'searchTerm': widget.initialSearchTerm});
      }
    });
  }

  void _onSearch(Map<String, dynamic> filters) {
    // If only searchTerm is present and it's empty, clear search
    if (filters.length == 1 && filters.containsKey('searchTerm') && (filters['searchTerm']?.toString().isEmpty ?? true)) {
      _clearSearch();
      return;
    }

    setState(() {
      _isSearching = true;
      _isFieldFocused = false;
      _currentFilters = filters;
    });
    // Trigger API call via controller
    context.read<ServiceListController>().getAllServices(filters: filters);
  }

  void _clearSearch() {
    setState(() {
      _isSearching = false;
      _isFieldFocused = false;
      _currentFilters = {};
    });
  }

  void _navigateToCategoryDetails(String categoryName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CategoryDetailsScreen(categoryName: categoryName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            child: Column(
              children: [
                SearchHeader(
                  onFilterApplied: _onSearch,
                  onFocus: () {
                    setState(() {
                      _isFieldFocused = true;
                    });
                  },
                ),
                if (!_isFieldFocused)
                  CategoryBar(
                    selectedCategoryId: context
                        .watch<CategoryController>()
                        .selectedCategoryId,
                    onCategorySelected: (categoryId) {
                      context.read<CategoryController>().selectCategory(
                        categoryId,
                      );
                      _clearSearch();
                    },
                  ),
                SizedBox(height: 15.h),
              ],
            ),
          ),

          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isSearching || _currentFilters.isNotEmpty) {
      return _buildSearchResults();
    }
    return _buildBrowseView();
  }

  Widget _buildSuggestionsView() {
    return Consumer<SearchHistoryController>(
      builder: (context, historyController, child) {
        final history = historyController.recentSearches;
        
        return ListView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          children: [
            if (history.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.recentSearches,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  TextButton(
                    onPressed: () => historyController.clearHistory(),
                    child: Text(context.l10n.clearAll, style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
                  ),
                ],
              ),
              Wrap(
                spacing: 8.w,
                runSpacing: 0.h,
                children: history.map<Widget>((term) => RawChip(
                  label: Text(term, style: TextStyle(fontSize: 12.sp)),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                  onPressed: () => _onSearch({'searchTerm': term}),
                  onDeleted: () => historyController.removeSearchTerm(term),
                  deleteIcon: Icon(Icons.close, size: 14.sp),
                )).toList(),
              ),
              SizedBox(height: 25.h),
            ],
            
            Text(
              context.l10n.browseCategories,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 12.h),
            Consumer<CategoryController>(
              builder: (context, controller, child) {
                final trending = controller.rootCategories.take(4).toList();
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10.h,
                    crossAxisSpacing: 10.w,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: trending.length,
                  itemBuilder: (context, index) {
                    final cat = trending[index];
                    return GestureDetector(
                      onTap: () => _onSearch({'searchTerm': cat.name}),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          cat.name,
                          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildBrowseView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20.h),
        Consumer<CategoryController>(
          builder: (context, controller, child) {
            final bool inSubcategory =
                controller.selectedCategoryId != null;

            String headerTitle = context.l10n.browseCategories;
            if (inSubcategory) {
              try {
                final selected = controller.categories.firstWhere(
                  (c) => c.id == controller.selectedCategoryId,
                );
                headerTitle = selected.name;
              } catch (_) {
                headerTitle = context.l10n.categories;
              }
            }

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  if (inSubcategory) ...[
                    GestureDetector(
                      onTap: () => controller.selectCategory(null),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_back,
                              size: 16.sp,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              context.l10n.back,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                  ],

                  Text(
                      headerTitle,
                      style: TextStyle(
                        fontSize: AppTypography.h2,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                  ),
                ],
              ),
            );
          },
        ),
        SizedBox(height: 16.h),

        Expanded(
          child: Consumer<CategoryController>(
            builder: (context, controller, child) {
              if (controller.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final List<CategoryModel> categoriesToDisplay =
                  controller.selectedCategoryId == null
                  ? controller.rootCategories
                  : controller.subCategories;

              if (categoriesToDisplay.isEmpty) {
                return Center(
                  child: Text(
                    controller.selectedCategoryId == null
                        ? context.l10n.noCategoriesFound
                        : context.l10n.noSubcategoriesFound,
                    style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                  ),
                );
              }

              return GridView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.w,
                  mainAxisSpacing: 20.h,
                  childAspectRatio: 0.85,
                ),
                itemCount: categoriesToDisplay.length,
                itemBuilder: (context, index) {
                  final category = categoriesToDisplay[index];
                  final imageUrl =
                      category.image ?? 'assets/images/img1.png';
                  final bool isNetworkImage = imageUrl.startsWith('http');

                  return GestureDetector(
                    onTap: () {
                      if (controller.selectedCategoryId == null) {
                        controller.selectCategory(category.id);
                      } else {
                        _navigateToCategoryDetails(category.name);
                      }
                    },
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16.r),
                              image: DecorationImage(
                                image: isNetworkImage
                                    ? NetworkImage(imageUrl)
                                    : AssetImage(imageUrl) as ImageProvider,
                                fit: BoxFit.cover,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                            category.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: AppTypography.bodySmall,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    return Consumer<ServiceListController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return GridView.builder(
            padding: EdgeInsets.all(16.w),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 20.h,
              childAspectRatio: 0.6,
            ),
            itemCount: 4,
            itemBuilder: (context, index) => const ServiceCardSkeleton(),
          );
        }

        if (controller.errorMessage != null) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Text(
                controller.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red, fontSize: 14.sp),
              ),
            ),
          );
        }

        final results = controller.services;

        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 60.sp, color: Colors.grey[300]),
                SizedBox(height: 16.h),
                Text(
                  context.l10n.noServicesFound,
                  style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                ),
                SizedBox(height: 20.h),
                GestureDetector(
                  onTap: _clearSearch,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back_ios_new,
                        size: 16.sp,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        context.l10n.backToCategories,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _currentFilters['searchTerm'] != null && _currentFilters['searchTerm'].toString().startsWith('#') 
                    ? '${context.l10n.searchResultsFor} ${_currentFilters['searchTerm']}' 
                    : context.l10n.searchResults,
                    style: TextStyle(
                      fontSize: AppTypography.h2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearSearch,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_back_ios_new,
                          size: 14.sp,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          context.l10n.back,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
             Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await context.read<ServiceListController>().getAllServices(filters: _currentFilters);
                },
                child: GridView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.w,
                    mainAxisSpacing: 20.h,
                    childAspectRatio: 0.6,
                  ),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final service = results[index];
                    return ServiceCard(
                      id: service.sId ?? '',
                      title: service.title ?? '',
                      subtitle: service.providerId?.name ?? context.l10n.professional,
                      imageUrl: service.coverMedia ?? '',
                      rating: service.rating ?? 0.0,
                      reviews: service.reviews ?? 0,
                      price: service.price,
                      currency: service.currency,
                      providerId: service.providerId?.sId,
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
