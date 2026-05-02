import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/search_provider.dart';
import '../../widgets/cards/note_card.dart';
import '../../widgets/common/empty_state_widget.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            context.read<SearchProvider>().clearSearch();
            Navigator.pop(context);
          },
        ),
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          onChanged: (q) => context.read<SearchProvider>().search(q),
          style: TextStyle(
            fontSize: 16,
            color:
                isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Search notes, tags, categories...',
            hintStyle: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
            suffixIcon: ValueListenableBuilder(
              valueListenable: _ctrl,
              builder: (_, v, __) => v.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _ctrl.clear();
                        context.read<SearchProvider>().clearSearch();
                      },
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
      body: Consumer<SearchProvider>(
        builder: (_, prov, __) {
          if (!prov.hasQuery) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_rounded,
                      size: 64,
                      color: isDark
                          ? AppColors.darkTextHint
                          : AppColors.lightTextHint),
                  const SizedBox(height: 16),
                  Text('Search your notes',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text('by title, content, tags, category or priority',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center),
                ],
              ),
            );
          }
          if (prov.searching) {
            return const Center(child: CircularProgressIndicator());
          }
          if (prov.results.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.search_off_rounded,
              title: 'No Results',
              subtitle: 'No notes match "${prov.query}"',
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  '${prov.results.length} result${prov.results.length == 1 ? '' : 's'} for "${prov.query}"',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Expanded(
                child: MasonryGridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  itemCount: prov.results.length,
                  itemBuilder: (_, i) {
                    final note = prov.results[i];
                    return NoteCard(
                      note: note,
                      isGrid: true,
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.noteEditor,
                        arguments: note,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
