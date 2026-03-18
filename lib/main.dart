import 'package:flutter/material.dart';
import 'get_started_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const greenSeed = Color(0xFF6CC51D);
    return MaterialApp(
      title: 'INSAF MARKET',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: greenSeed),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
        ),
        progressIndicatorTheme:
            const ProgressIndicatorThemeData(color: greenSeed),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: greenSeed, width: 1.6),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? greenSeed
                : null,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? greenSeed.withValues(alpha: 0.35)
                : null,
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? greenSeed
                : null,
          ),
        ),
      ),
      home: const GetStartedPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
