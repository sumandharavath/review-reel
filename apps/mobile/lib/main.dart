import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_theme.dart';
import 'core/network/dio_client.dart';
import 'core/router/app_router.dart';
import 'core/storage/secure_storage_service.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'presentation/bloc/auth/auth_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Dark Status Bar / System Navigation Bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF181820),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Core Services & Clean Architecture Dependency Injection
  final secureStorage = SecureStorageService();
  final dioClient = DioClient(secureStorage: secureStorage);
  final authRemoteDataSource = AuthRemoteDataSourceImpl(dioClient: dioClient);
  final authRepository = AuthRepositoryImpl(
    remoteDataSource: authRemoteDataSource,
    secureStorage: secureStorage,
  );

  final authBloc = AuthBloc(authRepository: authRepository);
  final appRouter = AppRouter(authBloc: authBloc);

  runApp(ReviewReelApp(
    authBloc: authBloc,
    appRouter: appRouter,
  ));
}

class ReviewReelApp extends StatelessWidget {
  final AuthBloc authBloc;
  final AppRouter appRouter;

  const ReviewReelApp({
    super.key,
    required this.authBloc,
    required this.appRouter,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: authBloc,
      child: MaterialApp.router(
        title: 'Review Reel',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: appRouter.router,
      ),
    );
  }
}
