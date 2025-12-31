import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/item_list/item_list_bloc.dart';
import 'presentation/bloc/item_list/item_list_event.dart';
import 'presentation/screens/splash_screen.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/storage_repository.dart';
import 'data/repositories/otp_repository.dart';
import 'data/repositories/item_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(
          create: (context) => AuthRepository(),
        ),
        RepositoryProvider<StorageRepository>(
          create: (context) => StorageRepository(),
        ),
        RepositoryProvider<OtpRepository>(create: (context) => OtpRepository()),
        RepositoryProvider<ItemRepository>(
          create: (context) => ItemRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(
              authRepository: context.read<AuthRepository>(),
              storageRepository: context.read<StorageRepository>(),
              otpRepository: context.read<OtpRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) =>
                ItemListBloc(itemRepository: context.read<ItemRepository>())
                  ..add(const LoadItems()),
          ),
        ],
        child: MaterialApp(
          title: 'Login App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFFB74D),
            ),
            useMaterial3: true,
            primaryColor: const Color(0xFFFFB74D),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFFB74D)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFFB74D)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFFFB74D),
                  width: 2,
                ),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB74D),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
