import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api.dart';
import '../services/recovery_service.dart';
import '../theme.dart';

/// "Forgot password?" — the same two steps as the web owner login
/// (digivetonline/client/src/pages/OwnerLoginPage.jsx): username -> a
/// 6-digit code is mailed to the account's VERIFIED recovery email -> code
/// + new password. The server answers the same way whether or not the
/// username exists, so this sheet never says which accounts are real.
/// Returns the username when the password was changed, else null.
Future<String?> showRecoverySheet(BuildContext context, {String? username}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _RecoverySheet(username: username ?? ''),
  );
}

class _RecoverySheet extends StatefulWidget {
  const _RecoverySheet({required this.username});
  final String username;

  @override
  State<_RecoverySheet> createState() => _RecoverySheetState();
}

class _RecoverySheetState extends State<_RecoverySheet> {
  late final _who = TextEditingController(text: widget.username);
  final _code = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _codeStep = false;
  bool _busy = false;
  bool? _available; // null = checking
  String? _note;

  @override
  void initState() {
    super.initState();
    RecoveryService.instance
        .available()
        .then((v) => mounted ? setState(() => _available = v) : null)
        .catchError((_) => mounted ? setState(() => _available = false) : null);
  }

  @override
  void dispose() {
    for (final c in [_who, _code, _pass, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _request() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _note = null;
    });
    try {
      await RecoveryService.instance.requestResetCode(_who.text.trim());
      if (!mounted) return;
      _code.clear();
      _pass.clear();
      _confirm.clear();
      setState(() => _codeStep = true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _note = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    if (_pass.text.length < 8) {
      setState(() => _note = 'The new password needs at least 8 characters.');
      return;
    }
    if (_pass.text != _confirm.text) {
      setState(() => _note = 'The new passwords don’t match.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _note = null;
    });
    try {
      await RecoveryService.instance.resetPassword(
        username: _who.text.trim(),
        code: _code.text,
        newPassword: _pass.text,
      );
      HapticFeedback.lightImpact();
      if (mounted) Navigator.of(context).pop(_who.text.trim());
    } on ApiException catch (e) {
      if (!mounted) return;
      _code.clear();
      setState(() {
        _note = e.message;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final who = _who.text.trim();
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          4,
          24,
          24 + MediaQuery.of(context).viewPadding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _codeStep ? _codeView(who) : _recoverView(who),
        ),
      ),
    );
  }

  List<Widget> _recoverView(String who) => [
    const _Title('Reset your password'),
    const SizedBox(height: 6),
    const _Sub(
      'Enter your username. If your account has a verified recovery email, we’ll email you a 6-digit code.',
    ),
    const SizedBox(height: 20),
    if (_available == false)
      _noteBox(
        'Password reset by email isn’t available right now. Please contact the Lipa City Veterinary Office for help.',
      )
    else ...[
      _input(
        _who,
        'Username',
        autofocus: true,
        onChanged: (_) => setState(() {}),
      ),
      if (_note != null) ...[const SizedBox(height: 14), _noteBox(_note!)],
      const SizedBox(height: 20),
      _button(
        _busy ? 'Sending…' : 'Send reset code',
        who.isEmpty || _busy || _available == null ? null : _request,
      ),
    ],
    const SizedBox(height: 10),
    const _Sub(
      'No recovery email on your account? Please contact the Lipa City Veterinary Office.',
    ),
    const SizedBox(height: 6),
    _link('‹ Back to log in', () => Navigator.of(context).pop()),
  ];

  List<Widget> _codeView(String who) => [
    const _Title('Check your email'),
    const SizedBox(height: 6),
    Text.rich(
      TextSpan(
        style: const TextStyle(
          fontSize: 14,
          height: 1.45,
          color: Brand.inkSoft,
        ),
        children: [
          const TextSpan(text: 'If '),
          TextSpan(
            text: who.isEmpty ? 'that account' : who,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Brand.ink,
            ),
          ),
          const TextSpan(
            text:
                ' has a verified recovery email, a 6-digit code is on its way. It expires in 15 minutes.',
          ),
        ],
      ),
    ),
    const SizedBox(height: 20),
    _input(
      _code,
      '6-digit code',
      autofocus: true,
      number: true,
      hint: '••••••',
      onChanged: (_) => setState(() {}),
    ),
    const SizedBox(height: 12),
    _input(_pass, 'New password', obscure: true, hint: 'At least 8 characters'),
    const SizedBox(height: 12),
    _input(_confirm, 'Confirm new password', obscure: true),
    if (_note != null) ...[const SizedBox(height: 14), _noteBox(_note!)],
    const SizedBox(height: 20),
    _button(
      _busy ? 'Resetting…' : 'Reset password',
      _busy || _code.text.length != 6 ? null : _reset,
    ),
    const SizedBox(height: 6),
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _link(
          'Send a new code',
          () => setState(() {
            _codeStep = false;
            _note = null;
          }),
        ),
        _link('‹ Back to log in', () => Navigator.of(context).pop()),
      ],
    ),
  ];

  Widget _noteBox(String text) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFDECEA),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE6B3B3)),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 13.5, color: Color(0xFFB3261E)),
    ),
  );

  Widget _input(
    TextEditingController c,
    String label, {
    bool autofocus = false,
    bool obscure = false,
    bool number = false,
    String? hint,
    ValueChanged<String>? onChanged,
  }) => TextField(
    controller: c,
    autofocus: autofocus,
    obscureText: obscure,
    enabled: !_busy,
    keyboardType: number ? TextInputType.number : TextInputType.text,
    // A pasted code keeps only its digits (an email may space them out).
    inputFormatters: number
        ? [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ]
        : null,
    onChanged: onChanged,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      counterText: '',
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Brand.border, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Brand.maroon700, width: 1.8),
      ),
    ),
  );

  Widget _button(String text, VoidCallback? onPressed) => SizedBox(
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
      onPressed: onPressed,
      child: Text(text),
    ),
  );

  Widget _link(String text, VoidCallback onTap) => TextButton(
    style: TextButton.styleFrom(foregroundColor: Brand.maroon700),
    onPressed: _busy ? null : onTap,
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
  );
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontFamily: Brand.serif,
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: Brand.maroon900,
    ),
  );
}

class _Sub extends StatelessWidget {
  const _Sub(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 14, height: 1.45, color: Brand.inkSoft),
  );
}
