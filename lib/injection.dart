import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'features/logs/presentation/bloc/dashboard_bloc.dart';
import 'features/logs/presentation/bloc/expense_log_bloc.dart';
import 'features/vehicles/domain/repositories/vehicle_repository.dart';
import 'features/vehicles/data/repositories/vehicle_repository_impl.dart';
import 'features/vehicles/presentation/bloc/vehicle_bloc.dart';
import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init', // default
  preferRelativeImports: true, // default
  asExtension: true, // default
)
void configureDependencies() {
  getIt.init();
  getIt.registerFactory(() => ExpenseLogBloc(getIt()));
  getIt.registerFactory(() => DashboardBloc(getIt()));
  getIt.registerLazySingleton<VehicleRepository>(() => VehicleRepositoryImpl(getIt()));
  getIt.registerFactory(() => VehicleBloc(getIt()));
}
