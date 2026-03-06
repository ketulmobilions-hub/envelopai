import 'package:equatable/equatable.dart';

class CategoryGroup extends Equatable {
  const CategoryGroup({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.isHidden,
  });

  final String id;
  final String name;
  final int sortOrder;
  final bool isHidden;

  CategoryGroup copyWith({
    String? id,
    String? name,
    int? sortOrder,
    bool? isHidden,
  }) {
    return CategoryGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      isHidden: isHidden ?? this.isHidden,
    );
  }

  @override
  List<Object?> get props => [id, name, sortOrder, isHidden];
}
