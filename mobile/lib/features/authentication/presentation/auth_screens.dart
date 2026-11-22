import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../settings/presentation/settings_controller.dart';
import 'auth_controller.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool register = false;
  bool phoneMode = false;
  String accountType = 'personal';
  final name = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();
  final phone = TextEditingController();
  final smsCode = TextEditingController();
  final form = GlobalKey<FormState>();

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    pass.dispose();
    phone.dispose();
    smsCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final auth = context.watch<AuthController>();

    void switchPhoneMode() {
      setState(() {
        phoneMode = !phoneMode;
        register = false;
        smsCode.clear();
        auth.resetPhoneFlow();
      });
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      s.t('app_name'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w700,
                        color: DeenColors.accent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.t('tagline'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: DeenColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (!auth.available)
                      DeenCard(
                        color: DeenColors.sage,
                        child: Text(s.t('firebase_missing'), style: const TextStyle(height: 1.6)),
                      ),
                    if (auth.available && phoneMode) ...[
                      Text(
                        'ফোন নম্বর দিয়ে প্রবেশ',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'ফোন নম্বর',
                          hintText: '+8801XXXXXXXXX',
                          helperText: 'দেশের কোডসহ আন্তর্জাতিক ফরম্যাটে লিখুন',
                        ),
                        validator: (value) {
                          final v = (value ?? '').trim();
                          return RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(v)
                              ? null
                              : 'যেমন +8801XXXXXXXXX লিখুন';
                        },
                      ),
                      const SizedBox(height: 12),
                      if (auth.phoneCodeSent) ...[
                        TextFormField(
                          controller: smsCode,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: const InputDecoration(
                            labelText: 'SMS verification code',
                            hintText: '৬ সংখ্যার কোড',
                          ),
                          validator: (value) =>
                              (value ?? '').trim().length == 6 ? null : '৬ সংখ্যার কোড লিখুন',
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: auth.busy
                              ? null
                              : () async {
                                  if (smsCode.text.trim().length != 6) return;
                                  await auth.verifyPhoneCode(smsCode.text);
                                },
                          child: auth.busy
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('কোড যাচাই করে প্রবেশ করুন'),
                        ),
                        TextButton(
                          onPressed: auth.busy
                              ? null
                              : () async {
                                  smsCode.clear();
                                  auth.resetPhoneFlow();
                                  await auth.sendPhoneCode(phone.text);
                                },
                          child: const Text('নতুন কোড পাঠান'),
                        ),
                      ] else
                        FilledButton(
                          onPressed: auth.busy
                              ? null
                              : () async {
                                  if (!(form.currentState?.validate() ?? false)) return;
                                  await auth.sendPhoneCode(phone.text);
                                },
                          child: auth.busy
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('SMS কোড পাঠান'),
                        ),
                      if (auth.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(auth.error!, style: const TextStyle(color: Colors.red)),
                        ),
                      TextButton(
                        onPressed: auth.busy ? null : switchPhoneMode,
                        child: const Text('ইমেইল দিয়ে প্রবেশ করুন'),
                      ),
                    ],
                    if (auth.available && !phoneMode) ...[
                      if (register) ...[
                        TextFormField(
                          controller: name,
                          decoration: InputDecoration(labelText: s.t('name')),
                          validator: (v) => (v ?? '').trim().isEmpty ? '•' : null,
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(labelText: s.t('email')),
                        validator: (v) => (v ?? '').contains('@') ? null : '•',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: pass,
                        obscureText: true,
                        decoration: InputDecoration(labelText: s.t('password')),
                        validator: (v) => (v ?? '').length >= 6 ? null : '•',
                      ),
                      if (register) ...[
                        const SizedBox(height: 12),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'personal', label: Text('Personal')),
                            ButtonSegment(value: 'public', label: Text('Public')),
                          ],
                          selected: {accountType},
                          onSelectionChanged: (v) => setState(() => accountType = v.first),
                        ),
                      ],
                      if (auth.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(auth.error!, style: const TextStyle(color: Colors.red)),
                        ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: auth.busy
                            ? null
                            : () async {
                                if (!(form.currentState?.validate() ?? false)) return;
                                if (register) {
                                  await auth.register(name.text, email.text, pass.text, accountType);
                                } else {
                                  await auth.signIn(email.text, pass.text);
                                }
                              },
                        child: auth.busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(register ? s.t('register') : s.t('login')),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                        onPressed: auth.busy ? null : () => auth.google(),
                        child: Text(s.t('google_signin')),
                      ),
                      if (!register) ...[
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                          ),
                          child: Text(s.t('forgot_password')),
                        ),
                        TextButton(
                          onPressed: auth.busy ? null : switchPhoneMode,
                          child: const Text('ফোন নম্বর দিয়ে OTP প্রবেশ'),
                        ),
                      ],
                      TextButton(
                        onPressed: () => setState(() => register = !register),
                        child: Text(register ? s.t('have_account') : s.t('no_account')),
                      ),
                    ],
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.read<SettingsController>().setGuest(true),
                      child: Text(s.t('continue_guest')),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final l in const [('bn', 'বাংলা'), ('en', 'English'), ('ar', 'العربية')])
                          TextButton(
                            onPressed: () => context.read<SettingsController>().setLang(l.$1),
                            child: Text(l.$2),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final email = TextEditingController();

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final auth = context.watch<AuthController>();
    return Scaffold(
      appBar: AppBar(title: Text(s.t('forgot_password'))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: s.t('email')),
            ),
            if (auth.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(auth.error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: auth.busy
                  ? null
                  : () async {
                      final ok = await auth.reset(email.text);
                      if (ok && context.mounted) {
                        showMsg(context, s.t('reset_sent'));
                        Navigator.pop(context);
                      }
                    },
              child: Text(s.t('send_reset')),
            ),
          ],
        ),
      ),
    );
  }
}
