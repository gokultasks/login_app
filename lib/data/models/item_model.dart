import 'package:equatable/equatable.dart';

class ItemModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime createdAt;
  final bool isActive;

  const ItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.createdAt,
    required this.isActive,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  ItemModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return ItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    category,
    createdAt,
    isActive,
  ];
}
