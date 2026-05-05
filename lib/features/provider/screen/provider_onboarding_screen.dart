import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:photopia/controller/provider/provider_onboarding_controller.dart';
import 'package:photopia/core/widgets/custom_snacbar.dart';
import 'package:photopia/core/routes/app_routes.dart';

class ProviderOnboardingScreen extends StatefulWidget {
  const ProviderOnboardingScreen({super.key});
  static const String name = '/provider-onboarding';

  @override
  State<ProviderOnboardingScreen> createState() => _ProviderOnboardingScreenState();
}

class _ProviderOnboardingScreenState extends State<ProviderOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 5;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    final ctrl = context.read<ProviderOnboardingController>();
    if (_currentPage == 0 && !ctrl.isStep1Valid) {
      CustomSnackBar.show(context: context, message: 'Please fill in your date of birth and select at least one domain.', isError: true);
      return;
    }
    if (_currentPage == _totalPages - 1) {
      if (!ctrl.isStep5Valid) {
        CustomSnackBar.show(context: context, message: 'Please accept all terms to continue.', isError: true);
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
      CustomSnackBar.show(context: context, message: ctrl.errorMessage ?? 'Failed to save. Please retry.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.provider_bottom_navigation,
            (route) => false,
          );
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
                    _Step1DomainBirthday(),
                    _Step2Experience(),
                    _Step3Location(),
                    _Step4BioPorfolio(),
                    _Step5Legal(),
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
    final titles = ['Domain & Info', 'Experience', 'Location', 'Bio & Portfolio', 'Preferences'];
    final subtitles = [
      'Tell us about your craft',
      'Share your background',
      'Where do you work?',
      'Introduce yourself',
      'Confirm & finish',
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Step ${_currentPage + 1} of $_totalPages',
                  style: TextStyle(fontSize: 12.sp, color: cs.onSurface.withOpacity(0.5))),
              if (_currentPage > 0 && _currentPage < _totalPages - 1)
                GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(_totalPages - 1,
                        duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                  },
                  child: Text('Skip', style: TextStyle(fontSize: 13.sp, color: cs.onSurface.withOpacity(0.5))),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          // Progress bar
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
                              _currentPage == _totalPages - 1 ? 'Finish & Start' : 'Continue',
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

class _Step1DomainBirthday extends StatelessWidget {
  const _Step1DomainBirthday();

  static const _domains = ['Photography', 'Videography', 'Editing'];

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
              _SectionLabel('Date of Birth', isRequired: true),
              SizedBox(height: 8.h),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: ctrl.dateOfBirth ?? DateTime(1995),
                    firstDate: DateTime(1940),
                    lastDate: DateTime.now().subtract(const Duration(days: 365 * 16)),
                    builder: (context, child) => Theme(
                      data: Theme.of(context),
                      child: child!,
                    ),
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
                            : 'Select your date of birth',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: ctrl.dateOfBirth != null ? cs.onSurface : cs.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              _SectionLabel('Primary Domain', isRequired: true),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 10.w,
                runSpacing: 10.h,
                children: _domains.map((domain) {
                  final selected = ctrl.primaryDomain.contains(domain);
                  return GestureDetector(
                    onTap: () {
                      if (selected) {
                        ctrl.primaryDomain.remove(domain);
                      } else {
                        ctrl.primaryDomain.add(domain);
                      }
                      ctrl.notifyListeners();
                    },
                    child: _SelectChip(label: domain, selected: selected),
                  );
                }).toList(),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }
}

class _Step2Experience extends StatelessWidget {
  const _Step2Experience();

  static const _specialtiesOptions = ['Wedding', 'Portrait', 'Corporate', 'Fashion', 'Real Estate', 'Event', 'Product', 'Travel', 'Street', 'Documentary'];
  static const _yearsOptions = ['<1 year', '1-3 years', '3-5 years', '5-10 years', '>10 years'];
  static const _projectsOptions = ['<10', '10-50', '50-100', '>100'];
  static const _educationOptions = ['Self-taught', 'School', 'Professional training'];

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
              _SectionLabel('Specialties', isOptional: true),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 10.w,
                runSpacing: 10.h,
                children: _specialtiesOptions.map((s) {
                  final selected = ctrl.specialties.contains(s);
                  return GestureDetector(
                    onTap: () {
                      if (selected) ctrl.specialties.remove(s);
                      else ctrl.specialties.add(s);
                      ctrl.notifyListeners();
                    },
                    child: _SelectChip(label: s, selected: selected),
                  );
                }).toList(),
              ),
              SizedBox(height: 24.h),
              _SectionLabel('Years of Experience', isOptional: true),
              SizedBox(height: 8.h),
              _DropdownField(
                hint: 'Select experience',
                value: ctrl.yearsOfExperience,
                items: _yearsOptions,
                onChanged: (v) { ctrl.yearsOfExperience = v; ctrl.notifyListeners(); },
                cs: cs,
              ),
              SizedBox(height: 16.h),
              _SectionLabel('Projects Completed', isOptional: true),
              SizedBox(height: 8.h),
              _DropdownField(
                hint: 'Select range',
                value: ctrl.projectsCompleted,
                items: _projectsOptions,
                onChanged: (v) { ctrl.projectsCompleted = v; ctrl.notifyListeners(); },
                cs: cs,
              ),
              SizedBox(height: 16.h),
              _SectionLabel('Education', isOptional: true),
              SizedBox(height: 8.h),
              _DropdownField(
                hint: 'Select education',
                value: ctrl.education,
                items: _educationOptions,
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

class _Step3Location extends StatelessWidget {
  const _Step3Location();
  static const _radiusOptions = ['10km', '30km', '50km', '100km', 'whole France'];

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
              _SectionLabel('Main City', isOptional: true),
              SizedBox(height: 8.h),
              _TextField(
                hint: 'e.g. Paris',
                value: ctrl.mainCity,
                icon: Icons.location_city_outlined,
                onChanged: (v) { ctrl.mainCity = v; },
                cs: cs,
              ),
              SizedBox(height: 16.h),
              _SectionLabel('Department', isOptional: true),
              SizedBox(height: 8.h),
              _TextField(
                hint: 'e.g. 75',
                value: ctrl.department,
                icon: Icons.map_outlined,
                onChanged: (v) { ctrl.department = v; },
                cs: cs,
              ),
              SizedBox(height: 16.h),
              _SectionLabel('Intervention Radius', isOptional: true),
              SizedBox(height: 8.h),
              _DropdownField(
                hint: 'Select radius',
                value: ctrl.radius,
                items: _radiusOptions,
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
                        Text('Available for travel', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: cs.onSurface)),
                        Text('Can travel outside your area', style: TextStyle(fontSize: 12.sp, color: cs.onSurface.withOpacity(0.5))),
                      ],
                    ),
                    Switch(
                      value: ctrl.availableForTravel,
                      onChanged: (v) { ctrl.availableForTravel = v; ctrl.notifyListeners(); },
                      activeColor: cs.primary,
                    ),
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

class _Step4BioPorfolio extends StatelessWidget {
  const _Step4BioPorfolio();

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
              _SectionLabel('Mini Bio', isOptional: true),
              SizedBox(height: 4.h),
              Text('Max 500 characters', style: TextStyle(fontSize: 11.sp, color: cs.onSurface.withOpacity(0.4))),
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
                    hintText: 'Professional photographer with 5 years of experience...',
                    hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.4), fontSize: 14.sp),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(14.w),
                    counterStyle: TextStyle(color: cs.onSurface.withOpacity(0.4), fontSize: 11.sp),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              _SectionLabel('External Portfolio Link', isOptional: true),
              SizedBox(height: 8.h),
              _TextField(
                hint: 'https://yourportfolio.com',
                value: ctrl.externalPortfolioLink,
                icon: Icons.link_outlined,
                onChanged: (v) { ctrl.externalPortfolioLink = v; },
                cs: cs,
                keyboardType: TextInputType.url,
              ),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }
}

class _Step5Legal extends StatelessWidget {
  const _Step5Legal();

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
              _SectionLabel('Notification Preferences', isOptional: true),
              SizedBox(height: 12.h),
              _SwitchTile(
                label: 'Email for new requests', icon: Icons.email_outlined,
                value: ctrl.emailNewRequests,
                onChanged: (v) { ctrl.emailNewRequests = v; ctrl.notifyListeners(); }, cs: cs,
              ),
              _SwitchTile(
                label: 'SMS for urgent requests', icon: Icons.sms_outlined,
                value: ctrl.smsUrgentRequests,
                onChanged: (v) { ctrl.smsUrgentRequests = v; ctrl.notifyListeners(); }, cs: cs,
              ),
              _SwitchTile(
                label: 'Newsletter & Pro tips', icon: Icons.newspaper_outlined,
                value: ctrl.newsletterPros,
                onChanged: (v) { ctrl.newsletterPros = v; ctrl.notifyListeners(); }, cs: cs,
              ),
              _SwitchTile(
                label: 'Review reminders', icon: Icons.star_outline,
                value: ctrl.customerReviewReminder,
                onChanged: (v) { ctrl.customerReviewReminder = v; ctrl.notifyListeners(); }, cs: cs,
              ),
              SizedBox(height: 24.h),
              _SectionLabel('Legal Agreement', isRequired: true),
              SizedBox(height: 4.h),
              Text('All three must be accepted to continue.', style: TextStyle(fontSize: 11.sp, color: cs.onSurface.withOpacity(0.4))),
              SizedBox(height: 12.h),
              _CheckTile(
                label: 'I accept the Terms & Conditions',
                value: ctrl.acceptedTerms,
                onChanged: (v) { ctrl.acceptedTerms = v!; ctrl.notifyListeners(); }, cs: cs,
              ),
              _CheckTile(
                label: 'I accept the Privacy Policy',
                value: ctrl.privacyPolicy,
                onChanged: (v) { ctrl.privacyPolicy = v!; ctrl.notifyListeners(); }, cs: cs,
              ),
              _CheckTile(
                label: 'I authorize GDPR data processing',
                value: ctrl.gdprAuthorization,
                onChanged: (v) { ctrl.gdprAuthorization = v!; ctrl.notifyListeners(); }, cs: cs,
              ),
              SizedBox(height: 20.h),
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
    return Row(
      children: [
        Text(text,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            )),
        SizedBox(width: 8.w),
        if (isRequired)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFF4D4D).withOpacity(0.12),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text('Required',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFF4D4D),
                )),
          )
        else if (isOptional)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: cs.onSurface.withOpacity(0.07),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text('Optional',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface.withOpacity(0.45),
                )),
          ),
      ],
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
      child: Text(label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? cs.onPrimary : cs.onSurface,
          )),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final ColorScheme cs;
  const _DropdownField({required this.hint, required this.value, required this.items, required this.onChanged, required this.cs});
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
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
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
      padding: EdgeInsets.only(bottom: 10.h),
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: value ? cs.primary.withOpacity(0.08) : cs.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: value ? cs.primary.withOpacity(0.4) : cs.onSurface.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Icon(value ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 20.sp, color: value ? cs.primary : cs.onSurface.withOpacity(0.4)),
              SizedBox(width: 12.w),
              Expanded(child: Text(label, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500, color: cs.onSurface))),
            ],
          ),
        ),
      ),
    );
  }
}
