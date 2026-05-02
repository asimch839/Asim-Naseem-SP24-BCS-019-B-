import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/category_model.dart';
import '../../providers/category_provider.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/dialogs/confirmation_dialog.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories 📁'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddDialog(context),
          ),
        ],
      ),
      body: Consumer<CategoryProvider>(
        builder: (_, prov, __) {
          if (prov.loading)
            return const Center(child: CircularProgressIndicator());
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: prov.categories.length,
            itemBuilder: (_, i) => _CategoryCard(cat: prov.categories[i]),
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _CategoryFormSheet(),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryModel cat;
  const _CategoryCard({required this.cat});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = Color(cat.colorValue);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
              child: Text(cat.icon, style: const TextStyle(fontSize: 20))),
        ),
        title: Text(cat.name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        subtitle: cat.isDefault
            ? const Text('Default',
                style: TextStyle(fontSize: 11, color: AppColors.primary))
            : null,
        trailing: cat.isDefault
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    onPressed: () => _showEditDialog(context, cat),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 18, color: AppColors.error),
                    onPressed: () => _delete(context, cat),
                  ),
                ],
              ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, CategoryModel cat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CategoryFormSheet(existing: cat),
    );
  }

  Future<void> _delete(BuildContext context, CategoryModel cat) async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Delete Category?',
      message:
          '"${cat.name}" will be deleted. Notes in this category will remain.',
      confirmText: 'Delete',
      icon: Icons.delete_outline_rounded,
    );
    if (confirm == true && context.mounted) {
      final ok = await context.read<CategoryProvider>().deleteCategory(cat);
      if (context.mounted) {
        AppSnackbar.show(
          context,
          ok ? 'Category deleted' : 'Cannot delete default category',
          type: ok ? SnackbarType.success : SnackbarType.error,
        );
      }
    }
  }
}

class _CategoryFormSheet extends StatefulWidget {
  final CategoryModel? existing;
  const _CategoryFormSheet({this.existing});

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  late TextEditingController _nameCtrl;
  late String _selectedEmoji;
  late int _colorValue;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _selectedEmoji = widget.existing?.icon ?? '📁';
    _colorValue = widget.existing?.colorValue ?? 0xFF6C63FF;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      AppSnackbar.show(context, 'Enter a category name',
          type: SnackbarType.error);
      return;
    }
    final prov = context.read<CategoryProvider>();
    bool ok;
    if (widget.existing != null) {
      ok = await prov.updateCategory(widget.existing!.copyWith(
        name: _nameCtrl.text.trim(),
        icon: _selectedEmoji,
        colorValue: _colorValue,
      ));
    } else {
      ok = await prov.addCategory(
        name: _nameCtrl.text.trim(),
        icon: _selectedEmoji,
        colorValue: _colorValue,
      );
    }
    if (!mounted) return;
    Navigator.pop(context);
    AppSnackbar.show(
      context,
      ok
          ? (widget.existing != null ? 'Category updated' : 'Category added')
          : 'Category already exists',
      type: ok ? SnackbarType.success : SnackbarType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          Text(widget.existing != null ? 'Edit Category' : 'New Category',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
                labelText: 'Category Name',
                prefixIcon: Icon(Icons.label_outline_rounded)),
          ),
          const SizedBox(height: 16),
          Text('Choose Icon', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CategoryProvider.emojiOptions.map((e) {
              final selected = e == _selectedEmoji;
              return GestureDetector(
                onTap: () => setState(() => _selectedEmoji = e),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color:
                            selected ? AppColors.primary : Colors.transparent),
                  ),
                  child: Center(
                      child: Text(e, style: const TextStyle(fontSize: 20))),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Color', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(width: 12),
              ...AppColors.categoryColors.take(8).map((c) {
                final selected = c.value == _colorValue;
                return GestureDetector(
                  onTap: () => setState(() => _colorValue = c.value),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: selected ? Colors.black38 : Colors.transparent,
                          width: 2.5),
                    ),
                    child: selected
                        ? const Icon(Icons.check_rounded,
                            size: 16, color: Colors.white)
                        : null,
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _save,
              child: Text(
                  widget.existing != null ? 'Update Category' : 'Add Category'),
            ),
          ),
        ],
      ),
    );
  }
}
