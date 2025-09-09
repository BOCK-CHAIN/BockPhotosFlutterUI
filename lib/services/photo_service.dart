import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'api_client.dart';

class PhotoItem {
  final String id;
  final String url;
  final String filename;
  final int size;
  final DateTime createdAt;

  PhotoItem({
    required this.id,
    required this.url,
    required this.filename,
    required this.size,
    required this.createdAt,
  });

  factory PhotoItem.fromJson(Map<String, dynamic> json) {
    return PhotoItem(
      id: json['id'] as String,
      url: json['url'] as String,
      filename: json['filename'] as String,
      size: json['size'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class UploadUrlResult {
  final Uri uploadUrl;
  final String photoId;

  UploadUrlResult({required this.uploadUrl, required this.photoId});
}

class PhotoService {
  final ApiClient _api;

  PhotoService(this._api);

  Future<List<PhotoItem>> list() async {
    final resp = await _api.get('/photos');
    if (resp.statusCode != 200) {
      throw Exception('Failed to list photos: ${resp.statusCode}');
    }
    final decoded = jsonDecode(resp.body);
    final list = decoded is Map<String, dynamic>
        ? (decoded['data'] as List? ?? [])
        : (decoded as List);
    return list.map((e) => PhotoItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Get upload URL for photo
  Future<UploadUrlResult> getUploadUrl(String filename, String contentType) async {
    final resp = await _api.post(
      '/photos/upload-url',
      body: jsonEncode({
        'filename': filename,
        'contentType': contentType,
      }),
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to get upload URL: ${resp.statusCode}');
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final data = (body['data'] as Map<String, dynamic>?) ?? body;
    final url = Uri.parse(data['url'] as String);
    final photoId = (data['photoId'] ?? data['photo_id']) as String;
    return UploadUrlResult(uploadUrl: url, photoId: photoId);
  }

  /// Upload photo to the provided URL
  Future<void> uploadPhoto(Uri uploadUrl, Uint8List bytes, {String? contentType}) async {
    final resp = await http.put(
      uploadUrl,
      headers: {
        if (contentType != null) 'Content-Type': contentType,
      },
      body: bytes,
    );
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception('Upload failed with status ${resp.statusCode}');
    }
  }

  /// Update photo metadata
  Future<void> updatePhoto(String photoId, Map<String, dynamic> updates) async {
    final resp = await _api.put(
      '/photos/$photoId',
      body: jsonEncode(updates),
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to update photo: ${resp.statusCode}');
    }
  }

  /// Delete photo
  Future<void> delete(String photoId) async {
    final resp = await _api.delete('/photos/$photoId');
    if (resp.statusCode != 200) {
      throw Exception('Delete failed: ${resp.statusCode}');
    }
  }

  /// Pick file from device
  Future<PlatformFile?> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        return result.files.first;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick file: $e');
    }
  }

  /// Complete photo upload process
  Future<PhotoItem> uploadPhotoFromFile(PlatformFile file) async {
    try {
      const maxBytes = 50 * 1024 * 1024;
      if (file.size > maxBytes) {
        throw Exception('File exceeds 50MB limit');
      }
      // Get upload URL
      final contentType = file.extension != null ? 'image/${file.extension}' : 'application/octet-stream';
      final uploadResult = await getUploadUrl(file.name, contentType);
      
      // Upload the file
      await uploadPhoto(
        uploadResult.uploadUrl,
        file.bytes!,
        contentType: contentType,
      );
      
      // Update photo metadata
      await updatePhoto(uploadResult.photoId, {
        'filename': file.name,
        'size': file.size,
      });
      
      // Return the uploaded photo
      return PhotoItem(
        id: uploadResult.photoId,
        url: uploadResult.uploadUrl.toString(),
        filename: file.name,
        size: file.size,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }
}