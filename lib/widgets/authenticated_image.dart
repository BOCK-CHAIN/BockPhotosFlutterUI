import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../services/photo_service.dart';

class AuthenticatedImage extends StatefulWidget {
  final PhotoService photoService;
  final String? fileKey;
  final String fallbackUrl;
  final BoxFit fit;
  final int? cacheWidth;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const AuthenticatedImage({
    super.key,
    required this.photoService,
    this.fileKey,
    required this.fallbackUrl,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  State<AuthenticatedImage> createState() => _AuthenticatedImageState();
}

class _AuthenticatedImageState extends State<AuthenticatedImage> {
  String? _authenticatedUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAuthenticatedUrl();
  }

  Future<void> _loadAuthenticatedUrl() async {
    // If no fileKey available, skip authentication and use fallback
    if (widget.fileKey == null || widget.fileKey!.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final url = await widget.photoService.getViewUrl(widget.fileKey!);
      if (mounted) {
        setState(() {
          _authenticatedUrl = url;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _defaultShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(color: Colors.grey.shade300),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.loadingWidget ?? _defaultShimmer();
    }

    final imageUrl = _authenticatedUrl ?? widget.fallbackUrl;

    return Image.network(
      imageUrl,
      fit: widget.fit,
      cacheWidth: widget.cacheWidth,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return widget.loadingWidget ?? _defaultShimmer();
      },
      errorBuilder: (context, error, stackTrace) {
        // If we tried authenticated URL and it failed, try fallback URL
        if (_authenticatedUrl != null && imageUrl == _authenticatedUrl) {
          return Image.network(
            widget.fallbackUrl,
            fit: widget.fit,
            cacheWidth: widget.cacheWidth,
            errorBuilder: (context, error, stackTrace) {
              return widget.errorWidget ??
                  Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error, color: Colors.red, size: 32),
                  );
            },
          );
        }

        return widget.errorWidget ??
            Container(
              color: Colors.grey[300],
              child: const Icon(Icons.error, color: Colors.red, size: 32),
            );
      },
    );
  }
}
