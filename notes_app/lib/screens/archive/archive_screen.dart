import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../models/note_model.dart';
import '../../providers/notes_provider.dart';
import '../../widgets/cards/note_card.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/app_snackbar.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  List<NoteModel> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _notes = await context.read<NotesProvider>().getArchivedNotes();
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archive 📦'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.archive_outlined,
                  title: 'Archive is Empty',
                  subtitle: 'Archived notes will appear here',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemCount: _notes.length,
                    itemBuilder: (_, i) {
                      final note = _notes[i];
                      return NoteCard(
                        note: note,
                        isGrid: false,
                        onTap: () => Navigator.pushNamed(
                                context, AppRoutes.noteEditor,
                                arguments: note)
                            .then((_) => _load()),
                        onFavorite: () async {
                          await context
                              .read<NotesProvider>()
                              .toggleFavorite(note);
                          _load();
                        },
                        onPin: null,
                        onArchive: () async {
                          await context
                              .read<NotesProvider>()
                              .unarchiveNote(note);
                          _load();
                          AppSnackbar.show(context, 'Note unarchived',
                              type: SnackbarType.success);
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
