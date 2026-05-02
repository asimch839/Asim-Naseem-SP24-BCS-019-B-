class CategoryModel {
  final int? id;
  final String name;
  final String icon;
  final int colorValue;
  final bool isDefault;
  final DateTime createdAt;

  CategoryModel({
    this.id,
    required this.name,
    required this.icon,
    required this.colorValue,
    this.isDefault = false,
    required this.createdAt,
  });

  CategoryModel copyWith({
    int? id,
    String? name,
    String? icon,
    int? colorValue,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colorValue: colorValue ?? this.colorValue,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'icon': icon,
      'color_value': colorValue,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String? ?? '📁',
      colorValue: map['color_value'] as int? ?? 0xFF6C63FF,
      isDefault: (map['is_default'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
