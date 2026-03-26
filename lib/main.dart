import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_gate.dart';
import 'get_started_page.dart';
import 'data/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox<int>('cart');
  await Hive.openBox<bool>('favorites');
  await Hive.openBox<bool>('settings');

  var firebaseReady = false;
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (_) {
    firebaseReady = false;
  }

  runApp(ProviderScope(child: MyApp(firebaseReady: firebaseReady)));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const greenSeed = Color(0xFF6CC51D);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'INSAF MARKET',
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: greenSeed, brightness: Brightness.light),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(color: greenSeed),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: greenSeed, width: 1.6),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: greenSeed, brightness: Brightness.dark),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(color: greenSeed),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: greenSeed, width: 1.6),
          ),
        ),
      ),
      home: firebaseReady ? const AuthGate() : const GetStartedPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
