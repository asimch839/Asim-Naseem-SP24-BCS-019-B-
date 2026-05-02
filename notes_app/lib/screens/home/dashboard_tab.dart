import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/helpers/date_helper.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/notes_provider.dart';
import '../../models/note_model.dart';
import '../../widgets/common/loading_shimmer.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<DashboardProvider>().loadDashboard();
          await context.read<NotesProvider>().loadNotes();
        },
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context, isDark),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 20),
                  _buildStatsRow(context),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                      context, 'Pinned Notes', Icons.push_pin_rounded),
                  const SizedBox(height: 12),
                  _buildPinnedNotes(context),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                      context, 'Recent Notes', Icons.access_time_rounded),
                  const SizedBox(height: 12),
                  _buildRecentNotes(context),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 16, 16),
        title: Text(
          AppConstants.appName,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color:
                isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        background: Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
          child: Text(
            'Good ${_greeting()}! 👋',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.search),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert_rounded),
          onPressed: () => _showMenu(context),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _QuickActionsSheet(),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (_, dash, __) {
        if (dash.loading) {
          return const SizedBox(
              height: 90, child: Center(child: CircularProgressIndicator()));
        }
        return Row(
          children: [
            Expanded(
                child: _StatCard(
                    label: 'Total Notes',
                    value: '${dash.totalNotes}',
                    icon: Icons.note_rounded,
                    color: AppColors.primary)),
            const SizedBox(width: 12),
            Expanded(
                child: _StatCard(
                    label: 'Favorites',
                    value: '${dash.favoriteCount}',
                    icon: Icons.favorite_rounded,
                    color: AppColors.secondary)),
            const SizedBox(width: 12),
            Expanded(
                child: _StatCard(
                    label: 'Pinned',
                    value: '${dash.pinnedCount}',
                    icon: Icons.push_pin_rounded,
                    color: AppColors.accent)),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }

  Widget _buildPinnedNotes(BuildContext context) {
    return Consumer<NotesProvider>(
      builder: (_, prov, __) {
        final pinned = prov.pinnedNotes;
        if (prov.status == NotesStatus.loading) {
          return const NoteCardShimmer(isGrid: false);
        }
        if (pinned.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.push_pin_outlined, color: AppColors.primary),
                const SizedBox(width: 12),
                Text('No pinned notes yet',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          );
        }
        return SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: pinned.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) =>
                _MiniNoteCard(note: pinned[i], context: context),
          ),
        );
      },
    );
  }

  Widget _buildRecentNotes(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (_, dash, __) {
        if (dash.loading) return const NoteCardShimmer(isGrid: false);
        if (dash.recentNotes.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accent.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.note_add_outlined, color: AppColors.accent),
                const SizedBox(width: 12),
                Expanded(
                    child: Text('Create your first note!',
                        style: Theme.of(context).textTheme.bodyMedium)),
              ],
            ),
          );
        }
        return Column(
          children: dash.recentNotes
              .map((n) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RecentNoteRow(note: n, context: context),
                  ))
              .toList(),
        );
      },
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary)),
        ],
      ),
    );
  }
}

class _MiniNoteCard extends StatelessWidget {
  final NoteModel note;
  final BuildContext context;

  const _MiniNoteCard({required this.note, required this.context});

  @override
  Widget build(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final cardColor = note.colorValue == 0xFFFFFFFF && isDark
        ? AppColors.darkCard
        : Color(note.colorValue);
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(ctx, AppRoutes.noteEditor, arguments: note),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.push_pin_rounded, size: 12, color: AppColors.primary),
              Spacer(),
            ]),
            const SizedBox(height: 6),
            Text(note.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const Spacer(),
            Text(DateHelper.formatRelative(note.updatedAt),
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _RecentNoteRow extends StatelessWidget {
  final NoteModel note;
  final BuildContext context;

  const _RecentNoteRow({required this.note, required this.context});

  @override
  Widget build(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(ctx, AppRoutes.noteEditor, arguments: note),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: Color(note.colorValue == 0xFFFFFFFF
                    ? 0xFF6C63FF
                    : note.colorValue),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(
                      note.description.isEmpty
                          ? note.category
                          : note.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(DateHelper.formatRelative(note.updatedAt),
                style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? AppColors.darkTextHint
                        : AppColors.lightTextHint)),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      _SheetItem(Icons.archive_rounded, 'Archive', AppRoutes.archive),
      _SheetItem(Icons.delete_outline_rounded, 'Trash', AppRoutes.trash),
      _SheetItem(Icons.category_rounded, 'Categories', AppRoutes.categories),
      _SheetItem(Icons.notifications_rounded, 'Reminders', AppRoutes.reminders),
      _SheetItem(Icons.calendar_month_rounded, 'Calendar', AppRoutes.calendar),
      _SheetItem(Icons.settings_rounded, 'Settings', AppRoutes.settings),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.1,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children:
                items.map((item) => _buildActionTile(context, item)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, _SheetItem item) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, item.route);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: AppColors.primary, size: 26),
            const SizedBox(height: 6),
            Text(item.label,
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _SheetItem {
  final IconData icon;
  final String label;
  final String route;
  _SheetItem(this.icon, this.label, this.route);
}
