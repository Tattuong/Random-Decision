import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/wheel_provider.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/coin_balance_chip.dart';
import '../../widgets/coin_purchase_sheet.dart';
import '../auth/auth_screen.dart';
import '../main_shell.dart';
import '../privacy_policy_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopProvider>();
    final theme = context.watch<ThemeProvider>();
    final locale = context.watch<LocaleProvider>();
    final auth = context.watch<AuthProvider>();
    final wheel = context.read<WheelProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppStrings.t(context, 'settingsTitle')),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CoinBalanceChip(onTap: () => CoinPurchaseSheet.show(context)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle(AppStrings.t(context, 'accountSection')),
          _AccountCard(auth: auth),
          const SizedBox(height: 16),
          _SectionTitle(AppStrings.t(context, 'activeCustomization')),
          _InfoTile(
            icon: Icons.palette_outlined,
            title: AppStrings.t(context, 'activeTheme'),
            subtitle: AppStrings.t(context, _themeNameKey(shop.activeThemeId)),
          ),
          _InfoTile(
            icon: Icons.layers_outlined,
            title: AppStrings.t(context, 'activeBackground'),
            subtitle: AppStrings.t(context, _bgNameKey(shop.activeBackgroundId)),
          ),
          _InfoTile(
            icon: Icons.casino_outlined,
            title: AppStrings.t(context, 'activeSkin'),
            subtitle: AppStrings.t(context, _skinNameKey(shop.activeSkinId)),
          ),
          const SizedBox(height: 16),
          _SectionTitle(AppStrings.t(context, 'appearance')),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: Text(AppStrings.t(context, 'darkMode')),
            value: theme.isDarkMode,
            onChanged: (_) => theme.toggleTheme(),
          ),
          const SizedBox(height: 16),
          _SectionTitle(AppStrings.t(context, 'other')),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: Text(AppStrings.t(context, 'language')),
            subtitle: Text(locale.isVietnamese ? AppStrings.t(context, 'vietnamese') : AppStrings.t(context, 'english')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickLanguage(context, locale),
          ),
          ListTile(
            leading: const Icon(Icons.restart_alt_outlined),
            title: Text(AppStrings.t(context, 'resetChoices')),
            subtitle: Text(AppStrings.t(context, 'resetChoicesDesc')),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(AppStrings.t(context, 'resetChoices')),
                  content: Text(AppStrings.t(context, 'resetChoicesConfirm')),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.t(context, 'cancel'))),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppStrings.t(context, 'save'))),
                  ],
                ),
              );
              if (ok == true) await wheel.resetToDefaults();
            },
          ),
          ListTile(
            leading: const Icon(Icons.stars_outlined),
            title: Text(AppStrings.t(context, 'openShop')),
            subtitle: Text(AppStrings.t(context, 'openShopDesc')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => MainShell.of(context)?.openShop(),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(AppStrings.t(context, 'privacyPolicy')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              AppStrings.t(context, 'copyright'),
              style: TextStyle(color: AppColors.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickLanguage(BuildContext context, LocaleProvider locale) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 22)),
              title: Text(AppStrings.t(context, 'english')),
              trailing: !locale.isVietnamese ? Icon(Icons.check_rounded, color: context.brand) : null,
              onTap: () async {
                await locale.setEnglish();
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Text('🇻🇳', style: TextStyle(fontSize: 22)),
              title: Text(AppStrings.t(context, 'vietnamese')),
              trailing: locale.isVietnamese ? Icon(Icons.check_rounded, color: context.brand) : null,
              onTap: () async {
                await locale.setVietnamese();
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _themeNameKey(String id) => switch (id) {
        'theme_sunset' => 'shopThemeSunset',
        'theme_midnight' => 'shopThemeMidnight',
        'theme_tropical' => 'shopThemeTropical',
        'theme_sakura' => 'shopThemeSakura',
        _ => 'shopThemeSunset',
      };

  String _bgNameKey(String id) => switch (id) {
        'bg_sunrise' => 'shopBgSunrise',
        'bg_ocean' => 'shopBgOcean',
        'bg_aurora' => 'shopBgAurora',
        'bg_galaxy' => 'shopBgGalaxy',
        _ => 'shopBgSunrise',
      };

  String _skinNameKey(String id) => switch (id) {
        'skin_neon' => 'shopSkinNeon',
        'skin_classic' => 'shopSkinClassic',
        'skin_glass' => 'shopSkinGlass',
        _ => 'shopSkinNeon',
      };
}

class _AccountCard extends StatelessWidget {
  final AuthProvider auth;

  const _AccountCard({required this.auth});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = auth.user;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.brand.withValues(alpha: 0.12)),
      ),
      child: user == null
          ? Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: context.brand.withValues(alpha: 0.12),
                    child: Icon(Icons.person_outline_rounded, color: context.brand),
                  ),
                  title: Text(AppStrings.t(context, 'accountGuestTitle')),
                  subtitle: Text(AppStrings.t(context, 'accountGuestDesc')),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () => _openAuth(context, register: false),
                          child: Text(AppStrings.t(context, 'authLoginAction')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _openAuth(context, register: true),
                          child: Text(AppStrings.t(context, 'authRegisterAction')),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: context.brand.withValues(alpha: 0.15),
                    child: Text(
                      _initials(user.displayName),
                      style: TextStyle(color: context.brand, fontWeight: FontWeight.w800),
                    ),
                  ),
                  title: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(user.email ?? AppStrings.t(context, 'accountSignedIn')),
                ),
                ListTile(
                  leading: const Icon(Icons.logout_rounded),
                  title: Text(AppStrings.t(context, 'authLogout')),
                  onTap: () => _confirmLogout(context),
                ),
              ],
            ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  Future<void> _openAuth(BuildContext context, {required bool register}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AuthScreen(startOnRegister: register)),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.t(context, 'authLogout')),
        content: Text(AppStrings.t(context, 'authLogoutConfirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.t(context, 'cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppStrings.t(context, 'authLogout'))),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    AppToast.show(
      context,
      title: AppStrings.t(context, 'authLogoutSuccess'),
      icon: Icons.check_circle_rounded,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.onSurfaceVariant)),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: context.brand),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
    );
  }
}
