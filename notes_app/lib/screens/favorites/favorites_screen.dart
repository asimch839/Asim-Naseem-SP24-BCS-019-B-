import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../core/routes/app_routes.dart';
import '../../models/note_model.dart';
import '../../providers/notes_provider.dart';
import '../../widgets/cards/note_card.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/app_snackbar.dart';

class FavoritesScreen extends StatefulWidget {
  final bool embedded;
  const FavoritesScreen({super.key, this.embedded = false});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<NoteModel> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _notes = await context.read<NotesProvider>().getFavoriteNotes();
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites ❤️'),
        leading: widget.embedded
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                onPressed: () => Navigator.pop(context),
              ),
        automaticallyImplyLeading: !widget.embedded,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.favorite_outline_rounded,
                  title: 'No Favorites Yet',
                  subtitle: 'Mark notes as favorites to see them here',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: MasonryGridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: _notes.length,
                    itemBuilder: (_, i) {
                      final note = _notes[i];
                      return NoteCard(
                        note: note,
                        isGrid: true,
                        onTap: () => Navigator.pushNamed(
                                context, AppRoutes.noteEditor,
                                arguments: note)
                            .then((_) => _load()),
                        onFavorite: () async {
                          await context
                              .read<NotesProvider>()
                              .toggleFavorite(note);
                          _load();
                          AppSnackbar.show(context, 'Removed from favorites',
                              type: SnackbarType.info);
                        },
                        onPin: () async {
                          await context.read<NotesProvider>().togglePin(note);
                          _load();
                        },
                        onArchive: () async {
                          await context.read<NotesProvider>().archiveNote(note);
                          _load();
                        },
                        onDelete: () async {
                          await context.read<NotesProvider>().moveToTrash(note);
                          _load();
                          AppSnackbar.show(context, 'Moved to trash',
                              type: SnackbarType.warning);
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
