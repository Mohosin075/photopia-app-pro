import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'dart:io';
import 'package:photopya/core/widgets/exif_aware_network_image.dart';
import 'package:photopya/core/network/urls.dart';

class FullScreenImageViewer extends StatelessWidget {
  final String? imageUrl;
  final String? filePath;
  final ImageProvider? imageProvider; // Fallback
  final String? tag;

  const FullScreenImageViewer({
    super.key,
    this.imageUrl,
    this.filePath,
    this.imageProvider,
    this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Interactive Viewer for zoom and pan
          Center(
            child: Hero(
              tag: tag ?? 'image_hero_${imageUrl ?? filePath ?? imageProvider.hashCode}',
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: _buildImage(),
              ),
            ),
          ),
          
          // Close button
          Positioned(
            top: 40.h,
            right: 20.w,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    final bool hasImageUrl = imageUrl != null && imageUrl!.isNotEmpty && imageUrl != 'null';
    final bool hasFilePath = filePath != null && filePath!.isNotEmpty;

    if (hasImageUrl) {
      if (imageUrl!.startsWith('assets/')) {
        return Image.asset(
          imageUrl!,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => _buildEmptyState(),
        );
      }
      final String fullUrl = imageUrl!.startsWith('http') ? imageUrl! : '${Urls.baseUrl}$imageUrl';
      return ExifAwareNetworkImage(
        url: fullUrl,
        height: double.infinity,
        width: double.infinity,
        fit: BoxFit.contain,
      );
    } else if (hasFilePath) {
      if (filePath!.startsWith('assets/')) {
        return Image.asset(
          filePath!,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => _buildEmptyState(),
        );
      }
      return Image.file(
        File(filePath!),
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildEmptyState(),
      );
    } else if (imageProvider != null) {
      return Image(
        image: imageProvider!,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildEmptyState(),
      );
    }
    return _buildEmptyState();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person,
            color: Colors.white.withOpacity(0.5),
            size: 100.sp,
          ),
          SizedBox(height: 16.h),
          Text(
            'No profile picture',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
