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
                ? 'Crop Profile Picture'
                : 'Crop Cover Photo',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: isProfile
                ? CropAspectRatioPreset.square
                : CropAspectRatioPreset.ratio16x9,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: isProfile ? 'Crop Profile Picture' : 'Crop Cover Photo',
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
          message: 'Profile picture is mandatory for creators',
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
    );

    if (success) {
      // Exit the screen first
      navigator.pop();

      // Show success message using the context of the Screen that just appeared
      if (navigator.mounted) {
        CustomSnackBar.show(
          context: navigator.context,
          message: 'Profile updated successfully',
          isError: false,
        );
      }
    } else {
      // Show error message on current screen if it failed
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: controller.errorMessage ?? 'Failed to update profile',
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
                          'No cover photo',
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
                    'Profile',
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
        _buildStatItem(Icons.star_border, '4.9', 'Rating'),
        _buildStatItem(Icons.verified_outlined, '127', 'Reviews'),
        _buildStatItem(Icons.military_tech_outlined, '95%', 'Response Rate'),
        _buildStatItem(Icons.camera_alt_outlined, '342', 'Projects'),
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
            'About Me',
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
            'Specializations',
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
            'Languages',
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
    final isLanguage = title == 'Languages';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text('Add $title'),
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
                        'Select a language',
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
                  decoration: const InputDecoration(hintText: 'Enter name'),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
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
                'Add',
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

  Widget _buildGallerySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent (${_tempRecentWork.length})',
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
                    'Add Photo',
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
