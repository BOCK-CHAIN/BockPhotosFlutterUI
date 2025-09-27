import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'api_client.dart';
import '../config.dart';

class PhotoItem {
  final String id;
  final String url;
  final String filename;
  final int size;
  final DateTime createdAt;
  final String? fileKey; // S3 object key for authenticated URLs

  PhotoItem({
    required this.id,
    required this.url,
    required this.filename,
    required this.size,
    required this.createdAt,
    this.fileKey,
  });

  factory PhotoItem.fromJson(Map<String, dynamic> json) {
    // Backend returns DB columns (file_key, original_name, content_type, file_size, created_at)
    final fileKey = json['file_key'] as String?;
    final url = json['url'] as String? ??
        (AppConfig.publicBucketBaseUrl.isNotEmpty && fileKey != null
            ? '${AppConfig.publicBucketBaseUrl}/$fileKey'
            : '');
    final createdRaw = json['created_at'];
    final createdAt = DateTime.tryParse(createdRaw?.toString() ?? '') ?? DateTime.now();
    final sizeRaw = json['file_size'] ?? json['size'] ?? 0;
    final size = sizeRaw is int ? sizeRaw : int.tryParse(sizeRaw.toString()) ?? 0;
    return PhotoItem(
      id: (json['id'] ?? json['photoId'] ?? json['photo_id']).toString(),
      url: url,
      filename: (json['original_name'] ?? json['filename'] ?? '').toString(),
      size: size,
      createdAt: createdAt,
      fileKey: fileKey,
    );
  }
}

class UploadUrlResult {
  final Uri uploadUrl;
  final String? photoId; // optional depending on backend
  final String? fileKey; // S3 object key

  UploadUrlResult({required this.uploadUrl, this.photoId, this.fileKey});
}

class PhotoService {
  final ApiClient _api;

  PhotoService(this._api);

  Future<List<PhotoItem>> list() async {
    final resp = await _api.get('/photos');
    if (resp.statusCode != 200) {
      final body = resp.body;
      throw Exception('Failed to list photos: ${resp.statusCode}${body.isNotEmpty ? ' - ' + body : ''}');
    }
    final decoded = jsonDecode(resp.body);
    // Backend returns { photos: [...], pagination: {...} }
    final list = decoded is Map<String, dynamic>
        ? (decoded['photos'] as List? ?? [])
        : (decoded as List);
    return list.map((e) => PhotoItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Get upload URL for photo
  Future<UploadUrlResult> getUploadUrl(String filename, String contentType, int fileSize) async {
    final resp = await _api.post(
      '/photos/upload-url',
      body: jsonEncode({
        'filename': filename,
        'contentType': contentType,
        'fileSize': fileSize,
      }),
    );

    if (resp.statusCode != 200) {
      final body = resp.body;
      throw Exception(
          'Failed to get upload URL: ${resp.statusCode}${body.isNotEmpty ? ' - ' + body : ''}');
    }

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final data = (body['data'] as Map<String, dynamic>?) ?? body;

    // Upload URL
    final urlStr = (data['uploadUrl'] ?? data['url'])?.toString();
    if (urlStr == null || urlStr.isEmpty) {
      throw Exception('Upload URL missing in response: $data');
    }
    final url = Uri.parse(urlStr);

    // Photo ID optional, fileKey provided by backend
    final photoId = (data['photoId'] ?? data['photo_id'])?.toString();
    final fileKey = data['fileKey']?.toString();

    return UploadUrlResult(uploadUrl: url, photoId: photoId, fileKey: fileKey);
  }


  /// Upload photo to the provided URL
  Future<void> uploadPhoto(Uri uploadUrl, Uint8List bytes, {String? contentType}) async {
    // Debug prints for troubleshooting web uploads
    // ignore: avoid_print
    print('Uploading to: $uploadUrl');
    // ignore: avoid_print
    print('Bytes length: ${bytes.length}');
    // ignore: avoid_print
    print('Content-Type: ${contentType ?? 'none'}');

    // Only include Content-Type if the presigned URL actually signed it.
    // Otherwise S3 can reject with SignatureDoesNotMatch if headers differ from the signature.
    final signedHeadersRaw = uploadUrl.queryParameters['X-Amz-SignedHeaders']
        ?? uploadUrl.queryParameters['x-amz-signedheaders'];
    final signedHeaders = (signedHeadersRaw ?? '').toLowerCase();
    final signedHeaderSet = signedHeaders
        .split(';')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet();
    final headers = <String, String>{};
    if (contentType != null && signedHeaderSet.contains('content-type')) {
      headers['Content-Type'] = contentType;
    }
    // Forward x-amz-meta-* headers that were part of the signature
    uploadUrl.queryParameters.forEach((k, v) {
      final lower = k.toLowerCase();
      if (lower.startsWith('x-amz-meta-') && signedHeaderSet.contains(lower)) {
        headers[k] = v;
      }
      // Common optional signed headers we may need to forward
      if ((lower == 'x-amz-acl' || lower == 'x-amz-storage-class') && signedHeaderSet.contains(lower)) {
        headers[k] = v;
      }
    });

    final resp = await http.put(
      uploadUrl,
      headers: headers,
      body: bytes,
    );
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      final respBody = resp.body;
      throw Exception('S3 upload failed: ${resp.statusCode}${respBody.isNotEmpty ? ' - ' + respBody : ''}');
    }
  }

  /// Update photo metadata
  Future<void> updatePhoto(String photoId, Map<String, dynamic> updates) async {
    final resp = await _api.put('/photos/$photoId', body: jsonEncode(updates));
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

  /// Get authenticated view URL for a photo using S3 key
  Future<String> getViewUrl(String s3Key) async {
    try {
      final resp = await _api.get('/photos/view-url', query: {'key': s3Key});
      if (resp.statusCode != 200) {
        final body = resp.body;
        throw Exception('Failed to get view URL: ${resp.statusCode}${body.isNotEmpty ? ' - ' + body : ''}');
      }
      
      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      final viewUrl = decoded['viewUrl'] ?? decoded['url'] ?? decoded['data']?['viewUrl'] ?? decoded['data']?['url'];
      
      if (viewUrl == null || viewUrl.toString().isEmpty) {
        throw Exception('View URL not found in response');
      }
      
      return viewUrl.toString();
    } catch (e) {
      // If all else fails, rethrow the original error
      throw Exception('Unable to get authenticated URL for S3 key $s3Key: ${e.toString()}');
    }
  }

  /// Optionally inform backend to persist metadata after successful S3 upload
  Future<PhotoItem?> _finalizeUpload({
    String? fileKey,
    required String originalName,
    required String contentType,
    required int fileSize,
  }) async {
    // If the backend exposes an endpoint to persist metadata (e.g., POST /api/photos),
    // implement it here. Since your shared backend does not show it, we no-op unless fileKey is provided.
    if (fileKey == null) return null;
    try {
      final resp = await _api.post(
        '/photos',
        body: jsonEncode({
          'fileKey': fileKey,
          'originalName': originalName,
          'contentType': contentType,
          'fileSize': fileSize,
        }),
      );
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final photoJson = (data['photo'] as Map<String, dynamic>?) ?? data;
        return PhotoItem.fromJson(photoJson);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Pick file from device
  Future<PlatformFile?> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // required on Web so bytes are available
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
      if (file.bytes == null) {
        throw Exception('No file data available for upload');
      }

      // Detect content type (important for S3 presigned URLs)
      String? detected = lookupMimeType(
        file.name,
        headerBytes: file.bytes!.length >= 12 ? file.bytes!.sublist(0, 12) : file.bytes!,
      );
      // Some cameras use jpg extension but require image/jpeg
      if (detected == null && file.extension != null) {
        detected = 'image/${file.extension}';
      }
      final contentType = detected ?? 'application/octet-stream';

      // Get upload URL with the same contentType used for PUT
      final uploadResult = await getUploadUrl(file.name, contentType, file.size);
      
      // Debug before upload
      // ignore: avoid_print
      print('Presigned URL: ${uploadResult.uploadUrl}');
      // ignore: avoid_print
      print('Uploading ${file.name} (${file.size} bytes)');

      // Upload the file
      await uploadPhoto(
        uploadResult.uploadUrl,
        file.bytes!,
        contentType: contentType,
      );
      
      // Persist in backend if endpoint exists (POST /photos). If not available, fall back to constructing URL
      try {
        final created = await _finalizeUpload(
          fileKey: uploadResult.fileKey,
          originalName: file.name,
          contentType: contentType,
          fileSize: file.size,
        );
        if (created != null) {
          return created;
        }
      } catch (_) {
        // If finalize not available or fails, proceed to fallback
      }

      // Fallback: construct a displayable item using fileKey/public base URL
      String url = uploadResult.uploadUrl.toString();
      if (uploadResult.fileKey != null && AppConfig.publicBucketBaseUrl.isNotEmpty) {
        url = '${AppConfig.publicBucketBaseUrl}/${uploadResult.fileKey}';
      }

      return PhotoItem(
        id: uploadResult.photoId ?? uploadResult.fileKey ?? DateTime.now().millisecondsSinceEpoch.toString(),
        url: url,
        filename: file.name,
        size: file.size,
        createdAt: DateTime.now(),
        fileKey: uploadResult.fileKey,
      );
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }
}