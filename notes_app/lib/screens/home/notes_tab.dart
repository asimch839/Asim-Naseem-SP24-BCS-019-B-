import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/notes_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/cards/note_card.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/app_snackbar.dart';

class NotesTab extends StatelessWidget {
  const NotesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildFilterBar(context),
            Expanded(child: _buildNotesList(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
      child: Row(
        children: [
          Text('My Notes', style: Theme.of(context).textTheme.headlineMedium),
          const Spacer(),
          // Sort button
          Consumer<NotesProvider>(
            builder: (_, prov, __) => PopupMenuButton<String>(
              icon: const Icon(Icons.sort_rounded),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onSelected: prov.setSortMode,
              itemBuilder: (_) => [
                _sortItem(
                    'Newest First', AppConstants.sortNewest, prov.sortMode),
                _sortItem(
                    'Oldest First', AppConstants.sortOldest, prov.sortMode),
                _sortItem('Title A–Z', AppConstants.sortTitle, prov.sortMode),
                _sortItem(
                    'By Priority', AppConstants.sortPriority, prov.sortMode),
              ],
            ),
          ),
          // View toggle
          Consumer<NotesProvider>(
            builder: (_, prov, __) => IconButton(
              icon: Icon(
                prov.viewMode == AppConstants.viewGrid
                    ? Icons.view_list_rounded
                    : Icons.grid_view_rounded,
              ),
              onPressed: () => prov.setViewMode(
                prov.viewMode == AppConstants.viewGrid
                    ? AppConstants.viewList
                    : AppConstants.viewGrid,
              ),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _sortItem(String label, String value, String current) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
              current == value
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 18,
              color: AppColors.primary),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Consumer2<CategoryProvider, NotesProvider>(
      builder: (_, cats, notes, __) {
        final categories = ['All', ...cats.categoryNames];
        return SizedBox(
          height: 46,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: categories.length,
            itemBuilder: (_, i) {
              final cat = categories[i];
              final isAll = cat == 'All';
              final isSelected = isAll
                  ? notes.selectedCategory.isEmpty
                  : notes.selectedCategory == cat;
              return GestureDetector(
                onTap: () =>
                    isAll ? notes.setCategory('') : notes.setCategory(cat),
                child: AnimatedContainer(
                  duration: AppConstants.animFast,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.primary,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildNotesList(BuildContext context) {
    return Consumer<NotesProvider>(
      builder: (_, prov, __) {
        if (prov.status == NotesStatus.loading) {
          return NoteCardShimmer(
              isGrid: prov.viewMode == AppConstants.viewGrid);
        }
        if (prov.filteredNotes.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.note_add_outlined,
            title: 'No Notes Yet',
            subtitle: 'Tap the + button to create your first note',
            action: ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.noteEditor),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Note'),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => prov.loadNotes(),
          child: prov.viewMode == AppConstants.viewGrid
              ? _buildGrid(context, prov)
              : _buildList(context, prov),
        );
      },
    );
  }

  Widget _buildGrid(BuildContext context, NotesProvider prov) {
    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: prov.filteredNotes.length,
      itemBuilder: (_, i) =>
          _noteCard(context, prov, prov.filteredNotes[i], true),
    );
  }

  Widget _buildList(BuildContext context, NotesProvider prov) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemCount: prov.filteredNotes.length,
      itemBuilder: (_, i) =>
          _noteCard(context, prov, prov.filteredNotes[i], false),
    );
  }

  Widget _noteCard(
      BuildContext context, NotesProvider prov, note, bool isGrid) {
    return NoteCard(
      key: ValueKey(note.id),
      note: note,
      isGrid: isGrid,
      onTap: () =>
          Navigator.pushNamed(context, AppRoutes.noteEditor, arguments: note)
              .then((_) => prov.loadNotes()),
      onFavorite: () {
        prov.toggleFavorite(note);
        AppSnackbar.show(context,
            note.isFavorite ? 'Removed from favorites' : 'Added to favorites',
            type: SnackbarType.success);
      },
      onPin: () {
        prov.togglePin(note);
        AppSnackbar.show(
            context, note.isPinned ? 'Note unpinned' : 'Note pinned',
            type: SnackbarType.info);
      },
      onArchive: () {
        prov.archiveNote(note);
        AppSnackbar.show(context, 'Note archived', type: SnackbarType.info);
      },
      onDelete: () {
        prov.moveToTrash(note);
        AppSnackbar.show(context, 'Moved to trash',
            type: SnackbarType.warning,
            actionLabel: 'Undo',
            onAction: () => prov.restoreFromTrash(note));
      },
    );
  }
}
