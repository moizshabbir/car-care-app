import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'features/logs/domain/repositories/log_repository.dart';
import 'features/logs/presentation/bloc/expense_log_bloc.dart';
import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init', // default
  preferRelativeImports: true, // default
  asExtension: true, // default
)
void configureDependencies({String? environment}) {
  getIt.init(environment: environment);

  // Dependencies that are missing the @injectable annotation
  if (!getIt.isRegistered<ExpenseLogBloc>()) {
    getIt.registerFactory(() => ExpenseLogBloc(getIt<LogRepository>()));
  }
}
