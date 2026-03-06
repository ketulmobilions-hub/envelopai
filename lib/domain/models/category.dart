import 'package:equatable/equatable.dart';

class Category extends Equatable {
  const Category({
    required this.id,
    required this.groupId,
    required this.name,
    required this.sortOrder,
    this.note,
    this.goalId,
  });

  final String id;
  final String groupId;
  final String name;
  final int sortOrder;
  final String? note;
  final String? goalId;

  Category copyWith({
    String? id,
    String? groupId,
    String? name,
    int? sortOrder,
    String? note,
    String? goalId,
  }) {
    return Category(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      note: note ?? this.note,
      goalId: goalId ?? this.goalId,
    );
  }

  @override
  List<Object?> get props => [id, groupId, name, sortOrder, note, goalId];
}
