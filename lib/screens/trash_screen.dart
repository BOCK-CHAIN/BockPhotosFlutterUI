import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/photo_service.dart';
import '../services/token_store.dart';
import '../widgets/photo_tile.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  late final PhotoService _photoService;
  List<PhotoItem> _photos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _photoService = PhotoService(ApiClient(TokenStore()));
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _photoService.listTrash();
      if (!mounted) return;
      setState(() {
        _photos = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _restore(String id) async {
    await _photoService.restoreFromTrash(id);
    await _load();
  }

  Future<void> _deleteForever(String id) async {
    await _photoService.delete(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trash')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _photos.isEmpty
              ? const Center(child: Text('Trash is empty'))
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _photos.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final p = _photos[index];
                    return Stack(
                      children: [
                        PhotoTile(
                          imageUrl: p.url,
                          photoId: p.id,
                          fileKey: p.fileKey,
                          photoService: _photoService,
                          onDelete: () => _deleteForever(p.id),
                        ),
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: ElevatedButton.icon(
                            onPressed: () => _restore(p.id),
                            icon: const Icon(Icons.restore, size: 16),
                            label: const Text('Restore'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B2D8B), foregroundColor: Colors.white),
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}
