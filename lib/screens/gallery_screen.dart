import 'package:flutter/material.dart';
import '../services/photo_service.dart';
import '../services/api_client.dart';
import '../services/token_store.dart';
import '../services/auth_service.dart';
import '../services/health_service.dart';

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
  int _tabIndex = 0; // 0: Photos, 1: Collections, 2: Search

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
    _authService = AuthService(tokenStore);
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

  void _goToUpload() {
    Navigator.pushNamed(context, '/upload').then((_) => _fetchPhotos());
  }

  void _goToNotifications() {
    Navigator.pushNamed(context, '/notifications');
  }

  void _goToProfile() {
    Navigator.pushNamed(context, '/profile');
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
        title: const Text('Hynorvixx'),
        actions: [
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
          if (!_backendOk)
            Container(
              width: double.infinity,
              color: Colors.amber.shade100,
              padding: const EdgeInsets.all(8),
              child: const Text('Backend health degraded or down'),
            ),
          Expanded(child: _buildTabContent()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) {
          setState(() => _tabIndex = i);
          if (i == 0) {
            _fetchPhotos();
          } else if (i == 1) {
            Navigator.pushNamed(context, '/collections');
          } else if (i == 2) {
            Navigator.pushNamed(context, '/search');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.image), label: 'Photos'),
          BottomNavigationBarItem(icon: Icon(Icons.collections_bookmark), label: 'Collections'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    if (_tabIndex != 0) {
      return const SizedBox.shrink();
    }
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
          return Card(
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  photo.url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                        size: 48,
                      ),
                    );
                  },
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => _delete(photo.id),
                      tooltip: 'Delete photo',
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
