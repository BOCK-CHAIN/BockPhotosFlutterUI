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
  final bool isStarred;
  final bool selected;
  final bool selectionMode;

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
    this.isStarred = false,
    this.selected = false,
    this.selectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              photoService != null 
                ? AuthenticatedImage(
                    photoService: photoService!,
                    fileKey: fileKey,
                    fallbackUrl: imageUrl,
                    fit: BoxFit.cover,
                  )
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
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
              if (onDelete != null)
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
                        color: selectionMode ? const Color(0xFF7B2D8B) : Colors.black87,
                        size: 20,
                      ),
                      onPressed: selectionMode
                          ? onTap
                          : () async {
                              final value = await showMenu<String>(
                                context: context,
                                position: const RelativeRect.fromLTRB(1000, 100, 8, 0),
                                items: [
                                  PopupMenuItem(
                                    value: 'star',
                                    child: Row(
                                      children: [
                                        Icon(isStarred ? Icons.star : Icons.star_border, color: Colors.amber),
                                        const SizedBox(width: 8),
                                        Text(isStarred ? 'Unstar' : 'Star'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'trash',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Move to Trash'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_forever, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete permanently'),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                              if (value == 'star') onToggleStar?.call();
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
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF7B2D8B), width: 3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
