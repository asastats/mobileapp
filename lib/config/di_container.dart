import 'package:asa_stats/data/datasource/remote/dio/logging_interceptor.dart';
import 'package:asa_stats/data/repository/app_setting_repo.dart';
import 'package:asa_stats/providers/app_setting_provider.dart';
import 'package:asa_stats/providers/menu_provider.dart';
import 'package:asa_stats/providers/theme_provider.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:asa_stats/config/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/datasource/remote/dio/dio_client.dart';
import '../data/repository/auth_repo.dart';
import '../providers/asa_provider.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // For API AND FIREBASE

  //? Core
  sl.registerLazySingleton(() => DioClient(APIConstants.BASE_URL, sl(),
      loggingInterceptor: sl(), sharedPreferences: sl()));

  //? Repository
  sl.registerLazySingleton(
      () => ASArepo(dioClient: sl(), sharedPreferences: sl()));
  sl.registerLazySingleton(() => AppSettingRepo(sharedPreferences: sl()));

  //? Provider
  sl.registerFactory(() => ASAProvider(asaRepo: sl()));
  sl.registerFactory(() => MenuProvider());
  sl.registerFactory(() => AppSettingProvider(appSettingRepo: sl()));
  sl.registerFactory(() => ThemeProvider(sharedPreferences: sl()));

  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => LoggingInterceptor());
  sl.registerLazySingleton(() => Dio());
}
