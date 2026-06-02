import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photopya/data/models/service_list_model.dart';
import 'package:photopya/features/client/widgets/service_card.dart';
import 'package:photopya/core/localization/app_localizations.dart';

class HomeSeeAllScreen extends StatelessWidget {
  final String title;
  final List<ServiceItem> services;

  const HomeSeeAllScreen({
    super.key,
    required this.title,
    required this.services,
  });

  @override
  Widget build(BuildContext context) {
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
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: services.isEmpty
          ? Center(
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
            )
          : GridView.builder(
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
                  tags: service.tags ?? [],
                  isPremium: service.providerId?.isSubscribed ?? false,
                );
              },
            ),
    );
  }
}
