import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/owner_profile.dart';
import '../services/api.dart';
import '../services/auth_service.dart';
import '../services/owner_data.dart';
import '../services/owner_service.dart';
import '../services/recovery_service.dart';
import '../theme.dart';
import '../widgets/fade_in.dart';
import 'pet_care_tab.dart' show RemindSwitch;

/// Settings: the owner's contact details, password, reminders, privacy note
/// and sign-out. Everything goes through the DIGIVET Online API.
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontFamily: Brand.serif,
                fontSize: 32,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: Brand.maroon900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Manage your profile details and account password.',
              style: TextStyle(fontSize: 14, color: Brand.inkSoft),
            ),
            const SizedBox(height: 22),
            const _Label('MY DETAILS'),
            const SizedBox(height: 10),
            FadeIn(index: 1, child: const _ProfileCard()),
            const SizedBox(height: 22),
            const _Label('ACCOUNT'),
            const SizedBox(height: 10),
            FadeIn(
              index: 2,
              child: _Row(
                icon: Icons.lock_outline_rounded,
                title: 'Change password',
                subtitle: 'Update the password you sign in with',
                onTap: () => _showSheet(context, const _PasswordSheet()),
              ),
            ),
            const SizedBox(height: 10),
            const FadeIn(index: 3, child: _RecoveryRow()),
            const SizedBox(height: 22),
            const _Label('NOTIFICATIONS'),
            const SizedBox(height: 10),
            FadeIn(index: 3, child: const RemindSwitch()),
            const SizedBox(height: 8),
            const Text(
              'Announcements from the City Veterinary Office arrive automatically.',
              style: TextStyle(fontSize: 12.5, color: Brand.inkSoft),
            ),
            const SizedBox(height: 22),
            const _Label('PRIVACY'),
            const SizedBox(height: 10),
            const Text(
              'DIGIVET keeps nothing about you or your pets on this phone. '
              'Your records are read from the City Veterinary Office each time '
              'you open the app, in line with the Data Privacy Act (RA 10173).',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: Brand.inkSoft,
              ),
            ),
            const SizedBox(height: 22),
            _Row(
              icon: Icons.logout_rounded,
              title: 'Log out',
              subtitle:
                  'You’ll need your username and password to sign back in',
              danger: true,
              onTap: () => _confirmLogout(context),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You’ll need to sign in again to see your pets.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text(
              'Log out',
              style: TextStyle(color: Color(0xFFB3261E)),
            ),
          ),
        ],
      ),
    );
    if (ok == true) await AuthService.instance.logout();
  }
}

Future<void> _showSheet(BuildContext context, Widget sheet) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => sheet,
    );

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1,
      color: Brand.inkSoft,
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.danger = false,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFB3261E) : Brand.ink;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Brand.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: danger ? color : Brand.maroon700, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Brand.inkSoft,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!danger)
                const Icon(Icons.chevron_right_rounded, color: Brand.inkSoft),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: OwnerData.instance,
      builder: (context, _) {
        final p = OwnerData.instance.profile;
        final user = AuthService.instance.user;
        String or(String? v) => v ?? '—';
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Brand.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      p == null || p.fullName.isEmpty
                          ? (user?.username ?? '')
                          : p.fullName,
                      style: const TextStyle(
                        fontFamily: Brand.serif,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Brand.maroon900,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: p == null
                        ? null
                        : () => _showSheet(context, _ProfileSheet(profile: p)),
                    child: const Text('Edit'),
                  ),
                ],
              ),
              if (user != null) _Line('Username', user.username),
              _Line('Contact no.', or(p?.contactNo)),
              _Line('Email', or(p?.email)),
              _Line('Address', or(p?.address)),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6, right: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Brand.inkSoft),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13.5, color: Brand.ink),
          ),
        ),
      ],
    ),
  );
}

// ---- Sheets ---------------------------------------------------------------

InputDecoration _decoration(String label) => InputDecoration(
  labelText: label,
  filled: true,
  fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  border: _border(Brand.border),
  enabledBorder: _border(Brand.border),
  focusedBorder: _border(Brand.maroon700, 1.8),
);

OutlineInputBorder _border(Color c, [double w = 1.2]) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(14),
  borderSide: BorderSide(color: c, width: w),
);

/// Shared frame: title, fields, error line, one save button.
class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.title,
    required this.fields,
    required this.error,
    required this.busy,
    required this.onSave,
    required this.saveLabel,
  });
  final String title;
  final List<Widget> fields;
  final String? error;
  final bool busy;
  final VoidCallback onSave;
  final String saveLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          22,
          4,
          22,
          22 + MediaQuery.of(context).viewPadding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: Brand.serif,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Brand.maroon900,
              ),
            ),
            const SizedBox(height: 16),
            for (final f in fields) ...[f, const SizedBox(height: 12)],
            if (error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDECEA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE6B3B3)),
                ),
                child: Text(
                  error!,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFFB3261E),
                  ),
                ),
              ),
            SizedBox(
              height: 54,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Brand.maroon700,
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: busy ? null : onSave,
                child: busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(saveLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSheet extends StatefulWidget {
  const _ProfileSheet({required this.profile});
  final OwnerProfile profile;

  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> {
  late final _c = {
    'first_name': TextEditingController(text: widget.profile.firstName),
    'middle_name': TextEditingController(text: widget.profile.middleName),
    'last_name': TextEditingController(text: widget.profile.lastName),
    'contact_no': TextEditingController(text: widget.profile.contactNo),
    'email': TextEditingController(text: widget.profile.email),
    'address_line': TextEditingController(text: widget.profile.address),
  };
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final changes = {for (final e in _c.entries) e.key: e.value.text.trim()};
    if (changes['first_name']!.isEmpty || changes['last_name']!.isEmpty) {
      setState(() => _error = 'First and last name are required.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final p = await OwnerService.instance.updateProfile(changes);
      OwnerData.instance.setProfile(p);
      AuthService.instance.setFirstName(p.firstName);
      HapticFeedback.lightImpact();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(content: Text('Details saved.')));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget field(String key, String label, {TextInputType? type}) => TextField(
      controller: _c[key],
      enabled: !_busy,
      keyboardType: type,
      textCapitalization: key == 'email'
          ? TextCapitalization.none
          : TextCapitalization.words,
      decoration: _decoration(label),
    );
    return _SheetFrame(
      title: 'Edit my details',
      saveLabel: 'Save',
      busy: _busy,
      error: _error,
      onSave: _save,
      fields: [
        field('first_name', 'First name'),
        field('middle_name', 'Middle name'),
        field('last_name', 'Last name'),
        field('contact_no', 'Contact no.', type: TextInputType.phone),
        field('email', 'Email', type: TextInputType.emailAddress),
        field('address_line', 'Address'),
      ],
    );
  }
}

class _PasswordSheet extends StatefulWidget {
  const _PasswordSheet();

  @override
  State<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends State<_PasswordSheet> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_current.text.isEmpty) {
      return setState(() => _error = 'Enter your current password.');
    }
    if (_next.text.length < 8) {
      return setState(
        () => _error = 'New password must be at least 8 characters.',
      );
    }
    if (_next.text != _confirm.text) {
      return setState(() => _error = 'The new passwords don’t match.');
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await OwnerService.instance.changePassword(_current.text, _next.text);
      HapticFeedback.lightImpact();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Password changed.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget field(TextEditingController c, String label) => TextField(
      controller: c,
      enabled: !_busy,
      obscureText: true,
      enableSuggestions: false,
      autocorrect: false,
      decoration: _decoration(label),
    );
    return _SheetFrame(
      title: 'Change password',
      saveLabel: 'Change password',
      busy: _busy,
      error: _error,
      onSave: _save,
      fields: [
        field(_current, 'Current password'),
        field(_next, 'New password'),
        field(_confirm, 'Confirm new password'),
      ],
    );
  }
}

/// Account → Recovery email: the address password-reset codes go to.
/// Shows whether it's verified; tapping opens a two-step sheet (email +
/// password -> a 6-digit code is mailed -> type it). Same Online routes as
/// the web portal's Settings (/owner/recovery-email).
class _RecoveryRow extends StatefulWidget {
  const _RecoveryRow();

  @override
  State<_RecoveryRow> createState() => _RecoveryRowState();
}

class _RecoveryRowState extends State<_RecoveryRow> {
  RecoveryEmailStatus? _status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final st = await RecoveryService.instance.status();
      if (mounted) setState(() => _status = st);
    } on ApiException {
      // Leave the row in its neutral state.
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = _status;
    final subtitle = st == null
        ? 'Used to reset your password if you forget it'
        : st.verified
        ? '${st.masked} · Verified'
        : st.email != null
        ? '${st.masked} · Not verified yet'
        : 'Not set. Add one so you can reset a forgotten password';
    return _Row(
      icon: st?.verified == true
          ? Icons.mark_email_read_outlined
          : Icons.alternate_email_rounded,
      title: 'Recovery email',
      subtitle: subtitle,
      onTap: () async {
        if (st != null && !st.mailAvailable) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Email isn’t available right now. Please try again later.',
              ),
            ),
          );
          return;
        }
        await _showSheet(
          context,
          _RecoveryEmailSheet(
            initialEmail: st != null && !st.verified ? st.email ?? '' : '',
          ),
        );
        _load();
        OwnerData.instance.refresh(); // the profile shows the new address
      },
    );
  }
}

class _RecoveryEmailSheet extends StatefulWidget {
  const _RecoveryEmailSheet({required this.initialEmail});
  final String initialEmail;

  @override
  State<_RecoveryEmailSheet> createState() => _RecoveryEmailSheetState();
}

class _RecoveryEmailSheetState extends State<_RecoveryEmailSheet> {
  late final _email = TextEditingController(text: widget.initialEmail);
  final _password = TextEditingController();
  final _code = TextEditingController();
  String _step = 'email'; // email -> code -> done
  String _sentTo = '';
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      _sentTo = await RecoveryService.instance.sendVerifyCode(
        email: _email.text.trim(),
        password: _password.text,
      );
      _password.clear();
      _code.clear();
      if (mounted) setState(() => _step = 'code');
    } on ApiException catch (e) {
      _password.clear();
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await RecoveryService.instance.confirmVerifyCode(_code.text);
      HapticFeedback.lightImpact();
      if (mounted) setState(() => _step = 'done');
    } on ApiException catch (e) {
      _code.clear();
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _deco(String label, {String? hint}) => InputDecoration(
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
  );

  Widget _primary(String text, VoidCallback? onPressed) => SizedBox(
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

  @override
  Widget build(BuildContext context) {
    const title = TextStyle(
      fontFamily: Brand.serif,
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: Brand.maroon900,
    );
    const sub = TextStyle(fontSize: 14, height: 1.45, color: Brand.inkSoft);
    final children = <Widget>[];
    if (_step == 'email') {
      children.addAll([
        const Text('Recovery email', style: title),
        const SizedBox(height: 6),
        const Text(
          'We’ll send a 6-digit code to this address to make sure it’s yours. Use an email only you can open.',
          style: sub,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _email,
          enabled: !_busy,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          decoration: _deco('Email'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _password,
          enabled: !_busy,
          obscureText: true,
          onChanged: (_) => setState(() {}),
          decoration: _deco('Current password'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          _ErrorText(_error!),
        ],
        const SizedBox(height: 20),
        _primary(
          _busy ? 'Sending…' : 'Send code',
          _busy || _email.text.trim().isEmpty || _password.text.isEmpty
              ? null
              : _send,
        ),
      ]);
    } else if (_step == 'code') {
      children.addAll([
        const Text('Check your email', style: title),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            style: sub,
            children: [
              const TextSpan(text: 'We sent a 6-digit code to '),
              TextSpan(
                text: _sentTo,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Brand.ink,
                ),
              ),
              const TextSpan(text: '. It expires in 15 minutes.'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _code,
          enabled: !_busy,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 8,
          ),
          onChanged: (_) => setState(() {}),
          decoration: _deco('6-digit code', hint: '••••••'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          _ErrorText(_error!),
        ],
        const SizedBox(height: 20),
        _primary(
          _busy ? 'Checking…' : 'Confirm',
          _busy || _code.text.length != 6 ? null : _confirm,
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Brand.maroon700),
          onPressed: _busy
              ? null
              : () => setState(() {
                  _step = 'email';
                  _error = null;
                }),
          child: const Text(
            'Send a new code',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ]);
    } else {
      children.addAll([
        const Text('Recovery email verified', style: title),
        const SizedBox(height: 6),
        Text(
          'If you forget your password, you can reset it with a code sent to $_sentTo.',
          style: sub,
        ),
        const SizedBox(height: 20),
        _primary('Done', () => Navigator.of(context).pop()),
      ]);
    }
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
          children: children,
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
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
}
