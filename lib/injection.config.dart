// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:cloud_firestore/cloud_firestore.dart' as _i974;
import 'package:firebase_analytics/firebase_analytics.dart' as _i398;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:firebase_performance/firebase_performance.dart' as _i346;
import 'package:get_it/get_it.dart' as _i174;
import 'package:google_sign_in/google_sign_in.dart' as _i116;
import 'package:injectable/injectable.dart' as _i526;

import 'core/config/firebase_module.dart' as _i819;
import 'core/services/ai_service.dart' as _i716;
import 'core/services/analytics_service.dart' as _i661;
import 'core/services/location_service.dart' as _i65;
import 'core/services/ocr_service.dart' as _i400;
import 'core/services/receipt_parser_service.dart' as _i729;
import 'core/services/settings_service.dart' as _i607;
import 'features/auth/data/repositories/auth_repository_impl.dart' as _i111;
import 'features/auth/domain/repositories/auth_repository.dart' as _i1015;
import 'features/auth/presentation/bloc/auth_bloc.dart' as _i363;
import 'features/logs/data/repositories/category_repository_impl.dart' as _i331;
import 'features/logs/data/repositories/log_repository_impl.dart' as _i425;
import 'features/logs/domain/repositories/category_repository.dart' as _i165;
import 'features/logs/domain/repositories/log_repository.dart' as _i349;
import 'features/logs/presentation/bloc/category_bloc.dart' as _i234;
import 'features/logs/presentation/bloc/dashboard_bloc.dart' as _i958;
import 'features/logs/presentation/bloc/expense_log_bloc.dart' as _i697;
import 'features/logs/presentation/bloc/quick_log_bloc.dart' as _i795;
import 'features/reports/presentation/bloc/reports_bloc.dart' as _i866;
import 'features/vehicles/data/repositories/vehicle_repository_impl.dart'
    as _i186;
import 'features/vehicles/domain/repositories/vehicle_repository.dart' as _i737;
import 'features/vehicles/presentation/bloc/vehicle_bloc.dart' as _i114;

const String _test = 'test';
const String _prod = 'prod';

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final mockFirebaseModule = _$MockFirebaseModule();
    final firebaseModule = _$FirebaseModule();
    gh.lazySingleton<_i65.LocationService>(() => _i65.LocationService());
    gh.lazySingleton<_i400.OCRService>(() => _i400.OCRService());
    gh.lazySingleton<_i59.FirebaseAuth>(
      () => mockFirebaseModule.firebaseAuth,
      registerFor: {_test},
    );
    gh.lazySingleton<_i116.GoogleSignIn>(
      () => mockFirebaseModule.googleSignIn,
      registerFor: {_test},
    );
    gh.lazySingleton<_i398.FirebaseAnalytics>(
      () => mockFirebaseModule.analytics,
      registerFor: {_test},
    );
    gh.lazySingleton<_i346.FirebasePerformance>(
      () => mockFirebaseModule.performance,
      registerFor: {_test},
    );
    gh.lazySingleton<_i974.FirebaseFirestore>(
      () => mockFirebaseModule.firestore,
      registerFor: {_test},
    );
    gh.lazySingleton<_i59.FirebaseAuth>(
      () => firebaseModule.firebaseAuth,
      registerFor: {_prod},
    );
    gh.lazySingleton<_i116.GoogleSignIn>(
      () => firebaseModule.googleSignIn,
      registerFor: {_prod},
    );
    gh.lazySingleton<_i398.FirebaseAnalytics>(
      () => firebaseModule.analytics,
      registerFor: {_prod},
    );
    gh.lazySingleton<_i346.FirebasePerformance>(
      () => firebaseModule.performance,
      registerFor: {_prod},
    );
    gh.lazySingleton<_i974.FirebaseFirestore>(
      () => firebaseModule.firestore,
      registerFor: {_prod},
    );
    gh.lazySingleton<_i1015.AuthRepository>(
      () => _i111.AuthRepositoryImpl(
        gh<_i59.FirebaseAuth>(),
        gh<_i116.GoogleSignIn>(),
      ),
    );
    gh.lazySingleton<_i349.LogRepository>(
      () => _i425.LogRepositoryImpl(
        gh<_i974.FirebaseFirestore>(),
        gh<_i59.FirebaseAuth>(),
      ),
    );
    gh.factory<_i697.ExpenseLogBloc>(
      () => _i697.ExpenseLogBloc(
        gh<_i349.LogRepository>(),
        gh<_i59.FirebaseAuth>(),
      ),
    );
    gh.singleton<_i661.AnalyticsService>(
      () => _i661.AnalyticsService(
        gh<_i398.FirebaseAnalytics>(),
        gh<_i346.FirebasePerformance>(),
      ),
    );
    gh.factory<_i363.AuthBloc>(
      () => _i363.AuthBloc(gh<_i1015.AuthRepository>()),
    );
    gh.lazySingleton<_i607.SettingsService>(
      () => _i607.SettingsService(
        gh<_i59.FirebaseAuth>(),
        gh<_i974.FirebaseFirestore>(),
      ),
      dispose: (i) => i.dispose(),
    );
    gh.factory<_i866.ReportsBloc>(
      () => _i866.ReportsBloc(gh<_i349.LogRepository>()),
    );
    gh.lazySingleton<_i737.VehicleRepository>(
      () => _i186.VehicleRepositoryImpl(
        gh<_i974.FirebaseFirestore>(),
        gh<_i59.FirebaseAuth>(),
      ),
    );
    gh.lazySingleton<_i165.CategoryRepository>(
      () => _i331.CategoryRepositoryImpl(
        gh<_i974.FirebaseFirestore>(),
        gh<_i59.FirebaseAuth>(),
      ),
    );
    gh.lazySingleton<_i716.AIService>(
      () => _i716.AIService(gh<_i607.SettingsService>()),
    );
    gh.factory<_i958.DashboardBloc>(
      () => _i958.DashboardBloc(
        gh<_i349.LogRepository>(),
        gh<_i607.SettingsService>(),
      ),
    );
    gh.factory<_i114.VehicleBloc>(
      () => _i114.VehicleBloc(gh<_i737.VehicleRepository>()),
    );
    gh.factory<_i234.CategoryBloc>(
      () => _i234.CategoryBloc(gh<_i165.CategoryRepository>()),
    );
    gh.lazySingleton<_i729.ReceiptParserService>(
      () => _i729.ReceiptParserService(gh<_i729.AIService>()),
    );
    gh.factory<_i795.QuickLogBloc>(
      () => _i795.QuickLogBloc(
        gh<_i400.OCRService>(),
        gh<_i65.LocationService>(),
        gh<_i349.LogRepository>(),
        gh<_i729.ReceiptParserService>(),
        gh<_i59.FirebaseAuth>(),
      ),
    );
    return this;
  }
}

class _$MockFirebaseModule extends _i819.MockFirebaseModule {}

class _$FirebaseModule extends _i819.FirebaseModule {}
