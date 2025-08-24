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

class PresignResult {
  final Uri putUrl;
  final String objectKey;

  PresignResult({required this.putUrl, required this.objectKey});
}

class PhotoService {
  final ApiClient _api;

  PhotoService(this._api);

  Future<List<PhotoItem>> list() async {
    final resp = await _api.get('/photos');
    if (resp.statusCode != 200) {
      throw Exception('Failed to list photos: ${resp.statusCode}');
    }
    final data = jsonDecode(resp.body) as List;
    return data.map((e) => PhotoItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Returns presigned PUT URL and object key
  Future<PresignResult> presignUpload(String filename, String mime) async {
    final resp = await _api.post(
      '/photos/presign-upload',
      body: jsonEncode({'filename': filename, 'mime': mime}),
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to presign upload: ${resp.statusCode}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final url = Uri.parse(data['put_url'] as String);
    final key = data['object_key'] as String;
    return PresignResult(putUrl: url, objectKey: key);
  }

  /// Uploads raw bytes to S3 via presigned URL
  Future<void> uploadToS3(Uri putUrl, Uint8List bytes, {String? contentType}) async {
    final resp = await http.put(
      putUrl,
      headers: {
        if (contentType != null) 'Content-Type': contentType,
      },
      body: bytes,
    );
    if (resp.statusCode != 200) {
      throw Exception('Upload failed with status ${resp.statusCode}');
    }
  }

  Future<void> confirmUpload(String objectKey, int size) async {
    final resp = await _api.post(
      '/photos/confirm',
      body: jsonEncode({'object_key': objectKey, 'size': size}),
    );
    if (resp.statusCode != 200) {
      throw Exception('Confirm failed: ${resp.statusCode}');
    }
  }

  Future<void> delete(String photoId) async {
    final resp = await _api.delete('/photos/$photoId');
    if (resp.statusCode != 200) {
      throw Exception('Delete failed: ${resp.statusCode}');
    }
  }

  Future<PlatformFile?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    return result?.files.firstOrNull;
  }

  Future<void> uploadPhoto(PlatformFile file) async {
    if (file.bytes == null) {
      throw Exception('File bytes are null');
    }

    final presignResult = await presignUpload(file.name, file.extension ?? '');
    await uploadToS3(presignResult.putUrl, file.bytes!, contentType: file.extension);
    await confirmUpload(presignResult.objectKey, file.size);
  }

  Future<List<Map<String, dynamic>>> listPhotos() async {
    final photos = await list();
    return photos.map((photo) => {
      'id': photo.id,
      'url': photo.url,
      'filename': photo.filename,
      'size': photo.size,
      'created_at': photo.createdAt.toIso8601String(),
    }).toList();
  }

  Future<void> deletePhoto(String id) async {
    await delete(id);
  }
}