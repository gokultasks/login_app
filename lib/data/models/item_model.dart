import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ItemModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime createdAt;
  final bool isActive;
  final String userId;

  const ItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.createdAt,
    required this.isActive,
    required this.userId,
  });

  factory ItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ItemModel(
      id: doc.id,
      title: data['title'] as String,
      description: data['description'] as String,
      category: data['category'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] as bool,
      userId: data['userId'] as String,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'userId': userId,
    };
  }

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool,
      userId: json['userId'] as String,
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
      'userId': userId,
    };
  }

  ItemModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    DateTime? createdAt,
    bool? isActive,
    String? userId,
  }) {
    return ItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      userId: userId ?? this.userId,
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
        userId,
      ];
}
  

