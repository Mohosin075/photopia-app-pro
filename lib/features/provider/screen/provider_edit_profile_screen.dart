import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photopya/core/constants/app_typography.dart';
import 'dart:ui';
import 'dart:io';
import 'package:photopya/core/utils/image_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import 'package:photopya/controller/provider/provider_profile_controller.dart';
import 'package:photopya/core/widgets/custom_network_image.dart';
import 'package:photopya/core/widgets/custom_snacbar.dart';
import 'package:photopya/core/widgets/subscription_badge.dart';
import 'package:photopya/features/client/widgets/auth_profile_image.dart';
import 'package:photopya/core/widgets/full_screen_image_viewer.dart';
import 'package:photopya/core/localization/app_localizations.dart';

class ProviderEditProfileScreen extends StatefulWidget {
  const ProviderEditProfileScreen({super.key});

  @override
  State<ProviderEditProfileScreen> createState() =>
      _ProviderEditProfileScreenState();
}

class _ProviderEditProfileScreenState extends State<ProviderEditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _specialtyController;
  late TextEditingController _aboutController;
  late List<String> _tempSpecializations;
  late List<String> _tempLanguages;
  late List<String> _tempRecentWork;

  // Professional details
  String? _selectedExperience;
  String? _selectedProjects;
  String? _selectedEducation;
  late TextEditingController _cityController;
  String? _selectedDepartment;
  String? _selectedRadius;
  bool _availableForTravel = false;

  File? _profilePhoto;
  File? _coverPhoto;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final controller = context.read<ProviderProfileController>();
    _nameController = TextEditingController(text: controller.name);
    _specialtyController = TextEditingController(text: controller.specialty);
    _aboutController = TextEditingController(text: controller.aboutMe);
    _tempSpecializations = List.from(controller.specializations);
    _tempLanguages = List.from(controller.languages);
    _tempRecentWork = List.from(controller.recentWork);

    _selectedExperience = controller.yearsOfExperience.isEmpty ? null : controller.yearsOfExperience;
    _selectedProjects = controller.projectsCompleted.isEmpty ? null : controller.projectsCompleted;
    _selectedEducation = controller.education.isEmpty ? null : controller.education;
    _cityController = TextEditingController(text: controller.mainCity);
    _selectedDepartment = controller.department.isEmpty ? null : controller.department;
    _selectedRadius = controller.radius.isEmpty ? null : controller.radius;
    _availableForTravel = controller.availableForTravel;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specialtyController.dispose();
    _aboutController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _pickAndCropImage({required bool isProfile}) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: isProfile
            ? const CropAspectRatio(ratioX: 1, ratioY: 1)
            : const CropAspectRatio(ratioX: 16, ratioY: 9),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: isProfile
                ? context.l10n.cropProfilePicture
                : context.l10n.cropCoverPhoto,
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: isProfile
                ? CropAspectRatioPreset.square
                : CropAspectRatioPreset.ratio16x9,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: isProfile ? context.l10n.cropProfilePicture : context.l10n.cropCoverPhoto,
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (croppedFile != null) {
        final processedFile = await ImageUtils.fixImageOrientation(
          File(croppedFile.path),
        );
        setState(() {
          if (isProfile) {
            _profilePhoto = processedFile;
          } else {
            _coverPhoto = processedFile;
          }
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    final controller = context.read<ProviderProfileController>();
    final navigator = Navigator.of(context);

    // Mandatory profile picture check
    if ((controller.profileImage == null || controller.profileImage!.isEmpty) &&
        _profilePhoto == null) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: context.l10n.profilePicMandatory,
          isError: true,
        );
      }
      return;
    }

    // Check for changes
    final String currentName = controller.name;
    final String newName = _nameController.text;
    final bool nameChanged = newName != currentName;

    final String currentBio = controller.aboutMe;
    final String newBio = _aboutController.text;
    final bool bioChanged = newBio != currentBio;

    // Call update API
    final success = await controller.updateProviderProfile(
      name: nameChanged ? newName : null,
      bio: bioChanged ? newBio : null,
      profilePhoto: _profilePhoto,
      coverPhoto: _coverPhoto,
      yearsOfExperience: _selectedExperience != controller.yearsOfExperience ? (_selectedExperience ?? '') : null,
      projectsCompleted: _selectedProjects != controller.projectsCompleted ? (_selectedProjects ?? '') : null,
      education: _selectedEducation != controller.education ? (_selectedEducation ?? '') : null,
      mainCity: _cityController.text != controller.mainCity ? _cityController.text : null,
      department: _selectedDepartment != controller.department ? (_selectedDepartment ?? '') : null,
      radius: _selectedRadius != controller.radius ? (_selectedRadius ?? '') : null,
      availableForTravel: _availableForTravel != controller.availableForTravel ? _availableForTravel : null,
    );

    if (success) {
      // Exit the screen first
      navigator.pop();

      // Show success message using the context of the Screen that just appeared
      if (navigator.mounted) {
        CustomSnackBar.show(
          context: navigator.context,
          message: context.l10n.profileUpdatedSuccess,
          isError: false,
        );
      }
    } else {
      // Show error message on current screen if it failed
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: controller.errorMessage ?? context.l10n.updateFailed,
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderProfileController>(
      builder: (context, controller, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(controller),
                SizedBox(height: 100.h),
                _buildEditBody(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ProviderProfileController controller) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Header Image
        GestureDetector(
          onTap: () => _pickAndCropImage(isProfile: false),
          child: Hero(
            tag: 'banner_hero',
            child: _coverPhoto != null
                ? Image.file(
                    _coverPhoto!,
                    width: double.infinity,
                    height: 220.h,
                    fit: BoxFit.cover,
                  )
                : (controller.coverPhoto != null &&
                      controller.coverPhoto!.isNotEmpty)
                ? CustomNetworkImage(
                    width: double.infinity,
                    height: 220.h,
                    imageUrl: controller.coverPhoto!,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 220.h,
                    width: double.infinity,
                    color: Colors.grey[900],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                          size: 32.sp,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          context.l10n.noCoverPhoto,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        // Camera overlay for banner
        Positioned(
          top: MediaQuery.of(context).padding.top + 10.h,
          right: 20.w,
          child: GestureDetector(
            onTap: () => _pickAndCropImage(isProfile: false),
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.5)),
              ),
              child: Icon(Icons.camera_alt, color: Colors.white, size: 20.sp),
            ),
          ),
        ),

        // Floating Glassmorphism Profile Card
        Positioned(
          bottom: -5.h,
          left: 6.w,
          right: 6.w,
          child: _buildProfileCard(controller),
        ),

        // Overlapping Stats Row
        Positioned(
          bottom: -80.h,
          left: 0,
          right: 0,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: _buildStatsRow(),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(ProviderProfileController controller) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: Colors.black12.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.profileTitle,
                    style: TextStyle(
                      fontSize: AppTypography.h1,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Image.asset(
                          'assets/images/camera_icon.png',
                          width: 20.sp,
                          height: 20.sp,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      if (controller.inProgress)
                        SizedBox(
                          width: 36.sp,
                          height: 36.sp,
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(
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
                              color: const Color(0xFF4C6A5A).withOpacity(0.8),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Image.asset(
                              'assets/images/edit_done_icon.png',
                              width: 20.sp,
                              height: 20.sp,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _pickAndCropImage(isProfile: true),
                    child: Hero(
                      tag: 'profile_hero',
                      child: Stack(
                        children: [
                          _profilePhoto != null
                              ? Container(
                                  width: 75.r,
                                  height: 75.r,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey.shade200,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: Image.file(
                                      _profilePhoto!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              : AuthProfileImage(
                                  imageUrl: controller.profileImage,
                                  size: 75.r,
                                ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.all(4.w),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: Theme.of(context).colorScheme.onSurface,
                                size: 12.sp,
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
                        TextField(
                          controller: _nameController,
                          style: TextStyle(
                            fontSize: AppTypography.h1,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        TextField(
                          controller: _specialtyController,
                          style: TextStyle(
                            fontSize: AppTypography.bodyMedium,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        SizedBox(height: 6.h),
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

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(Icons.star_border, '4.9', context.l10n.ratingLabel),
        _buildStatItem(Icons.verified_outlined, '127', context.l10n.reviewsLabel),
        _buildStatItem(Icons.military_tech_outlined, '95%', context.l10n.responseRateLabel),
        _buildStatItem(Icons.camera_alt_outlined, '342', context.l10n.projectsLabel),
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
                fontSize: AppTypography.h1,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTypography.bodySmall,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              height: 1,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditBody() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.aboutMeTitle,
            style: TextStyle(
              fontSize: AppTypography.h2,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              ),
            ),
            child: TextField(
              controller: _aboutController,
              maxLines: 4,
              style: TextStyle(
                fontSize: AppTypography.bodyLarge,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12.w),
              ),
            ),
          ),
          SizedBox(height: 25.h),

          _buildEditableSection(
            context.l10n.specializationsTitle,
            _tempSpecializations,
            (value) {
              setState(() {
                _tempSpecializations.add(value);
              });
            },
            (value) {
              setState(() {
                _tempSpecializations.remove(value);
              });
            },
          ),
          SizedBox(height: 25.h),

          _buildEditableSection(
            context.l10n.languagesTitle,
            _tempLanguages,
            (value) {
              setState(() {
                _tempLanguages.add(value);
              });
            },
            (value) {
              setState(() {
                _tempLanguages.remove(value);
              });
            },
          ),
          SizedBox(height: 25.h),

          _buildProfessionalDetailsSection(),
          SizedBox(height: 25.h),

          _buildGallerySection(),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  Widget _buildEditableSection(
    String title,
    List<String> items,
    Function(String) onAdd,
    Function(String) onRemove,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: AppTypography.h2,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () => _showAddDialog(title, onAdd),
              child: Icon(
                Icons.add,
                size: 22.sp,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: items
              .map((item) => _buildEditChip(item, () => onRemove(item)))
              .toList(),
        ),
      ],
    );
  }

  void _showAddDialog(String title, Function(String) onAdd) {
    final textController = TextEditingController();

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
    final isLanguage = title == context.l10n.languagesTitle || title == 'Languages';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text('${context.l10n.add} $title'),
          content: isLanguage
              ? Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10.r),
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
                          ).colorScheme.onSurface.withOpacity(0.4),
                          fontSize: 14.sp,
                        ),
                      ),
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(10.r),
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
              : TextField(
                  controller: textController,
                  decoration: InputDecoration(hintText: context.l10n.enterSpecializationHint),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                context.l10n.cancelBtn,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                if (isLanguage) {
                  if (_selectedLanguage != null) {
                    onAdd(_selectedLanguage!);
                    Navigator.pop(context);
                  }
                } else {
                  if (textController.text.isNotEmpty) {
                    onAdd(textController.text);
                    Navigator.pop(context);
                  }
                }
              },
              child: Text(
                context.l10n.addBtn,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditChip(String label, VoidCallback onRemove) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.bodySmall,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(width: 6.w),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 14.sp,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalDetailsSection() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Professional Details',
          style: TextStyle(
            fontSize: AppTypography.h2,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: cs.onSurface.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Experience dropdown
              _buildFormDropdown(
                label: context.l10n.experience,
                value: _selectedExperience,
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
                    _selectedExperience = val;
                  });
                },
              ),
              SizedBox(height: 16.h),
              
              // Projects dropdown
              _buildFormDropdown(
                label: context.l10n.projectsLabel,
                value: _selectedProjects,
                items: const ['<10', '10-50', '50-100', '100+'],
                displayLabels: {
                  '<10': context.l10n.projLess10,
                  '10-50': context.l10n.proj10To50,
                  '50-100': context.l10n.proj50To100,
                  '100+': context.l10n.proj100Plus,
                },
                onChanged: (val) {
                  setState(() {
                    _selectedProjects = val;
                  });
                },
              ),
              SizedBox(height: 16.h),

              // Education dropdown
              _buildFormDropdown(
                label: context.l10n.education,
                value: _selectedEducation,
                items: const ['Self-taught', 'School', 'Professional Training'],
                displayLabels: {
                  'Self-taught': context.l10n.eduSelfTaught,
                  'School': context.l10n.eduSchool,
                  'Professional Training': context.l10n.eduProfessionalTraining,
                },
                onChanged: (val) {
                  setState(() {
                    _selectedEducation = val;
                  });
                },
              ),
              SizedBox(height: 16.h),

              // City textfield
              _buildFormTextField(
                label: context.l10n.serviceArea,
                controller: _cityController,
                hint: 'e.g. Dhaka',
              ),
              SizedBox(height: 16.h),

              // Department dropdown
              _buildFormDropdown(
                label: 'Department',
                value: _selectedDepartment,
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
                    _selectedDepartment = val;
                  });
                },
              ),
              SizedBox(height: 16.h),

              // Radius dropdown
              _buildFormDropdown(
                label: context.l10n.interventionRadius,
                value: _selectedRadius,
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
                    _selectedRadius = val;
                  });
                },
              ),
              SizedBox(height: 16.h),

              // Switch for Travel
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.availableForTravel,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface.withOpacity(0.8),
                    ),
                  ),
                  Switch(
                    value: _availableForTravel,
                    onChanged: (val) {
                      setState(() {
                        _availableForTravel = val;
                      });
                    },
                    activeColor: cs.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Map<String, String> displayLabels,
    required ValueChanged<String?> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: cs.onSurface.withOpacity(0.8),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: cs.onSurface.withOpacity(0.12)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(
                'Select Option',
                style: TextStyle(color: cs.onSurface.withOpacity(0.4), fontSize: 14.sp),
              ),
              dropdownColor: cs.surface,
              isExpanded: true,
              style: TextStyle(fontSize: 14.sp, color: cs.onSurface),
              borderRadius: BorderRadius.circular(10.r),
              items: items.map((e) {
                final labelText = displayLabels[e] ?? e;
                return DropdownMenuItem(value: e, child: Text(labelText));
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: cs.onSurface.withOpacity(0.8),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: cs.onSurface.withOpacity(0.12)),
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(fontSize: 14.sp, color: cs.onSurface),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.4), fontSize: 14.sp),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGallerySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.portfolioCount(_tempRecentWork.length),
              style: TextStyle(
                fontSize: AppTypography.h2,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () {
                // Mock adding a photo
                setState(() {
                  _tempRecentWork.add('assets/images/img1.png');
                });
              },
              child: Row(
                children: [
                  Icon(
                    Icons.add,
                    size: 14.sp,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    context.l10n.addPhotoBtn,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
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
            mainAxisSpacing: 12.h,
            crossAxisSpacing: 12.w,
            childAspectRatio: 1,
          ),
          itemCount: _tempRecentWork.length,
          itemBuilder: (context, index) {
            return Stack(
              children: [
                CustomNetworkImage(
                  imageUrl: _tempRecentWork[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                Positioned(
                  top: 6.h,
                  right: 6.w,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _tempRecentWork.removeAt(index);
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 10.sp,
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
}
