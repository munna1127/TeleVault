import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'constants.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';
import 'services/telegram_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  final StorageService storage = StorageService();
  await storage.init();

  runApp(TeleVaultApp(storage: storage));
}

class TeleVaultApp extends StatelessWidget {
  const TeleVaultApp({super.key, required this.storage});

  final StorageService storage;

  @override
  Widget build(BuildContext context) {
    const Color seed = Color(0xFF2AABEE); // Telegram-esque blue.

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<StorageService>.value(value: storage),
        ChangeNotifierProvider<TelegramService>(
          create: (_) => TelegramService(storage: storage),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: seed),
          appBarTheme: const AppBarTheme(centerTitle: false),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: seed,
            brightness: Brightness.dark,
          ),
          appBarTheme: const AppBarTheme(centerTitle: false),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
