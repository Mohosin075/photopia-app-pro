import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photopya/data/models/professional_profile_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:photopya/controller/provider/provider_profile_controller.dart';
import 'package:photopya/core/widgets/subscription_badge.dart';
import 'package:photopya/core/widgets/custom_network_image.dart';
import 'package:photopya/features/client/widgets/auth_profile_image.dart';
import 'package:photopya/core/widgets/custom_snacbar.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:photopya/core/utils/image_utils.dart';
import 'package:photopya/core/widgets/full_screen_image_viewer.dart';
import 'package:photopya/core/widgets/document_viewer_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:photopya/core/localization/app_localizations.dart';
import 'package:photopya/features/client/search_screen.dart';
import 'package:photopya/features/client/search_result_screen.dart';
import 'package:photopya/core/widgets/app_refresher.dart';

class ProviderProfileScreen extends StatefulWidget {
  final bool showSpecializations; 
  const ProviderProfileScreen({super.key, this.showSpecializations = true});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  bool _isEditing = false;
  bool _isSaving = false;
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  File? _coverPhoto;
  File? _profilePhoto;

  // Temporary state for in-place editing
  List<String> _tempSpecializations = [];
  List<String> _tempLanguages = [];
  List<dynamic> _tempPortfolio = [];
  List<dynamic> _tempDocuments = [];

  // Professional details editing state
  String? _tempYearsOfExperience;
  String? _tempProjectsCompleted;
  String? _tempEducation;
  String? _tempDepartment;
  String? _tempRadius;
  bool _tempAvailableForTravel = false;

  // Tracking deletions for the /remove-items API
  final Set<String> _removedSpecializations = {};
  final Set<String> _removedLanguages = {};
  final Set<String> _removedPortfolio = {};
  final Set<String> _removedDocuments = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  void _loadProfileData() {
    context.read<ProviderProfileController>().getProviderProfile().then((
      success,
    ) {
      if (success && mounted) {
        final ctrl = context.read<ProviderProfileController>();
        _aboutController.text = ctrl.aboutMe;
        _bioController.text = ctrl.shortBio;
        _nameController.text = ctrl.name;
        _tempSpecializations = List<String>.from(ctrl.specializations);
        _tempLanguages = List<String>.from(ctrl.languages);
        _tempPortfolio = List<dynamic>.from(ctrl.recentWork);
        _tempDocuments = List<dynamic>.from(ctrl.uploadedDocuments);
        _tempYearsOfExperience = ctrl.yearsOfExperience.isEmpty ? null : ctrl.yearsOfExperience;
        _tempProjectsCompleted = ctrl.projectsCompleted.isEmpty ? null : ctrl.projectsCompleted;
        _tempEducation = ctrl.education.isEmpty ? null : ctrl.education;
        _cityController.text = ctrl.mainCity;
        _tempDepartment = ctrl.department.isEmpty ? null : ctrl.department;
        _tempRadius = ctrl.radius.isEmpty ? null : ctrl.radius;
        _tempAvailableForTravel = ctrl.availableForTravel;
        _profilePhoto = null;
        _coverPhoto = null;
        setState(() {});

        // Fetch reviews using the provider's ID
        final providerId =
            ctrl.professionalProfile?.user?.id ?? ctrl.userProfile?.id;
        if (providerId != null) {
          ctrl.getProviderReviews(providerId);
        }
      }
    });
  }

  @override
  void dispose() {
    _aboutController.dispose();
    _bioController.dispose();
    _nameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _onHashtagTap(String hashtag) {
    if (_isEditing) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SearchResultScreen(
          filters: {'searchTerm': '#$hashtag'},
          title: '#$hashtag',
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    final controller = context.read<ProviderProfileController>();

    setState(() {
      _isEditing = false;
      _isSaving = true;
    });

    // 0. Enforce mandatory profile picture
    final bool hasProfileImage =
        controller.profileImage != null && controller.profileImage!.isNotEmpty;
    if (!hasProfileImage && _profilePhoto == null) {
      setState(() => _isSaving = false);
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Profile picture is mandatory for creators',
          isError: true,
        );
      }
      return;
    }

    // 1. Handle explicit removals first using the new API
    bool removalSuccess = true;

    if (_removedSpecializations.isNotEmpty) {
      for (var item in _removedSpecializations) {
        if (!await controller.removeItemFromProfessionalProfile(
          field: 'specialties',
          value: item,
        ))
          removalSuccess = false;
      }
    }
    if (_removedLanguages.isNotEmpty) {
      for (var item in _removedLanguages) {
        if (!await controller.removeItemFromProfessionalProfile(
          field: 'language',
          value: item,
        ))
          removalSuccess = false;
      }
    }
    if (_removedPortfolio.isNotEmpty) {
      for (var item in _removedPortfolio) {
        if (!await controller.removeItemFromProfessionalProfile(
          field: 'portfolio',
          value: item,
        ))
          removalSuccess = false;
      }
    }
    if (_removedDocuments.isNotEmpty) {
      for (var item in _removedDocuments) {
        if (!await controller.removeItemFromProfessionalProfile(
          field: 'documents',
          value: item,
        ))
          removalSuccess = false;
      }
    }

    if (!removalSuccess) {
      setState(() {
        _isSaving = false;
        _isEditing = true;
      });
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: context.l10n.itemsFailedToDelete(
            controller.errorMessage ?? '',
          ),
          isError: true,
        );
      }
      return;
    }

    // 2. Calculate New Additions (to avoid duplication since backend appends)
    final List<String> newSpecializations = _tempSpecializations
        .where((s) => !controller.specializations.contains(s))
        .toList();
    final List<String> newLanguages = _tempLanguages
        .where((l) => !controller.languages.contains(l))
        .toList();
    final List<File> newPortfolioFiles = _tempPortfolio
        .whereType<File>()
        .toList();

    // 3. Perform main update (only new additions and text changes)
    final success = await controller.updateProviderProfile(
      name: _nameController.text != controller.name
          ? _nameController.text
          : null,
      bio: _bioController.text != controller.shortBio
          ? _bioController.text
          : null,
      description: _aboutController.text != controller.aboutMe
          ? _aboutController.text
          : null,
      newSpecializations: newSpecializations,
      newLanguages: newLanguages,
      newPortfolioFiles: newPortfolioFiles,
      newDocumentFiles: _tempDocuments.whereType<File>().toList(),
      profilePhoto: _profilePhoto,
      coverPhoto: _coverPhoto,
      yearsOfExperience: _tempYearsOfExperience != controller.yearsOfExperience ? (_tempYearsOfExperience ?? '') : null,
      projectsCompleted: _tempProjectsCompleted != controller.projectsCompleted ? (_tempProjectsCompleted ?? '') : null,
      education: _tempEducation != controller.education ? (_tempEducation ?? '') : null,
      mainCity: _cityController.text != controller.mainCity ? _cityController.text : null,
      department: _tempDepartment != controller.department ? (_tempDepartment ?? '') : null,
      radius: _tempRadius != controller.radius ? (_tempRadius ?? '') : null,
      availableForTravel: _tempAvailableForTravel != controller.availableForTravel ? _tempAvailableForTravel : null,
    );

    setState(() => _isSaving = false);

    if (success) {
      if (mounted) {
        // Clear removal trackers
        _removedSpecializations.clear();
        _removedLanguages.clear();
        _removedPortfolio.clear();
        _removedDocuments.clear();

        // Reload from fresh API data
        _aboutController.text = controller.aboutMe;
        _bioController.text = controller.shortBio;
        _nameController.text = controller.name;
        _tempSpecializations = List<String>.from(controller.specializations);
        _tempLanguages = List<String>.from(controller.languages);
        _tempPortfolio = List<dynamic>.from(controller.recentWork);
        _tempDocuments = List<dynamic>.from(controller.uploadedDocuments);
        _tempYearsOfExperience = controller.yearsOfExperience.isEmpty ? null : controller.yearsOfExperience;
        _tempProjectsCompleted = controller.projectsCompleted.isEmpty ? null : controller.projectsCompleted;
        _tempEducation = controller.education.isEmpty ? null : controller.education;
        _cityController.text = controller.mainCity;
        _tempDepartment = controller.department.isEmpty ? null : controller.department;
        _tempRadius = controller.radius.isEmpty ? null : controller.radius;
        _tempAvailableForTravel = controller.availableForTravel;
        setState(() {});

        CustomSnackBar.show(
          context: context,
          message: context.l10n.profileUpdatedSuccess,
          isError: false,
        );
      }
    } else {
      setState(() => _isEditing = true);
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: controller.errorMessage ?? context.l10n.updateFailed,
          isError: true,
        );
      }
    }
  }

  Future<void> _pickPortfolioImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final processedFile = await ImageUtils.fixImageOrientation(
        File(image.path),
      );
      setState(() {
        _tempPortfolio.add(processedFile);
      });
    }
  }

  Future<void> _pickProfilePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final processedFile = await ImageUtils.fixImageOrientation(
        File(image.path),
      );
      setState(() {
        _profilePhoto = processedFile;
      });
    }
  }

  Future<void> _pickCoverPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final processedFile = await ImageUtils.fixImageOrientation(
        File(image.path),
      );
      setState(() {
        _coverPhoto = processedFile;
      });
    }
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _tempDocuments.add(File(result.files.single.path!));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderProfileController>(
      builder: (context, profileController, child) {
        if (profileController.inProgress &&
            profileController.userProfile == null) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).colorScheme.onSurface,
                size: 24.sp,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (_isEditing)
                IconButton(
                  icon: Icon(
                    Icons.camera_alt_outlined,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 24.sp,
                  ),
                  onPressed: _pickCoverPhoto,
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async => _loadProfileData(),
            color: Theme.of(context).colorScheme.primary,
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Header Stack with Card + Stats overlapping
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Header Image (Background)
                      _coverPhoto != null
                          ? Image.file(
                              _coverPhoto!,
                              height: 220.h,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : (profileController.coverPhoto != null &&
                                profileController.coverPhoto!.isNotEmpty)
                          ? CustomNetworkImage(
                              imageUrl: profileController.coverPhoto!,
                              height: 220.h,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              height: 220.h,
                              width: double.infinity,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.05),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.1),
                                    size: 32.sp,
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'No cover photo',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.2),
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                      // Gradient Overlay
                      Container(
                        height: 200.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.1),
                              Colors.black.withOpacity(0.4),
                            ],
                          ),
                        ),
                      ),

                      // Invisible Tap Layer for Cover Photo (Must be above Image and Overlay)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 220.h,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FullScreenImageViewer(
                                  imageUrl: _coverPhoto == null
                                      ? profileController.coverPhoto
                                      : null,
                                  filePath: _coverPhoto?.path,
                                  tag: 'cover_photo_hero',
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Floating Glassmorphism Profile Card
                      Positioned(
                        bottom: -5.h,
                        left: 6.w,
                        right: 6.w,
                        child: _buildProfileCard(context, profileController),
                      ),

                      // Overlapping Stats Row
                      Positioned(
                        bottom: -80.h,
                        left: 0,
                        right: 0,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.w),
                          child: _buildStatsRow(context, profileController),
                        ),
                      ),
                    ],
                  ),

                  // Padding for the overlapping stats cards
                  SizedBox(height: 100.h),

                  // Content below
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAboutSection(),
                        SizedBox(height: 25.h),
                        if (widget.showSpecializations) ...[
                          _buildChipsSection(
                            context.l10n.specializationsTitle,
                            true,
                          ),
                          SizedBox(height: 25.h),
                        ],
                        _buildChipsSection(context.l10n.languagesTitle, false),
                        SizedBox(height: 25.h),
                        _buildDocumentsSection(),
                        SizedBox(height: 25.h),
                        _buildRecentWorkSection(),
                        SizedBox(height: 25.h),
                        _buildProfessionalDetailsSection(profileController),
                        SizedBox(height: 25.h),
                        _buildReviewsSection(profileController),
                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    ProviderProfileController controller,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // "Profile" title + Edit button row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.profileTitle,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  if (!_isEditing && !_isSaving)
                    GestureDetector(
                      onTap: () => setState(() => _isEditing = true),
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Icon(
                          Icons.edit_outlined,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                      ),
                    )
                  else if (_isSaving)
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: SizedBox(
                        width: 20.sp,
                        height: 20.sp,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _saveChanges,
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 8.h),
              // Avatar + Name/Specialty/Badge row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenImageViewer(
                            imageUrl: _profilePhoto == null
                                ? controller.profileImage
                                : null,
                            filePath: _profilePhoto?.path,
                            tag: 'profile_photo_hero',
                          ),
                        ),
                      );
                    },
                    child: Hero(
                      tag: 'profile_photo_hero',
                      child: Stack(
                        children: [
                          _profilePhoto != null
                              ? Container(
                                  width: 75.r,
                                  height: 75.r,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.5.w,
                                    ),
                                    image: DecorationImage(
                                      image: FileImage(_profilePhoto!),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              : AuthProfileImage(
                                  imageUrl: controller.profileImage,
                                  size: 75.r,
                                ),
                          if (_isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickProfilePhoto,
                                child: Container(
                                  padding: EdgeInsets.all(4.r),
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 14.sp,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 18.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isEditing) ...[
                          TextFormField(
                            controller: _nameController,
                            style: TextStyle(
                              fontSize: 19.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              hintText: context.l10n.fullNameHint,
                              hintStyle: TextStyle(
                                color: Colors.white60,
                                fontSize: 16.sp,
                              ),
                              isCollapsed: true,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 4.h,
                              ),
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          TextFormField(
                            controller: _bioController,
                            style: TextStyle(
                              fontSize: 12.5.sp,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            decoration: InputDecoration(
                              hintText: context.l10n.bioTaglineHint,
                              hintStyle: TextStyle(
                                color: Colors.white60,
                                fontSize: 13.sp,
                              ),
                              isCollapsed: true,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 4.h,
                              ),
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          Text(
                            controller.name,
                            style: TextStyle(
                              fontSize: 19.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (controller.profileTagline.isNotEmpty) ...[
                            SizedBox(height: 4.h),
                            Text(
                              controller.profileTagline,
                              style: TextStyle(
                                fontSize: 12.5.sp,
                                color: Colors.white.withOpacity(0.9),
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                        SizedBox(height: 10.h),
                        SubscriptionBadge(
                          isSubscribed:
                              controller.userProfile?.isSubscribed ?? false,
                          fontSize: 10.5.sp,
                          iconSize: 12.sp,
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 5.h,
                          ),
                        ),
                        SizedBox(height: 5.h),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    ProviderProfileController controller,
  ) {
    final rating = controller.rating.toStringAsFixed(1);
    final reviews = controller.reviewCount.toString();
    final responseRate = '${controller.responseRate}%';
    final projectsCount = controller.projectsCount.toString();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(Icons.star_border, rating, context.l10n.ratingLabel),
        _buildStatItem(
          Icons.verified_outlined,
          reviews,
          context.l10n.reviewsLabel,
        ),
        _buildStatItem(
          Icons.military_tech_outlined,
          responseRate,
          context.l10n.responseRateLabel,
        ),
        _buildStatItem(
          Icons.camera_alt_outlined,
          projectsCount,
          context.l10n.projectsLabel,
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Container(
      width: 78.w,
      height: 90.h,
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10).r,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Icon(
            icon,
            size: 22.sp,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.sp,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              height: 1,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.aboutMeTitle,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 12.h),
        if (_isEditing)
          TextFormField(
            controller: _aboutController,
            maxLines: null,
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
            ),
          )
        else
          Text(
            _aboutController.text,
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              height: 1.5,
            ),
          ),
      ],
    );
  }

  Widget _buildChipsSection(String title, bool isSpecialty) {
    final List<String> list = isSpecialty
        ? _tempSpecializations
        : _tempLanguages;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (_isEditing)
              IconButton(
                icon: Icon(
                  Icons.add_circle_outline,
                  color: Colors.blueAccent,
                  size: 22.sp,
                ),
                onPressed: () => _showAddChipDialog(title, isSpecialty),
              ),
          ],
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: list.map((item) => _buildChip(item, isSpecialty)).toList(),
        ),
      ],
    );
  }

  Widget _buildChip(String label, bool isSpecialty) {
    return GestureDetector(
      onTap: () => isSpecialty ? _onHashtagTap(label) : null,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20).r,
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isSpecialty ? '#$label' : label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_isEditing) ...[
              SizedBox(width: 6.w),
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSpecialty) {
                      _tempSpecializations.remove(label);
                      _removedSpecializations.add(label);
                    } else {
                      _tempLanguages.remove(label);
                      _removedLanguages.add(label);
                    }
                  });
                },
                child: Icon(Icons.close, size: 14.sp, color: Colors.red[400]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentWorkSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.portfolioCount(_tempPortfolio.length),
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            if (_isEditing)
              GestureDetector(
                onTap: _pickPortfolioImage,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 16.sp,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        context.l10n.addPhotoBtn,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 15.h),
        GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10.h,
            crossAxisSpacing: 10.w,
            childAspectRatio: 1,
          ),
          itemCount: _tempPortfolio.length,
          itemBuilder: (context, index) {
            final item = _tempPortfolio[index];
            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenImageViewer(
                            imageUrl: item is String ? item : null,
                            filePath: item is File ? item.path : null,
                            tag: 'portfolio_$index',
                          ),
                        ),
                      );
                    },
                    child: Hero(
                      tag: 'portfolio_$index',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10).r,
                        child: item is File
                            ? Image.file(item, fit: BoxFit.cover)
                            : CustomNetworkImage(
                                imageUrl: item.toString(),
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  ),
                ),
                if (_isEditing)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          final removedItem = _tempPortfolio.removeAt(index);
                          if (removedItem is String) {
                            _removedPortfolio.add(removedItem);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildReviewsSection(ProviderProfileController controller) {
    if (controller.inProgress && controller.reviews.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final reviews = controller.reviews;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.clientReviewsTitle,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 16.sp),
                SizedBox(width: 4.w),
                Text(
                  '${controller.rating.toStringAsFixed(1)} (${controller.reviewCount} reviews)',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 20.h),
        if (reviews.isEmpty)
          Container(
            padding: EdgeInsets.symmetric(vertical: 30.h),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.02),
              borderRadius: BorderRadius.circular(15.r),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.2),
                  size: 40.sp,
                ),
                SizedBox(height: 12.h),
                Text(
                  context.l10n.noReviewsYet,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  context.l10n.completedBookingsWillAppearHere,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reviews.length > 3 ? 3 : reviews.length, // Limit preview
            separatorBuilder: (context, index) => SizedBox(height: 20.h),
            itemBuilder: (context, index) {
              final review = reviews[index];
              return _buildReviewItem(
                review.user?.name ?? context.l10n.anonymous,
                review.createdAt ?? '',
                review.comment ?? '',
                review.rating?.toDouble() ?? 5.0,
              );
            },
          ),
      ],
    );
  }

  Widget _buildEditableDetailDropdown({
    required IconData icon,
    required String label,
    required String? value,
    required List<String> items,
    required Map<String, String> displayLabels,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18.sp,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ),
          SizedBox(width: 12.w),
          Text(
            '$label:',
            style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.2),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  isDense: true,
                  isExpanded: true,
                  hint: Text(
                    'Select',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  borderRadius: BorderRadius.circular(8.r),
                  items: items.map((e) {
                    final l = displayLabels[e] ?? e;
                    return DropdownMenuItem(
                      value: e,
                      child: Text(
                        l,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: onChanged,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableDetailTextField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18.sp,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ),
          SizedBox(width: 12.w),
          Text(
            '$label:',
            style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Container(
              height: 36.h,
              alignment: Alignment.centerRight,
              child: TextField(
                controller: controller,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableDetailSwitch({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18.sp,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ),
          SizedBox(width: 12.w),
          Text(
            '$label:',
            style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
          ),
          const Spacer(),
          SizedBox(
            height: 24.h,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalDetailsSection(
    ProviderProfileController controller,
  ) {
    final prof = controller.professionalProfile;
    if (prof == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Professional Details',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 15.h),
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: [
              if (!_isEditing) ...[
                _buildDetailRow(
                  Icons.work_outline,
                  context.l10n.experience,
                  controller.yearsOfExperience.isEmpty ? 'Not specified' : controller.yearsOfExperience,
                ),
                _buildDetailRow(
                  Icons.task_alt,
                  context.l10n.projectsLabel,
                  controller.projectsCompleted.isEmpty ? 'Not specified' : controller.projectsCompleted,
                ),
                _buildDetailRow(
                  Icons.school_outlined,
                  context.l10n.education,
                  controller.education.isEmpty ? 'Not specified' : controller.education,
                ),
                _buildDetailRow(
                  Icons.location_city_outlined,
                  context.l10n.serviceArea,
                  controller.mainCity.isEmpty ? 'Not specified' : controller.mainCity,
                ),
                _buildDetailRow(
                  Icons.map_outlined,
                  'Department',
                  controller.department.isEmpty ? 'Not specified' : controller.department,
                ),
                _buildDetailRow(
                  Icons.explore_outlined,
                  context.l10n.interventionRadius,
                  controller.radius.isEmpty ? 'Not specified' : controller.radius,
                ),
                _buildDetailRow(
                  Icons.flight_takeoff_outlined,
                  context.l10n.availableForTravel,
                  controller.availableForTravel
                      ? context.l10n.yes
                      : context.l10n.no,
                ),
              ] else ...[
                _buildEditableDetailDropdown(
                  icon: Icons.work_outline,
                  label: context.l10n.experience,
                  value: _tempYearsOfExperience,
                  items: const ['<1 year', '1-3 years', '3-5 years', '5-10 years', '10+ years'],
                  displayLabels: {
                    '<1 year': context.l10n.expLess1Year,
                    '1-3 years': context.l10n.exp1To3Years,
                    '3-5 years': context.l10n.exp3To5Years,
                    '5-10 years': context.l10n.exp5To10Years,
                    '10+ years': context.l10n.exp10PlusYears,
                  },
                  onChanged: (val) {
                    setState(() {
                      _tempYearsOfExperience = val;
                    });
                  },
                ),
                _buildEditableDetailDropdown(
                  icon: Icons.task_alt,
                  label: context.l10n.projectsLabel,
                  value: _tempProjectsCompleted,
                  items: const ['<10', '10-50', '50-100', '100+'],
                  displayLabels: {
                    '<10': context.l10n.projLess10,
                    '10-50': context.l10n.proj10To50,
                    '50-100': context.l10n.proj50To100,
                    '100+': context.l10n.proj100Plus,
                  },
                  onChanged: (val) {
                    setState(() {
                      _tempProjectsCompleted = val;
                    });
                  },
                ),
                _buildEditableDetailDropdown(
                  icon: Icons.school_outlined,
                  label: context.l10n.education,
                  value: _tempEducation,
                  items: const ['Self-taught', 'School', 'Professional Training'],
                  displayLabels: {
                    'Self-taught': context.l10n.eduSelfTaught,
                    'School': context.l10n.eduSchool,
                    'Professional Training': context.l10n.eduProfessionalTraining,
                  },
                  onChanged: (val) {
                    setState(() {
                      _tempEducation = val;
                    });
                  },
                ),
                _buildEditableDetailTextField(
                  icon: Icons.location_city_outlined,
                  label: context.l10n.serviceArea,
                  controller: _cityController,
                  hint: 'e.g. Dhaka',
                ),
                _buildEditableDetailDropdown(
                  icon: Icons.map_outlined,
                  label: 'Department',
                  value: _tempDepartment,
                  items: const [
                    'Photography', 
                    'Videography & Cinematography', 
                    'Editing & Post-Production', 
                    'Scriptwriting & Storyboarding'
                  ],
                  displayLabels: const {
                    'Photography': 'Photography',
                    'Videography & Cinematography': 'Videography & Cinematography',
                    'Editing & Post-Production': 'Editing & Post-Production',
                    'Scriptwriting & Storyboarding': 'Scriptwriting & Storyboarding',
                  },
                  onChanged: (val) {
                    setState(() {
                      _tempDepartment = val;
                    });
                  },
                ),
                _buildEditableDetailDropdown(
                  icon: Icons.map_outlined,
                  label: context.l10n.interventionRadius,
                  value: _tempRadius,
                  items: const ['10km', '30km', '50km', '100km', 'Whole Country'],
                  displayLabels: {
                    '10km': '10km',
                    '30km': '30km',
                    '50km': '50km',
                    '100km': '100km',
                    'Whole Country': context.l10n.wholeCountry,
                  },
                  onChanged: (val) {
                    setState(() {
                      _tempRadius = val;
                    });
                  },
                ),
                _buildEditableDetailSwitch(
                  icon: Icons.flight_takeoff_outlined,
                  label: context.l10n.availableForTravel,
                  value: _tempAvailableForTravel,
                  onChanged: (val) {
                    setState(() {
                      _tempAvailableForTravel = val;
                    });
                  },
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 25.h),
        Text(
          context.l10n.performanceStats,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 15.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildPerformanceStat(
              context.l10n.responseTimeLabel,
              '${controller.responseTime}m',
            ),
            _buildPerformanceStat(
              context.l10n.deliveryLabel,
              '${controller.deliveryRate}%',
            ),
            _buildPerformanceStat(
              context.l10n.satisfactionLabel,
              '${controller.satisfactionRate}%',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18.sp,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ),
          SizedBox(width: 12.w),
          Text(
            '$label:',
            style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceStat(String label, String value) {
    return Container(
      width: 100.w,
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(
    String name,
    String date,
    String comment,
    double rating,
  ) {
    // Format date string (e.g., 2024-11-28T... -> Nov 28, 2024)
    String formattedDate = date;
    try {
      if (date.isNotEmpty) {
        final dt = DateTime.parse(date);
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        formattedDate = "${months[dt.month - 1]} ${dt.day}, ${dt.year}";
      }
    } catch (_) {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18.r,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.05),
                  child: Icon(
                    Icons.person,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.3),
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          Icons.star,
                          color: index < rating
                              ? Colors.amber
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.1),
                          size: 12.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 12.sp,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Padding(
          padding: EdgeInsets.only(left: 48.w),
          child: Text(
            comment,
            style: TextStyle(
              fontSize: 13.sp,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  void _showAddChipDialog(String title, bool isSpecialty) {
    final TextEditingController chipController = TextEditingController();

    // Predefined language list for dropdown
    const List<String> _availableLanguages = [
      'English',
      'French',
      'Spanish',
      'German',
      'Arabic',
      'Bengali',
      'Portuguese',
      'Italian',
      'Dutch',
      'Chinese',
      'Japanese',
      'Korean',
      'Hindi',
    ];
    String? _selectedLanguage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.addTitle(title),
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  isSpecialty
                      ? context.l10n.enterSpecializationHint
                      : context.l10n.selectLanguageHint,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 24.h),

                // Dropdown for Languages, text field for Specializations
                if (!isSpecialty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedLanguage,
                        hint: Text(
                          context.l10n.selectLanguageDropdownHint,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.3),
                            fontSize: 14.sp,
                          ),
                        ),
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                          size: 20.sp,
                        ),
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        dropdownColor: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12.r),
                        items: _availableLanguages
                            .where((lang) => !_tempLanguages.contains(lang))
                            .map(
                              (lang) => DropdownMenuItem(
                                value: lang,
                                child: Text(lang),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setDialogState(() => _selectedLanguage = val);
                        },
                      ),
                    ),
                  )
                else
                  TextField(
                    controller: chipController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: context.l10n.exPortraitPhotography,
                      hintStyle: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.3),
                        fontSize: 14.sp,
                      ),
                      filled: true,
                      fillColor: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.05),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1,
                        ),
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),

                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12).r,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          context.l10n.cancelBtn,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12).r,
                          ),
                        ),
                        onPressed: () {
                          if (!isSpecialty) {
                            // Language dropdown
                            if (_selectedLanguage != null) {
                              setState(
                                () => _tempLanguages.add(_selectedLanguage!),
                              );
                              Navigator.pop(context);
                            }
                          } else {
                            // Specialization text field
                            if (chipController.text.trim().isNotEmpty) {
                              setState(
                                () => _tempSpecializations.add(
                                  chipController.text.trim(),
                                ),
                              );
                              Navigator.pop(context);
                            }
                          }
                        },
                        child: Text(
                          context.l10n.addBtn,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.documentsTitle,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (_isEditing)
              IconButton(
                onPressed: _pickDocument,
                icon: Icon(
                  Icons.add_circle_outline,
                  color: Colors.blue,
                  size: 24.sp,
                ),
              ),
          ],
        ),
        SizedBox(height: 10.h),
        if (_tempDocuments.isEmpty)
          Text(
            context.l10n.noDocumentsAdded,
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _tempDocuments.length,
            separatorBuilder: (context, index) => SizedBox(height: 10.h),
            itemBuilder: (context, index) {
              final doc = _tempDocuments[index];
              final isFile = doc is File;
              final String fileName = isFile
                  ? doc.path.split('/').last
                  : doc.toString().split('/').last;

              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        fileName.toLowerCase().endsWith('.pdf')
                            ? Icons.picture_as_pdf
                            : Icons.insert_drive_file,
                        color: Colors.red.shade400,
                        size: 22.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        fileName,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!_isEditing)
                      IconButton(
                        onPressed: () async {
                          final String urlPath = isFile
                              ? doc.path
                              : doc.toString();
                          // Ensure we use the formatted network URL if it's not a local file
                          final String finalUrl = isFile
                              ? urlPath
                              : ProfessionalProfileModel.formatUrl(urlPath) ??
                                    urlPath;
                          final Uri url = Uri.parse(finalUrl);

                          if (await canLaunchUrl(url)) {
                            await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    context.l10n.couldNotOpenDocument,
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        icon: Icon(
                          Icons.remove_red_eye_outlined,
                          color: Colors.blue,
                          size: 20.sp,
                        ),
                      )
                    else
                      IconButton(
                        onPressed: () {
                          setState(() {
                            final removed = _tempDocuments.removeAt(index);
                            if (removed is String) {
                              _removedDocuments.add(removed);
                            }
                          });
                        },
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20.sp,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
