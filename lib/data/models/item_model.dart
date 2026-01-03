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
  final DateTime? dueDate;
  final double? estimatedHours;
  final double? budget;
  final List<String>? attachments;

  const ItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.createdAt,
    required this.isActive,
    required this.userId,
    this.dueDate,
    this.estimatedHours,
    this.budget,
    this.attachments,
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
      dueDate: data['dueDate'] != null 
          ? (data['dueDate'] as Timestamp).toDate() 
          : null,
      estimatedHours: data['estimatedHours'] != null 
          ? (data['estimatedHours'] as num).toDouble() 
          : null,
      budget: data['budget'] != null 
          ? (data['budget'] as num).toDouble() 
          : null,
      attachments: data['attachments'] != null 
          ? List<String>.from(data['attachments'] as List) 
          : null,
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
      if (dueDate != null) 'dueDate': Timestamp.fromDate(dueDate!),
      if (estimatedHours != null) 'estimatedHours': estimatedHours,
      if (budget != null) 'budget': budget,
      if (attachments != null) 'attachments': attachments,
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
      dueDate: json['dueDate'] != null 
          ? DateTime.parse(json['dueDate'] as String) 
          : null,
      estimatedHours: json['estimatedHours'] != null 
          ? (json['estimatedHours'] as num).toDouble() 
          : null,
      budget: json['budget'] != null 
          ? (json['budget'] as num).toDouble() 
          : null,
      attachments: json['attachments'] != null 
          ? List<String>.from(json['attachments'] as List) 
          : null,
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
      if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
      if (estimatedHours != null) 'estimatedHours': estimatedHours,
      if (budget != null) 'budget': budget,
      if (attachments != null) 'attachments': attachments,
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
    DateTime? dueDate,
    double? estimatedHours,
    double? budget,
    List<String>? attachments,
  }) {
    return ItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      userId: userId ?? this.userId,
      dueDate: dueDate ?? this.dueDate,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      budget: budget ?? this.budget,
      attachments: attachments ?? this.attachments,
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
        dueDate,
        estimatedHours,
        budget,
        attachments,
      ];
}





