import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../core/config/api_config.dart';

class UploadService {
  final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  /// Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error capturing image: $e');
      return null;
    }
  }

  /// Pick video from gallery
  Future<File?> pickVideoFromGallery() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      );
      if (video != null) {
        return File(video.path);
      }
      return null;
    } catch (e) {
      print('Error picking video: $e');
      return null;
    }
  }

  /// Pick video from camera
  Future<File?> pickVideoFromCamera() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 10),
      );
      if (video != null) {
        return File(video.path);
      }
      return null;
    } catch (e) {
      print('Error capturing video: $e');
      return null;
    }
  }

  /// Upload image to server
  Future<Map<String, dynamic>?> uploadImage(File imageFile, {String folder = 'crick11'}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/upload/image');
      
      final request = http.MultipartRequest('POST', uri);
      request.fields['folder'] = folder;
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = response.body;
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Upload failed: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error uploading image: $e',
      };
    }
  }

  /// Upload video to server
  Future<Map<String, dynamic>?> uploadVideo(File videoFile, {String folder = 'cric11/videos'}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/upload/video');
      
      final request = http.MultipartRequest('POST', uri);
      request.fields['folder'] = folder;
      request.files.add(await http.MultipartFile.fromPath('video', videoFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.body,
        };
      } else {
        return {
          'success': false,
          'message': 'Upload failed: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error uploading video: $e',
      };
    }
  }

  /// Upload multiple images
  Future<Map<String, dynamic>?> uploadMultipleImages(List<File> imageFiles, {String folder = 'crick11'}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/upload/images');
      
      final request = http.MultipartRequest('POST', uri);
      request.fields['folder'] = folder;

      for (var file in imageFiles) {
        request.files.add(await http.MultipartFile.fromPath('images', file.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.body,
        };
      } else {
        return {
          'success': false,
          'message': 'Upload failed: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error uploading images: $e',
      };
    }
  }

  /// Delete file from server
  Future<Map<String, dynamic>?> deleteFile(String publicId) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/upload/delete');
      
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: {'publicId': publicId},
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'message': 'Delete failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error deleting file: $e'};
    }
  }
}
