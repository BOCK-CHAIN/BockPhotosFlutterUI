import 'package:flutter/material.dart';
import '../services/photo_service.dart';
import 'authenticated_image.dart';

class PhotoTile extends StatelessWidget {
  final String imageUrl;
  final String photoId;
  final String? fileKey;
  final PhotoService? photoService;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onMoveToTrash;
  final VoidCallback? onToggleStar;
  final VoidCallback? onShare;
  final VoidCallback? onAddToCollection;
  final bool isStarred;
  final bool selected;
  final bool selectionMode;
  final bool isTrashView;
  final VoidCallback? onRestore;
  final int? thumbnailCacheWidth;
  final double aspectRatio;
  final String deleteMenuLabel;

  const PhotoTile({
    super.key,
    required this.imageUrl,
    required this.photoId,
    this.fileKey,
    this.photoService,
    this.onDelete,
    this.onTap,
    this.onLongPress,
    this.onMoveToTrash,
    this.onToggleStar,
    this.onShare,
    this.onAddToCollection,
    this.isStarred = false,
    this.selected = false,
    this.selectionMode = false,
    this.isTrashView = false,
    this.onRestore,
    this.thumbnailCacheWidth,
    this.aspectRatio = 1,
    this.deleteMenuLabel = 'Delete permanently',
  });

  RelativeRect _menuPosition(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final rect = Rect.fromPoints(
      renderBox.localToGlobal(Offset.zero, ancestor: overlay),
      renderBox.localToGlobal(
        renderBox.size.bottomRight(Offset.zero),
        ancestor: overlay,
      ),
    );
    return RelativeRect.fromRect(rect, Offset.zero & overlay.size);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AspectRatio(
        aspectRatio: aspectRatio <= 0 ? 1 : aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'photo_$photoId',
              child: photoService != null
                  ? AuthenticatedImage(
                      photoService: photoService!,
                      fileKey: fileKey,
                      fallbackUrl: imageUrl,
                      fit: BoxFit.cover,
                      cacheWidth: thumbnailCacheWidth ?? 400,
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      cacheWidth: thumbnailCacheWidth ?? 400,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.error,
                            color: Colors.red,
                            size: 32,
                          ),
                        );
                      },
                    ),
            ),
            if (onDelete != null && !isTrashView)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      selectionMode ? Icons.check_circle : Icons.more_vert,
                      color: selectionMode
                          ? const Color(0xFF7B2D8B)
                          : Colors.black87,
                      size: 20,
                    ),
                    onPressed: selectionMode
                        ? onTap
                        : () async {
                            final value = await showMenu<String>(
                              context: context,
                              position: _menuPosition(context),
                              items: [
                                PopupMenuItem(
                                  value: 'star',
                                  child: Row(
                                    children: [
                                      Icon(
                                        isStarred ? Icons.star : Icons.star_border,
                                        color: Colors.amber,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(isStarred ? 'Unstar' : 'Star'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'add_to_collection',
                                  child: Row(
                                    children: [
                                      Icon(Icons.playlist_add),
                                      SizedBox(width: 8),
                                      Text('Add to Collection'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'share',
                                  child: Row(
                                    children: [
                                      Icon(Icons.share_outlined),
                                      SizedBox(width: 8),
                                      Text('Share'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'trash',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Move to Trash'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_forever,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text(deleteMenuLabel),
                                    ],
                                  ),
                                ),
                              ],
                            );
                            if (value == 'star') onToggleStar?.call();
                            if (value == 'add_to_collection') {
                              onAddToCollection?.call();
                            }
                            if (value == 'share') onShare?.call();
                            if (value == 'trash') onMoveToTrash?.call();
                            if (value == 'delete') onDelete?.call();
                          },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ),
              ),
              if (isTrashView)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.restore,
                        color: Color(0xFF7B2D8B),
                        size: 20,
                      ),
                      onPressed: onRestore,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ),
                ),
            if (!isTrashView)
              Positioned(
                bottom: 4,
                right: 4,
                child: IconButton(
                  icon: Icon(
                    isStarred ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: onToggleStar,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            if (selected)
              Container(
                decoration: const BoxDecoration(
                  color: Color(0x553B82F6),
                ),
                child: const Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.check_circle, color: Color(0xFF2563EB)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
