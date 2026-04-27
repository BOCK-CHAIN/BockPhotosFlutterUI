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

  int _gridColumns(double width) {
    if (width < 600) return 2;
    if (width <= 1024) return 3;
    return 4;
  }

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

  Future<void> _openCollection(CollectionItem collection) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CollectionPhotosScreen(
          collection: collection,
          photoService: _photoService,
        ),
      ),
    );
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
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = _gridColumns(constraints.maxWidth);
                    return GridView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _collections.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.0,
                      ),
                      itemBuilder: (context, index) {
                        final c = _collections[index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Material(
                            color: const Color(0x207B2D8B),
                            child: InkWell(
                              onTap: () => _openCollection(c),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (c.coverPhotoUrl != null)
                                    Image.network(
                                      c.coverPhotoUrl!,
                                      fit: BoxFit.cover,
                                    )
                                  else
                                    const Center(child: Icon(Icons.photo_album)),
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      width: double.infinity,
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Color(0x00000000),
                                            Color(0xCC000000),
                                          ],
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${c.photoCount} photos',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}

class CollectionPhotosScreen extends StatefulWidget {
  final CollectionItem collection;
  final PhotoService photoService;

  const CollectionPhotosScreen({
    super.key,
    required this.collection,
    required this.photoService,
  });

  @override
  State<CollectionPhotosScreen> createState() => _CollectionPhotosScreenState();
}

class _CollectionPhotosScreenState extends State<CollectionPhotosScreen> {
  List<PhotoItem> _photos = [];
  bool _loading = true;
  late String _name;

  @override
  void initState() {
    super.initState();
    _name = widget.collection.name;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final photos = await widget.photoService.getCollectionPhotos(widget.collection.id);
      print('[CollectionPhotosScreen] fetched photos for ${widget.collection.id}: ${photos.length}');
      if (!mounted) return;
      setState(() {
        _photos = photos;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load collection: $e')),
      );
    }
  }

  Future<void> _rename() async {
    final controller = TextEditingController(text: _name);
    final nextName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename collection'),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (nextName == null || nextName.isEmpty) return;
    await widget.photoService.renameCollection(widget.collection.id, nextName);
    if (!mounted) return;
    setState(() => _name = nextName);
  }

  Future<void> _delete() async {
    await widget.photoService.deleteCollection(widget.collection.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_name),
        actions: [
          IconButton(onPressed: _rename, icon: const Icon(Icons.edit_outlined)),
          IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _photos.isEmpty
              ? const Center(
                  child: Text(
                    'No photos in this collection',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
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
                return PhotoTile(
                  imageUrl: photo.url,
                  photoId: photo.id,
                  fileKey: photo.fileKey,
                  photoService: widget.photoService,
                );
              },
            ),
    );
  }
}
