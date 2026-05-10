import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photopia/core/localization/app_localizations.dart';

class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key});
  static const String name = "search-filter";

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  final TextEditingController _locationController = TextEditingController(
    text: 'Barcelona, Spain',
  );
  double _radius = 200;
  RangeValues _budgetRange = const RangeValues(0, 5000);
  bool _showFavoritesOnly = false;

  final List<String> _serviceTypes = [
    'Photography',
    'Videography',
    'Wedding',
    'Corporate',
    'Portrait',
    'Product',
    'Fashion',
    'Real Estate',
    'Event',
    'Aerial/Drone',
  ];
  final Set<String> _selectedServices = {'Photography'};

  final List<String> _equipments = [
    'DSLR',
    'Mirrorless',
    'Drone',
    '4K Video',
    'Studio Lighting',
    'Smartphone',
    'Cinema Camera',
    'Gimbal/Stabilizer',
  ];
  final Set<String> _selectedEquipments = {'DSLR'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.l10n.navSearch,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18.sp.clamp(18, 20),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context.l10n.location),
            SizedBox(height: 10.h),
            _buildTextField(
              controller: _locationController,
              hint: context.l10n.searchLocationHint,
              prefixIcon: Icons.location_on_outlined,
            ),
            SizedBox(height: 20.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_buildSectionTitle(context.l10n.radius(_radius.toInt()))],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4.h,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.r),
                overlayShape: RoundSliderOverlayShape(overlayRadius: 16.r),
                activeTrackColor: Theme.of(context).colorScheme.primary,
                inactiveTrackColor: Theme.of(context).dividerColor.withOpacity(0.1),
                thumbColor: Theme.of(context).colorScheme.primary,
              ),
              child: Slider(
                value: _radius,
                min: 0,
                max: 500,
                onChanged: (value) {
                  setState(() => _radius = value);
                },
              ),
            ),
            SizedBox(height: 20.h),

            _buildSectionTitle(
              context.l10n.budget(_budgetRange.start.round(), _budgetRange.end.round()),
            ),
            SizedBox(height: 10.h),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4.h,
                rangeThumbShape: const RoundRangeSliderThumbShape(
                  enabledThumbRadius: 8,
                ),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                activeTrackColor: Theme.of(context).colorScheme.primary,
                inactiveTrackColor: Theme.of(context).dividerColor.withOpacity(0.1),
                thumbColor: Theme.of(context).colorScheme.primary,
              ),
              child: RangeSlider(
                values: _budgetRange,
                min: 0,
                max: 5000,
                divisions: 100,
                labels: RangeLabels(
                  '€${_budgetRange.start.round()}',
                  '€${_budgetRange.end.round()}',
                ),
                onChanged: (values) {
                  setState(() => _budgetRange = values);
                },
              ),
            ),
            SizedBox(height: 25.h),

            _buildSectionTitle(context.l10n.typeOfService),
            SizedBox(height: 10.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: _serviceTypes
                  .map(
                    (service) => _buildFilterChip(
                      label: service,
                      isSelected: _selectedServices.contains(service),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedServices.add(service);
                          } else {
                            _selectedServices.remove(service);
                          }
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
            SizedBox(height: 25.h),

            _buildSectionTitle(context.l10n.equipmentUsed),
            SizedBox(height: 10.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: _equipments
                  .map(
                    (equipment) => _buildFilterChip(
                      label: equipment,
                      isSelected: _selectedEquipments.contains(equipment),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedEquipments.add(equipment);
                          } else {
                            _selectedEquipments.remove(equipment);
                          }
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
            SizedBox(height: 40.h),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedServices.clear();
                        _selectedEquipments.clear();
                        _radius = 200;
                        _showFavoritesOnly = false;
                        _locationController.text = '';
                        _budgetRange = const RangeValues(0, 5000);
                      });
                      Navigator.pop(
                        context,
                      ); // Optional: if "clear all" should also go back
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      side: BorderSide.none,
                      padding: EdgeInsets.symmetric(vertical: 15.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10).r,
                      ),
                    ),
                    child: Text(
                      context.l10n.clearAll,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16.sp.clamp(16, 18),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 15.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Apply filters logic
                      Navigator.pop(context, {
                        'location': _locationController.text,
                        'radius': _radius,
                        'minPrice': _budgetRange.start.round(),
                        'maxPrice': _budgetRange.end.round(),
                        'serviceType': _selectedServices
                            .map((s) => s.toLowerCase())
                            .toList(),
                        'equipments': _selectedEquipments.toList(),
                        'favoritesOnly': _showFavoritesOnly,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: EdgeInsets.symmetric(vertical: 15.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10).r,
                      ),
                    ),
                    child: Text(
                      context.l10n.applyFilters,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 16.sp.clamp(16, 18),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15.sp.clamp(15, 17),
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? prefixIcon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10).r,
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: Colors.grey, size: 20.sp)
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 15.w,
            vertical: 12.h,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required Function(bool) onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedColor: Theme.of(context).colorScheme.primary,
      checkmarkColor: Theme.of(context).colorScheme.onPrimary,
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
        fontSize: 13.sp.clamp(13, 15),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10).r,
        side: BorderSide(
          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor.withOpacity(0.1),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
    );
  }
}
