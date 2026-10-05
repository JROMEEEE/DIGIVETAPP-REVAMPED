import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api.dart';
import '../services/auth_service.dart';
import '../theme.dart';

/// Pet Code sign-up: enter the code from your pet's vaccine card, confirm the
/// masked name and pets are yours, then choose a username and password.
/// The server never says WHY a code is invalid (expired / used / unknown all
/// look the same), and neither does this screen.
class PetCodeScreen extends StatefulWidget {
  const PetCodeScreen({super.key});

  @override
  State<PetCodeScreen> createState() => _PetCodeScreenState();
}

enum _Step { code, confirm, account }

class _PetCodeScreenState extends State<PetCodeScreen> {
  _Step _step = _Step.code;
  final _code = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _hidePassword = true;
  bool _busy = false;
  String? _error;
  ClaimPreview? _preview;

  @override
  void dispose() {
    _code.dispose();
    _username.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _codeReady => _code.text.replaceAll('-', '').length == 10;
  bool get _accountReady =>
      _username.text.trim().isNotEmpty &&
      _password.text.isNotEmpty &&
      _confirm.text.isNotEmpty;

  void _goTo(_Step step) => setState(() {
    _step = step;
    _error = null;
  });

  void _back() {
    switch (_step) {
      case _Step.code:
        Navigator.of(context).pop();
      case _Step.confirm:
        _goTo(_Step.code);
      case _Step.account:
        _goTo(_Step.confirm);
    }
  }

  Future<void> _verify() async {
    if (!_codeReady || _busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final preview = await AuthService.instance.claimVerify(_code.text);
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _busy = false;
        _step = _Step.confirm;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    }
  }

  Future<void> _create() async {
    if (!_accountReady || _busy) return;
    if (_password.text.length < 8) {
      setState(() => _error = 'Your password must be at least 8 characters.');
      return;
    }
    if (_password.text != _confirm.text) {
      setState(() => _error = 'The two passwords don’t match.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthService.instance.claimRedeem(
        _code.text,
        _username.text,
        _password.text,
      );
      HapticFeedback.lightImpact();
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on ApiException catch (e) {
      if (!mounted) return;
      _password.clear();
      _confirm.clear();
      setState(() {
        _busy = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == _Step.code && !_busy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_busy) _back();
      },
      child: Scaffold(
        body: ColoredBox(
          color: Colors.white,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 20, 0),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Back',
                        onPressed: _busy ? null : _back,
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                        ),
                        color: Brand.maroon900,
                      ),
                      const Spacer(),
                      _StepDots(
                        index: _Step.values.indexOf(_step),
                        count: _Step.values.length,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: KeyedSubtree(
                        key: ValueKey(_step),
                        child: _buildStep(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _Step.code:
        return _CodeStep(
          controller: _code,
          busy: _busy,
          ready: _codeReady,
          error: _error,
          onChanged: () => setState(() {}),
          onContinue: _verify,
        );
      case _Step.confirm:
        return _ConfirmStep(
          preview: _preview!,
          onYes: () => _goTo(_Step.account),
          onNo: () {
            _code.clear();
            _goTo(_Step.code);
          },
        );
      case _Step.account:
        return _AccountStep(
          username: _username,
          password: _password,
          confirm: _confirm,
          hidePassword: _hidePassword,
          busy: _busy,
          ready: _accountReady,
          error: _error,
          onToggle: () => setState(() => _hidePassword = !_hidePassword),
          onChanged: () => setState(() {}),
          onCreate: _create,
        );
    }
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.index, required this.count});
  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i <= index ? Brand.maroon700 : Brand.border,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
      ],
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.title, this.subtitle);
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: Brand.serif,
            fontSize: 30,
            height: 1.1,
            fontWeight: FontWeight.w700,
            color: Brand.maroon900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14.5,
            height: 1.45,
            color: Brand.inkSoft,
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

/// Upper-cases, strips anything but letters/digits, caps at 10 characters and
/// inserts the dash after the fifth: XXXXX-XXXXX.
class _CodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var raw = newValue.text.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
    if (raw.length > 10) raw = raw.substring(0, 10);
    final text = raw.length > 5
        ? '${raw.substring(0, 5)}-${raw.substring(5)}'
        : raw;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _CodeStep extends StatelessWidget {
  const _CodeStep({
    required this.controller,
    required this.busy,
    required this.ready,
    required this.error,
    required this.onChanged,
    required this.onContinue,
  });

  final TextEditingController controller;
  final bool busy;
  final bool ready;
  final String? error;
  final VoidCallback onChanged;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Title(
          'Enter your Pet Code',
          'It’s printed on your pet’s vaccine card. The office gives it to you once, when your pet is registered.',
        ),
        TextField(
          controller: controller,
          enabled: !busy,
          autofocus: true,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          inputFormatters: [_CodeFormatter()],
          onChanged: (_) => onChanged(),
          onSubmitted: (_) => onContinue(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
            color: Brand.maroon900,
          ),
          decoration: InputDecoration(
            hintText: 'XXXXX-XXXXX',
            hintStyle: TextStyle(
              color: Brand.border.withValues(alpha: 1),
              letterSpacing: 3,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 22),
            border: _border(Brand.border),
            enabledBorder: _border(Brand.border),
            disabledBorder: _border(Brand.border),
            focusedBorder: _border(Brand.maroon700, 1.8),
          ),
        ),
        _ErrorBox(error),
        const SizedBox(height: 22),
        _PrimaryButton(
          label: 'Continue',
          busy: busy,
          enabled: ready && !busy,
          onPressed: onContinue,
        ),
      ],
    );
  }
}

class _ConfirmStep extends StatelessWidget {
  const _ConfirmStep({
    required this.preview,
    required this.onYes,
    required this.onNo,
  });
  final ClaimPreview preview;
  final VoidCallback onYes;
  final VoidCallback onNo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Title(
          'Is this you?',
          'Check that these details match you and your pets before you continue.',
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Brand.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'OWNER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: Brand.inkSoft,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                preview.maskedName,
                style: const TextStyle(
                  fontFamily: Brand.serif,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Brand.maroon900,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'PETS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: Brand.inkSoft,
                ),
              ),
              const SizedBox(height: 8),
              if (preview.petNames.isEmpty)
                const Text(
                  'No pets on file yet.',
                  style: TextStyle(color: Brand.inkSoft),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final name in preview.petNames)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Brand.maroon100,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.pets,
                              size: 15,
                              color: Brand.maroon700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Brand.maroon900,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        _PrimaryButton(
          label: 'Yes, that’s me',
          busy: false,
          enabled: true,
          onPressed: onYes,
        ),
        const SizedBox(height: 4),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Brand.inkSoft),
          onPressed: onNo,
          child: const Text('Not me — try a different code'),
        ),
      ],
    );
  }
}

class _AccountStep extends StatelessWidget {
  const _AccountStep({
    required this.username,
    required this.password,
    required this.confirm,
    required this.hidePassword,
    required this.busy,
    required this.ready,
    required this.error,
    required this.onToggle,
    required this.onChanged,
    required this.onCreate,
  });

  final TextEditingController username;
  final TextEditingController password;
  final TextEditingController confirm;
  final bool hidePassword;
  final bool busy;
  final bool ready;
  final String? error;
  final VoidCallback onToggle;
  final VoidCallback onChanged;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Title(
          'Create your account',
          'Choose a username and a password of at least 8 characters.',
        ),
        _Input(
          controller: username,
          label: 'Username',
          icon: Icons.person_outline,
          enabled: !busy,
          action: TextInputAction.next,
          hints: const [AutofillHints.newUsername],
          onChanged: onChanged,
        ),
        const SizedBox(height: 14),
        _Input(
          controller: password,
          label: 'Password',
          icon: Icons.lock_outline,
          enabled: !busy,
          obscure: hidePassword,
          action: TextInputAction.next,
          hints: const [AutofillHints.newPassword],
          onChanged: onChanged,
          suffix: IconButton(
            tooltip: hidePassword ? 'Show password' : 'Hide password',
            icon: Icon(
              hidePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            color: Brand.inkSoft,
            onPressed: onToggle,
          ),
        ),
        const SizedBox(height: 14),
        _Input(
          controller: confirm,
          label: 'Confirm password',
          icon: Icons.lock_outline,
          enabled: !busy,
          obscure: hidePassword,
          action: TextInputAction.done,
          hints: const [AutofillHints.newPassword],
          onChanged: onChanged,
          onSubmitted: onCreate,
        ),
        _ErrorBox(error),
        const SizedBox(height: 22),
        _PrimaryButton(
          label: 'Create account',
          busy: busy,
          enabled: ready && !busy,
          onPressed: onCreate,
        ),
      ],
    );
  }
}

OutlineInputBorder _border(Color c, [double w = 1.2]) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(14),
  borderSide: BorderSide(color: c, width: w),
);

class _Input extends StatelessWidget {
  const _Input({
    required this.controller,
    required this.label,
    required this.icon,
    required this.enabled,
    required this.action,
    required this.hints,
    required this.onChanged,
    this.obscure = false,
    this.suffix,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;
  final bool obscure;
  final TextInputAction action;
  final Iterable<String> hints;
  final VoidCallback onChanged;
  final VoidCallback? onSubmitted;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscure,
      autocorrect: false,
      enableSuggestions: false,
      textCapitalization: TextCapitalization.none,
      keyboardType: obscure
          ? TextInputType.visiblePassword
          : TextInputType.text,
      textInputAction: action,
      autofillHints: hints,
      onChanged: (_) => onChanged(),
      onSubmitted: (_) => onSubmitted?.call(),
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
        border: _border(Brand.border),
        enabledBorder: _border(Brand.border),
        disabledBorder: _border(Brand.border),
        focusedBorder: _border(Brand.maroon700, 1.8),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.busy,
    required this.enabled,
    required this.onPressed,
  });
  final String label;
  final bool busy;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Brand.maroon700,
          disabledBackgroundColor: Brand.maroon700.withValues(alpha: 0.35),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        onPressed: enabled ? onPressed : null,
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox(this.message);
  final String? message;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.topCenter,
      child: message == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDECEA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE6B3B3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 18,
                      color: Color(0xFFB3261E),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        message!,
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
            ),
    );
  }
}
