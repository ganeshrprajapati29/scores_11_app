import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';
import '../../core/utils/friendly_error.dart';

class UploadService {
  final ApiClient _apiClient = ApiClient();
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
      return image != null ? File(image.path) : null;
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
      return image != null ? File(image.path) : null;
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
      return video != null ? File(video.path) : null;
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
      return video != null ? File(video.path) : null;
    } catch (e) {
      print('Error capturing video: $e');
      return null;
    }
  }

  /// Upload image to server
  Future<Map<String, dynamic>?> uploadImage(File imageFile, {String folder = 'crick11'}) async {
    try {
      final formData = FormData.fromMap({
        'folder': folder,
        'image': await MultipartFile.fromFile(imageFile.path),
      });

      final response = await _apiClient.uploadFile('${ApiConfig.upload}/image', formData: formData);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data['data'],
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Upload failed: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _handleDioError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': friendlyError(e, fallback: 'Could not upload the image.'),
      };
    }
  }

  /// Upload video to server
  Future<Map<String, dynamic>?> uploadVideo(File videoFile, {String folder = 'crick11/videos'}) async {
    try {
      final formData = FormData.fromMap({
        'folder': folder,
        'video': await MultipartFile.fromFile(videoFile.path),
      });

      final response = await _apiClient.uploadFile('${ApiConfig.upload}/video', formData: formData);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data['data'],
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Upload failed: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _handleDioError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': friendlyError(e, fallback: 'Could not upload the video.'),
      };
    }
  }

  /// Upload multiple images
  Future<Map<String, dynamic>?> uploadMultipleImages(List<File> imageFiles, {String folder = 'crick11'}) async {
    try {
      final formData = FormData.fromMap({
        'folder': folder,
      });
      
      for (var file in imageFiles) {
        formData.files.add(MapEntry('images', await MultipartFile.fromFile(file.path)));
      }

      final response = await _apiClient.uploadFile('${ApiConfig.upload}/images', formData: formData);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data['data'],
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Upload failed: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _handleDioError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': friendlyError(e, fallback: 'Could not upload the images.'),
      };
    }
  }

  /// Delete file from server
  Future<Map<String, dynamic>?> deleteFile(String publicId) async {
    try {
      final response = await _apiClient.post('${ApiConfig.upload}/delete', data: {'publicId': publicId});
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {'success': false, 'message': 'Delete failed'};
      }
    } on DioException catch (e) {
      return {'success': false, 'message': _handleDioError(e)};
    } catch (e) {
      return {'success': false, 'message': friendlyError(e, fallback: 'Could not delete the file.')};
    }
  }

  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet.';
      case DioExceptionType.badResponse:
        return e.response?.data['message'] ?? 'Server error (${e.response?.statusCode})';
      case DioExceptionType.cancel:
        return 'Upload cancelled';
      case DioExceptionType.connectionError:
        return 'No internet connection';
      default:
        return e.message ?? 'Upload failed';
    }
  }
}
