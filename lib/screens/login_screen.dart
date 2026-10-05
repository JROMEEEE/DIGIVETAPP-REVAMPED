import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api.dart';
import '../services/auth_service.dart';
import '../theme.dart';

/// Owner sign-in. Wrong credentials always show the server's one generic
/// message ("Invalid username or password") — the app never tries to tell
/// which part was wrong. There is no staff sign-in in this app.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onPetCode});

  /// Opens the Pet Code sign-up flow.
  final VoidCallback onPetCode;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _hidePassword = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _username.text.trim().isNotEmpty &&
      _password.text.isNotEmpty &&
      !_submitting;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await AuthService.instance.login(_username.text, _password.text);
      HapticFeedback.lightImpact();
      // The root gate now shows the signed-in home; drop this screen.
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on ApiException catch (e) {
      if (!mounted) return;
      _password.clear(); // never leave a rejected password sitting in the field
      setState(() {
        _submitting = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ColoredBox(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Back',
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  color: Brand.maroon900,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Header(),
                      const SizedBox(height: 32),
                      _Field(
                        controller: _username,
                        label: 'Username',
                        icon: Icons.person_outline,
                        enabled: !_submitting,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _passwordFocus.requestFocus(),
                      ),
                      const SizedBox(height: 14),
                      _Field(
                        controller: _password,
                        focusNode: _passwordFocus,
                        label: 'Password',
                        icon: Icons.lock_outline,
                        enabled: !_submitting,
                        obscure: _hidePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _submit(),
                        suffix: IconButton(
                          tooltip: _hidePassword
                              ? 'Show password'
                              : 'Hide password',
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          color: Brand.inkSoft,
                          onPressed: () =>
                              setState(() => _hidePassword = !_hidePassword),
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        alignment: Alignment.topCenter,
                        child: _error == null
                            ? const SizedBox(width: double.infinity)
                            : _ErrorBox(_error!),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        height: 54,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Brand.maroon700,
                            disabledBackgroundColor: Brand.maroon700.withValues(
                              alpha: 0.35,
                            ),
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: _canSubmit ? _submit : null,
                          child: _submitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Sign in'),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Brand.maroon700,
                          ),
                          onPressed: _submitting ? null : widget.onPetCode,
                          child: const Text.rich(
                            TextSpan(
                              text: 'New here? ',
                              style: TextStyle(color: Brand.inkSoft),
                              children: [
                                TextSpan(
                                  text: 'Sign up with a Pet Code',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Brand.maroon700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Brand.gold500, width: 3),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/digivet_logo.png',
              cacheWidth: 200,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Welcome back',
          style: TextStyle(
            fontFamily: Brand.serif,
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: Brand.maroon900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Sign in to see your pets’ records.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14.5, color: Brand.inkSoft),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    required this.enabled,
    required this.textInputAction,
    required this.autofillHints,
    required this.onChanged,
    required this.onSubmitted,
    this.focusNode,
    this.obscure = false,
    this.suffix,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final IconData icon;
  final bool enabled;
  final bool obscure;
  final TextInputAction textInputAction;
  final Iterable<String> autofillHints;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 1.2]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c, width: w),
    );
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      obscureText: obscure,
      // Credentials: no suggestions, no auto-capitalization or correction.
      autocorrect: false,
      enableSuggestions: false,
      textCapitalization: TextCapitalization.none,
      keyboardType: obscure
          ? TextInputType.visiblePassword
          : TextInputType.text,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: const TextStyle(fontSize: 16, color: Brand.ink),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Brand.inkSoft),
        floatingLabelStyle: const TextStyle(
          color: Brand.maroon700,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, color: Brand.inkSoft),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: border(Brand.border),
        enabledBorder: border(Brand.border),
        disabledBorder: border(Brand.border),
        focusedBorder: border(Brand.maroon700, 1.8),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFDECEA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE6B3B3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, size: 18, color: Color(0xFFB3261E)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.35,
                  color: Color(0xFFB3261E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
