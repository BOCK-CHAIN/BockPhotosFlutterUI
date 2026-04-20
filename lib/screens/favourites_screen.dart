import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/photo_service.dart';
import '../services/token_store.dart';
import '../widgets/photo_tile.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favourites')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _photos.isEmpty
              ? const Center(child: Text('No starred photos yet'))
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
                    return PhotoTile(
                      imageUrl: p.url,
                      photoId: p.id,
                      fileKey: p.fileKey,
                      photoService: _photoService,
                      isStarred: p.isStarred,
                      onToggleStar: () => _toggle(p),
                    );
                  },
                ),
    );
  }
}
