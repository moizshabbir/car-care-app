// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:cloud_firestore/cloud_firestore.dart' as _i974;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import 'core/config/firebase_module.dart' as _i819;
import 'core/services/location_service.dart' as _i65;
import 'core/services/ocr_service.dart' as _i400;
import 'features/logs/data/repositories/log_repository_impl.dart' as _i425;
import 'features/logs/domain/repositories/log_repository.dart' as _i349;
import 'features/logs/presentation/bloc/quick_log_bloc.dart' as _i795;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final firebaseModule = _$FirebaseModule();
    gh.lazySingleton<_i974.FirebaseFirestore>(() => firebaseModule.firestore);
    gh.lazySingleton<_i65.LocationService>(() => _i65.LocationService());
    gh.lazySingleton<_i400.OCRService>(() => _i400.OCRService());
    gh.lazySingleton<_i349.LogRepository>(
        () => _i425.LogRepositoryImpl(gh<_i974.FirebaseFirestore>()));
    gh.factory<_i795.QuickLogBloc>(() => _i795.QuickLogBloc(
          gh<_i400.OCRService>(),
          gh<_i65.LocationService>(),
          gh<_i349.LogRepository>(),
        ));
    return this;
  }
}

class _$FirebaseModule extends _i819.FirebaseModule {}
