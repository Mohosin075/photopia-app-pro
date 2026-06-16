import 'package:flutter/material.dart';
import 'package:photopya/core/network/Api_service/network_caller.dart';
import 'package:photopya/core/network/urls.dart';
import 'package:photopya/data/models/professional_profile_model.dart';
import 'package:photopya/data/models/user_profile_model.dart';

class ProviderDetailsController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  UserProfileModel? _providerDetails;
  UserProfileModel? get providerDetails => _providerDetails;

  ProfessionalProfileModel? _profProfileDetails;
  ProfessionalProfileModel? get profProfileDetails => _profProfileDetails;

  /// Called when the provider map already contains professional profile data
  /// (e.g. from the home screen's availableNow / superPros lists).
  /// Parses the map directly to avoid making an authenticated API call that
  /// would return the *logged-in user's* profile instead of the provider's.
  void setFromProviderMap(Map<String, dynamic> providerMap) {
    _profProfileDetails = ProfessionalProfileModel.fromJson(providerMap);

    // Also extract user details from the nested user object if present
    final userField = providerMap['user'];
    if (userField is Map<String, dynamic>) {
      _providerDetails = UserProfileModel.fromJson(userField);
    }

    debugPrint(
      "✅ [ProviderDetailsController] Set from provider map. coverPhoto=${_profProfileDetails?.coverPhoto}",
    );
    notifyListeners();
  }

  Future<bool> getProviderDetails(String id) async {
    _isLoading = true;
    _errorMessage = null;
    _providerDetails = null;
    _profProfileDetails = null;
    notifyListeners();

    try {
      debugPrint("🔍 [ProviderDetailsController] Fetching for userId: $id");

      // Fetch user profile (public, no auth needed).
      // NOTE: The professional-profiles endpoint with auth returns the *authenticated*
      // user's own profile (ignores userId param), so we skip it here.
      // Professional profile data is instead sourced from widget.provider directly
      // via setFromProviderMap() when the caller has the full object.
      final userResponse = await NetworkCaller.getRequest(
        url: Urls.getUserById(id),
        requireAuth: false,
      );

      _isLoading = false;

      bool success = false;

      // Parse User Details
      if (userResponse.isSuccess &&
          userResponse.body != null &&
          userResponse.body!['data'] != null) {
        _providerDetails = UserProfileModel.fromJson(
          userResponse.body!['data'],
        );
        success = true;
        debugPrint("✅ [ProviderDetailsController] User Details fetched from API");
      } else if (_profProfileDetails?.user != null) {
        // Fallback: use the user nested inside the professional profile (set via setFromProviderMap)
        final u = _profProfileDetails!.user!;
        _providerDetails = UserProfileModel(
          id: u.id,
          fullName: u.name,
          email: u.email,
          profile: u.profile,
          description: u.description,
        );
        success = true;
        debugPrint("🔸 [ProviderDetailsController] Using nested user from prof profile map");
      }

      if (_profProfileDetails != null) success = true;

      if (!success) {
        _errorMessage = userResponse.errorMessage ?? "Failed to fetch provider details";
      }

      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = "Exception: $e";
      debugPrint("❌ [ProviderDetailsController] Crash: $e");
    }

    notifyListeners();
    return false;
  }
}
