import 'package:bloc_test/bloc_test.dart';
import 'package:carlog/features/logs/data/models/category_model.dart';
import 'package:carlog/features/logs/domain/repositories/category_repository.dart';
import 'package:carlog/features/logs/presentation/bloc/category_bloc.dart';
import 'package:carlog/features/logs/presentation/bloc/category_event.dart';
import 'package:carlog/features/logs/presentation/bloc/category_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late CategoryBloc categoryBloc;
  late MockCategoryRepository mockCategoryRepository;

  setUp(() {
    mockCategoryRepository = MockCategoryRepository();
    categoryBloc = CategoryBloc(mockCategoryRepository);
    registerFallbackValue(FakeCategoryModel());
  });

  tearDown(() {
    categoryBloc.close();
  });

  group('CategoryBloc', () {
    final categories = [
      CategoryModel(id: '1', name: 'General', type: 'general', iconCodePoint: 0),
    ];

    test('initial state is correct', () {
      expect(categoryBloc.state, const CategoryState());
    });

    blocTest<CategoryBloc, CategoryState>(
      'emits [loading, loaded] when LoadCategories is successful',
      build: () {
        when(() => mockCategoryRepository.getCategories())
            .thenAnswer((_) async => categories);
        return categoryBloc;
      },
      act: (bloc) => bloc.add(LoadCategories()),
      expect: () => [
        const CategoryState(status: CategoryStatus.loading),
        CategoryState(status: CategoryStatus.loaded, categories: categories),
      ],
    );

    blocTest<CategoryBloc, CategoryState>(
      'emits [loading, error] when LoadCategories fails',
      build: () {
        when(() => mockCategoryRepository.getCategories())
            .thenThrow(Exception('Failed to load'));
        return categoryBloc;
      },
      act: (bloc) => bloc.add(LoadCategories()),
      expect: () => [
        const CategoryState(status: CategoryStatus.loading),
        isA<CategoryState>().having((s) => s.status, 'status', CategoryStatus.error),
      ],
    );

    blocTest<CategoryBloc, CategoryState>(
      'reloads categories after adding a new one',
      build: () {
        when(() => mockCategoryRepository.addCategory(any()))
            .thenAnswer((_) async => {});
        when(() => mockCategoryRepository.getCategories())
            .thenAnswer((_) async => categories);
        return categoryBloc;
      },
      act: (bloc) => bloc.add(const AddUserCategory(name: 'New', iconCodePoint: 1)),
      verify: (_) {
        verify(() => mockCategoryRepository.addCategory(any())).called(1);
        verify(() => mockCategoryRepository.getCategories()).called(1);
      },
    );
  });
}

class FakeCategoryModel extends Fake implements CategoryModel {}
