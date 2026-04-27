import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/photo_service.dart';
import '../services/token_store.dart';
import '../widgets/photo_tile.dart';
import 'photo_viewer_screen.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
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
      final items = await _photoService.listFavourites();
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

  Future<void> _toggle(PhotoItem item) async {
    await _photoService.setStarred(item.id, !item.isStarred);
    await _load();
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
      appBar: AppBar(title: const Text('Favourites')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _photos.isEmpty
          ? const Center(child: Text('No starred photos yet'))
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
                      isStarred: p.isStarred,
                      onToggleStar: () => _toggle(p),
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
