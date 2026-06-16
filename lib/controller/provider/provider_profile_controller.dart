import 'package:flutter/material.dart';
import 'package:photopya/core/network/Api_service/network_caller.dart';
import 'package:photopya/core/network/urls.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:photopya/controller/auth_controller.dart';
import 'package:photopya/data/models/user_profile_model.dart';
import 'package:photopya/data/models/professional_profile_model.dart';
import 'package:photopya/data/models/review_model.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ProviderProfileController extends ChangeNotifier {
  bool _inProgress = false;
  String? _errorMessage;
  UserProfileModel? _userProfile;
  ProfessionalProfileModel? _professionalProfile;
  List<ReviewItem> _reviews = [];
  
  bool get inProgress => _inProgress;
  String? get errorMessage => _errorMessage;
  UserProfileModel? get userProfile => _userProfile;
  ProfessionalProfileModel? get professionalProfile => _professionalProfile;
  List<ReviewItem> get reviews => _reviews;

  String get name =>
      _professionalProfile?.user?.name ?? _userProfile?.fullName ?? 'Michael Photographer';
  String get aboutMe =>
      _professionalProfile?.user?.description ??
      _userProfile?.description ??
      _professionalProfile?.miniBio ??
      _professionalProfile?.bio ??
      'Professional wedding and event photographer with 10+ years of experience.';
  String get profileTagline {
    if (_professionalProfile?.bio != null && _professionalProfile!.bio!.isNotEmpty) {
      return _professionalProfile!.bio!;
    }
    if (_professionalProfile?.miniBio != null && _professionalProfile!.miniBio!.isNotEmpty) {
      return _professionalProfile!.miniBio!;
    }
    if (_userProfile?.specialty != null && _userProfile!.specialty!.isNotEmpty) {
      return _userProfile!.specialty!;
    }
    return 'Professional Photographer';
  }

  String get shortBio => _professionalProfile?.bio ?? _professionalProfile?.miniBio ?? '';

  String get specialty =>
      _userProfile?.specialty ??
      'Professional Photographer';
  String? get profileImage =>
      _professionalProfile?.user?.profile ?? _userProfile?.profile;
  String? get coverPhoto =>
      _professionalProfile?.coverPhoto;

  // Stats getters
  int get bookingsCount => _professionalProfile?.statistics?.bookings?.count ?? 0;
  int get bookingsThisWeek => _professionalProfile?.statistics?.bookings?.thisWeek ?? 0;
  double get revenueAmount => (_professionalProfile?.statistics?.revenue?.amount ?? 0).toDouble();
  int get revenueChange => _professionalProfile?.statistics?.revenue?.percentageChange ?? 0;
  int get profileViews => _professionalProfile?.profileViews ?? 0;
  double get rating => _professionalProfile?.rating ?? 0.0;
  int get reviewCount => _professionalProfile?.reviewCount ?? 0;
  int get projectsCount => _professionalProfile?.projects ?? 0;
  int get responseRate => _professionalProfile?.responseRate ?? 0;
  int get responseTime => _professionalProfile?.responseTime ?? 0;
  int get deliveryRate => _professionalProfile?.deliveryRate ?? 0;
  int get satisfactionRate => _professionalProfile?.satisfactionRate ?? 0;
  bool get isSuperPro => _professionalProfile?.isSuperPro ?? false;
  
  // Area of Intervention
  String get mainCity => _professionalProfile?.areaOfIntervention?.mainCity ?? '';
  String get department => _professionalProfile?.areaOfIntervention?.department ?? '';
  String get radius => _professionalProfile?.areaOfIntervention?.radius ?? '';
  bool get availableForTravel => _professionalProfile?.areaOfIntervention?.availableForTravel ?? false;
  
  // Experience Details
  String get yearsOfExperience => _professionalProfile?.experienceDetails?.yearsOfExperience ?? '';
  String get projectsCompleted => _professionalProfile?.experienceDetails?.projectsCompleted ?? '';
  String get education => _professionalProfile?.experienceDetails?.education ?? '';

  List<String> get specializations => _professionalProfile?.specialties?.map((e) => e.toString()).toList() ?? [];
  List<String> get languages => _professionalProfile?.language?.map((e) => e.toString()).toList() ?? [];
  List<dynamic> get recentWork => _professionalProfile?.portfolio?.toList() ?? [];
  List<String> get uploadedDocuments => _professionalProfile?.documents?.map((e) => e.toString()).toList() ?? [];

  Future<bool> getProviderProfile() async {
    _inProgress = true;
    _errorMessage = null;
    notifyListeners();

    // Fetch both user profile and professional profile statistics
    final userProfileResponse = await NetworkCaller.getRequest(url: Urls.userProfile);
    final professionalProfileResponse = await NetworkCaller.getRequest(url: Urls.professionalProfile);

    debugPrint("🔍 User Profile Response: ${userProfileResponse.isSuccess} - ${userProfileResponse.body}");
    debugPrint("🔍 Prof Profile Response: ${professionalProfileResponse.isSuccess} - ${professionalProfileResponse.body}");
    
    if (professionalProfileResponse.isSuccess) {
      final documentsFromServer = professionalProfileResponse.body?['data']?['documents'];
      debugPrint("📄 [DEBUG] Documents from Database: $documentsFromServer");
    }

    _inProgress = false;
    
    if (userProfileResponse.isSuccess) {
      final data = userProfileResponse.body?['data'];
      if (data != null) {
        _userProfile = UserProfileModel.fromJson(data);
      }
    }

    if (professionalProfileResponse.isSuccess) {
      final data = professionalProfileResponse.body?['data'];
      debugPrint("📥 [PROFILE] Prof data type: ${data?.runtimeType}, keys: ${data is Map ? (data as Map).keys.toList() : 'N/A'}");
      if (data is Map<String, dynamic> && (data.containsKey('_id') || data.containsKey('id'))) {
        // Direct object response: { _id, coverPhoto, user, ... }
        _professionalProfile = ProfessionalProfileModel.fromJson(data);
        debugPrint("✅ [PROFILE] coverPhoto from API: ${_professionalProfile?.coverPhoto}");
      } else if (data is List && data.isNotEmpty && data[0] is Map<String, dynamic>) {
        // Defensive: handle if backend ever wraps in a list
        _professionalProfile = ProfessionalProfileModel.fromJson(data[0]);
      } else {
        _professionalProfile = null;
        debugPrint("⚠️ [PROFILE] Unexpected prof data structure: $data");
      }
    } else {
      _professionalProfile = null;
    }

    notifyListeners();
    return userProfileResponse.isSuccess || professionalProfileResponse.isSuccess;
  }

  Future<bool> getProviderReviews(String providerId) async {
    _inProgress = true;
    notifyListeners();
    try {
      final response = await NetworkCaller.getRequest(url: Urls.getReviewsByProvider(providerId));
      _inProgress = false;
      if (response.isSuccess) {
        final data = response.body?['data'];
        if (data != null && data['data'] != null) {
          final list = data['data'] as List?;
          _reviews = list?.map((e) => ReviewItem.fromJson(e)).toList() ?? [];
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching reviews: $e');
    }
    _inProgress = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateProviderProfile({
    String? name,
    String? bio,
    String? description,
    List<String>? newSpecializations,
    List<String>? newLanguages,
    List<File>? newPortfolioFiles,
    List<File>? newDocumentFiles,
    File? profilePhoto,
    File? coverPhoto,
  }) async {
    _inProgress = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Update Professional Profile Data (New Additions Only)
      bool profProfileSuccess = true;
      bool hasProfChanges = bio != null || 
                            (newSpecializations != null && newSpecializations.isNotEmpty) || 
                            (newLanguages != null && newLanguages.isNotEmpty) || 
                            (newPortfolioFiles != null && newPortfolioFiles.isNotEmpty) ||
                            (newDocumentFiles != null && newDocumentFiles.isNotEmpty) ||
                            coverPhoto != null;

      if (hasProfChanges) {
        debugPrint('👔 Updating Prof Profile with new additions...');
        String? token = AuthController.accessToken;

        // Check if professional profile exists on backend
        final checkResponse = await NetworkCaller.getRequest(url: Urls.professionalProfile);
        bool exists = checkResponse.isSuccess && _doesProfileExist(checkResponse.body);

        if (!exists) {
          debugPrint('👔 Profile not found, creating base professional profile via JSON POST first...');
          final Map<String, dynamic> createBody = {
            'dateOfBirth': '1995-01-01',
            'primaryDomain': ['Photography'],
            'notificationPreferences': {
              'emailNewRequests': true,
              'smsUrgentRequests': true,
              'newsletterPros': true,
              'customerReviewReminder': true,
            },
            'legalNotice': {
              'acceptedTerms': true,
              'privacyPolicy': true,
              'gdprAuthorization': true,
            },
          };
          final createResponse = await NetworkCaller.postRequest(
            url: Urls.professionalProfile,
            body: createBody,
          );
          
          if (createResponse.isSuccess) {
            debugPrint('👔 Base professional profile created successfully via JSON POST.');
            exists = true;
          } else {
            debugPrint('❌ Failed to create base professional profile: ${createResponse.errorMessage}');
            _errorMessage = createResponse.errorMessage ?? "Failed to initialize professional profile.";
            profProfileSuccess = false;
          }
        }

        if (profProfileSuccess && exists) {
          final Uri uri = Uri.parse(Urls.professionalProfile);
          final request = http.MultipartRequest('PATCH', uri);

          if (token != null && token.isNotEmpty) {
            request.headers['Authorization'] = token.startsWith('Bearer ') ? token : 'Bearer $token';
          }
          request.headers['Accept'] = 'application/json';

          if (bio != null) request.fields['bio'] = bio;
          
          // Add cover photo if present
          if (coverPhoto != null) {
          final tempDir = await getTemporaryDirectory();
          final targetPath = p.join(tempDir.path, "temp_cover_${DateTime.now().millisecondsSinceEpoch}.jpg");
          
          final compressedFile = await FlutterImageCompress.compressAndGetFile(
            coverPhoto.absolute.path,
            targetPath,
            quality: 80,
            keepExif: false, // This strips buggy EXIF and bakes orientation
          );

          if (compressedFile != null) {
            final fileStream = http.ByteStream(File(compressedFile.path).openRead());
            final length = await File(compressedFile.path).length();
            final multipartFile = http.MultipartFile(
              'coverPhoto',
              fileStream,
              length,
              filename: 'cover_photo.jpg',
              contentType: MediaType('image', 'jpeg'),
            );
            request.files.add(multipartFile);
          }
        }
        
        // Add only NEW specialties as repeated keys
        if (newSpecializations != null) {
           for (var s in newSpecializations) {
             request.fields['specialties[]'] = s;
           }
        }
        // Add only NEW languages as repeated keys
        if (newLanguages != null) {
           for (var l in newLanguages) {
             request.fields['language[]'] = l;
           }
        }

        // Add ONLY new files to portfolio
        if (newPortfolioFiles != null) {
          for (var file in newPortfolioFiles) {
            final fileStream = http.ByteStream(file.openRead());
            final length = await file.length();
            final multipartFile = http.MultipartFile(
              'portfolio',
              fileStream,
              length,
              filename: file.path.split('/').last,
              contentType: MediaType('image', 'jpeg'),
            );
            request.files.add(multipartFile);
          }
        }

        // Add ONLY new files to documents
        if (newDocumentFiles != null) {
          for (var file in newDocumentFiles) {
            final fileStream = http.ByteStream(file.openRead());
            final length = await file.length();
            final multipartFile = http.MultipartFile(
              'documents',
              fileStream,
              length,
              filename: file.path.split('/').last,
              contentType: MediaType('application', 'octet-stream'),
            );
            request.files.add(multipartFile);
          }
        }

        try {
          final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
          final response = await http.Response.fromStream(streamedResponse);
          debugPrint("👔 Prof Profile Update Status: ${response.statusCode}");
          debugPrint("👔 Prof Profile Update Body: ${response.body}");
          
          profProfileSuccess = (response.statusCode >= 200 && response.statusCode < 300);
          if (!profProfileSuccess) {
             _errorMessage = "Failed to update professional profile.";
          }
        } catch (e) {
          debugPrint('👔 Update failed: $e');
          _errorMessage = "Connection error during update.";
          profProfileSuccess = false;
        }
      }
    }

      bool userProfileSuccess = true;
      if (description != null || name != null || profilePhoto != null) {
        debugPrint('👔 Updating User Profile: name=$name, profilePhoto=${profilePhoto != null}');

        if (profilePhoto != null) {
          // Multipart request only when uploading a photo
          String? token = AuthController.accessToken;
          final Uri uri = Uri.parse(Urls.updateUserProfile);
          final request = http.MultipartRequest('PATCH', uri);

          if (token != null && token.isNotEmpty) {
            request.headers['Authorization'] = token.startsWith('Bearer ') ? token : 'Bearer $token';
          }
          request.headers['Accept'] = 'application/json';

          if (name != null) request.fields['name'] = name;
          if (description != null) request.fields['description'] = description;

          final tempDir = await getTemporaryDirectory();
          final targetPath = p.join(tempDir.path, "temp_profile_${DateTime.now().millisecondsSinceEpoch}.jpg");
          
          final compressedFile = await FlutterImageCompress.compressAndGetFile(
            profilePhoto.absolute.path,
            targetPath,
            quality: 80,
            keepExif: false, // Bakes orientation 
          );

          if (compressedFile != null) {
            final fileStream = http.ByteStream(File(compressedFile.path).openRead());
            final length = await File(compressedFile.path).length();
            final multipartFile = http.MultipartFile(
              'images',
              fileStream,
              length,
              filename: 'profile_photo.jpg',
              contentType: MediaType('image', 'jpeg'),
            );
            request.files.add(multipartFile);
          }

          try {
            final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
            final response = await http.Response.fromStream(streamedResponse);
            debugPrint('👤 User Profile Multipart Status: ${response.statusCode}');
            debugPrint('👤 User Profile Multipart Body: ${response.body}');
            userProfileSuccess = (response.statusCode >= 200 && response.statusCode < 300);
            if (!userProfileSuccess) {
              _errorMessage = 'Server error ${response.statusCode}: ${response.body}';
            }
          } catch (e) {
            debugPrint('❌ Profile photo upload failed: $e');
            _errorMessage = 'Connection error: $e';
            userProfileSuccess = false;
          }
        } else {
          // Text-only update → use JSON PATCH via NetworkCaller
          final body = <String, dynamic>{};
          if (name != null) body['name'] = name;
          if (description != null) body['description'] = description;

          debugPrint('👤 Sending JSON PATCH for user profile: $body');
          final response = await NetworkCaller.patchRequest(
            url: Urls.updateUserProfile,
            body: body,
          );
          debugPrint('👤 JSON PATCH response: ${response.statusCode} - ${response.body}');
          userProfileSuccess = response.isSuccess;
          if (!userProfileSuccess) {
            _errorMessage = response.errorMessage ?? 'Failed to update user profile.';
          }
        }
      }

      if (profProfileSuccess && userProfileSuccess) {
        await getProviderProfile();
        return true;
      } else {
        if (_errorMessage == null && !userProfileSuccess) _errorMessage = "Failed to update user profile.";
        return false;
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      _errorMessage = 'Crash: $e';
      return false;
    } finally {
      _inProgress = false;
      notifyListeners();
    }
  }

  /// Removes specific items from professional profile fields.
  Future<bool> removeItemFromProfessionalProfile({required String field, required String value}) async {
    _inProgress = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('👔 Removing item: field=$field, value=$value');
      final response = await NetworkCaller.patchRequest(
        url: Urls.removeProfProfileItems,
        body: {
          "field": field,
          "values": [value]
        },
      );

      if (response.isSuccess) {
        debugPrint('✅ Successfully removed item from $field');
        return true;
      } else {
        _errorMessage = "Failed to remove item: ${response.body?['message'] ?? 'Unknown error'}";
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error removing item: $e');
      _errorMessage = "Error connecting to server.";
      return false;
    } finally {
      _inProgress = false;
      notifyListeners();
    }
  }


  void reset() {
    _userProfile = null;
    _professionalProfile = null;
    _reviews = [];
    _inProgress = false;
    _errorMessage = null;
    notifyListeners();
  }

  bool _doesProfileExist(Map<String, dynamic>? body) {
    if (body == null) return false;
    final data = body['data'];
    if (data == null) {
      return body.containsKey('_id') || body.containsKey('id');
    }
    if (data is List) {
      return data.isNotEmpty;
    }
    if (data is Map<String, dynamic>) {
      if (data.containsKey('data')) {
        final nestedData = data['data'];
        if (nestedData is List) {
          return nestedData.isNotEmpty;
        }
        if (nestedData is Map<String, dynamic>) {
          return nestedData.containsKey('_id') || nestedData.containsKey('id');
        }
      }
      return data.containsKey('_id') || data.containsKey('id');
    }
    return false;
  }
}
