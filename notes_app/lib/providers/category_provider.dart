import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../models/category_model.dart';

class CategoryProvider extends ChangeNotifier {
  final AppDatabase _db = AppDatabase();

  List<CategoryModel> _categories = [];
  bool _loading = false;

  List<CategoryModel> get categories => _categories;
  bool get loading => _loading;

  List<String> get categoryNames => _categories.map((c) => c.name).toList();

  Future<void> loadCategories() async {
    _loading = true;
    notifyListeners();
    _categories = await _db.getAllCategories();
    _loading = false;
    notifyListeners();
  }

  Future<bool> addCategory({
    required String name,
    required String icon,
    required int colorValue,
  }) async {
    if (name.trim().isEmpty) return false;
    if (_categories.any((c) => c.name.toLowerCase() == name.toLowerCase())) {
      return false;
    }
    final cat = CategoryModel(
      name: name.trim(),
      icon: icon,
      colorValue: colorValue,
      isDefault: false,
      createdAt: DateTime.now(),
    );
    await _db.insertCategory(cat);
    await loadCategories();
    return true;
  }

  Future<bool> updateCategory(CategoryModel category) async {
    if (category.isDefault) return false;
    await _db.updateCategory(category);
    await loadCategories();
    return true;
  }

  Future<bool> deleteCategory(CategoryModel category) async {
    if (category.isDefault || category.id == null) return false;
    await _db.deleteCategory(category.id!);
    await loadCategories();
    return true;
  }

  CategoryModel? findByName(String name) {
    try {
      return _categories
          .firstWhere((c) => c.name.toLowerCase() == name.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  // Emoji options for category creation
  static const List<String> emojiOptions = [
    '📁',
    '📝',
    '💼',
    '📚',
    '🏢',
    '💡',
    '⭐',
    '💰',
    '❤️',
    '🎯',
    '🚀',
    '🎨',
    '🎵',
    '🏋️',
    '🌍',
    '🔑',
    '📅',
    '💻',
    '📷',
    '🛒',
    '🍎',
    '🎮',
    '✈️',
    '🏠',
  ];
}
