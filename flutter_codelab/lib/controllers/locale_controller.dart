import 'package:flutter/material.dart';

class LocaleController extends ValueNotifier<Locale> {
  // Private constructor
  LocaleController._() : super(const Locale('en'));

  // Singleton instance
  static final LocaleController instance = LocaleController._();

  void switchLocale(Locale newLocale) {
    value = newLocale;
  }
}
