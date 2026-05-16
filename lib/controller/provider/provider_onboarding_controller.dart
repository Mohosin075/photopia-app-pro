import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photopya/core/network/Api_service/network_caller.dart';
import 'package:photopya/core/network/urls.dart';
import 'package:photopya/core/utils/image_utils.dart';

class ProviderOnboardingController extends ChangeNotifier {
  static const String _onboardingKey = 'provider_onboarding_completed';

  bool _inProgress = false;
  String? _errorMessage;

  bool get inProgress => _inProgress;
  String? get errorMessage => _errorMessage;

  // ── Step 1: Personal Info & Domain ─────────────────────────────────────────
  String firstName = '';
  String lastName = '';
  String email = '';
  String phone = '';
  String country = 'France'; // Default or from user
  String city = '';
  String address = '';
  DateTime? dateOfBirth;
  List<String> primaryDomain = []; // Photography, Videography, Editing

  // ── Step 2: Experience & Specialties ────────────────────────────────────
  List<String> specialties = [];
  List<String> selectedCategoryIds = [];
  String? yearsOfExperience;
  String? projectsCompleted;
  String? education;

  // ── Step 3: Location & Travel ────────────────────────────────────────────
  String mainCity = '';
  String department = '';
  String radius = '50km';
  bool availableForTravel = false;

  // ── Step 4: Bio & Portfolio & Profile Pic ───────────────────────────────
  String miniBio = '';
  String externalPortfolioLink = '';
  File? profileImage;
  List<File> portfolioImages = [];

  // ── Step 5: Preferences & Legal ─────────────────────────────────────────
  bool emailNewRequests = true;
  bool smsUrgentRequests = true;
  bool newsletterPros = true; // Recommended default Yes
  bool customerReviewReminder = true;

  bool acceptedTerms = false;
  bool privacyPolicy = false;
  bool gdprAuthorization = false;

  // ── Image Picking ────────────────────────────────────────────────────────
  Future<void> pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      File file = File(pickedFile.path);
      profileImage = await ImageUtils.fixImageOrientation(file);
      notifyListeners();
    }
  }

  void removeProfileImage() {
    profileImage = null;
    notifyListeners();
  }

  Future<void> pickPortfolioImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 70);
    if (pickedFiles.isNotEmpty) {
      for (var pickedFile in pickedFiles) {
        if (portfolioImages.length >= 20) break; // Max 20
        File file = File(pickedFile.path);
        File? fixedFile = await ImageUtils.fixImageOrientation(file);
        if (fixedFile != null) {
          portfolioImages.add(fixedFile);
        }
      }
      notifyListeners();
    }
  }

  void removePortfolioImage(int index) {
    if (index >= 0 && index < portfolioImages.length) {
      portfolioImages.removeAt(index);
      notifyListeners();
    }
  }

  // ── State Management ─────────────────────────────────────────────────────
  
  void initFromUserProfile(dynamic userProfile) {
    if (userProfile == null) return;
    final fullName = userProfile.fullName ?? '';
    final parts = fullName.split(' ');
    firstName = parts.isNotEmpty ? parts.first : '';
    lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    email = userProfile.email ?? '';
    phone = userProfile.phone ?? '';
    if (userProfile.location != null && userProfile.location!.isNotEmpty) {
      address = userProfile.location!;
    }
    // We don't overwrite if they already typed something
  }

  void reset() {
    firstName = '';
    lastName = '';
    email = '';
    phone = '';
    country = 'France';
    city = '';
    address = '';
    dateOfBirth = null;
    primaryDomain = [];
    specialties = [];
    selectedCategoryIds = [];
    yearsOfExperience = null;
    projectsCompleted = null;
    education = null;
    mainCity = '';
    department = '';
    radius = '50km';
    availableForTravel = false;
    miniBio = '';
    externalPortfolioLink = '';
    profileImage = null;
    portfolioImages = [];
    emailNewRequests = true;
    smsUrgentRequests = true;
    newsletterPros = true;
    customerReviewReminder = true;
    acceptedTerms = false;
    privacyPolicy = false;
    gdprAuthorization = false;
    _errorMessage = null;
    _inProgress = false;
    notifyListeners();
  }

  @override
  void dispose() {
    // Note: Controllers provided by ChangeNotifierProvider usually don't need manual reset in dispose
    // unless they are reused. But we provide a reset() method for manual cleanup.
    super.dispose();
  }

  // ── Onboarding Status ────────────────────────────────────────────────────
  static bool isOnboardingCompleted() {
    return GetStorage().read(_onboardingKey) == true;
  }

  static Future<void> markOnboardingCompleted() async {
    await GetStorage().write(_onboardingKey, true);
  }

  static Future<void> resetOnboarding() async {
    await GetStorage().remove(_onboardingKey);
  }

  static Future<bool> checkOnboardingStatusFromServer() async {
    try {
      final response = await NetworkCaller.getRequest(url: Urls.professionalProfile);
      if (response.isSuccess) {
        final data = response.body?['data'];
        if (data != null) {
          final primaryDomain = data['primaryDomain'] as List?;
          // If primaryDomain is not null and not empty, it means they already filled at least step 1
          if (primaryDomain != null && primaryDomain.isNotEmpty) {
            return true;
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking onboarding status from server: $e');
    }
    return false;
  }

  // ── Validation ───────────────────────────────────────────────────────────
  bool get isStep1Valid => firstName.trim().isNotEmpty && lastName.trim().isNotEmpty && email.trim().isNotEmpty && phone.trim().isNotEmpty && country.trim().isNotEmpty && city.trim().isNotEmpty && dateOfBirth != null;
  bool get isStep2Valid => primaryDomain.isNotEmpty && specialties.isNotEmpty;
  bool get isStep5Valid => profileImage != null; // Profile picture is required
  bool get isStep6Valid => acceptedTerms && privacyPolicy && gdprAuthorization;

  // ── API Submission ───────────────────────────────────────────────────────
  Future<bool> submitOnboarding() async {
    _inProgress = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Map<String, dynamic> body = {
        // Required
        'dateOfBirth': dateOfBirth != null
            ? '${dateOfBirth!.year}-${dateOfBirth!.month.toString().padLeft(2, '0')}-${dateOfBirth!.day.toString().padLeft(2, '0')}'
            : null,
        'primaryDomain': primaryDomain,
        'notificationPreferences': {
          'emailNewRequests': emailNewRequests,
          'smsUrgentRequests': smsUrgentRequests,
          'newsletterPros': newsletterPros,
          'customerReviewReminder': customerReviewReminder,
        },
        'legalNotice': {
          'acceptedTerms': acceptedTerms,
          'privacyPolicy': privacyPolicy,
          'gdprAuthorization': gdprAuthorization,
        },
      };

      // Optional fields - only add if filled
      if (specialties.isNotEmpty) body['specialties'] = specialties;
      if (selectedCategoryIds.isNotEmpty) body['categories'] = selectedCategoryIds;

      if (mainCity.isNotEmpty || department.isNotEmpty) {
        body['areaOfIntervention'] = {
          'mainCity': mainCity,
          'department': department,
          'radius': radius,
          'availableForTravel': availableForTravel,
        };
      }

      final hasExperience = yearsOfExperience != null || projectsCompleted != null || education != null;
      if (hasExperience) {
        body['experienceDetails'] = {
          if (yearsOfExperience != null) 'yearsOfExperience': yearsOfExperience,
          if (projectsCompleted != null) 'projectsCompleted': projectsCompleted,
          if (education != null) 'education': education,
        };
      }

      if (miniBio.isNotEmpty) body['miniBio'] = miniBio;
      if (externalPortfolioLink.isNotEmpty) body['externalPortfolioLink'] = externalPortfolioLink;

      // Remove null values
      body.removeWhere((key, value) => value == null);

      debugPrint('📋 Submitting Professional Onboarding: $body');

      // 1. Try to fetch existing profile first to check if it exists
      final checkResponse = await NetworkCaller.getRequest(url: Urls.professionalProfile);
      
      NetworkResponse response;
      if (checkResponse.statusCode == 404 || checkResponse.body?['data'] == null) {
        // If profile doesn't exist (404), use POST to create it
        debugPrint('📋 Profile not found, creating new profile with POST');
        response = await NetworkCaller.postRequest(
          url: Urls.professionalProfile,
          body: body,
        );
      } else {
        // If profile exists, use PATCH to update it
        debugPrint('📋 Profile exists, updating with PATCH');
        response = await NetworkCaller.patchRequest(
          url: Urls.professionalProfile,
          body: body,
        );
      }

      debugPrint('📋 Onboarding Response: ${response.statusCode} - ${response.body}');

      if (response.isSuccess) {
        // 2. If profile image selected, upload it separately to User Profile API
        if (profileImage != null) {
          debugPrint('📸 Uploading profile image as part of onboarding...');
          await NetworkCaller.multipartRequest(
            url: Urls.updateUserProfile,
            method: 'PATCH',
            fileKey: 'images',
            filePath: profileImage!.path,
            requireAuth: true,
          );
        }

        await markOnboardingCompleted();
        _inProgress = false;
        reset(); // Clear state after successful submission as requested
        return true;
      } else {
        _errorMessage = response.errorMessage ?? 'Failed to save profile. Please try again.';
        _inProgress = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('❌ Onboarding submission error: $e');
      _errorMessage = 'An error occurred. Please check your connection.';
      _inProgress = false;
      notifyListeners();
      return false;
    }
  }
}
