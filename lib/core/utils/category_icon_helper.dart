import 'package:flutter/material.dart';

class CategoryIconHelper {
  static IconData getIcon(String? categoryName) {
    if (categoryName == null) return Icons.category_outlined;

    final name = categoryName.toUpperCase();

    if (name.contains('WEDDING')) return Icons.celebration_outlined;
    if (name.contains('CORPORATE')) return Icons.business_center_outlined;
    if (name.contains('REAL ESTATE')) return Icons.apartment_outlined;
    if (name.contains('FASHION')) return Icons.checkroom_outlined;
    if (name.contains('EVENT')) return Icons.event_available_outlined;
    if (name.contains('PORTRAIT')) return Icons.face_outlined;
    if (name.contains('NATURE')) return Icons.nature_people_outlined;
    if (name.contains('SPORT')) return Icons.sports_basketball_outlined;
    if (name.contains('FOOD')) return Icons.restaurant_outlined;
    if (name.contains('TRAVEL')) return Icons.flight_takeoff_outlined;
    if (name.contains('PRODUCT')) return Icons.inventory_2_outlined;
    if (name.contains('DRONE')) return Icons.toys_outlined;
    if (name.contains('BABY') || name.contains('KIDS')) return Icons.child_care_outlined;
    if (name.contains('PET')) return Icons.pets_outlined;
    if (name.contains('MUSIC')) return Icons.music_note_outlined;
    if (name.contains('BEAUTY')) return Icons.brush_outlined;
    if (name.contains('AUTOMOTIVE') || name.contains('CAR')) return Icons.directions_car_outlined;
    
    // Default icons for main themes if they come as categories
    if (name.contains('PHOTOGRAPHY')) return Icons.camera_alt_outlined;
    if (name.contains('VIDEOGRAPHY')) return Icons.videocam_outlined;
    if (name.contains('EDITING')) return Icons.video_settings_outlined;

    return Icons.grid_view_outlined;
  }
}
