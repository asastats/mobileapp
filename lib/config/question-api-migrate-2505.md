I had to update `lib/config/di_container.dart` as it was referencing the old constant. Please update the line to:
`sl.registerLazySingleton(() => DioClient(APIConstants.BASE_URL_V2, sl(),`

Please also check `test/widget_test.dart`. That's some old test module that is failing. I need you to see if we need to test that functionality and update the test module, and if we don't then just say and I'll delete the file.