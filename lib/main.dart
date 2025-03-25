import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/weatherpage.dart';
import 'services/city_service.dart';
import 'services/theme_service.dart';
import 'services/weatherservices.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cityService = CityService();
  await cityService.initialize();
  final themeService = ThemeService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CityService>(
          create: (context) => cityService,
        ),
        ChangeNotifierProvider<ThemeService>(
          create: (context) => themeService,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp(
          title: 'WeatheroGUI',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            fontFamily: 'Roboto',
            cardTheme: CardTheme(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              centerTitle: true,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
              primary: Colors.lightBlue,
              secondary: Colors.lightBlueAccent,
            ),
            fontFamily: 'Roboto',
            cardTheme: CardTheme(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              centerTitle: true,
            ),
          ),
          themeMode: themeService.themeMode,
          home: const WeatherPage(),
        );
      },
    );
  }
}
