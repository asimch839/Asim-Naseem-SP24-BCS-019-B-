import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/helpers/date_helper.dart';
import '../../models/note_model.dart';
import '../../providers/notes_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/dialogs/confirmation_dialog.dart';
import '../../widgets/cards/priority_badge.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  List<NoteModel> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _notes = await context.read<NotesProvider>().getTrashNotes();
    setState(() => _loading = false);
  }

  Future<void> _restore(NoteModel note) async {
    await context.read<NotesProvider>().restoreFromTrash(note);
    if (!mounted) return;
    _load();
    AppSnackbar.show(context, 'Note restored', type: SnackbarType.success);
  }

  Future<void> _deletePermanently(NoteModel note) async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Delete Permanently?',
      message: 'This note will be permanently deleted and cannot be recovered.',
      confirmText: 'Delete',
      icon: Icons.delete_forever_rounded,
    );
    if (confirm == true && mounted) {
      await context.read<NotesProvider>().deletePermanently(note.id);
      if (!mounted) return;
      _load();
      AppSnackbar.show(context, 'Note permanently deleted',
          type: SnackbarType.error);
    }
  }

  Future<void> _emptyTrash() async {
    if (_notes.isEmpty) return;
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Empty Trash?',
      message: 'All ${_notes.length} notes will be permanently deleted.',
      confirmText: 'Empty Trash',
      icon: Icons.delete_sweep_rounded,
    );
    if (confirm == true && mounted) {
      for (final n in _notes) {
        await context.read<NotesProvider>().deletePermanently(n.id);
      }
      if (!mounted) return;
      _load();
      AppSnackbar.show(context, 'Trash emptied', type: SnackbarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash 🗑️'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_notes.isNotEmpty)
            TextButton(
              onPressed: _emptyTrash,
              child:
                  const Text('Empty', style: TextStyle(color: AppColors.error)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.delete_outline_rounded,
                  title: 'Trash is Empty',
                  subtitle: 'Deleted notes appear here temporarily',
                )
              : Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.warning.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: AppColors.warning, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Notes in trash are not automatically deleted.',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.warning),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemCount: _notes.length,
                          itemBuilder: (_, i) =>
                              _buildTrashCard(_notes[i], isDark),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildTrashCard(NoteModel note, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                PriorityBadge(priority: note.priority, compact: true),
              ],
            ),
            if (note.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(note.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Text(DateHelper.formatRelative(note.updatedAt),
                    style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _restore(note),
                  icon: const Icon(Icons.restore_rounded, size: 16),
                  label: const Text('Restore'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.success,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () => _deletePermanently(note),
                  icon: const Icon(Icons.delete_forever_rounded, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
