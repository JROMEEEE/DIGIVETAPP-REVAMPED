import 'package:flutter/material.dart';

import '../theme.dart';

/// "Forgot password?" — the same two steps as the web owner login
/// (digivetonline/client/src/pages/OwnerLoginPage.jsx). PLACEHOLDER: the
/// screens are in place, but nothing is sent or changed yet; the last step
/// tells the owner to contact the LCVO, exactly like the web.
Future<void> showRecoverySheet(BuildContext context, {String? username}) {
  return showModalBottomSheet<void>(
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
  String? _note;

  @override
  void dispose() {
    for (final c in [_who, _code, _pass, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void _go(bool codeStep) => setState(() {
    _codeStep = codeStep;
    _note = null;
  });

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
      'Enter your username or the email on your account. We’ll email you a 6-digit code.',
    ),
    const SizedBox(height: 20),
    _input(
      _who,
      'Username or email',
      autofocus: true,
      onChanged: (_) => setState(() {}),
    ),
    const SizedBox(height: 20),
    _button('Send reset code', who.isEmpty ? null : () => _go(true)),
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
                ' has an email on file, a 6-digit code is on its way. It expires in 15 minutes.',
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
    ),
    const SizedBox(height: 12),
    _input(_pass, 'New password', obscure: true, hint: 'At least 8 characters'),
    const SizedBox(height: 12),
    _input(_confirm, 'Confirm new password', obscure: true),
    if (_note != null) ...[
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFDECEA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE6B3B3)),
        ),
        child: Text(
          _note!,
          style: const TextStyle(fontSize: 13.5, color: Color(0xFFB3261E)),
        ),
      ),
    ],
    const SizedBox(height: 20),
    _button(
      'Reset password',
      () => setState(
        () => _note =
            'Password recovery isn’t switched on yet. Please contact the Lipa City Veterinary Office for help.',
      ),
    ),
    const SizedBox(height: 6),
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _link('Send a new code', () => _go(false)),
        _link('‹ Back to log in', () => Navigator.of(context).pop()),
      ],
    ),
  ];

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
    maxLength: number ? 6 : null,
    keyboardType: number ? TextInputType.number : TextInputType.text,
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
    onPressed: onTap,
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
