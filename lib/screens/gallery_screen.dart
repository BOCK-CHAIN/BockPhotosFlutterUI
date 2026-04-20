import 'package:flutter/material.dart';
import '../services/photo_service.dart';
import '../services/api_client.dart';
import '../services/token_store.dart';
import '../services/auth_service.dart';
import '../services/health_service.dart';
import '../widgets/photo_tile.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<PhotoItem> _photos = [];
  bool _loading = true;
  late final PhotoService _photoService;
  late final AuthService _authService;
  final _healthService = HealthService();
  bool _backendOk = true;
  bool _dismissedOfflineBanner = false;
  late final TokenStore _tokenStore;
  bool _selectionMode = false;
  final Set<String> _selectedPhotoIds = <String>{};

  @override
  void initState() {
    super.initState();
    () async {
      await _initializeServices();
      if (mounted) {
        await _fetchPhotos();
      }
    }();
  }

  Future<void> _initializeServices() async {
    _tokenStore = TokenStore();
    await _tokenStore.init();
    final apiClient = ApiClient(_tokenStore);
    _photoService = PhotoService(apiClient);
    _authService = AuthService(_tokenStore);
    // Mirror login/signup behavior by proactively refreshing once
    try {
      await _authService.refreshToken();
    } catch (_) {}
    await _ensureToken();
  }

  Future<void> _ensureToken() async {
    final token = await _tokenStore.getAccess();
    if (token == null) {
      final refreshed = await _authService.refreshToken();
      if (!refreshed.success) {
        // No-op; fetch will surface any error
      }
    }
  }

  Future<void> _fetchPhotos() async {
    setState(() => _loading = true);
    try {
      final health = await _healthService.check();
      _backendOk = health.ok;
      final photos = await _photoService.list();
      if (!mounted) return;
      setState(() {
        _photos = photos;
        _loading = false;
      });
    } catch (e) {
      // If unauthorized, attempt a token refresh once and retry
      final message = e.toString();
      if (message.contains('401') || message.toLowerCase().contains('access token required')) {
        try {
          final refreshed = await _authService.refreshToken();
          if (refreshed.success) {
            final photos = await _photoService.list();
            if (!mounted) return;
            setState(() {
              _photos = photos;
              _loading = false;
            });
            return;
          }
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading photos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _delete(String id) async {
    try {
      await _photoService.delete(id);
      if (!mounted) return;
      await _fetchPhotos();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _moveToTrash(String id) async {
    try {
      await _photoService.moveToTrash(id);
      await _fetchPhotos();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Moved to Trash')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Move to Trash failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _toggleStar(PhotoItem photo) async {
    try {
      await _photoService.setStarred(photo.id, !photo.isStarred);
      await _fetchPhotos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Star update failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _goToUpload() {
    Navigator.pushNamed(context, '/upload').then((_) => _fetchPhotos());
  }

  void _goToNotifications() {
    Navigator.pushNamed(context, '/notifications');
  }

  void _goToProfile() {
    Navigator.pushNamed(context, '/profile');
  }

  Future<void> _addSelectedToCollection() async {
    if (_selectedPhotoIds.isEmpty) return;
    try {
      final collections = await _photoService.listCollections();
      if (!mounted) return;
      if (collections.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Create a collection first in Collections')),
        );
        return;
      }
      final collectionId = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Add to collection'),
          children: collections
              .map((c) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, c.id),
                    child: Text(c.name),
                  ))
              .toList(),
        ),
      );
      if (collectionId == null) return;
      await _photoService.addPhotosToCollection(collectionId, _selectedPhotoIds.toList());
      if (!mounted) return;
      setState(() {
        _selectionMode = false;
        _selectedPhotoIds.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photos added to collection')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _logout() async {
    try {
      final result = await _authService.logout();
      if (!mounted) return;
      
      if (result.success) {
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Logout failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectionMode ? '${_selectedPhotoIds.length} selected' : 'Nexus Photo'),
        actions: [
          if (_selectionMode)
            IconButton(
              icon: const Icon(Icons.playlist_add),
              tooltip: 'Add to collection',
              onPressed: _addSelectedToCollection,
            ),
          if (_selectionMode)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancel selection',
              onPressed: () {
                setState(() {
                  _selectionMode = false;
                  _selectedPhotoIds.clear();
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Upload',
            onPressed: _goToUpload,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Notifications',
            onPressed: _goToNotifications,
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: _goToProfile,
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_backendOk && !_dismissedOfflineBanner)
            Container(
              width: double.infinity,
              color: Colors.amber.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  const Expanded(child: Text('Backend offline. Some features may not work.')),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _dismissedOfflineBanner = true),
                  ),
                ],
              ),
            ),
          Expanded(child: _buildPhotoContent()),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF7B2D8B)),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text('Nexus Photos', style: TextStyle(color: Colors.white, fontSize: 20)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.collections_bookmark),
              title: const Text('Collections'),
              onTap: () => Navigator.pushNamed(context, '/collections'),
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Favourites'),
              onTap: () => Navigator.pushNamed(context, '/favourites'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Trash'),
              onTap: () => Navigator.pushNamed(context, '/trash'),
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search'),
              onTap: () => Navigator.pushNamed(context, '/search'),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_photos.isEmpty) {
      return const Center(
        child: Text('No photos yet', style: TextStyle(color: Colors.grey)),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchPhotos,
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: _photos.length,
        itemBuilder: (context, index) {
          final photo = _photos[index];
          return PhotoTile(
            imageUrl: photo.url,
            photoId: photo.id,
            fileKey: photo.fileKey,
            photoService: _photoService,
            onDelete: () => _delete(photo.id),
            onMoveToTrash: () => _moveToTrash(photo.id),
            onToggleStar: () => _toggleStar(photo),
            isStarred: photo.isStarred,
            selectionMode: _selectionMode,
            selected: _selectedPhotoIds.contains(photo.id),
            onLongPress: () {
              setState(() {
                _selectionMode = true;
                _selectedPhotoIds.add(photo.id);
              });
            },
            onTap: () {
              if (_selectionMode) {
                setState(() {
                  if (_selectedPhotoIds.contains(photo.id)) {
                    _selectedPhotoIds.remove(photo.id);
                  } else {
                    _selectedPhotoIds.add(photo.id);
                  }
                  if (_selectedPhotoIds.isEmpty) {
                    _selectionMode = false;
                  }
                });
              }
            },
          );
        },
      ),
    );
  }
}
