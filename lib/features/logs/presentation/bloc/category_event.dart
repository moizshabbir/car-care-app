import 'package:equatable/equatable.dart';
import 'package:carlog/features/logs/data/models/category_model.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();
  @override
  List<Object> get props => [];
}

class LoadCategories extends CategoryEvent {}

class AddUserCategory extends CategoryEvent {
  final String name;
  final int iconCodePoint;
  const AddUserCategory({required this.name, required this.iconCodePoint});
  @override
  List<Object> get props => [name, iconCodePoint];
}

class DeleteUserCategory extends CategoryEvent {
  final String id;
  const DeleteUserCategory(this.id);
  @override
  List<Object> get props => [id];
}
