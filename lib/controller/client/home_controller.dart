import 'package:flutter/foundation.dart';
import 'package:photopia/core/network/Api_service/network_caller.dart';
import 'package:photopia/core/network/urls.dart';
import 'package:photopia/data/models/home_data_model.dart';
import 'package:photopia/controller/auth_controller.dart';

class HomeController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  HomeData? _homeData;
  HomeData? get homeData => _homeData;

  Future<bool> fetchHomeData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // requiresAuth depends if user is logged in to get 'recentlyViewed'
      final token = AuthController.accessToken;
      final response = await NetworkCaller.getRequest(
        url: Urls.home,
        requireAuth: token != null && token.isNotEmpty,
      );

      _isLoading = false;

      if (response.isSuccess && response.body != null) {
        final model = HomeDataModel.fromJson(response.body!);
        _homeData = model.data;

        // Print counts for each category to the terminal
        if (_homeData != null) {
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          debugPrint('🏠 [HOME DATA SUMMARY]');
          debugPrint('✨ Original Projects: ${_homeData?.originalProjects?.length ?? 0}');
          debugPrint('👁️ Recently Viewed: ${_homeData?.recentlyViewed?.length ?? 0}');
          debugPrint('🔥 Trending Subcategories: ${_homeData?.trendingSubcategories?.length ?? 0}');
          debugPrint('⚡ Available Now: ${_homeData?.availableNow?.length ?? 0}');
          debugPrint('🏆 Super Pros: ${_homeData?.superPros?.length ?? 0}');
          debugPrint('🎨 Styles: ${_homeData?.styles?.length ?? 0}');
          debugPrint('📍 Popular Locations: ${_homeData?.popularLocations?.length ?? 0}');
          debugPrint('💡 Inspirations: ${_homeData?.inspirations?.length ?? 0}');
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        }

        notifyListeners();
        return true;
      } else {
        _errorMessage = response.errorMessage ?? "Failed to fetch home data";
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = "Parsing error: $e";
      debugPrint("fetchHomeData error: $e");
      notifyListeners();
      return false;
    }
  }
}
