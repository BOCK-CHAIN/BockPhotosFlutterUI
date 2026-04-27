import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/photo_service.dart';
import '../widgets/authenticated_image.dart';

class PhotoViewerScreen extends StatefulWidget {
  final List<PhotoItem> photos;
  final int initialIndex;
  final PhotoService photoService;

  const PhotoViewerScreen({
    super.key,
    required this.photos,
    required this.initialIndex,
    required this.photoService,
  });

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late final PageController _controller;
  late int _index;
  bool _chromeVisible = true;
  final Map<String, PhotoItem> _photoDetailsById = <String, PhotoItem>{};

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  PhotoItem get _current => widget.photos[_index];
  PhotoItem get _currentResolved => _photoDetailsById[_current.id] ?? _current;

  bool get _isMobilePlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  String _dateText(DateTime? dt) {
    if (dt == null) return 'Unknown';
    return DateFormat('MMMM dd, yyyy • hh:mm a').format(dt.toLocal());
  }

  String _sizeText(int? size) {
    if (size == null) return 'Unknown';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _showInfoSheet() async {
    try {
      if (_currentResolved.filename.isEmpty || _currentResolved.uploadedAt == null) {
        final detail = await widget.photoService.getPhotoDetail(_current.id);
        if (!mounted) return;
        setState(() {
          _photoDetailsById[_current.id] = detail;
        });
      }
      final metadata = await widget.photoService.getPhotoMetadata(_current.id);
      print('[PhotoViewerScreen] metadata API response for ${_current.id}: '
          'file_name=${metadata.fileName}, file_size=${metadata.fileSize}, uploaded_at=${metadata.uploadedAt}');
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Photo info',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ListTile(
                dense: true,
                leading: const Text('📷'),
                title: const Text(
                  'File Name',
                  style: TextStyle(color: Colors.grey),
                ),
                trailing: Text(
                  metadata.fileName ?? _currentResolved.filename,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              ListTile(
                dense: true,
                leading: const Text('📅'),
                title: const Text('Date', style: TextStyle(color: Colors.grey)),
                trailing: Text(
                  _dateText(metadata.uploadedAt ?? _currentResolved.uploadedAt ?? _currentResolved.createdAt),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              ListTile(
                dense: true,
                leading: const Text('💾'),
                title: const Text('Size', style: TextStyle(color: Colors.grey)),
                trailing: Text(
                  _sizeText(metadata.fileSize ?? _currentResolved.size),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Metadata unavailable for this photo')),
      );
    }
  }

  Future<void> _showShareLinkDialog() async {
    final share = await widget.photoService.createPhotoShareLink(_current.id);
    if (!mounted) return;
    final link = share.url;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share link'),
        content: SelectableText(link),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: link));
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(this.context).showSnackBar(
                const SnackBar(content: Text('Link copied to clipboard')),
              );
            },
            child: const Text('Copy Link'),
          ),
          TextButton(
            onPressed: () async {
              final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(link)}');
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            child: const Text('WhatsApp'),
          ),
          TextButton(
            onPressed: () async {
              final uri = Uri.parse('mailto:?subject=Shared photo&body=${Uri.encodeComponent(link)}');
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            child: const Text('Email'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareCurrentPhoto() async {
    if (_isMobilePlatform) {
      final bytes = await NetworkAssetBundle(Uri.parse(_current.url)).load(_current.url);
      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes.buffer.asUint8List(),
            name: _current.filename,
            mimeType: 'image/*',
          ),
        ],
        text: _current.filename,
      );
      return;
    }
    await _showShareLinkDialog();
  }

  Future<void> _addToCollection() async {
    final collections = await widget.photoService.listCollections();
    if (!mounted) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined),
              title: const Text('New Collection'),
              onTap: () => Navigator.pop(context, '__new__'),
            ),
            ...collections.map(
              (c) => ListTile(
                title: Text(c.name),
                subtitle: Text('${c.photoCount} photos'),
                onTap: () => Navigator.pop(context, c.id),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    String targetId = selected;
    if (selected == '__new__') {
      final controller = TextEditingController();
      final name = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('New collection'),
          content: TextField(controller: controller),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Create')),
          ],
        ),
      );
      if (name == null || name.isEmpty) return;
      await widget.photoService.createCollection(name, coverPhotoId: _current.id);
      final refreshed = await widget.photoService.listCollections();
      targetId = refreshed.first.id;
    }
    await widget.photoService.addPhotosToCollection(targetId, [_current.id]);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to collection')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _chromeVisible
          ? AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _current.filename,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _dateText(_current.takenAt ?? _current.createdAt),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            )
          : null,
      body: GestureDetector(
        onTap: () => setState(() => _chromeVisible = !_chromeVisible),
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 800) {
            Navigator.of(context).pop();
          }
        },
        child: PageView.builder(
          controller: _controller,
          itemCount: widget.photos.length,
          onPageChanged: (value) => setState(() => _index = value),
          itemBuilder: (context, index) {
            final photo = widget.photos[index];
            return Center(
              child: Hero(
                tag: 'photo-${photo.id}',
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4,
                  child: photo.fileKey != null
                      ? AuthenticatedImage(
                          photoService: widget.photoService,
                          fileKey: photo.fileKey,
                          fallbackUrl: photo.url,
                          fit: BoxFit.contain,
                        )
                      : Image.network(photo.url, fit: BoxFit.contain),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _chromeVisible
          ? BottomAppBar(
              color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    color: Colors.white,
                    icon: const Icon(Icons.share_outlined),
                    onPressed: _shareCurrentPhoto,
                  ),
                  IconButton(
                    color: Colors.white,
                    icon: Icon(
                      _current.isStarred ? Icons.star : Icons.star_border,
                    ),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final photoId = _current.id;
                      final nextStarValue = !_current.isStarred;
                      await widget.photoService.setStarred(
                        photoId,
                        nextStarValue,
                      );
                      if (!mounted) return;
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Star status updated')),
                      );
                    },
                  ),
                  IconButton(
                    color: Colors.white,
                    icon: const Icon(Icons.info_outline),
                    onPressed: _showInfoSheet,
                  ),
                  PopupMenuButton<String>(
                    iconColor: Colors.white,
                    onSelected: (value) async {
                      if (value == 'collection') {
                        await _addToCollection();
                      } else if (value == 'share') {
                        await _shareCurrentPhoto();
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'collection', child: Text('Add to Collection')),
                      PopupMenuItem(value: 'share', child: Text('Share')),
                    ],
                  ),
                  IconButton(
                    color: Colors.white,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      final photoId = _current.id;
                      await widget.photoService.moveToTrash(photoId);
                      if (!mounted) return;
                      navigator.pop();
                    },
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
