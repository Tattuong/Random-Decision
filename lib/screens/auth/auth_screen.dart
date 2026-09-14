import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shop_provider.dart';
import '../../widgets/app_toast.dart';

class AuthScreen extends StatefulWidget {
  final bool startOnRegister;

  const AuthScreen({super.key, this.startOnRegister = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool _registerMode;
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _registerMode = widget.startOnRegister;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  String? _emailValidator(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return AppStrings.t(context, 'authEmailRequired');
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return AppStrings.t(context, 'authEmailInvalid');
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    if ((value ?? '').length < 6) {
      return AppStrings.t(context, 'authPasswordShort');
    }
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthProvider>();
    final email = _emailCtrl.text.trim().toLowerCase();
    final password = _passwordCtrl.text;
    final nickname = _nicknameCtrl.text.trim().isEmpty
        ? email.split('@').first
        : _nicknameCtrl.text.trim();

    final error = _registerMode
        ? await auth.register(email, password, nickname)
        : await auth.login(email, password);

    if (!mounted) return;
    if (error != null) {
      AppToast.show(
        context,
        title: AppStrings.t(context, error),
        icon: Icons.error_outline_rounded,
        color: AppColors.error,
      );
      return;
    }

    AppToast.show(
      context,
      title: AppStrings.t(context, _registerMode ? 'authRegisterSuccess' : 'authLoginSuccess'),
      icon: Icons.check_circle_rounded,
      color: AppColors.success,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final preset = context.watch<ShopProvider>().activeTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppStrings.t(context, _registerMode ? 'authRegisterTitle' : 'authLoginTitle')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: preset.headerGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _registerMode ? Icons.person_add_alt_1_rounded : Icons.login_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.t(context, _registerMode ? 'authRegisterHeadline' : 'authLoginHeadline'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppStrings.t(context, 'authOptionalHint'),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  if (_registerMode) ...[
                    TextFormField(
                      controller: _nicknameCtrl,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: AppStrings.t(context, 'authNickname'),
                        hintText: AppStrings.t(context, 'authNicknameHint'),
                        prefixIcon: const Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: _emailValidator,
                    decoration: InputDecoration(
                      labelText: AppStrings.t(context, 'authEmail'),
                      prefixIcon: const Icon(Icons.mail_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    autofillHints: _registerMode
                        ? const [AutofillHints.newPassword]
                        : const [AutofillHints.password],
                    validator: _passwordValidator,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: AppStrings.t(context, 'authPassword'),
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: auth.isBusy ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: auth.isBusy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                    )
                  : Text(
                      AppStrings.t(context, _registerMode ? 'authRegisterAction' : 'authLoginAction'),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: auth.isBusy ? null : () => setState(() => _registerMode = !_registerMode),
              child: Text(
                AppStrings.t(context, _registerMode ? 'authHaveAccount' : 'authNeedAccount'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
