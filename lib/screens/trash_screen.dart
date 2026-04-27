import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/photo_service.dart';
import '../services/token_store.dart';
import '../widgets/photo_tile.dart';
import 'photo_viewer_screen.dart';

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

  Future<void> _showTrashActions(PhotoItem photo) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Restore'),
              onTap: () => Navigator.pop(context, 'restore'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Delete Permanently'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (action == 'restore') {
      await _restore(photo.id);
    } else if (action == 'delete') {
      await _deleteForever(photo.id);
    }
  }

  int _gridColumns(double width) {
    if (width < 600) return 3;
    if (width < 1024) return 4;
    if (width < 1440) return 6;
    return 8;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trash')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _photos.isEmpty
          ? const Center(child: Text('Trash is empty'))
          : LayoutBuilder(
              builder: (context, constraints) {
                final columns = _gridColumns(constraints.maxWidth);
                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _photos.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final p = _photos[index];
                    return PhotoTile(
                      imageUrl: p.thumbnailUrl ?? p.url,
                      photoId: p.id,
                      fileKey: p.fileKey,
                      photoService: _photoService,
                      thumbnailCacheWidth: 400,
                      isTrashView: true,
                      onRestore: () => _restore(p.id),
                      onDelete: () => _deleteForever(p.id),
                      onLongPress: () => _showTrashActions(p),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PhotoViewerScreen(
                              photos: _photos,
                              initialIndex: index,
                              photoService: _photoService,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
