import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageUtils {
  /// Compresses an image and fixes its orientation based on EXIF data.
  static Future<File> fixImageOrientation(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final String fileName = p.basename(file.path);
      final String targetPath = p.join(tempDir.path, '${DateTime.now().millisecondsSinceEpoch}_$fileName');

      final XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 80,
        rotate: 0,
        autoCorrectionAngle: true, // This is the key to fixing rotation
        format: CompressFormat.jpeg,
      );

      if (compressedFile != null) {
        return File(compressedFile.path);
      }
    } catch (e) {
      print('Error fixing image orientation: $e');
    }
    return file; // Return original if processing fails
  }

  /// Processes a list of images to fix their orientation.
  static Future<List<File>> fixImagesOrientation(List<File> files) async {
    List<File> processedFiles = [];
    for (var file in files) {
      processedFiles.add(await fixImageOrientation(file));
    }
    return processedFiles;
  }
}
