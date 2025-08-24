import 'package:flutter/material.dart';
import '../services/photo_service.dart';
import '../services/api_client.dart';
import '../services/token_store.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<Map<String, dynamic>> _photos = [];
  bool _loading = true;
  late final PhotoService _photoService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _fetchPhotos();
  }

  void _initializeServices() {
    final tokenStore = TokenStore();
    final apiClient = ApiClient(tokenStore);
    _photoService = PhotoService(apiClient);
  }

  Future<void> _fetchPhotos() async {
    setState(() => _loading = true);
    try {
      final photos = await _photoService.listPhotos();
      if (!mounted) return;
      setState(() {
        _photos = photos;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _delete(String id) async {
    try {
      await _photoService.deletePhoto(id);
      if (!mounted) return;
      await _fetchPhotos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  void _goToUpload() {
    Navigator.pushNamed(context, '/upload');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
        actions: [
          IconButton(icon: const Icon(Icons.add_a_photo), onPressed: _goToUpload),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _photos.length,
              itemBuilder: (context, index) {
                final photo = _photos[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(photo['url'], fit: BoxFit.cover),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _delete(photo['id']),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
