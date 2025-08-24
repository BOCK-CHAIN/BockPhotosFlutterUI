import 'package:flutter/material.dart';
import '../services/photo_service.dart';
import '../services/api_client.dart';
import '../services/token_store.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  bool _uploading = false;
  late final PhotoService _photoService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() {
    final tokenStore = TokenStore();
    final apiClient = ApiClient(tokenStore);
    _photoService = PhotoService(apiClient);
  }

  void _pickAndUpload() async {
    final file = await _photoService.pickFile();
    if (file == null) return;

    setState(() => _uploading = true);
    try {
      await _photoService.uploadPhoto(file);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload successful')));
      Navigator.pushReplacementNamed(context, '/gallery');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Photo')),
      body: Center(
        child: _uploading
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
                onPressed: _pickAndUpload,
                icon: const Icon(Icons.upload),
                label: const Text('Select and Upload Photo'),
              ),
      ),
    );
  }
}