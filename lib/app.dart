import 'package:flutter/material.dart';
import 'main_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8F8F8);
  static const Color primary = Color(0xFF1A1B1E);
  static const Color accent = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline First Articles',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          surface: background,
          onSurface: primary,
          secondary: Colors.grey[600]!,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: primary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          iconTheme: IconThemeData(color: primary),
        ),
        cardTheme: CardTheme(
          color: background,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.grey.withAlpha(30), width: 1),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: primary, 
            fontWeight: FontWeight.w800, 
            fontSize: 32,
            letterSpacing: -1.0,
          ),
          titleLarge: TextStyle(
            color: primary, 
            fontWeight: FontWeight.w700, 
            fontSize: 20,
            letterSpacing: -0.5,
          ),
          bodyLarge: TextStyle(
            color: primary, 
            height: 1.6, 
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            color: primary, 
            height: 1.5,
            fontSize: 14,
          ),
          labelLarge: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      home: const MainScreen(),
    );
  }
}
