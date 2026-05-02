import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/helpers/date_helper.dart';
import '../../models/note_model.dart';
import 'priority_badge.dart';

class NoteCard extends StatelessWidget {
  final NoteModel note;
  final bool isGrid;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onPin;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;

  const NoteCard({
    super.key,
    required this.note,
    required this.isGrid,
    required this.onTap,
    this.onFavorite,
    this.onPin,
    this.onArchive,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return isGrid ? _buildGrid(context) : _buildList(context);
  }

  Widget _buildGrid(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = note.colorValue == 0xFFFFFFFF && isDark
        ? AppColors.darkCard
        : Color(note.colorValue);
    final isLight = _isLightColor(cardColor);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.animFast,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? AppColors.darkBorder
                : cardColor == Colors.white
                    ? AppColors.lightBorder
                    : cardColor.withOpacity(0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: pin + options
                  Row(
                    children: [
                      if (note.isPinned)
                        Icon(Icons.push_pin_rounded,
                            size: 14,
                            color: isLight ? Colors.black54 : Colors.white70),
                      const Spacer(),
                      _OptionsMenu(
                        note: note,
                        isLight: isLight,
                        onFavorite: onFavorite,
                        onPin: onPin,
                        onArchive: onArchive,
                        onDelete: onDelete,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Title
                  Text(
                    note.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isLight ? Colors.black87 : Colors.white,
                    ),
                  ),
                  if (note.description.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      note.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isLight ? Colors.black54 : Colors.white70,
                        height: 1.5,
                      ),
                    ),
                  ],
                  // Tags
                  if (note.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: note.tags.take(2).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isLight
                                ? Colors.black.withOpacity(0.07)
                                : Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isLight ? Colors.black54 : Colors.white70,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Bottom: priority + date
                  Row(
                    children: [
                      PriorityBadge(priority: note.priority, compact: true),
                      const Spacer(),
                      if (note.isFavorite)
                        const Icon(Icons.favorite_rounded,
                            size: 12, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      Text(
                        DateHelper.formatRelative(note.updatedAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: isLight ? Colors.black38 : Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = note.colorValue == 0xFFFFFFFF && isDark
        ? AppColors.darkCard
        : Color(note.colorValue);
    final isLight = _isLightColor(cardColor);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Left accent bar
                  Container(
                    width: 3,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _priorityColor(note.priority),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (note.isPinned)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Icon(Icons.push_pin_rounded,
                                    size: 12,
                                    color: isLight
                                        ? Colors.black54
                                        : Colors.white70),
                              ),
                            Expanded(
                              child: Text(
                                note.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      isLight ? Colors.black87 : Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (note.description.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            note.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isLight ? Colors.black54 : Colors.white70,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            PriorityBadge(
                                priority: note.priority, compact: true),
                            const SizedBox(width: 8),
                            Text(
                              note.category,
                              style: TextStyle(
                                fontSize: 10,
                                color:
                                    isLight ? Colors.black38 : Colors.white54,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              DateHelper.formatRelative(note.updatedAt),
                              style: TextStyle(
                                fontSize: 10,
                                color:
                                    isLight ? Colors.black38 : Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _OptionsMenu(
                    note: note,
                    isLight: isLight,
                    onFavorite: onFavorite,
                    onPin: onPin,
                    onArchive: onArchive,
                    onDelete: onDelete,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isLightColor(Color color) {
    return color.computeLuminance() > 0.5;
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case AppConstants.priorityUrgent:
        return AppColors.priorityUrgent;
      case AppConstants.priorityHigh:
        return AppColors.priorityHigh;
      case AppConstants.priorityMedium:
        return AppColors.priorityMedium;
      default:
        return AppColors.priorityLow;
    }
  }
}

class _OptionsMenu extends StatelessWidget {
  final NoteModel note;
  final bool isLight;
  final VoidCallback? onFavorite;
  final VoidCallback? onPin;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;

  const _OptionsMenu({
    required this.note,
    required this.isLight,
    this.onFavorite,
    this.onPin,
    this.onArchive,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        size: 18,
        color: isLight ? Colors.black45 : Colors.white54,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (val) {
        switch (val) {
          case 'pin':
            onPin?.call();
            break;
          case 'favorite':
            onFavorite?.call();
            break;
          case 'archive':
            onArchive?.call();
            break;
          case 'delete':
            onDelete?.call();
            break;
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'pin',
          child: Row(
            children: [
              Icon(
                note.isPinned
                    ? Icons.push_pin_outlined
                    : Icons.push_pin_rounded,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(note.isPinned ? 'Unpin' : 'Pin'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'favorite',
          child: Row(
            children: [
              Icon(
                note.isFavorite
                    ? Icons.favorite_border_rounded
                    : Icons.favorite_rounded,
                size: 18,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 10),
              Text(note.isFavorite ? 'Unfavorite' : 'Favorite'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'archive',
          child: Row(
            children: [
              Icon(Icons.archive_rounded, size: 18),
              SizedBox(width: 10),
              Text('Archive'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded,
                  size: 18, color: AppColors.error),
              SizedBox(width: 10),
              Text('Delete', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
    );
  }
}
