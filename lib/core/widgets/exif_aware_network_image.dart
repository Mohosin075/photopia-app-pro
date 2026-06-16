import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

/// A network image widget with disk caching and shimmer loading placeholder.
/// Replaces the previous manual HTTP+compress approach for fast, cached loading.
class ExifAwareNetworkImage extends StatelessWidget {
  final String url;
  final double height;
  final double width;
  final BoxFit fit;
  final Map<String, String>? headers;
  final Widget? errorPlaceholder;

  const ExifAwareNetworkImage({
    super.key,
    required this.url,
    required this.height,
    required this.width,
    this.fit = BoxFit.cover,
    this.headers,
    this.errorPlaceholder,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      httpHeaders: headers,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: height,
          width: width,
          color: Colors.white,
        ),
      ),
      errorWidget: (context, url, error) {
        if (errorPlaceholder != null) return errorPlaceholder!;
        return SizedBox(
          height: height,
          width: width,
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          ),
        );
      },
    );
  }
}
