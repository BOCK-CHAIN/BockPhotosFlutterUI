import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/photo_service.dart';
import '../services/token_store.dart';
import '../widgets/photo_tile.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  late final PhotoService _photoService;
  List<CollectionItem> _collections = [];
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
      final collections = await _photoService.listCollections();
      final photos = await _photoService.list();
      if (!mounted) return;
      setState(() {
        _collections = collections;
        _photos = photos;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _createCollection() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New collection'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Collection name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Create')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await _photoService.createCollection(name);
    await _load();
  }

  Future<void> _addPhotos(String collectionId) async {
    final selected = <String>{};
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add photos'),
        content: SizedBox(
          width: 360,
          height: 360,
          child: StatefulBuilder(
            builder: (context, setInner) => GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              children: _photos
                  .map((p) => GestureDetector(
                        onTap: () => setInner(() {
                          if (selected.contains(p.id)) {
                            selected.remove(p.id);
                          } else {
                            selected.add(p.id);
                          }
                        }),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            PhotoTile(imageUrl: p.url, photoId: p.id, fileKey: p.fileKey, photoService: _photoService),
                            if (selected.contains(p.id))
                              Container(
                                color: const Color(0x667B2D8B),
                                child: const Icon(Icons.check_circle, color: Colors.white),
                              ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    );
    if (confirmed != true || selected.isEmpty) return;
    await _photoService.addPhotosToCollection(collectionId, selected.toList());
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collections'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _createCollection),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _collections.isEmpty
              ? const Center(child: Text('No collections yet', style: TextStyle(color: Colors.grey)))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _collections.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final c = _collections[index];
                    return Card(
                      child: InkWell(
                        onTap: () => _addPhotos(c.id),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: c.coverPhotoUrl == null
                                  ? Container(
                                      color: const Color(0x207B2D8B),
                                      child: const Center(child: Icon(Icons.photo_album)),
                                    )
                                  : Image.network(c.coverPhotoUrl!, width: double.infinity, fit: BoxFit.cover),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text('${c.photoCount} photos', style: const TextStyle(color: Colors.grey)),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
