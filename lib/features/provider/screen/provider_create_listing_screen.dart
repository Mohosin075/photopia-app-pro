import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photopya/core/utils/image_utils.dart';
import 'package:photopya/core/utils/theme_formatter.dart';
import 'package:photopya/core/constants/app_typography.dart';
import 'package:photopya/core/widgets/custom_snacbar.dart';
import 'package:photopya/core/network/urls.dart';
import 'package:photopya/core/constants/location_data.dart';
import 'package:country_picker/country_picker.dart';
import 'package:photopya/controller/category_controller.dart';
import 'package:photopya/controller/location_controller.dart';
import 'package:photopya/controller/provider/service_controller.dart';
import 'package:photopya/data/models/category_model.dart';
import 'package:photopya/data/models/provider_service_model.dart';
import 'package:photopya/data/models/service_duration.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:photopya/core/widgets/app_refresher.dart';
import 'package:photopya/core/widgets/video_player_screen.dart';
import 'package:photopya/core/localization/app_localizations.dart';

class ProviderCreateListingScreen extends StatefulWidget {
  final Data? existingListing;
  const ProviderCreateListingScreen({super.key, this.existingListing});

  @override
  State<ProviderCreateListingScreen> createState() =>
      _ProviderCreateListingScreenState();
}

class _ProviderCreateListingScreenState
    extends State<ProviderCreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _equipmentController = TextEditingController();
  final TextEditingController _otherServiceController = TextEditingController();

  // Pricing controllers
  final TextEditingController _weekdayHourlyRateController =
      TextEditingController();
  final TextEditingController _weekendHourlyRateController =
      TextEditingController();
  final TextEditingController _dailyRateController = TextEditingController();
  final TextEditingController _dailyHoursController = TextEditingController();
  final TextEditingController _minBudgetController = TextEditingController();

  // Multi-step management
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Step 1: Service variables (internal English keys)
  String? _selectedServiceTypeKey; // 'Photography', 'Videography', 'Editing'

  // Step 2: Details variables
  final TextEditingController _durationUnitController = TextEditingController(text: 'Hours');
  final List<AddonControllers> _addonControllers = [];
  bool _isAutoAcceptEnabled = false;
  bool _verifiedClientsOnly = false;
  int _selectedAutoAcceptRadius = 30;

  // Step 3: Availability variables
  final List<AvailabilitySlotControllers> _availabilityControllers = [];

  // Dynamic Package controllers
  final List<PackageControllers> _packageControllers = [];

  CategoryModel? _selectedCategory;
  CategoryModel? _selectedSubCategory;
  bool _isLoadingCategories = true;

  final List<String> _selectedServiceTypes = [];
  final List<String> _customTags = [];
  final TextEditingController _tagInputController = TextEditingController();
  String _selectedPricingModel = 'By Hour';
  String _selectedLocationType = 'On-site'; // Mandatory location type
  double _serviceRadius = 25.0;
  bool _acceptOutsideRadius = false;
  final List<String> _equipment = [];
  final List<String> _otherServices = [];
  final List<File> _selectedImages = [];
  final List<String> _existingNetworkImages = []; // Track original images URL
  final ImagePicker _picker = ImagePicker();
  int _previewImageIndex = 0;

  final Map<String, String> _localFieldErrors = {};

  final List<String> _locationTypes = ['On-site', 'Remote', 'Studio'];
  double? _depositPercentage = 0.0;

  String? _selectedCountry;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _populateExistingData();
  }

  void _populateExistingData() {
    if (widget.existingListing != null) {
      final listing = widget.existingListing!;
      _titleController.text = listing.title ?? '';
      _descriptionController.text = listing.description ?? '';
      _locationController.text = listing.location?.city ?? '';
      _addressController.text = listing.location?.address ?? '';
      _countryController.text = listing.location?.country ?? '';
      _selectedCountry = listing.location?.country;
      _selectedCity = listing.location?.city;
      if (listing.duration != null) {
        int val = listing.duration!.value ?? 0;
        final String rawUnit = listing.duration!.unit?.toLowerCase() ?? 'hour';
        
        if (rawUnit == 'minute' || rawUnit == 'minutes') {
          _durationController.text = val.toString();
          _durationUnitController.text = 'Minutes';
        } else if (rawUnit == 'day' || rawUnit == 'days') {
          _durationController.text = val.toString();
          _durationUnitController.text = 'Days';
        } else if (rawUnit == 'week' || rawUnit == 'weeks') {
          _durationController.text = val.toString();
          _durationUnitController.text = 'Weeks';
        } else if (rawUnit == 'hour' || rawUnit == 'hours') {
          // Check if we can convert back from hours to weeks or days
          if (val > 0 && val % 168 == 0) {
            _durationController.text = (val ~/ 168).toString();
            _durationUnitController.text = 'Weeks';
          } else if (val > 0 && val % 24 == 0) {
            _durationController.text = (val ~/ 24).toString();
            _durationUnitController.text = 'Days';
          } else {
            _durationController.text = val.toString();
            _durationUnitController.text = 'Hours';
          }
        } else {
          _durationController.text = val.toString();
          _durationUnitController.text = 'Hours';
        }
      } else {
        _durationController.text = '';
      }

      if (listing.tags != null && listing.tags!.isNotEmpty) {
        _customTags.addAll(listing.tags!);
      }

      if (listing.equipment != null) {
        _equipment.addAll(listing.equipment!);
      }

      if (listing.pricingType != null) {
        if (listing.pricingType == "HOURLY") {
          _selectedPricingModel = 'By Hour';
          _weekdayHourlyRateController.text =
              listing.pricingModel?.weekdayHourlyRate?.toString() ??
              listing.price?.toString() ??
              '';
          _weekendHourlyRateController.text =
              listing.pricingModel?.weekendHourlyRate?.toString() ??
              listing.price?.toString() ??
              '';
        } else if (listing.pricingType == "DAILY") {
          _selectedPricingModel = 'By Day';
          _dailyRateController.text = listing.price?.toString() ?? '';
          _dailyHoursController.text =
              listing.pricingModel?.dailyHours?.toString() ?? '8';
        } else if (listing.pricingType == "PACKAGE") {
          _selectedPricingModel = 'By Service';
          if (listing.pricingModel?.packages != null &&
              listing.pricingModel!.packages!.isNotEmpty) {
            _packageControllers.clear();
            for (var pkg in listing.pricingModel!.packages!) {
              _packageControllers.add(
                PackageControllers(
                  name: pkg.name ?? '',
                  price: pkg.price?.toString() ?? '',
                  duration: pkg.duration?.toString() ?? '',
                  description: pkg.description ?? '',
                  includes: pkg.includes?.join(', ') ?? '',
                ),
              );
            }
          } else {
            // Fallback for old listings
            _packageControllers.add(
              PackageControllers(
                name: 'Basic',
                price: listing.price?.toString() ?? '',
              ),
            );
          }
        }
      }

      if (listing.gallery != null) {
        for (var img in listing.gallery!) {
          if (img is String) _existingNetworkImages.add(img);
        }
      }

      if (listing.location?.type != null) {
        String rawType = listing.location!.type!.toLowerCase();
        if (rawType.contains('onsite') || rawType.contains('physical')) {
          _selectedLocationType = 'On-site';
        } else if (rawType.contains('remote') || rawType.contains('virtual')) {
          _selectedLocationType = 'Remote';
        } else if (rawType.contains('studio')) {
          _selectedLocationType = 'Studio';
        } else {
          _selectedLocationType = 'On-site'; // Fallback
        }
      }
      _serviceRadius = listing.location?.serviceRadiusKm?.toDouble() ?? 25.0;

      if (listing.autoAcceptBookings != null) {
        _isAutoAcceptEnabled = listing.autoAcceptBookings!.enabled;
        _minBudgetController.text = listing.autoAcceptBookings!.minimumBudget != null
            ? listing.autoAcceptBookings!.minimumBudget!.toInt().toString()
            : '';
        _selectedAutoAcceptRadius = listing.autoAcceptBookings!.withinRadiusKm?.toInt() ?? 30;
        _verifiedClientsOnly = listing.autoAcceptBookings!.verifiedClientsOnly ?? false;
      } else if (listing.autoAccept != null) {
        _isAutoAcceptEnabled = listing.autoAccept!.isEnabled ?? false;
        _minBudgetController.text = listing.autoAccept!.minBudget?.toString() ?? '';
        _selectedAutoAcceptRadius = listing.autoAccept!.withinRadius ?? 30;
        _verifiedClientsOnly = listing.autoAccept!.verifiedClientsOnly ?? false;
      }
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final categoryController = Provider.of<CategoryController>(
        context,
        listen: false,
      );
      // Fetch ALL categories (no theme filter) so all themes have their categories
      await categoryController.fetchAllCategoriesForListing();

      // Debug: print what themes and categories are available
      final allCats = categoryController.allCategories;
      debugPrint('🗂 [CreateListing] Total categories fetched: ${allCats.length}');
      for (var c in allCats) {
        debugPrint('  📁 Category: ${c.name} | theme: ${c.theme} | type: ${c.type}');
      }

      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
          if (widget.existingListing != null &&
              widget.existingListing!.category != null) {
            // Extract the ID safely
            final String? categoryId = widget.existingListing!.category!.id;

            final allRoots = allCats.where((c) => c.type == 'category').toList();
            try {
              _selectedCategory = allRoots.firstWhere(
                (c) => c.id == categoryId,
              );
            } catch (_) {
              _selectedCategory = null;
            }

            // Set the theme in controller if available from the selected category
            if (_selectedCategory?.theme != null) {
              final String theme = _selectedCategory!.theme!;
              categoryController.selectTheme(theme);
              
              // Map theme back to Service Type for UI selection
              if (theme == 'PHOTOGRAPHY') {
                _selectedServiceTypeKey = 'Photography';
              } else if (theme == 'VIDEOGRAPHY') {
                _selectedServiceTypeKey = 'Videography';
              } else if (theme == 'EDITING AND POST-PRODUCTION') {
                _selectedServiceTypeKey = 'Editing';
              }
            }

            // Use the new selectCategory logic to fetch subcategories
            categoryController.selectCategory(_selectedCategory?.id).then((
              _,
            ) {
              if (mounted && widget.existingListing!.subCategory != null) {
                final subId = widget.existingListing!.subCategory!;
                final subcategories = categoryController.subCategories;
                if (subcategories.isNotEmpty) {
                  try {
                    setState(() {
                      _selectedSubCategory = subcategories.firstWhere(
                        (s) => s.id == subId,
                      );
                    });
                  } catch (_) {
                    _selectedSubCategory = null;
                  }
                }
              }
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _countryController.dispose();
    _durationController.dispose();
    _equipmentController.dispose();
    _otherServiceController.dispose();
    _weekdayHourlyRateController.dispose();
    _weekendHourlyRateController.dispose();
    _dailyRateController.dispose();
    _dailyHoursController.dispose();
    _minBudgetController.dispose();
    _pageController.dispose();
    _durationUnitController.dispose();
    for (var controller in _addonControllers) {
      controller.dispose();
    }
    for (var controller in _availabilityControllers) {
      controller.dispose();
    }
    for (var controller in _packageControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _validateStep0() {
    setState(() {
      _localFieldErrors.clear();
    });

    bool isValid = true;
    final Map<String, String> errors = {};

    if (context.read<CategoryController>().selectedTheme == null) {
      errors['theme'] = "Theme is required";
      isValid = false;
    }
    if (_selectedCategory == null) {
      errors['category'] = "Category is required";
      isValid = false;
    }
    final subCategories = context.read<CategoryController>().subCategories;
    if (_selectedSubCategory == null && subCategories.isNotEmpty) {
      errors['subCategory'] = "Sub-Category is required";
      isValid = false;
    }
    // if (_selectedServiceTypes.isEmpty) {
    //   errors['serviceType'] = "At least one Service Type is required";
    //   isValid = false;
    // }
    if (_locationController.text.trim().isEmpty) {
      errors['city'] = "City is required";
      isValid = false;
    }

    setState(() {
      _localFieldErrors.addAll(errors);
    });

    if (!isValid) {
      CustomSnackBar.show(
        context: context,
        message: errors.values.first,
        isError: true,
      );
    }
    return isValid;
  }

  bool _validateStep1() {
    setState(() {
      _localFieldErrors.remove('title');
      _localFieldErrors.remove('description');
      _localFieldErrors.remove('duration');
      _localFieldErrors.remove('photos');
    });

    bool isValid = true;
    final Map<String, String> errors = {};

    if (_titleController.text.trim().isEmpty) {
      errors['title'] = "Title is required";
      isValid = false;
    }
    if (_descriptionController.text.trim().length < 10) {
      errors['description'] = "Description must be at least 10 characters";
      isValid = false;
    }

    if (_selectedPricingModel == 'By Hour' || _selectedPricingModel == 'By Day') {
      if (_durationController.text.trim().isEmpty) {
        errors['duration'] = "Please enter a duration value";
        isValid = false;
      }
    }

    if (_selectedImages.isEmpty && _existingNetworkImages.isEmpty) {
      errors['photos'] = "At least one portfolio photo or video is required";
      isValid = false;
    } else {
      final bool hasImage = _selectedImages.any((f) => !_isVideo(f.path)) ||
                            _existingNetworkImages.any((url) => !_isVideo(url));
      if (!hasImage) {
        errors['photos'] = "At least one image is required to act as the cover photo";
        isValid = false;
      }
    }

    setState(() {
      _localFieldErrors.addAll(errors);
    });

    if (!isValid) {
      CustomSnackBar.show(
        context: context,
        message: errors.values.first,
        isError: true,
      );
    }
    return isValid;
  }

  bool _validateStep2() {
    setState(() {
      _localFieldErrors.remove('weekdayHourlyRate');
      _localFieldErrors.remove('weekendHourlyRate');
      _localFieldErrors.remove('dailyRate');
      _localFieldErrors.remove('dailyHours');
      _localFieldErrors.remove('pricing');
      _localFieldErrors.removeWhere((key, value) => key.startsWith('package_'));
    });

    bool isValid = true;
    final Map<String, String> errors = {};

    if (_selectedPricingModel == 'By Hour') {
      if (_weekdayHourlyRateController.text.trim().isEmpty) {
        errors['weekdayHourlyRate'] = "Weekday hourly rate is required";
        isValid = false;
      }
      if (_weekendHourlyRateController.text.trim().isEmpty) {
        errors['weekendHourlyRate'] = "Weekend hourly rate is required";
        isValid = false;
      }
    } else if (_selectedPricingModel == 'By Day') {
      if (_dailyRateController.text.trim().isEmpty) {
        errors['dailyRate'] = "Daily rate is required";
        isValid = false;
      }
      if (_dailyHoursController.text.trim().isEmpty) {
        errors['dailyHours'] = "Daily hours is required";
        isValid = false;
      }
    } else if (_selectedPricingModel == 'By Service') {
      if (_packageControllers.isEmpty) {
        errors['pricing'] = "At least one package is required";
        isValid = false;
      }
      for (int i = 0; i < _packageControllers.length; i++) {
        final pkg = _packageControllers[i];
        if (pkg.name.text.trim().isEmpty ||
            pkg.price.text.trim().isEmpty ||
            pkg.duration.text.trim().isEmpty ||
            pkg.description.text.trim().isEmpty) {
          errors['package_$i'] =
              "Package ${i + 1} requires name, price, duration, and description";
          isValid = false;
        }
      }
    }

    setState(() {
      _localFieldErrors.addAll(errors);
    });

    if (!isValid) {
      CustomSnackBar.show(
        context: context,
        message: errors.values.first,
        isError: true,
      );
    }
    return isValid;
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_validateStep0()) return;
    } else if (_currentStep == 1) {
      if (!_validateStep1()) return;
    } else if (_currentStep == 2) {
      if (!_validateStep2()) return;
    }

    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveDraft() async {
    // Similar to publish but with status 'DRAFT'
    await _publishListing(isDraft: true);
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      final List<File> originalFiles = images.map((x) => File(x.path)).toList();
      final List<File> processedImages = await ImageUtils.fixImagesOrientation(
        originalFiles,
      );

      setState(() {
        _selectedImages.addAll(processedImages);
      });
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );
    if (video != null) {
      setState(() {
        _selectedImages.add(File(video.path));
      });
    }
  }

  void _showMediaPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: Theme.of(context).colorScheme.primary),
                title: const Text('Upload Photos'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImages();
                },
              ),
              ListTile(
                leading: Icon(Icons.video_library, color: Theme.of(context).colorScheme.primary),
                title: const Text('Upload Video'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isVideo(String path) {
    final String lower = path.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm');
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingNetworkImages.removeAt(index);
    });
  }

  bool _isFormValid({bool showErrors = false}) {
    if (showErrors) {
      setState(() {
        _localFieldErrors.clear();
      });
    }

    bool isValid = true;
    final Map<String, String> errors = {};

    // 1. Basic Fields
    if (_titleController.text.trim().isEmpty) {
      errors['title'] = "Title is required";
      isValid = false;
    }
    if (context.read<CategoryController>().selectedTheme == null) {
      errors['theme'] = "Theme is required";
      isValid = false;
    }
    if (_selectedCategory == null) {
      errors['category'] = "Category is required";
      isValid = false;
    }
    final subCategories = context.read<CategoryController>().subCategories;
    if (_selectedSubCategory == null && subCategories.isNotEmpty) {
      errors['subCategory'] = "Sub-Category is required";
      isValid = false;
    }
    // if (_selectedServiceTypes.isEmpty) {
    //   errors['serviceType'] = "At least one Service Type is required";
    //   isValid = false;
    // }
    if (_descriptionController.text.trim().length < 10) {
      errors['description'] = "Description must be at least 10 characters";
      isValid = false;
    }

    // 2. Pricing & Duration Specifics
    if (_selectedPricingModel == 'By Hour') {
      if (_weekdayHourlyRateController.text.trim().isEmpty) {
        errors['weekdayHourlyRate'] = "Weekday hourly rate is required";
        isValid = false;
      }
      if (_weekendHourlyRateController.text.trim().isEmpty) {
        errors['weekendHourlyRate'] = "Weekend hourly rate is required";
        isValid = false;
      }
      if (_durationController.text.trim().isEmpty) {
        errors['duration'] = "Please enter a duration value";
        isValid = false;
      }
    } else if (_selectedPricingModel == 'By Day') {
      if (_dailyRateController.text.trim().isEmpty) {
        errors['dailyRate'] = "Daily rate is required";
        isValid = false;
      }
      if (_dailyHoursController.text.trim().isEmpty) {
        errors['dailyHours'] = "Daily hours is required";
        isValid = false;
      }
      if (_durationController.text.trim().isEmpty) {
        errors['duration'] = "Please enter a duration value";
        isValid = false;
      }
    } else if (_selectedPricingModel == 'By Service') {
      if (_packageControllers.isEmpty) {
        errors['pricing'] = "At least one package is required";
        isValid = false;
      }
      for (int i = 0; i < _packageControllers.length; i++) {
        final pkg = _packageControllers[i];
        if (pkg.name.text.trim().isEmpty ||
            pkg.price.text.trim().isEmpty ||
            pkg.duration.text.trim().isEmpty ||
            pkg.description.text.trim().isEmpty) {
          errors['package_$i'] =
              "Package requires name, price, duration, and description";
          isValid = false;
        }
      }
    }

    // 3. Location Fields
    if (_locationController.text.trim().isEmpty) {
      errors['city'] = "City is required";
      isValid = false;
    }

    // Photos (mandatory)
    if (_selectedImages.isEmpty && _existingNetworkImages.isEmpty) {
      errors['photos'] = "At least one portfolio photo or video is required";
      isValid = false;
    } else {
      final bool hasImage = _selectedImages.any((f) => !_isVideo(f.path)) ||
                            _existingNetworkImages.any((url) => !_isVideo(url));
      if (!hasImage) {
        errors['photos'] = "At least one image is required to act as the cover photo";
        isValid = false;
      }
    }

    if (showErrors) {
      setState(() {
        _localFieldErrors.addAll(errors);
      });
      if (!isValid) {
        CustomSnackBar.show(
          context: context,
          message: errors.values.first,
          isError: true,
        );
      }
    }

    return isValid;
  }

  Future<void> _publishListing({bool isDraft = false}) async {
    if (!isDraft && !_isFormValid(showErrors: true)) return;

    final controller = Provider.of<ServiceController>(context, listen: false);
    controller.clearErrors();

    // Prepare service data
    final serviceData = Data(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      subCategory: _selectedSubCategory?.id,
      tags: [..._customTags],
      equipment: _equipment,
      pricingType: _selectedPricingModel == 'By Hour'
          ? "HOURLY"
          : _selectedPricingModel == 'By Day'
          ? "DAILY"
          : "PACKAGE",
      price: int.tryParse(
            _selectedPricingModel == 'By Hour'
                ? _weekdayHourlyRateController.text
                : _selectedPricingModel == 'By Day'
                ? _dailyRateController.text
                : (_packageControllers.isNotEmpty
                    ? _packageControllers.first.price.text
                    : '0'),
          ) ?? 0,
      currency: "EUR",
      duration: ServiceDuration(
        value: (_durationUnitController.text.trim().toLowerCase().startsWith('day'))
            ? (int.tryParse(_durationController.text.trim()) ?? 1) * 24
            : (_durationUnitController.text.trim().toLowerCase().startsWith('week'))
                ? (int.tryParse(_durationController.text.trim()) ?? 1) * 168
                : int.tryParse(_durationController.text.trim()) ?? 1,
        unit: _durationUnitController.text.trim().toLowerCase().startsWith('minute') ? 'minute' : 'hour',
      ),
      serviceType: _normalizeServiceType(_selectedServiceTypeKey ?? "Photography"),
      location: Location(
        type: _selectedLocationType == 'Remote' ? 'REMOTE' : 'ONSITE',
        country: _countryController.text.trim(),
        city: _locationController.text.trim(),
        address: _addressController.text.trim(),
        serviceRadiusKm: _serviceRadius.toInt(),
      ),
      gallery: _existingNetworkImages,
      coverMedia: _existingNetworkImages.isNotEmpty ? _existingNetworkImages.first : "",
      status: isDraft ? "DRAFT" : (widget.existingListing?.status ?? "ACTIVE").toUpperCase(),
      isVerified: widget.existingListing?.isVerified ?? false,
      depositPercentage: _depositPercentage ?? 0,
      
      // New fields
      addons: _addonControllers.map((a) => Addon(
        name: a.name.text.trim(),
        price: int.tryParse(a.price.text) ?? 0,
      )).toList(),
      
      autoAcceptBookings: AutoAcceptBookings(
        enabled: _isAutoAcceptEnabled,
        minimumBudget: double.tryParse(_minBudgetController.text),
        withinRadiusKm: _selectedAutoAcceptRadius.toDouble(),
        verifiedClientsOnly: _verifiedClientsOnly,
      ),
      autoAccept: AutoAccept(
        isEnabled: _isAutoAcceptEnabled,
        minBudget: int.tryParse(_minBudgetController.text) ?? 0,
        withinRadius: _selectedAutoAcceptRadius,
        verifiedClientsOnly: _verifiedClientsOnly,
      ),
      
      availabilitySlots: _availabilityControllers.map((s) => AvailabilitySlot(
        startDate: s.startDate.text,
        endDate: s.endDate.text,
        startTime: s.startTime.text,
        endTime: s.endTime.text,
      )).toList(),
    );

    // Pricing Model
    if (_selectedPricingModel == 'By Hour') {
      serviceData.pricingModel = PricingModel(
        type: "HOURLY",
        weekdayHourlyRate: double.tryParse(_weekdayHourlyRateController.text) ?? 0,
        weekendHourlyRate: double.tryParse(_weekendHourlyRateController.text) ?? 0,
      );
    } else if (_selectedPricingModel == 'By Day') {
      serviceData.pricingModel = PricingModel(
        type: "DAILY",
        dailyRate: double.tryParse(_dailyRateController.text),
        dailyHours: int.tryParse(_dailyHoursController.text),
      );
    } else if (_selectedPricingModel == 'By Service') {
      serviceData.pricingModel = PricingModel(
        type: "PACKAGE",
        packages: _packageControllers.map((p) => Packages(
          name: p.name.text.trim(),
          price: int.tryParse(p.price.text) ?? 0,
          duration: int.tryParse(p.duration.text) ?? 1,
          description: p.description.text.trim(),
          includes: p.includes.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        )).toList(),
      );
    }

    bool success;
    if (widget.existingListing != null) {
      success = await controller.updateService(widget.existingListing!.sId!, serviceData, _selectedImages);
    } else {
      success = await controller.createService(serviceData, _selectedImages);
    }

    if (success && mounted) {
      CustomSnackBar.show(
        context: context,
        message: isDraft ? "Draft saved" : "Listing published",
        isError: false,
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      CustomSnackBar.show(
        context: context,
        message: controller.errorMessage ?? "Operation failed",
        isError: true,
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    bool inProgress = context.watch<ServiceController>().inProgress;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: 100.h,
        automaticallyImplyLeading: false,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
                ),
                Expanded(
                  child: Text(
                    widget.existingListing != null ? context.l10n.editListing : context.l10n.createListing,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: inProgress ? null : _saveDraft,
                  child: Text(
                    context.l10n.saveDraft,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            _buildStepper(),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoadingCategories
            ? const Center(child: CircularProgressIndicator())
            : PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                children: [
                  _buildStep1Service(inProgress),
                  _buildStep2Details(inProgress),
                  _buildStep3PricingAvailability(inProgress),
                  _buildStep4Review(inProgress),
                ],
              ),
      ),
    );
  }

  Widget _buildStepper() {
    final steps = [
      context.l10n.stepService,
      context.l10n.stepDetails,
      context.l10n.stepPricing,
      context.l10n.stepReview
    ];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: List.generate(steps.length, (index) {
          bool isActive = index <= _currentStep;
          bool isCurrent = index == _currentStep;
          return Expanded(
            child: Column(
              children: [
                Container(
                  height: 3.h,
                  decoration: BoxDecoration(
                    color: isActive 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  steps[index],
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isActive 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNavigationButtons(bool inProgress) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: inProgress ? null : _previousStep,
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(0, 42.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                child: Text(context.l10n.back),
              ),
            ),
          if (_currentStep > 0) SizedBox(width: 12.w),
          Expanded(
            child: ElevatedButton(
              onPressed: inProgress
                  ? null
                  : (_currentStep == 3 ? _publishListing : _nextStep),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                minimumSize: Size(0, 42.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                elevation: 0,
              ),
              child: inProgress
                  ? SizedBox(
                      height: 20.h,
                      width: 20.h,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(_currentStep == 3 ? context.l10n.publishListing : context.l10n.continueBtn),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildStep1Service(bool inProgress) {
    return ListView(
      padding: EdgeInsets.all(20.w),
      children: [
        Text(
          context.l10n.stepService,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          context.l10n.selectDomainAndCategory,
          style: TextStyle(
            fontSize: 14.sp,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        SizedBox(height: 30.h),
        
        _buildLabel(context.l10n.serviceType, isRequired: true),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 10.w,
          crossAxisSpacing: 10.w,
          childAspectRatio: 0.95,
          children: [
            _buildServiceTypeCard('Photography', context.l10n.photography, Icons.camera_alt),
            _buildServiceTypeCard('Videography', context.l10n.videography, Icons.videocam),
            _buildServiceTypeCard('Editing', context.l10n.editing, Icons.content_cut),
          ],
        ),
        
        if (_selectedServiceTypeKey != null) ...[
          SizedBox(height: 25.h),
          // _buildLabel('Theme', isRequired: true),
          // _buildThemeDropdown(errorText: _localFieldErrors['theme']),
          // SizedBox(height: 15.h),
          _buildLabel(context.l10n.category, isRequired: true),
          _buildCategoryDropdown(errorText: _localFieldErrors['category']),
          SizedBox(height: 15.h),
          _buildLabel(context.l10n.subCategory, isRequired: true),
          _buildSubCategoryDropdown(errorText: _localFieldErrors['subCategory']),
          SizedBox(height: 15.h),
          _buildLabel(context.l10n.otherServiceName),
          _buildOtherServicesInput(),
          _buildOtherServicesList(),
          // SizedBox(height: 15.h),
          // _buildLabel('Service Types (Select multiple)', isRequired: true),
          // _buildServiceTypeDropdown(errorText: _localFieldErrors['serviceType']),
        ],

        SizedBox(height: 30.h),
        _buildSectionTitle(context.l10n.serviceLocation),
        _buildLabel(context.l10n.enterCityOrRegion, isRequired: true),
        _buildLocationAutocomplete(errorText: _localFieldErrors['city']),
        
        SizedBox(height: 20.h),
        _buildLabel(context.l10n.coverageRadius),
        _buildRadiusSelector(),
        
        SizedBox(height: 40.h),
        _buildNavigationButtons(inProgress),
      ],
    );
  }

  Widget _buildStep3PricingAvailability(bool inProgress) {
    return ListView(
      padding: EdgeInsets.all(20.w),
      children: [
        Text(
          context.l10n.pricingAndAvailability,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          context.l10n.setRatesAndSlots,
          style: TextStyle(
            fontSize: 14.sp,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        SizedBox(height: 30.h),
        
        _buildPricingToggle(),
        SizedBox(height: 20.h),
        _buildPricingFields(),
        
        // SizedBox(height: 30.h),
        // _buildLabel('Deposit Required'),
        // _buildDepositDropdown(),
        
        SizedBox(height: 30.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(context.l10n.availabilitySlots),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _availabilityControllers.add(AvailabilitySlotControllers());
                });
              },
              icon: Icon(Icons.add, size: 18.sp, color: const Color(0xFF9C27B0)),
              label: Text(
                context.l10n.addSlot,
                style: TextStyle(
                  color: const Color(0xFF9C27B0),
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ),
        _buildAvailabilitySlotsList(),
        
        SizedBox(height: 20.h),
        Text(
          '💡 These slots are specific to this listing. You can also manage global availability in Calendar Settings.',
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.orange[800],
            fontStyle: FontStyle.italic,
          ),
        ),
        SizedBox(height: 40.h),
        _buildNavigationButtons(inProgress),
      ],
    );
  }

  Widget _buildStep4Review(bool inProgress) {
    return ListView(
      padding: EdgeInsets.all(20.w),
      children: [
        Text(
          context.l10n.reviewAndPublish,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          context.l10n.doubleCheckBeforeLive,
          style: TextStyle(
            fontSize: 14.sp,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        SizedBox(height: 30.h),
        
        // Listing Preview Card
        _buildListingPreviewCard(),
        
        SizedBox(height: 30.h),
        _buildSummarySection(context.l10n.aboutServiceDetails, [
          '${context.l10n.description}: ${_descriptionController.text.isEmpty ? "No description provided" : _descriptionController.text}',
          '${context.l10n.serviceType}: ${_getServiceTypeLabel(_selectedServiceTypeKey)}',
          '${context.l10n.theme}: ${context.read<CategoryController>().selectedTheme ?? "N/A"}',
          '${context.l10n.category}: ${_selectedCategory?.name ?? "N/A"}',
          '${context.l10n.subCategory}: ${_selectedSubCategory?.name ?? "N/A"}',
          if ([..._selectedServiceTypes, ..._customTags].isNotEmpty) '${context.l10n.tags}: ${[..._selectedServiceTypes, ..._customTags].join(", ")}',
          '${context.l10n.serviceDuration}: ${_durationController.text.trim()} ${_durationUnitController.text}',
        ], onEdit: () => _jumpToStep(1)),
        
        SizedBox(height: 20.h),
        _buildSummarySection(context.l10n.locationAndRange, [
          '${context.l10n.location}: $_selectedLocationType',
          '${context.l10n.city}/${context.l10n.country}: ${_locationController.text}, ${_countryController.text}',
          '${context.l10n.coverageRadius}: ${_serviceRadius.toInt()} km',
          'Outside Range Booking: ${_acceptOutsideRadius ? "Accepted" : "Not Accepted"}',
          if (_otherServices.isNotEmpty) '${context.l10n.otherServicesProvided}: ${_otherServices.join(", ")}',
        ], onEdit: () => _jumpToStep(0)),
        
        SizedBox(height: 20.h),
        _buildSummarySection(context.l10n.pricingAndPackages, [
          '${context.l10n.pricingModel}: $_selectedPricingModel',
          if (_selectedPricingModel == 'By Hour') '${context.l10n.weekdayHourlyRate}: €${_weekdayHourlyRateController.text}/hr',
          if (_selectedPricingModel == 'By Hour') '${context.l10n.weekendHourlyRate}: €${_weekendHourlyRateController.text}/hr',
          if (_selectedPricingModel == 'By Day') '${context.l10n.dailyRate}: €${_dailyRateController.text}/day (${_dailyHoursController.text} hours included)',
          if (_selectedPricingModel == 'By Service') 'Packages Added: ${_packageControllers.length}',
          if (_selectedPricingModel == 'By Service') ..._packageControllers.map((p) => '- ${p.name.text}: €${p.price.text} (${p.duration.text})'),
          'Required Booking Deposit: ${_depositPercentage ?? 0}%',
          'Auto Accept Bookings: ${_isAutoAcceptEnabled ? "Enabled (within $_selectedAutoAcceptRadius km)" : "Disabled"}',
        ], onEdit: () => _jumpToStep(2)),

        if (_addonControllers.isNotEmpty) ...[
          SizedBox(height: 20.h),
          _buildSummarySection(context.l10n.addonsAvailable, _addonControllers.map((a) => '${a.name.text}: €${a.price.text}').toList(), onEdit: () => _jumpToStep(1)),
        ],

        if (_equipment.isNotEmpty) ...[
          SizedBox(height: 20.h),
          _buildSummarySection(context.l10n.equipmentUtilized, _equipment, onEdit: () => _jumpToStep(1)),
        ],

        if (_availabilityControllers.isNotEmpty) ...[
          SizedBox(height: 20.h),
          _buildSummarySection(
            context.l10n.availabilitySlots,
            _availabilityControllers
                .map(
                  (slot) =>
                      '${slot.rangeController.text.isEmpty ? "${slot.startDate.text} to ${slot.endDate.text}" : slot.rangeController.text} (${slot.startTime.text} - ${slot.endTime.text})',
                )
                .toList(),
            onEdit: () => _jumpToStep(2),
          ),
        ],
        
        SizedBox(height: 50.h),
        _buildNavigationButtons(inProgress),
      ],
    );
  }

  void _jumpToStep(int step) {
    setState(() {
      _currentStep = step;
    });
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildListingPreviewCard() {
    final allImages = [..._existingNetworkImages, ..._selectedImages];
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (allImages.isNotEmpty)
            SizedBox(
              height: 200.h,
              child: StatefulBuilder(
                builder: (context, setCardState) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                        child: PageView.builder(
                          itemCount: allImages.length,
                          onPageChanged: (idx) {
                            setCardState(() {
                              _previewImageIndex = idx;
                            });
                          },
                          itemBuilder: (context, idx) {
                            final img = allImages[idx];
                            return img is File
                                ? Image.file(img, width: double.infinity, fit: BoxFit.cover)
                                : Image.network(
                                    img.toString().startsWith('http')
                                        ? img.toString()
                                        : "${Urls.baseUrl}$img",
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  );
                          },
                        ),
                      ),
                      Positioned(
                        bottom: 10.h,
                        right: 15.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            '${_previewImageIndex + 1}/${allImages.length}',
                            style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  );
                }
              ),
            )
          else
            Container(
              height: 180.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: Icon(Icons.image_outlined, size: 50.sp, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
            ),
          Padding(
            padding: EdgeInsets.all(15.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        _getServiceTypeLabel(_selectedServiceTypeKey),
                        style: TextStyle(fontSize: 10.sp, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (_selectedCategory != null) ...[
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          _selectedCategory!.name,
                          style: TextStyle(fontSize: 10.sp, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 10.h),
                Text(
                  _titleController.text.isEmpty ? 'Listing Title' : _titleController.text,
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
                if ([..._selectedServiceTypes, ..._customTags].isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 6.h,
                    children: [..._selectedServiceTypes, ..._customTags].map((tag) {
                      final formattedTag = tag.startsWith('#') ? tag : '#$tag';
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          formattedTag,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14.sp, color: Theme.of(context).colorScheme.primary),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        _locationController.text.isEmpty ? 'City, Country' : '${_locationController.text}, ${_countryController.text} (${_selectedLocationType})',
                        style: TextStyle(fontSize: 12.sp, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16.sp),
                        SizedBox(width: 4.w),
                        Text('0.0 (0)', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text(
                      _selectedPricingModel == 'By Hour'
                          ? '€${_weekdayHourlyRateController.text}/hr'
                          : _selectedPricingModel == 'By Day'
                          ? '€${_dailyRateController.text}/day'
                          : (_packageControllers.isNotEmpty ? 'From €${_packageControllers.first.price.text}' : 'Free'),
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(String title, List<String> details, {required VoidCallback onEdit}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            TextButton(onPressed: onEdit, child: Text(context.l10n.editBtn, style: TextStyle(fontSize: 12.sp))),
          ],
        ),
        if (title == 'Equipment Utilized')
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: details.map((d) => Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.03),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                ),
              ),
              child: Text(
                d,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            )).toList(),
          )
        else
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(15.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.02),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: details.map((d) => Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Text(d, style: TextStyle(fontSize: 13.sp, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
              )).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildDepositDropdown() {
    final values = [0, 20, 25, 50];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<double>(
          value: _depositPercentage ?? 0,
          isExpanded: true,
          items: values.map((int v) {
            return DropdownMenuItem<double>(
              value: v.toDouble(),
              child: Text('$v%'),
            );
          }).toList(),
          onChanged: (double? newValue) {
            setState(() {
              _depositPercentage = newValue;
            });
          },
        ),
      ),
    );
  }

  Widget _buildAvailabilitySlotsList() {
    if (_availabilityControllers.isEmpty) {
      return Text(
        'No availability slots added yet',
        style: TextStyle(
          fontSize: 12.sp,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _availabilityControllers.length,
      separatorBuilder: (_, __) => SizedBox(height: 15.h),
      itemBuilder: (context, index) {
        final slot = _availabilityControllers[index];
        return Container(
          padding: EdgeInsets.all(15.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.02),
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildDateRangePickerField(slot),
                  ),
                  SizedBox(width: 10.w),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        slot.dispose();
                        _availabilityControllers.removeAt(index);
                      });
                    },
                    icon: Icon(Icons.delete_outline, color: Colors.red[400], size: 20.sp),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: 15.h),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Time',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                        SizedBox(height: 5.h),
                        _buildTimePickerField(slot.startTime, '09:00'),
                      ],
                    ),
                  ),
                  SizedBox(width: 15.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'End Time',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                        SizedBox(height: 5.h),
                        _buildTimePickerField(slot.endTime, '18:00'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateRangePickerField(AvailabilitySlotControllers slot) {
    return GestureDetector(
      onTap: () async {
        final DateTimeRange? picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime.now(),
          lastDate: DateTime(2030),
          initialDateRange: (slot.startDate.text.isNotEmpty && slot.endDate.text.isNotEmpty)
              ? DateTimeRange(
                  start: DateTime.parse(slot.startDate.text),
                  end: DateTime.parse(slot.endDate.text),
                )
              : null,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                  onPrimary: Theme.of(context).colorScheme.onPrimary,
                  surface: Theme.of(context).colorScheme.surface,
                  onSurface: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              child: child!,
            );
          },
        );

        if (picked != null) {
          setState(() {
            slot.startDate.text = DateFormat('yyyy-MM-dd').format(picked.start);
            slot.endDate.text = DateFormat('yyyy-MM-dd').format(picked.end);
            slot.rangeController.text = _formatDateRange(picked.start, picked.end);
          });
        }
      },
      child: AbsorbPointer(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  slot.rangeController.text.isEmpty ? 'Select Date Range' : slot.rangeController.text,
                  style: TextStyle(
                    color: slot.rangeController.text.isEmpty
                        ? Theme.of(context).colorScheme.onSurface.withOpacity(0.4)
                        : Theme.of(context).colorScheme.onSurface,
                    fontSize: 14.sp,
                  ),
                ),
              ),
              Icon(
                Icons.calendar_today_outlined,
                size: 16.sp,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    if (start.year == end.year) {
      if (start.month == end.month) {
        if (start.day == end.day) {
          return DateFormat('MMM d, yyyy').format(start);
        }
        return "${DateFormat('MMM d').format(start)}-${end.day}, ${start.year}";
      }
      return "${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d').format(end)}, ${start.year}";
    }
    return "${DateFormat('MMM d, yyyy').format(start)} - ${DateFormat('MMM d, yyyy').format(end)}";
  }

  Widget _buildDatePickerField(TextEditingController controller, String label) {
    return GestureDetector(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2030),
        );
        if (picked != null) {
          setState(() {
            controller.text = DateFormat('yyyy-MM-dd').format(picked);
          });
        }
      },
      child: AbsorbPointer(
        child: _buildTextField(controller, label),
      ),
    );
  }

  Widget _buildTimePickerField(TextEditingController controller, String label) {
    return GestureDetector(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (picked != null) {
          setState(() {
            final now = DateTime.now();
            final dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
            controller.text = DateFormat('HH:mm').format(dt);
          });
        }
      },
      child: AbsorbPointer(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  controller.text.isEmpty ? label : controller.text,
                  style: TextStyle(
                    color: controller.text.isEmpty
                        ? Theme.of(context).colorScheme.onSurface.withOpacity(0.4)
                        : Theme.of(context).colorScheme.onSurface,
                    fontSize: 14.sp,
                  ),
                ),
              ),
              Icon(
                Icons.access_time,
                size: 16.sp,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceTypeCard(String key, String label, IconData icon) {
    bool isSelected = _selectedServiceTypeKey == key;
    return GestureDetector(
      onTap: () {
        if (_selectedServiceTypeKey != key) {
          String? theme;
          if (key == 'Photography') {
            theme = 'PHOTOGRAPHY';
          } else if (key == 'Videography') {
            theme = 'VIDEOGRAPHY';
          } else if (key == 'Editing') {
            theme = 'EDITING AND POST-PRODUCTION';
          }

          setState(() {
            _selectedServiceTypeKey = key;
            _selectedCategory = null;
            _selectedSubCategory = null;
            _selectedServiceTypes.clear();
            if (theme != null) {
              _localFieldErrors.remove('theme');
            }
          });
          context.read<CategoryController>().selectTheme(theme);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary 
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24.sp,
              color: isSelected 
                  ? Theme.of(context).colorScheme.primary 
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getServiceTypeLabel(String? key) {
    switch (key) {
      case 'Photography':
        return context.l10n.photography;
      case 'Videography':
        return context.l10n.videography;
      case 'Editing':
        return context.l10n.editing;
      default:
        return 'Service Type';
    }
  }

  Widget _buildRadiusSelector() {
    final radii = [
      {'label': '30 km', 'value': 30},
      {'label': '50 km', 'value': 50},
      {'label': '100 km', 'value': 100},
    ];
    
    return Row(
      children: radii.map((r) {
        bool isSelected = _serviceRadius == (r['value'] as num).toDouble();
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _serviceRadius = (r['value'] as num).toDouble();
              });
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              padding: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1) 
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary 
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                ),
              ),
              child: Center(
                child: Text(
                  r['label'] as String,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStep2Details(bool inProgress) {
    return ListView(
      padding: EdgeInsets.all(20.w),
      children: [
        Text(
          context.l10n.stepDetails,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          context.l10n.addDetailsAboutService,
          style: TextStyle(
            fontSize: 14.sp,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        SizedBox(height: 30.h),
        
        _buildLabel(context.l10n.listingTitle, isRequired: true),
        _buildTextField(
          _titleController,
          'e.g. Wedding Photography Premium Package',
          errorText: _localFieldErrors['title'],
        ),
        
        SizedBox(height: 20.h),
        _buildLabel(context.l10n.description, isRequired: true),
        _buildTextField(
          _descriptionController,
          'Describe your service in detail...',
          maxLines: 5,
          errorText: _localFieldErrors['description'],
        ),
        
        SizedBox(height: 20.h),
        _buildLabel(context.l10n.serviceDuration, isRequired: true),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: _localFieldErrors['duration'] != null
                              ? Colors.red
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                        ),
                      ),
                      child: TextField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            if (value.isNotEmpty) {
                              _localFieldErrors.remove('duration');
                            }
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Value',
                          hintStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                            fontSize: AppTypography.bodyLarge,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                        ),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: AppTypography.bodyLarge,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 15.w),
                  Expanded(
                    flex: 3,
                    child: _buildDurationUnitDropdown(),
                  ),
                ],
              ),
            ),
            if (_localFieldErrors['duration'] != null)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 14.sp),
                    SizedBox(width: 6.w),
                    Text(
                      _localFieldErrors['duration']!,
                      style: TextStyle(color: Colors.red, fontSize: 12.sp),
                    ),
                  ],
                ),
              ),
          ],
        ),
        
        SizedBox(height: 30.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(context.l10n.addons),
            TextButton.icon(
              onPressed: _showAddAddonSheet,
              icon: Icon(Icons.add, size: 18.sp),
              label: Text(context.l10n.add),
            ),
          ],
        ),
        _buildAddonList(),
        
        SizedBox(height: 30.h),
        _buildSectionTitle(context.l10n.equipment),
        _buildEquipmentInput(),
        _buildEquipmentList(),

        SizedBox(height: 30.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(context.l10n.tags),
            TextButton.icon(
              onPressed: _showAddTagSheet,
              icon: Icon(Icons.add, size: 18.sp),
              label: Text(context.l10n.add),
            ),
          ],
        ),
        _buildTagsList(),
        
        SizedBox(height: 30.h),
        _buildAutoAcceptSection(),
        
        SizedBox(height: 30.h),
        _buildPhotoUploadArea(errorText: _localFieldErrors['photos']),
        _buildSelectedImagesGrid(),
        
        SizedBox(height: 40.h),
        _buildNavigationButtons(inProgress),
      ],
    );
  }

  Widget _buildDurationUnitDropdown() {
    final units = {
      'Minutes': context.l10n.minutes,
      'Hours': context.l10n.hours,
      'Days': context.l10n.days,
      'Weeks': context.l10n.weeks,
    };
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _durationUnitController.text,
          dropdownColor: Theme.of(context).colorScheme.surface,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: AppTypography.bodyLarge,
          ),
          items: units.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(
                entry.value,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: AppTypography.bodyLarge,
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _durationUnitController.text = newValue;
              });
            }
          },
        ),
      ),
    );
  }

  void _showAddTagSheet() {
    _tagInputController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20.w,
            right: 20.w,
            top: 24.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 20.h),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              Text(
                context.l10n.addTag,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                context.l10n.addSearchableTags,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  ),
                ),
                child: TextField(
                  controller: _tagInputController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'e.g. drone_photography',
                    prefixText: '# ',
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                      fontSize: 13.sp,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  ),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  onSubmitted: (val) {
                    final tag = val.trim().replaceAll(' ', '_').toLowerCase();
                    if (tag.isNotEmpty && !_customTags.contains(tag)) {
                      setState(() => _customTags.add(tag));
                      Navigator.pop(ctx);
                    }
                  },
                ),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: () {
                    final tag = _tagInputController.text.trim().replaceAll(' ', '_').toLowerCase();
                    if (tag.isNotEmpty && !_customTags.contains(tag)) {
                      setState(() => _customTags.add(tag));
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    context.l10n.addTag,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTagsList() {
    if (_customTags.isEmpty) {
      return Text(
        context.l10n.noTagsAdded,
        style: TextStyle(
          fontSize: 12.sp,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
        ),
      );
    }
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: _customTags.asMap().entries.map((entry) {
        final tag = entry.value;
        final label = tag.startsWith('#') ? tag : '#$tag';
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 6.w),
              GestureDetector(
                onTap: () => setState(() => _customTags.removeAt(entry.key)),
                child: Icon(
                  Icons.close,
                  size: 14.sp,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showAddAddonSheet() {

    final nameController = TextEditingController();
    final priceController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20.w,
            right: 20.w,
            top: 24.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 20.h),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              Text(
                context.l10n.addAddon,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                context.l10n.nameLabel,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  ),
                ),
                child: TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'e.g. Extra hour of coverage',
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                      fontSize: 13.sp,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  ),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Price (€)', // Keep as is or translate?
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  ),
                ),
                child: TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '0',
                    prefixText: '€ ',
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                      fontSize: 13.sp,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  ),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                ),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isNotEmpty &&
                        priceController.text.trim().isNotEmpty) {
                      final addon = AddonControllers();
                      addon.name.text = nameController.text.trim();
                      addon.price.text = priceController.text.trim();
                      setState(() => _addonControllers.add(addon));
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    context.l10n.add,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddonList() {
    if (_addonControllers.isEmpty) {
      return Text(
        'No add-ons added yet',
        style: TextStyle(
          fontSize: 12.sp,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _addonControllers.length,
      separatorBuilder: (_, __) => SizedBox(height: 8.h),
      itemBuilder: (context, index) {
        final addon = _addonControllers[index];
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  addon.name.text,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                '€${addon.price.text}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(width: 12.w),
              GestureDetector(
                onTap: () {
                  setState(() {
                    addon.dispose();
                    _addonControllers.removeAt(index);
                  });
                },
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.red[400],
                  size: 20.sp,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAutoAcceptSection() {
    return Container(
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Auto-Accept Bookings',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Automatically accept matching requests',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              Switch(
                value: _isAutoAcceptEnabled,
                onChanged: (val) {
                  setState(() {
                    _isAutoAcceptEnabled = val;
                  });
                },
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
          if (_isAutoAcceptEnabled) ...[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 15.h),
              child: Divider(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
            ),
            _buildLabel('Minimum budget (€)'),
            _buildTextField(_minBudgetController, 'e.g. 500'),
            SizedBox(height: 15.h),
            _buildLabel('Within radius'),
            _buildAutoAcceptRadiusDropdown(),
            SizedBox(height: 15.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Verified clients only',
                  style: TextStyle(fontSize: 14.sp),
                ),
                Switch(
                  value: _verifiedClientsOnly,
                  onChanged: (val) {
                    setState(() {
                      _verifiedClientsOnly = val;
                    });
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAutoAcceptRadiusDropdown() {
    final radii = [30, 50, 100];
    if (!radii.contains(_selectedAutoAcceptRadius)) {
      radii.add(_selectedAutoAcceptRadius);
      radii.sort();
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedAutoAcceptRadius,
          isExpanded: true,
          items: radii.map((int r) {
            return DropdownMenuItem<int>(
              value: r,
              child: Text('$r km'),
            );
          }).toList(),
          onChanged: (int? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedAutoAcceptRadius = newValue;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: AppTypography.h2,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildLabel(String label, {bool isRequired = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: RichText(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: AppTypography.bodySmall,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          children: [
            if (isRequired)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    String? errorText,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: errorText != null
                  ? Colors.red
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            onChanged: (value) =>
                setState(() {}), // Trigger rebuild for button validation
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                fontSize: AppTypography.bodyLarge,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 12.h,
              ),
            ),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 14.sp),
                SizedBox(width: 6.w),
                Text(
                  errorText,
                  style: TextStyle(color: Colors.red, fontSize: 12.sp),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildThemeDropdown({String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: errorText != null
                  ? Colors.red
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: context.watch<CategoryController>().selectedTheme,
              dropdownColor: Theme.of(context).colorScheme.surface,
              isExpanded: true,
              hint: Text(
                'Select Theme',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = null;
                  _selectedSubCategory = null;
                  if (newValue != null) _localFieldErrors.remove('theme');
                });
                context.read<CategoryController>().selectTheme(newValue);
              },
              items: context
                  .read<CategoryController>()
                  .themes
                  .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        context.l10n.translateCategory(ThemeFormatter.format(value)),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13.sp,
                        ),
                      ),
                    );
                  })
                  .toList(),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 14.sp),
                SizedBox(width: 6.w),
                Text(
                  errorText,
                  style: TextStyle(color: Colors.red, fontSize: 12.sp),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryDropdown({String? errorText}) {
    final categoryController = context.watch<CategoryController>();
    final rootCategories = categoryController.rootCategories;
    final selectedTheme = categoryController.selectedTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: selectedTheme == null
                ? Theme.of(context).colorScheme.onSurface.withOpacity(0.05)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: errorText != null
                  ? Colors.red
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<CategoryModel>(
              value: _selectedCategory,
              dropdownColor: Theme.of(context).colorScheme.surface,
              isExpanded: true,
              disabledHint: Text(
                selectedTheme == null
                    ? 'Select a theme first'
                    : 'No category available for this theme',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.4),
                  fontSize: 13.sp,
                ),
              ),
              hint: Text(
                'Select Category',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.4),
                  fontSize: 13.sp,
                ),
              ),
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
              onChanged: (selectedTheme == null || rootCategories.isEmpty)
                  ? null
                  : (CategoryModel? newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                        _selectedSubCategory = null;
                        if (newValue != null) {
                          _localFieldErrors.remove('category');
                        }
                      });
                      if (newValue != null) {
                        categoryController.selectCategory(newValue.id);
                      }
                    },
              items: rootCategories.map<DropdownMenuItem<CategoryModel>>((
                CategoryModel value,
              ) {
                return DropdownMenuItem<CategoryModel>(
                  value: value,
                  child: Text(
                    value.name,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 13.sp,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 14.sp),
                SizedBox(width: 6.w),
                Text(
                  errorText,
                  style: TextStyle(color: Colors.red, fontSize: 12.sp),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSubCategoryDropdown({String? errorText}) {
    final categoryController = context.watch<CategoryController>();
    final subcategories = categoryController.subCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: _selectedCategory == null
                ? Theme.of(context).colorScheme.onSurface.withOpacity(0.05)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: errorText != null
                  ? Colors.red
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<CategoryModel>(
              value: _selectedSubCategory,
              dropdownColor: Theme.of(context).colorScheme.surface,
              isExpanded: true,
              disabledHint: Text(
                _selectedCategory == null
                    ? 'Select a category first'
                    : 'No sub-category available',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.4),
                  fontSize: 13.sp,
                ),
              ),
              hint: Text(
                'Select Sub-Category',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.4),
                  fontSize: 13.sp,
                ),
              ),
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
              onChanged: (_selectedCategory == null || subcategories.isEmpty)
                  ? null
                  : (CategoryModel? newValue) {
                      setState(() {
                        _selectedSubCategory = newValue;
                        if (newValue != null) {
                          _localFieldErrors.remove('subCategory');
                        }
                      });
                    },
              items: subcategories.map<DropdownMenuItem<CategoryModel>>((
                CategoryModel value,
              ) {
                return DropdownMenuItem<CategoryModel>(
                  value: value,
                  child: Text(
                    value.name,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 13.sp,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 14.sp),
                SizedBox(width: 6.w),
                Text(
                  errorText,
                  style: TextStyle(color: Colors.red, fontSize: 12.sp),
                ),
              ],
            ),
          ),
      ],
    );
  }


  Widget _buildLocationAutocomplete({String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: errorText != null
                  ? Colors.red
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            ),
          ),
          child: Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) async {
              final query = textEditingValue.text.trim();
              if (query.length < 3) {
                return const Iterable<String>.empty();
              }
              
              // 1. Try backend search
              try {
                final locationController = Provider.of<LocationController>(context, listen: false);
                final backendResults = await locationController.searchLocations(query);
                if (backendResults.isNotEmpty) {
                  return backendResults.map<String>((item) {
                    if (item is Map) {
                      return item['description']?.toString() ?? item['formattedAddress']?.toString() ?? item['name']?.toString() ?? '';
                    }
                    return item.toString();
                  }).where((s) => s.isNotEmpty).toList();
                }
              } catch (e) {
                debugPrint("Backend location search error: $e");
              }

              // 2. Fallback: Search from OpenStreetMap Nominatim API (fully dynamic, worldwide)
              try {
                final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=5&accept-language=en');
                final response = await http.get(url, headers: {'User-Agent': 'PhotopiaApp/1.0'});
                if (response.statusCode == 200) {
                  final List<dynamic> data = jsonDecode(response.body);
                  return data.map<String>((item) {
                    return item['display_name']?.toString() ?? '';
                  }).where((s) => s.isNotEmpty).toList();
                }
              } catch (e) {
                debugPrint("Nominatim search error: $e");
              }

              return const Iterable<String>.empty();
            },
            onSelected: (String selection) async {
              // Automatically extract country and city from selection
              final parts = selection.split(',');
              if (parts.length >= 2) {
                final countryPart = parts.last.trim();
                final cityPart = parts[0].trim();
                setState(() {
                  _locationController.text = cityPart;
                  _selectedCity = cityPart;
                  _selectedCountry = countryPart;
                  _countryController.text = countryPart;
                  _localFieldErrors.remove('city');
                });
              } else {
                setState(() {
                  _locationController.text = selection;
                  _selectedCity = selection;
                  _localFieldErrors.remove('city');
                });
                
                final locationController = Provider.of<LocationController>(context, listen: false);
                final geocodeResult = await locationController.geocodeAddress(selection);
                if (geocodeResult != null) {
                  setState(() {
                    _selectedCountry = geocodeResult['country']?.toString();
                    if (_selectedCountry != null) {
                      _countryController.text = _selectedCountry!;
                    }
                  });
                }
              }
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              if (controller.text != _locationController.text) {
                controller.text = _locationController.text;
              }
              
              return TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: (value) {
                  setState(() {
                    _locationController.text = value;
                    if (value.isNotEmpty) _localFieldErrors.remove('city');
                  });
                },
                decoration: InputDecoration(
                  hintText: context.l10n.enterCityOrRegion,
                  prefixIcon: Icon(Icons.location_on_outlined, size: 20.sp),
                  suffixIcon: Consumer<LocationController>(
                    builder: (context, locCtrl, child) {
                      return locCtrl.isLoading
                          ? SizedBox(
                              width: 20.w,
                              height: 20.h,
                              child: const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : IconButton(
                              icon: Icon(Icons.my_location, size: 20.sp, color: Theme.of(context).colorScheme.primary),
                              onPressed: () async {
                                await locCtrl.determinePosition();
                                if (locCtrl.currentAddress.isNotEmpty) {
                                  setState(() {
                                    _locationController.text = locCtrl.city ?? locCtrl.currentAddress;
                                    controller.text = locCtrl.city ?? locCtrl.currentAddress;
                                    _selectedCity = locCtrl.city;
                                    _selectedCountry = locCtrl.country;
                                    _countryController.text = locCtrl.country ?? '';
                                    _localFieldErrors.remove('city');
                                  });
                                }
                              },
                            );
                    },
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                ),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  borderRadius: BorderRadius.circular(10.r),
                  color: Theme.of(context).colorScheme.surface,
                  child: Container(
                    width: 300.w,
                    constraints: BoxConstraints(maxHeight: 200.h),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final String option = options.elementAt(index);
                        return ListTile(
                          title: Text(option, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (errorText != null)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 14.sp),
                SizedBox(width: 6.w),
                Text(
                  errorText,
                  style: TextStyle(color: Colors.red, fontSize: 12.sp),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /*
  Widget _buildServiceTypeDropdown({String? errorText}) {
    final List<String> serviceTypes = [
      'photography',
      'videography',
      'video_editing',
      'photo_editing',
      'graphic_design',
      'drone_photography',
      'event_coverage',
      'studio_rental',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: errorText != null ? Colors.red : const Color(0xFFE0E0E0),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              hint: Text(
                'Select Service Types',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
              dropdownColor: Theme.of(context).colorScheme.surface,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
              onChanged: (String? newValue) {
                if (newValue != null &&
                    !_selectedServiceTypes.contains(newValue)) {
                  setState(() {
                    _selectedServiceTypes.add(newValue);
                    _localFieldErrors.remove('serviceType');
                  });
                }
              },
              items: serviceTypes.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  // Convert technical name (photography) to readable label (Photography)
                  child: Text(
                    value
                        .split('_')
                        .map(
                          (e) => e.isNotEmpty
                              ? (e[0].toUpperCase() + e.substring(1))
                              : '',
                        )
                        .join(' '),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 14.sp),
                SizedBox(width: 6.w),
                Text(
                  errorText,
                  style: TextStyle(color: Colors.red, fontSize: 12.sp),
                ),
              ],
            ),
          ),
        if (_selectedServiceTypes.isNotEmpty) ...[
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _selectedServiceTypes.map((type) {
              return Chip(
                label: Text(
                  type
                      .split('_')
                      .map(
                        (e) => e.isNotEmpty
                            ? (e[0].toUpperCase() + e.substring(1))
                            : '',
                      )
                      .join(' '),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                deleteIcon: Icon(Icons.close, size: 16.sp),
                onDeleted: () {
                  setState(() {
                    _selectedServiceTypes.remove(type);
                    if (_selectedServiceTypes.isEmpty) {
                      _localFieldErrors['serviceType'] =
                          "At least one Service Type is required";
                    }
                  });
                },
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                  side: BorderSide.none,
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
  */

  Widget _buildLocationTypeDropdown() {
    // Safety check: ensure selected value is in the options list
    if (!_locationTypes.contains(_selectedLocationType)) {
      _selectedLocationType = _locationTypes.first;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLocationType,
          dropdownColor: Theme.of(context).colorScheme.surface,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          onChanged: (String? newValue) {
            setState(() {
              _selectedLocationType = newValue!;
            });
          },
          items: _locationTypes.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPricingToggle() {
    final models = ['By Hour', 'By Day', 'By Service'];
    return Row(
      children: models.map((model) {
        bool isSelected = _selectedPricingModel == model;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedPricingModel = model;
                if (model == 'By Service' && _packageControllers.isEmpty) {
                  _packageControllers.add(PackageControllers(name: 'Starter'));
                }
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: model == models.last ? 0 : 8.w),
              padding: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.1),
                ),
              ),
              child: Text(
                model,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.surface
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: AppTypography.bodyMedium,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPricingFields() {
    if (_selectedPricingModel == 'By Hour') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Weekday Hourly Rate (EUR)', isRequired: true),
          _buildTextField(
            _weekdayHourlyRateController,
            'e.g. 50',
            errorText:
                _localFieldErrors['weekdayHourlyRate'] ??
                context
                    .watch<ServiceController>()
                    .fieldErrors['weekdayHourlyRate'],
          ),
          SizedBox(height: 15.h),
          _buildLabel('Weekend Hourly Rate (EUR)', isRequired: true),
          _buildTextField(
            _weekendHourlyRateController,
            'e.g. 75',
            errorText:
                _localFieldErrors['weekendHourlyRate'] ??
                context
                    .watch<ServiceController>()
                    .fieldErrors['weekendHourlyRate'],
          ),
        ],
      );
    } else if (_selectedPricingModel == 'By Day') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Daily Rate (EUR)', isRequired: true),
          _buildTextField(
            _dailyRateController,
            'e.g. 350',
            errorText:
                _localFieldErrors['dailyRate'] ??
                context.watch<ServiceController>().fieldErrors['dailyRate'],
          ),
          SizedBox(height: 15.h),
          _buildLabel('Hours per Day', isRequired: true),
          _buildTextField(
            _dailyHoursController,
            'e.g. 8',
            errorText:
                _localFieldErrors['dailyHours'] ??
                context.watch<ServiceController>().fieldErrors['dailyHours'],
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._packageControllers.asMap().entries.map((entry) {
            int index = entry.key;
            PackageControllers controllers = entry.value;
            return Container(
              margin: EdgeInsets.only(bottom: 20.h),
              padding: EdgeInsets.all(15.w),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.02),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Package ${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (_packageControllers.length > 1)
                        GestureDetector(
                          onTap: () => setState(
                            () => _packageControllers.removeAt(index).dispose(),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  _buildPackageField(
                    controllers.name,
                    'Package Name (e.g. Basic)',
                    isRequired: true,
                    errorText: _localFieldErrors['package_$index'],
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPackageField(
                          controllers.price,
                          'Price (EUR)',
                          isNumber: true,
                          isRequired: true,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _buildDurationDropdown(
                          controllers.duration,
                          hint: 'Duration',
                          isRequired: true,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  _buildPackageField(
                    controllers.description,
                    'Description (Short)',
                    maxLines: 2,
                    isRequired: true,
                  ),
                  SizedBox(height: 10.h),
                  _buildPackageField(
                    controllers.includes,
                    'Includes (comma separated)',
                    maxLines: 2,
                  ),
                ],
              ),
            );
          }),
          TextButton.icon(
            onPressed: () =>
                setState(() => _packageControllers.add(PackageControllers())),
            icon: const Icon(Icons.add),
            label: const Text('Add Another Package'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildPackageField(
    TextEditingController controller,
    String hint, {
    bool isNumber = false,
    int maxLines = 1,
    String? errorText,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isRequired) ...[
          _buildLabel(hint.split('(').first.trim(), isRequired: true),
        ],
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: errorText != null
                  ? Colors.red
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            onChanged: (value) =>
                setState(() {}), // Trigger rebuild for button validation
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                fontSize: AppTypography.bodyMedium,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 10.h,
              ),
            ),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: EdgeInsets.only(left: 4.w, top: 2.h),
            child: Text(
              errorText,
              style: TextStyle(color: Colors.red, fontSize: 11.sp),
            ),
          ),
      ],
    );
  }

  Widget _buildDurationDropdown(
    TextEditingController controller, {
    required String hint,
    String? errorText,
    bool isRequired = false,
  }) {
    final durationOptions = [
      {'value': '30min', 'label': '30 Minutes'},
      {'value': '45min', 'label': '45 Minutes'},
      {'value': '1',    'label': '1 Hour'},
      {'value': '1.5',  'label': '1.5 Hours'},
      {'value': '2',    'label': '2 Hours'},
      {'value': '2.5',  'label': '2.5 Hours'},
      {'value': '3',    'label': '3 Hours'},
      {'value': '4',    'label': '4 Hours'},
      {'value': '5',    'label': '5 Hours'},
      {'value': '6',    'label': '6 Hours'},
      {'value': '8',    'label': '8 Hours'},
      {'value': '10',   'label': '10 Hours'},
      {'value': '12',   'label': '12 Hours'},
    ];
    final optionValues = durationOptions.map((e) => e['value']!).toList();

    // Safety check: ensure selected value is in options or handles null
    String? effectiveValue = optionValues.contains(controller.text)
        ? controller.text
        : null;

    final dropdown = Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      height: 48.h, // Match standard text field height roughly
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: Theme.of(context).colorScheme.surface,
          hint: Text(
            hint,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              fontSize: AppTypography.bodyMedium,
            ),
          ),
          value: effectiveValue,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          onChanged: (String? newValue) {
            setState(() {
              if (newValue != null) {
                controller.text = newValue;
              }
            });
          },
          items: durationOptions.map<DropdownMenuItem<String>>((opt) {
            return DropdownMenuItem<String>(
              value: opt['value'],
              child: Text(
                opt['label']!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isRequired) ...[_buildLabel(hint, isRequired: true)],
        dropdown,
        if (errorText != null)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 14.sp),
                SizedBox(width: 6.w),
                Text(
                  errorText,
                  style: TextStyle(color: Colors.red, fontSize: 12.sp),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRadiusSlider() {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: Theme.of(context).colorScheme.onSurface,
        inactiveTrackColor: Theme.of(
          context,
        ).colorScheme.onSurface.withOpacity(0.1),
        thumbColor: Theme.of(context).colorScheme.onSurface,
        overlayColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        trackHeight: 4.h,
      ),
      child: Slider(
        min: 0,
        max: 100,
        value: _serviceRadius,
        onChanged: (val) => setState(() => _serviceRadius = val),
      ),
    );
  }

  Widget _buildAcceptOutsideRadiusToggle() {
    return GestureDetector(
      onTap: () => setState(() => _acceptOutsideRadius = !_acceptOutsideRadius),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 2.h),
            width: 18.w,
            height: 18.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _acceptOutsideRadius
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
            child: _acceptOutsideRadius
                ? Center(
                    child: Container(
                      width: 10.w,
                      height: 10.w,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Accept orders from outside location radius',
                  style: TextStyle(
                    fontSize: AppTypography.bodyLarge,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.87),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Additional travel fees may apply for bookings outside your service radius',
                  style: TextStyle(
                    fontSize: AppTypography.bodySmall,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentInput() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              ),
            ),
            child: TextField(
              controller: _equipmentController,
              decoration: InputDecoration(
                hintText: 'Canon EOS R5',
                hintStyle: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.4),
                  fontSize: AppTypography.bodyLarge,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        GestureDetector(
          onTap: () {
            if (_equipmentController.text.isNotEmpty) {
              setState(() {
                _equipment.add(_equipmentController.text.trim());
                _equipmentController.clear();
              });
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              'Add',
              style: TextStyle(
                color: Theme.of(context).colorScheme.surface,
                fontSize: AppTypography.bodyLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEquipmentList() {
    return Padding(
      padding: EdgeInsets.only(top: 10.h),
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: _equipment.map((item) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item,
                  style: TextStyle(
                    fontSize: AppTypography.bodySmall,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.87),
                  ),
                ),
                SizedBox(width: 4.w),
                GestureDetector(
                  onTap: () => setState(() => _equipment.remove(item)),
                  child: Icon(
                    Icons.close,
                    size: 14.sp,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPhotoUploadArea({String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Upload Photos & Videos', isRequired: true),
        GestureDetector(
          onTap: _showMediaPickerOptions,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 40.h),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(15.r),
              border: Border.all(
                color: errorText != null
                    ? Colors.red
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 40.sp,
                  color: errorText != null
                      ? Colors.red[300]
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.4),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Click to upload photos or videos',
                  style: TextStyle(
                    fontSize: AppTypography.bodyLarge,
                    color: errorText != null
                        ? Colors.red
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.87),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Select up to 5 high-quality files',
                  style: TextStyle(
                    fontSize: AppTypography.bodySmall,
                    color: errorText != null
                        ? Colors.red[300]
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 14.sp),
                SizedBox(width: 6.w),
                Text(
                  errorText,
                  style: TextStyle(color: Colors.red, fontSize: 12.sp),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSelectedImagesGrid() {
    final totalItems = _existingNetworkImages.length + _selectedImages.length;

    return Padding(
      padding: EdgeInsets.only(top: 15.h),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10.w,
          mainAxisSpacing: 10.h,
          childAspectRatio: 1,
        ),
        itemCount: totalItems,
        itemBuilder: (context, index) {
          final isExisting = index < _existingNetworkImages.length;
          final String? existingUrl = isExisting
              ? (_existingNetworkImages[index].startsWith('http')
                    ? _existingNetworkImages[index]
                    : "${Urls.baseUrl}${_existingNetworkImages[index]}")
              : null;
          final File? newFile = !isExisting
              ? _selectedImages[index - _existingNetworkImages.length]
              : null;

          final bool isVideoFile = isExisting
              ? (existingUrl != null && _isVideo(existingUrl))
              : (newFile != null && _isVideo(newFile.path));

          return Stack(
            children: [
              GestureDetector(
                onTap: isVideoFile
                    ? () {
                        final String path = isExisting ? existingUrl! : newFile!.path;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoPlayerScreen(videoUrl: path),
                          ),
                        );
                      }
                    : null,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: isVideoFile
                      ? Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: Colors.black87,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.play_circle_fill,
                                color: Colors.white,
                                size: 40.sp,
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                isExisting ? 'Network Video' : 'Local Video',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ],
                          ),
                        )
                      : (isExisting
                          ? Image.network(
                              existingUrl!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.error),
                              ),
                            )
                          : Image.file(
                              newFile!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            )),
                ),
              ),
              Positioned(
                top: 5,
                right: 5,
                child: GestureDetector(
                  onTap: () {
                    if (isExisting) {
                      _removeExistingImage(index);
                    } else {
                      _removeImage(index - _existingNetworkImages.length);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.surface,
                      size: 16.sp,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _normalizeServiceType(String type) {
    String normalized = type.toLowerCase().trim();
    if (normalized == 'photo') return 'photography';
    if (normalized == 'video') return 'videography';

    // Check if it's already one of the valid enums
    const validEnums = [
      'photography',
      'videography',
      'video_editing',
      'photo_editing',
      'graphic_design',
      'drone_photography',
      'event_coverage',
      'studio_rental',
    ];

    if (validEnums.contains(normalized)) return normalized;

    // Try underscore replacement for others
    normalized = normalized.replaceAll(' ', '_');
    if (validEnums.contains(normalized)) return normalized;

    // Default to photography if we can't match it (safest fallback for this app)
    return 'photography';
  }

  Widget _buildOtherServicesInput() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              ),
            ),
            child: TextField(
              controller: _otherServiceController,
              decoration: InputDecoration(
                hintText: 'e.g. Drone Videography',
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  fontSize: AppTypography.bodyLarge,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        GestureDetector(
          onTap: () {
            if (_otherServiceController.text.trim().isNotEmpty) {
              setState(() {
                _otherServices.add(_otherServiceController.text.trim());
                _otherServiceController.clear();
              });
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              'Add',
              style: TextStyle(
                color: Theme.of(context).colorScheme.surface,
                fontSize: AppTypography.bodyLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtherServicesList() {
    if (_otherServices.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.only(top: 10.h),
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: _otherServices.map((item) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item,
                  style: TextStyle(
                    fontSize: AppTypography.bodySmall,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.87),
                  ),
                ),
                SizedBox(width: 4.w),
                GestureDetector(
                  onTap: () => setState(() => _otherServices.remove(item)),
                  child: Icon(
                    Icons.close,
                    size: 14.sp,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class PackageControllers {
  final TextEditingController name;
  final TextEditingController price;
  final TextEditingController duration;
  final TextEditingController description;
  final TextEditingController includes; // Comma separated for UI

  PackageControllers({
    String name = '',
    String price = '',
    String duration = '',
    String description = '',
    String includes = '',
  }) : name = TextEditingController(text: name),
       price = TextEditingController(text: price),
       duration = TextEditingController(text: duration),
       description = TextEditingController(text: description),
       includes = TextEditingController(text: includes);

  void dispose() {
    name.dispose();
    price.dispose();
    duration.dispose();
    description.dispose();
    includes.dispose();
  }
}

class AddonControllers {
  final TextEditingController name;
  final TextEditingController price;

  AddonControllers({String name = '', String price = ''})
    : name = TextEditingController(text: name),
      price = TextEditingController(text: price);

  void dispose() {
    name.dispose();
    price.dispose();
  }
}

class AvailabilitySlotControllers {
  final TextEditingController startDate;
  final TextEditingController endDate;
  final TextEditingController rangeController;
  final TextEditingController startTime;
  final TextEditingController endTime;

  AvailabilitySlotControllers({
    String startDate = '',
    String endDate = '',
    String startTime = '',
    String endTime = '',
  }) : startDate = TextEditingController(text: startDate),
       endDate = TextEditingController(text: endDate),
       rangeController = TextEditingController(
         text: (startDate.isNotEmpty && endDate.isNotEmpty) 
           ? "$startDate to $endDate" 
           : ''
       ),
       startTime = TextEditingController(text: startTime),
       endTime = TextEditingController(text: endTime);

  void dispose() {
    startDate.dispose();
    endDate.dispose();
    rangeController.dispose();
    startTime.dispose();
    endTime.dispose();
  }
}

