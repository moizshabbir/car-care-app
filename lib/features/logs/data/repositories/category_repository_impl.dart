import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:carlog/features/logs/data/models/category_model.dart';
import 'package:carlog/features/logs/domain/repositories/category_repository.dart';

@LazySingleton(as: CategoryRepository)
class CategoryRepositoryImpl implements CategoryRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  CategoryRepositoryImpl(this._firestore, this._firebaseAuth);

  @override
  Future<List<CategoryModel>> getCategories() async {
    final userId = _firebaseAuth.currentUser?.uid;
    if (userId == null) return [];

    var box = Hive.isBoxOpen('categories')
        ? Hive.box<CategoryModel>('categories')
        : await Hive.openBox<CategoryModel>('categories');

    List<CategoryModel> categories = box.values.toList();

    if (categories.isEmpty) {
      // Seed default categories
      final defaultCats = [
        CategoryModel(id: '1', name: 'General', type: 'general', iconCodePoint: Icons.category.codePoint),
        CategoryModel(id: '2', name: 'Maintenance', type: 'general', iconCodePoint: Icons.car_repair.codePoint),
        CategoryModel(id: '3', name: 'Repair', type: 'general', iconCodePoint: Icons.build.codePoint),
        CategoryModel(id: '4', name: 'Insurance', type: 'general', iconCodePoint: Icons.security.codePoint),
        CategoryModel(id: '5', name: 'Fuel', type: 'general', iconCodePoint: Icons.local_gas_station.codePoint),
        CategoryModel(id: '6', name: 'Misc', type: 'general', iconCodePoint: Icons.more_horiz.codePoint),
      ];

      for (var cat in defaultCats) {
        await box.put(cat.id, cat);
      }
      categories = defaultCats;

      // Try fetching from Firestore for user-defined ones
      try {
        final snapshot = await _firestore
            .collection('categories')
            .where('userId', isEqualTo: userId)
            .get();

        final remoteCats = snapshot.docs.map((doc) => CategoryModel.fromJson(doc.data())).toList();
        for (var cat in remoteCats) {
          await box.put(cat.id, cat);
          if (!categories.any((c) => c.id == cat.id)) {
            categories.add(cat);
          }
        }
      } catch (e) {
        debugPrint("Error fetching categories from Firestore: $e");
      }
    }

    return categories;
  }

  @override
  Future<void> addCategory(CategoryModel category) async {
    final userId = _firebaseAuth.currentUser?.uid;
    if (userId == null) throw Exception("User not authenticated");

    var box = Hive.isBoxOpen('categories')
        ? Hive.box<CategoryModel>('categories')
        : await Hive.openBox<CategoryModel>('categories');

    await box.put(category.id, category);

    // Save to Firestore if user-defined
    if (category.type == 'user_defined') {
      final json = category.toJson();
      json['userId'] = userId;
      await _firestore.collection('categories').doc(category.id).set(json);
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    var box = Hive.isBoxOpen('categories')
        ? Hive.box<CategoryModel>('categories')
        : await Hive.openBox<CategoryModel>('categories');

    final category = box.get(id);
    if (category != null && category.type == 'user_defined') {
      await box.delete(id);
      await _firestore.collection('categories').doc(id).delete();
    }
  }
}
