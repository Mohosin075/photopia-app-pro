import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:photopya/controller/provider/provider_onboarding_controller.dart';
import 'package:photopya/controller/client/user_profile_controller.dart';
import 'package:photopya/core/widgets/custom_snacbar.dart';
import 'package:photopya/core/routes/app_routes.dart';
import 'package:photopya/core/localization/app_localizations.dart';

class ProviderOnboardingScreen extends StatefulWidget {
  const ProviderOnboardingScreen({super.key});
  static const String name = '/provider-onboarding';

  @override
  State<ProviderOnboardingScreen> createState() => _ProviderOnboardingScreenState();
}

class _ProviderOnboardingScreenState extends State<ProviderOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 6;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<ProviderOnboardingController>();
      ctrl.reset();
      // Pre-fill user data
      final userCtrl = context.read<UserProfileController>();
      if (userCtrl.userProfile != null) {
        ctrl.initFromUserProfile(userCtrl.userProfile!);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    final ctrl = context.read<ProviderOnboardingController>();
    if (_currentPage == 0 && !ctrl.isStep1Valid) {
      CustomSnackBar.show(context: context, message: context.l10n.fillRequiredPersonalInfo, isError: true);
      return;
    }
    if (_currentPage == 1 && !ctrl.isStep2Valid) {
      CustomSnackBar.show(context: context, message: context.l10n.selectDomainAndCategory, isError: true);
      return;
    }
    if (_currentPage == 4 && !ctrl.isStep5Valid) {
      CustomSnackBar.show(context: context, message: context.l10n.profilePicRequired, isError: true);
      return;
    }
    if (_currentPage == _totalPages - 1) {
      if (!ctrl.isStep6Valid) {
        CustomSnackBar.show(context: context, message: context.l10n.acceptLegalTerms, isError: true);
        return;
      }
      _submit();
      return;
    }
    _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
  }

  void _goBack() {
    if (_currentPage == 0) return;
    _pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
  }

  Future<void> _submit() async {
    final ctrl = context.read<ProviderOnboardingController>();
    final success = await ctrl.submitOnboarding();
    if (!mounted) return;
    if (success) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.provider_bottom_navigation, (r) => false);
    } else {
      CustomSnackBar.show(context: context, message: ctrl.errorMessage ?? context.l10n.failedToSaveRetry, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopScope(
      canPop: _currentPage == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentPage > 0) {
          _goBack();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(cs),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: const [
                    _Step1PersonalInfo(),
                    _Step2Profession(),
                    _Step3Location(),
                    _Step4Experience(),
                    _Step5BioPortfolio(),
                    _Step6Legal(),
                  ],
                ),
              ),
              _buildFooter(cs),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    final titles = [
      context.l10n.onboardingPersonalInfo,
      context.l10n.onboardingProfession,
      context.l10n.onboardingWorkArea,
      context.l10n.onboardingExperience,
      context.l10n.onboardingPortfolio,
      context.l10n.onboardingPreferences
    ];
    final subtitles = [
      context.l10n.onboardingVerifyIdentity,
      context.l10n.onboardingWhatDoYouDo,
      context.l10n.onboardingWhereDoYouWork,
      context.l10n.onboardingShareBackground,
      context.l10n.onboardingShowcaseWork,
      context.l10n.onboardingConfirmFinish
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_currentPage == 0)
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Padding(
                    padding: EdgeInsets.only(right: 12.w),
                    child: Icon(Icons.arrow_back, size: 24.sp, color: cs.onSurface),
                  ),
                ),
              Text(context.l10n.stepXofY((_currentPage + 1).toString(), _totalPages.toString()),
                  style: TextStyle(fontSize: 12.sp, color: cs.onSurface.withOpacity(0.5))),
              const Spacer(),
              if (_currentPage > 0 && _currentPage < _totalPages - 1)
                GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(_totalPages - 1,
                        duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                  },
                  child: Text(context.l10n.skip, style: TextStyle(fontSize: 13.sp, color: cs.onSurface.withOpacity(0.5))),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / _totalPages,
              backgroundColor: cs.onSurface.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
              minHeight: 4.h,
            ),
          ),
          SizedBox(height: 20.h),
          Text(titles[_currentPage],
              style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: cs.onSurface)),
          SizedBox(height: 4.h),
          Text(subtitles[_currentPage],
              style: TextStyle(fontSize: 14.sp, color: cs.onSurface.withOpacity(0.5))),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildFooter(ColorScheme cs) {
    return Consumer<ProviderOnboardingController>(
      builder: (context, ctrl, _) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
          child: Row(
            children: [
              if (_currentPage > 0)
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: _goBack,
                    child: Container(
                      height: 52.h,
                      decoration: BoxDecoration(
                        border: Border.all(color: cs.onSurface.withOpacity(0.15)),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Icon(Icons.arrow_back_ios_new, size: 18.sp, color: cs.onSurface),
                    ),
                  ),
                ),
              if (_currentPage > 0) SizedBox(width: 12.w),
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTap: ctrl.inProgress ? null : _goNext,
                  child: Container(
                    height: 52.h,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Center(
                      child: ctrl.inProgress
                          ? SizedBox(width: 22.sp, height: 22.sp,
                              child: CircularProgressIndicator(color: cs.onPrimary, strokeWidth: 2))
                          : Text(
                              _currentPage == _totalPages - 1 ? context.l10n.finishAndStart : context.l10n.continueBtn,
                              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: cs.onPrimary),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Step Widgets ─────────────────────────────────────────────────────────────

class _Step1PersonalInfo extends StatelessWidget {
  const _Step1PersonalInfo();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Consumer<ProviderOnboardingController>(
      builder: (context, ctrl, _) {
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel(context.l10n.firstName, isRequired: true),
                        SizedBox(height: 8.h),
                        _TextField(hint: 'John', value: ctrl.firstName, icon: Icons.person_outline, onChanged: (v) => ctrl.firstName = v, cs: cs),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel(context.l10n.lastName, isRequired: true),
                        SizedBox(height: 8.h),
                        _TextField(hint: 'Doe', value: ctrl.lastName, icon: Icons.person_outline, onChanged: (v) => ctrl.lastName = v, cs: cs),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              _SectionLabel(context.l10n.emailAddress, isRequired: true),
              SizedBox(height: 8.h),
              _TextField(hint: context.l10n.emailLabel, value: ctrl.email, icon: Icons.email_outlined, onChanged: (v) => ctrl.email = v, cs: cs, keyboardType: TextInputType.emailAddress),
              SizedBox(height: 16.h),
              _SectionLabel(context.l10n.phoneNumber, isRequired: true),
              SizedBox(height: 8.h),
              _TextField(hint: '+33 6 12 34 56 78', value: ctrl.phone, icon: Icons.phone_outlined, onChanged: (v) => ctrl.phone = v, cs: cs, keyboardType: TextInputType.phone),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel(context.l10n.country, isRequired: true),
                        SizedBox(height: 8.h),
                        _DropdownField(
                          hint: Localizations.localeOf(context).languageCode == 'fr' ? 'Sélectionner' : 'Select',
                          value: ctrl.country,
                          items: const ['France', 'Belgium', 'Switzerland', 'UK'],
                          displayLabels: {
                            'France': 'France',
                            'Belgium': Localizations.localeOf(context).languageCode == 'fr' ? 'Belgique' : 'Belgium',
                            'Switzerland': Localizations.localeOf(context).languageCode == 'fr' ? 'Suisse' : 'Switzerland',
                            'UK': Localizations.localeOf(context).languageCode == 'fr' ? 'Royaume-Uni' : 'UK',
                          },
                          onChanged: (v) { ctrl.country = v ?? 'France'; ctrl.notifyListeners(); },
                          cs: cs,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel(context.l10n.city, isRequired: true),
                        SizedBox(height: 8.h),
                        _TextField(hint: 'Paris', value: ctrl.city, icon: Icons.location_city, onChanged: (v) => ctrl.city = v, cs: cs),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              _SectionLabel(context.l10n.address, isOptional: true),
              SizedBox(height: 8.h),
              _TextField(hint: '123 Main St', value: ctrl.address, icon: Icons.home_outlined, onChanged: (v) => ctrl.address = v, cs: cs),
              SizedBox(height: 16.h),
              _SectionLabel(
                Localizations.localeOf(context).languageCode == 'fr' ? 'Date de naissance' : 'Date of Birth',
                isRequired: true,
              ),
              SizedBox(height: 8.h),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: ctrl.dateOfBirth ?? DateTime(2000),
                    firstDate: DateTime(1940),
                    lastDate: DateTime.now().subtract(const Duration(days: 365 * 16)), // Minimum 16 years old
                    builder: (context, child) => Theme(data: Theme.of(context), child: child!),
                  );
                  if (picked != null) {
                    ctrl.dateOfBirth = picked;
                    ctrl.notifyListeners();
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: cs.onSurface.withOpacity(0.12)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cake_outlined, size: 20.sp, color: cs.onSurface.withOpacity(0.5)),
                      SizedBox(width: 12.w),
                      Text(
                        ctrl.dateOfBirth != null
                            ? '${ctrl.dateOfBirth!.day}/${ctrl.dateOfBirth!.month}/${ctrl.dateOfBirth!.year}'
                            : context.l10n.dobSelectHint,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: ctrl.dateOfBirth != null ? cs.onSurface : cs.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }
}

class _Step2Profession extends StatelessWidget {
  const _Step2Profession();

  static const _domains = ['Photography', 'Videography', 'Editing'];

  List<String> _getCategoriesForDomains(List<String> domains) {
    List<String> categories = [];
    if (domains.contains('Photography')) {
      categories.addAll(['Wedding Photography', 'Portrait', 'Event', 'Product', 'Fashion']);
    }
    if (domains.contains('Videography')) {
      categories.addAll(['Wedding Video', 'Cinematic', 'Event Coverage', 'Commercial']);
    }
    if (domains.contains('Editing')) {
      categories.addAll(['Photo Retouching', 'Color Grading', 'Video Editing', 'Motion Graphics']);
    }
    return categories.toSet().toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Consumer<ProviderOnboardingController>(
      builder: (context, ctrl, _) {
        final dynamicCategories = _getCategoriesForDomains(ctrl.primaryDomain);
        
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel(context.l10n.primaryDomain, isRequired: true),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 10.w,
                runSpacing: 10.h,
                children: _domains.map((domain) {
                  final selected = ctrl.primaryDomain.contains(domain);
                  final domainLabels = {
                    'Photography': context.l10n.photography,
                    'Videography': context.l10n.videography,
                    'Editing': context.l10n.editing,
                  };
                  return GestureDetector(
                    onTap: () {
                      if (selected) {
                        ctrl.primaryDomain.remove(domain);
                        // Clean up categories that belong to the removed domain
                        ctrl.specialties.removeWhere((s) => !_getCategoriesForDomains(ctrl.primaryDomain).contains(s));
                      } else {
                        ctrl.primaryDomain.add(domain);
                      }
                      ctrl.notifyListeners();
                    },
                    child: _SelectChip(label: domainLabels[domain] ?? domain, selected: selected),
                  );
                }).toList(),
              ),
              SizedBox(height: 24.h),
              
              if (ctrl.primaryDomain.isNotEmpty) ...[
                _SectionLabel(context.l10n.categoriesSpecialties, isRequired: true),
                SizedBox(height: 4.h),
                Text(context.l10n.selectAtLeastOneSpecialization, style: TextStyle(fontSize: 12.sp, color: cs.onSurface.withOpacity(0.5))),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 10.w,
                  runSpacing: 10.h,
                  children: dynamicCategories.map((s) {
                    final selected = ctrl.specialties.contains(s);
                    final categoryLabels = {
                      'Wedding Photography': context.l10n.catWeddingPhoto,
                      'Portrait': context.l10n.catPortrait,
                      'Event': context.l10n.catEvent,
                      'Product': context.l10n.catProduct,
                      'Fashion': context.l10n.catFashion,
                      'Wedding Video': context.l10n.catWeddingVideo,
                      'Cinematic': context.l10n.catCinematic,
                      'Event Coverage': context.l10n.catEventCoverage,
                      'Commercial': context.l10n.catCommercial,
                      'Photo Retouching': context.l10n.catPhotoRetouching,
                      'Color Grading': context.l10n.catColorGrading,
                      'Video Editing': context.l10n.catVideoEditing,
                      'Motion Graphics': context.l10n.catMotionGraphics,
                    };
                    return GestureDetector(
                      onTap: () {
                        if (selected) ctrl.specialties.remove(s);
                        else ctrl.specialties.add(s);
                        ctrl.notifyListeners();
                      },
                      child: _SelectChip(label: categoryLabels[s] ?? s, selected: selected),
                    );
                  }).toList(),
                ),
                SizedBox(height: 20.h),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Step3Location extends StatelessWidget {
  const _Step3Location();
  static const _radiusOptions = ['10km', '30km', '50km', '100km', 'Whole Country'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Consumer<ProviderOnboardingController>(
      builder: (context, ctrl, _) {
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel(context.l10n.mainCityWorkArea, isOptional: true),
              SizedBox(height: 8.h),
              _TextField(hint: 'e.g. Paris', value: ctrl.mainCity, icon: Icons.location_city_outlined, onChanged: (v) { ctrl.mainCity = v; }, cs: cs),
              SizedBox(height: 16.h),
              _SectionLabel(context.l10n.departmentLabel, isOptional: true),
              SizedBox(height: 8.h),
              _DropdownField(
                hint: 'Select Department', 
                value: ctrl.department.isEmpty ? null : ctrl.department, 
                items: const [
                  'Photography', 
                  'Videography & Cinematography', 
                  'Editing & Post-Production', 
                  'Scriptwriting & Storyboarding'
                ], 
                onChanged: (v) { ctrl.department = v ?? ''; ctrl.notifyListeners(); }, 
                cs: cs,
              ),
              SizedBox(height: 16.h),
              _SectionLabel(context.l10n.interventionRadius, isOptional: true),
              SizedBox(height: 8.h),
              _DropdownField(
                hint: Localizations.localeOf(context).languageCode == 'fr' ? 'Sélectionner le rayon' : 'Select radius',
                value: ctrl.radius,
                items: _radiusOptions,
                displayLabels: {
                  '10km': '10km',
                  '30km': '30km',
                  '50km': '50km',
                  '100km': '100km',
                  'Whole Country': context.l10n.wholeCountry,
                },
                onChanged: (v) { if (v != null) { ctrl.radius = v; ctrl.notifyListeners(); } },
                cs: cs,
              ),
              SizedBox(height: 20.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: cs.onSurface.withOpacity(0.12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.l10n.availableForTravel, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: cs.onSurface)),
                        Text(context.l10n.canTravelOutside, style: TextStyle(fontSize: 12.sp, color: cs.onSurface.withOpacity(0.5))),
                      ],
                    ),
                    Switch(value: ctrl.availableForTravel, onChanged: (v) { ctrl.availableForTravel = v; ctrl.notifyListeners(); }, activeColor: cs.primary),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }
}

class _Step4Experience extends StatelessWidget {
  const _Step4Experience();

  static const _yearsOptions = ['<1 year', '1-3 years', '3-5 years', '5-10 years', '10+ years'];
  static const _projectsOptions = ['<10', '10-50', '50-100', '100+'];
  static const _educationOptions = ['Self-taught', 'School', 'Professional Training'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Consumer<ProviderOnboardingController>(
      builder: (context, ctrl, _) {
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel(context.l10n.yearsOfExperience, isOptional: true),
              SizedBox(height: 8.h),
              _DropdownField(
                hint: Localizations.localeOf(context).languageCode == 'fr' ? 'Sélectionner l\'expérience' : 'Select experience',
                value: ctrl.yearsOfExperience,
                items: _yearsOptions,
                displayLabels: {
                  '<1 year': context.l10n.expLess1Year,
                  '1-3 years': context.l10n.exp1To3Years,
                  '3-5 years': context.l10n.exp3To5Years,
                  '5-10 years': context.l10n.exp5To10Years,
                  '10+ years': context.l10n.exp10PlusYears,
                },
                onChanged: (v) { ctrl.yearsOfExperience = v; ctrl.notifyListeners(); },
                cs: cs,
              ),
              SizedBox(height: 16.h),
              _SectionLabel(context.l10n.projectsCompleted, isOptional: true),
              SizedBox(height: 8.h),
              _DropdownField(
                hint: Localizations.localeOf(context).languageCode == 'fr' ? 'Sélectionner la plage' : 'Select range',
                value: ctrl.projectsCompleted,
                items: _projectsOptions,
                displayLabels: {
                  '<10': context.l10n.projLess10,
                  '10-50': context.l10n.proj10To50,
                  '50-100': context.l10n.proj50To100,
                  '100+': context.l10n.proj100Plus,
                },
                onChanged: (v) { ctrl.projectsCompleted = v; ctrl.notifyListeners(); },
                cs: cs,
              ),
              SizedBox(height: 16.h),
              _SectionLabel(context.l10n.education, isOptional: true),
              SizedBox(height: 8.h),
              _DropdownField(
                hint: Localizations.localeOf(context).languageCode == 'fr' ? 'Sélectionner l\'éducation' : 'Select education',
                value: ctrl.education,
                items: _educationOptions,
                displayLabels: {
                  'Self-taught': context.l10n.eduSelfTaught,
                  'School': context.l10n.eduSchool,
                  'Professional Training': context.l10n.eduProfessionalTraining,
                },
                onChanged: (v) { ctrl.education = v; ctrl.notifyListeners(); },
                cs: cs,
              ),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }
}

class _Step5BioPortfolio extends StatelessWidget {
  const _Step5BioPortfolio();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Consumer<ProviderOnboardingController>(
      builder: (context, ctrl, _) {
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel(
                Localizations.localeOf(context).languageCode == 'fr' ? 'Photo de profil' : 'Profile Picture',
                isRequired: true,
              ),
              SizedBox(height: 12.h),
              Center(
                child: GestureDetector(
                  onTap: ctrl.pickProfileImage,
                  child: Container(
                    width: 100.w,
                    height: 100.w,
                    decoration: BoxDecoration(
                      color: cs.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.onSurface.withOpacity(0.1)),
                      image: ctrl.profileImage != null
                          ? DecorationImage(image: FileImage(ctrl.profileImage!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: ctrl.profileImage == null
                        ? Icon(Icons.add_a_photo_outlined, size: 32.sp, color: cs.onSurface.withOpacity(0.4))
                        : Stack(
                            children: [
                              Positioned(
                                right: 0,
                                top: 0,
                                child: GestureDetector(
                                  onTap: ctrl.removeProfileImage,
                                  child: Container(
                                    padding: EdgeInsets.all(4.w),
                                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    child: Icon(Icons.close, size: 14.sp, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              
              _SectionLabel(context.l10n.miniBio, isOptional: true),
              SizedBox(height: 4.h),
              Text(context.l10n.max500Chars, style: TextStyle(fontSize: 11.sp, color: cs.onSurface.withOpacity(0.4))),
              SizedBox(height: 8.h),
              Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: cs.onSurface.withOpacity(0.12)),
                ),
                child: TextField(
                  maxLines: 5,
                  maxLength: 500,
                  onChanged: (v) => ctrl.miniBio = v,
                  style: TextStyle(fontSize: 14.sp, color: cs.onSurface),
                  decoration: InputDecoration(
                    hintText: context.l10n.bioPlaceholder,
                    hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.4), fontSize: 14.sp),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(14.w),
                    counterStyle: TextStyle(color: cs.onSurface.withOpacity(0.4), fontSize: 11.sp),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SectionLabel(context.l10n.portfolioImages, isOptional: true),
                  Text('${ctrl.portfolioImages.length}/20', style: TextStyle(fontSize: 12.sp, color: cs.onSurface.withOpacity(0.5))),
                ],
              ),
              SizedBox(height: 8.h),
              Text(context.l10n.uploadImagesShowcase, style: TextStyle(fontSize: 12.sp, color: cs.onSurface.withOpacity(0.5))),
              SizedBox(height: 12.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  ...List.generate(ctrl.portfolioImages.length, (index) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Image.file(
                            ctrl.portfolioImages[index],
                            width: 80.w,
                            height: 80.w,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 4.w,
                          top: 4.w,
                          child: GestureDetector(
                            onTap: () => ctrl.removePortfolioImage(index),
                            child: Container(
                              padding: EdgeInsets.all(2.w),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: Icon(Icons.close, size: 12.sp, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  if (ctrl.portfolioImages.length < 20)
                    GestureDetector(
                      onTap: ctrl.pickPortfolioImages,
                      child: Container(
                        width: 80.w,
                        height: 80.w,
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: cs.onSurface.withOpacity(0.2), style: BorderStyle.solid),
                        ),
                        child: Icon(Icons.add_photo_alternate_outlined, size: 28.sp, color: cs.primary),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 40.h),
            ],
          ),
        );
      },
    );
  }
}

class _Step6Legal extends StatelessWidget {
  const _Step6Legal();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Consumer<ProviderOnboardingController>(
      builder: (context, ctrl, _) {
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel(
                Localizations.localeOf(context).languageCode == 'fr' ? 'Préférences de notification' : 'Notification Preferences',
                isRequired: true,
              ),
              SizedBox(height: 12.h),
              _SwitchTile(label: context.l10n.emailNewRequests, icon: Icons.email_outlined, value: ctrl.emailNewRequests, onChanged: (v) { ctrl.emailNewRequests = v; ctrl.notifyListeners(); }, cs: cs),
              _SwitchTile(label: context.l10n.smsUrgentRequests, icon: Icons.sms_outlined, value: ctrl.smsUrgentRequests, onChanged: (v) { ctrl.smsUrgentRequests = v; ctrl.notifyListeners(); }, cs: cs),
              _SwitchTile(label: context.l10n.newsletterPros, icon: Icons.newspaper_outlined, value: ctrl.newsletterPros, onChanged: (v) { ctrl.newsletterPros = v; ctrl.notifyListeners(); }, cs: cs),
              _SwitchTile(label: context.l10n.reviewReminders, icon: Icons.star_outline, value: ctrl.customerReviewReminder, onChanged: (v) { ctrl.customerReviewReminder = v; ctrl.notifyListeners(); }, cs: cs),
              
              SizedBox(height: 24.h),
              _SectionLabel(context.l10n.legalAgreement, isRequired: true),
              SizedBox(height: 4.h),
              Text(context.l10n.acceptAllToContinue, style: TextStyle(fontSize: 11.sp, color: cs.onSurface.withOpacity(0.4))),
              SizedBox(height: 12.h),
              _CheckTile(label: context.l10n.acceptTermsOfUse, value: ctrl.acceptedTerms, onChanged: (v) { ctrl.acceptedTerms = v!; ctrl.notifyListeners(); }, cs: cs),
              _CheckTile(label: context.l10n.acceptPrivacyPolicy, value: ctrl.privacyPolicy, onChanged: (v) { ctrl.privacyPolicy = v!; ctrl.notifyListeners(); }, cs: cs),
              _CheckTile(label: context.l10n.acceptGdpr, value: ctrl.gdprAuthorization, onChanged: (v) { ctrl.gdprAuthorization = v!; ctrl.notifyListeners(); }, cs: cs),
              SizedBox(height: 40.h),
            ],
          ),
        );
      },
    );
  }
}

// ── Shared Sub-Widgets ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool isRequired;
  final bool isOptional;
  const _SectionLabel(this.text, {this.isRequired = false, this.isOptional = false});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return RichText(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
          fontFamily: 'HelveticaNeue', // Ensuring consistency
        ),
        children: [
          if (isRequired)
            TextSpan(
              text: ' *',
              style: TextStyle(
                color: const Color(0xFFFF4D4D),
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (isOptional)
            TextSpan(
              text: ' (${context.l10n.optionalLabel})',
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.4),
                fontSize: 10.sp,
                fontWeight: FontWeight.normal,
              ),
            ),
        ],
      ),
    );
  }
}

class _SelectChip extends StatelessWidget {
  final String label;
  final bool selected;
  const _SelectChip({required this.label, required this.selected});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: selected ? cs.primary : cs.surface,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: selected ? cs.primary : cs.onSurface.withOpacity(0.12)),
      ),
      child: Text(label, style: TextStyle(fontSize: 13.sp, fontWeight: selected ? FontWeight.w600 : FontWeight.normal, color: selected ? cs.onPrimary : cs.onSurface)),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final ColorScheme cs;
  final Map<String, String>? displayLabels;
  const _DropdownField({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.cs,
    this.displayLabels,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: cs.onSurface.withOpacity(0.12)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(color: cs.onSurface.withOpacity(0.4), fontSize: 14.sp)),
          icon: Icon(Icons.keyboard_arrow_down, color: cs.onSurface.withOpacity(0.5)),
          dropdownColor: cs.surface,
          isExpanded: true,
          style: TextStyle(fontSize: 14.sp, color: cs.onSurface),
          borderRadius: BorderRadius.circular(12.r),
          items: items.map((e) {
            final label = displayLabels != null ? (displayLabels![e] ?? e) : e;
            return DropdownMenuItem(value: e, child: Text(label));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final String hint;
  final String value;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final ColorScheme cs;
  final TextInputType keyboardType;
  const _TextField({required this.hint, required this.value, required this.icon, required this.onChanged, required this.cs, this.keyboardType = TextInputType.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: cs.onSurface.withOpacity(0.12)),
      ),
      child: TextField(
        keyboardType: keyboardType,
        onChanged: onChanged,
        controller: TextEditingController(text: value)..selection = TextSelection.collapsed(offset: value.length),
        style: TextStyle(fontSize: 14.sp, color: cs.onSurface),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.4), fontSize: 14.sp),
          prefixIcon: Icon(icon, size: 20.sp, color: cs.onSurface.withOpacity(0.5)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14.h),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final ColorScheme cs;
  const _SwitchTile({required this.label, required this.icon, required this.value, required this.onChanged, required this.cs});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: cs.onSurface.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20.sp, color: cs.onSurface.withOpacity(0.6)),
            SizedBox(width: 12.w),
            Expanded(child: Text(label, style: TextStyle(fontSize: 13.sp, color: cs.onSurface))),
            Switch(value: value, onChanged: onChanged, activeColor: cs.primary),
          ],
        ),
      ),
    );
  }
}

class _CheckTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;
  final ColorScheme cs;
  const _CheckTile({required this.label, required this.value, required this.onChanged, required this.cs});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: cs.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
          ),
          Expanded(child: Text(label, style: TextStyle(fontSize: 13.sp, color: cs.onSurface))),
        ],
      ),
    );
  }
}
