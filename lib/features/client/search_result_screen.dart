import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photopya/controller/client/service_list_controller.dart';
import 'package:photopya/features/client/widgets/service_card.dart';
import 'package:photopya/features/client/widgets/shimmer_skeletons.dart';
import 'package:photopya/features/client/service_details_screen.dart';
import 'package:provider/provider.dart';

class SearchResultScreen extends StatefulWidget {
  final Map<String, dynamic> filters;
  final String? title;
  const SearchResultScreen({super.key, required this.filters, this.title});

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint("🔍 [SEARCH_RESULT] Filters: ${widget.filters}");
      context.read<ServiceListController>().getAllServices(filters: widget.filters);
    });
  }

  String _getDynamicTitle() {
    if (widget.title != null) return widget.title!;
    
    if (widget.filters.containsKey('searchTerm') && widget.filters['searchTerm'].toString().isNotEmpty) {
      return widget.filters['searchTerm'];
    }
    if (widget.filters.containsKey('theme')) {
      return widget.filters['theme'];
    }
    if (widget.filters.containsKey('city')) {
      return widget.filters['city'];
    }
    if (widget.filters.containsKey('categoryName')) {
      return widget.filters['categoryName'];
    }
    
    return 'Search Results';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _getDynamicTitle(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<ServiceListController>(
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
            return Center(child: Text(controller.errorMessage!));
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
                    'No services found',
                    style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
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
                tags: service.tags ?? [],
                providerId: service.providerId?.sId,
              );
            },
          );
        },
      ),
    );
  }
}
