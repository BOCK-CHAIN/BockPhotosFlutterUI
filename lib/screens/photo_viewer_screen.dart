import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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
  bool _pagingEnabled = true;
  double _verticalDragOffset = 0;
  final Map<String, PhotoItem> _photoDetailsById = <String, PhotoItem>{};

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    _controller.dispose();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
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

  String _resolutionText(PhotoMetadata metadata) {
    final w = metadata.width ?? _current.width;
    final h = metadata.height ?? _current.height;
    if (w == null || h == null) return 'Unknown';
    return '${w}x$h';
  }

  String _locationText(PhotoMetadata metadata) {
    final lat = metadata.locationLat ?? _current.locationLat;
    final lng = metadata.locationLng ?? _current.locationLng;
    if (lat == null || lng == null) return 'Unknown';
    return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
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
                  _dateText(
                    metadata.uploadedAt ??
                        _currentResolved.uploadedAt ??
                        _currentResolved.createdAt,
                  ),
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
              ListTile(
                dense: true,
                leading: const Text('🧭'),
                title: const Text(
                  'Resolution',
                  style: TextStyle(color: Colors.grey),
                ),
                trailing: Text(
                  _resolutionText(metadata),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              ListTile(
                dense: true,
                leading: const Text('📍'),
                title: const Text(
                  'Location',
                  style: TextStyle(color: Colors.grey),
                ),
                trailing: Text(
                  _locationText(metadata),
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
    final rootContext = context;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share link'),
        content: SelectableText(link),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: link));
              Navigator.pop(context);
              ScaffoldMessenger.of(rootContext).showSnackBar(
                const SnackBar(content: Text('Link copied to clipboard')),
              );
            },
            child: const Text('Copy Link'),
          ),
          TextButton(
            onPressed: () async {
              final uri = Uri.parse(
                'https://wa.me/?text=${Uri.encodeComponent(link)}',
              );
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            child: const Text('WhatsApp'),
          ),
          TextButton(
            onPressed: () async {
              final uri = Uri.parse(
                'mailto:?subject=Shared photo&body=${Uri.encodeComponent(link)}',
              );
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
      final bytes = await NetworkAssetBundle(Uri.parse(_current.url)).load(
        _current.url,
      );
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

  Future<void> _downloadCurrentPhoto() async {
    final uri = Uri.parse(_current.url);
    if (kIsWeb) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    final bytes = await http.readBytes(uri);
    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          name: _current.filename.isEmpty ? 'photo.jpg' : _current.filename,
          mimeType: 'image/*',
        ),
      ],
      text: 'Downloaded ${_current.filename}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPhoto = _current;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => setState(() => _chromeVisible = !_chromeVisible),
            onVerticalDragUpdate: (details) {
              if (!_pagingEnabled) return;
              setState(() {
                _verticalDragOffset =
                    (_verticalDragOffset + details.delta.dy).clamp(0, 260);
              });
            },
            onVerticalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              final shouldClose =
                  velocity > 500 || _verticalDragOffset > 150;
              if (shouldClose) {
                Navigator.of(context).pop();
                return;
              }
              setState(() => _verticalDragOffset = 0);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(0, _verticalDragOffset, 0),
              child: PageView.builder(
                controller: _controller,
                physics: _pagingEnabled
                    ? const PageScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                itemCount: widget.photos.length,
                onPageChanged: (value) {
                  setState(() {
                    _index = value;
                    _pagingEnabled = true;
                  });
                },
                itemBuilder: (context, index) {
                  final photo = widget.photos[index];
                  return Center(
                    child: Hero(
                      tag: 'photo_${photo.id}',
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 5.0,
                        onInteractionUpdate: (details) {
                          if (_index != index) return;
                          final isZoomed = details.scale > 1.01;
                          if (isZoomed != !_pagingEnabled) {
                            setState(() => _pagingEnabled = !isZoomed);
                          }
                        },
                        onInteractionEnd: (details) {
                          if (_index != index) return;
                          setState(() => _pagingEnabled = true);
                        },
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
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _chromeVisible ? 1 : 0,
              child: IgnorePointer(
                ignoring: !_chromeVisible,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.75),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentPhoto.filename,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white),
                            ),
                            Text(
                              _dateText(
                                currentPhoto.takenAt ?? currentPhoto.createdAt,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _chromeVisible && _index > 0 ? 1 : 0,
                child: IgnorePointer(
                  ignoring: !(_chromeVisible && _index > 0),
                  child: IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.45),
                    ),
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: () {
                      _controller.previousPage(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _chromeVisible && _index < widget.photos.length - 1
                    ? 1
                    : 0,
                child: IgnorePointer(
                  ignoring:
                      !(_chromeVisible && _index < widget.photos.length - 1),
                  child: IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.45),
                    ),
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: () {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _chromeVisible ? 1 : 0,
              child: IgnorePointer(
                ignoring: !_chromeVisible,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.85),
                  padding: EdgeInsets.only(
                    left: 8,
                    right: 8,
                    bottom: MediaQuery.of(context).padding.bottom,
                  ),
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
                            const SnackBar(
                              content: Text('Star status updated'),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        color: Colors.white,
                        icon: const Icon(Icons.info_outline),
                        onPressed: _showInfoSheet,
                      ),
                      IconButton(
                        color: Colors.white,
                        icon: const Icon(Icons.download_outlined),
                        onPressed: _downloadCurrentPhoto,
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
