import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

class ThemeNotifier extends Notifier<ThemeMode> {
  late Box<bool> _box;

  @override
  ThemeMode build() {
    _box = Hive.box<bool>('settings');
    final isDark = _box.get('isDark', defaultValue: false) ?? false;
    return isDark ? ThemeMode.dark : ThemeMode.light;
  }

  void toggleTheme() {
    final isDark = state == ThemeMode.dark;
    _box.put('isDark', !isDark);
    state = !isDark ? ThemeMode.dark : ThemeMode.light;
  }
}
