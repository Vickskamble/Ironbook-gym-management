import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ironbook/core/utils/error_handler.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    ErrorHandler.logStep('LocaleNotifier', 'constructor');
    _load();
  }

  Future<void> _load() async {
    ErrorHandler.logStep('LocaleNotifier', '_load');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('language') ?? 'en';
    state = Locale(code);
  }

  Future<void> setLocale(String code) async {
    ErrorHandler.logStep('LocaleNotifier', 'setLocale', {'code': code});
    state = Locale(code);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', code);
  }
}
