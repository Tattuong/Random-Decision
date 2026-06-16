import 'package:flutter/material.dart';

import '../core/services/storage_service.dart';

class LocaleProvider extends ChangeNotifier {
  static const _storageKey = 'app_locale';

  Locale _locale = const Locale('en');

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;
  bool get isVietnamese => _locale.languageCode == 'vi';

  static Locale _localeFromCode(String code) =>
      code == 'vi' ? const Locale('vi') : const Locale('en');

  static Locale _systemLocale() {
    final code = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return _localeFromCode(code);
  }

  Future<void> init() async {
    final saved = await StorageService.instance.getString(_storageKey);
    if (saved == 'vi' || saved == 'en') {
      _locale = _localeFromCode(saved!);
      return;
    }

    _locale = _systemLocale();
    await StorageService.instance.saveString(_storageKey, _locale.languageCode);
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    await StorageService.instance.saveString(_storageKey, locale.languageCode);
    notifyListeners();
  }

  Future<void> setEnglish() => setLocale(const Locale('en'));
  Future<void> setVietnamese() => setLocale(const Locale('vi'));
}
