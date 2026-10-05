import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/owner_profile.dart';
import '../services/api.dart';
import '../services/auth_service.dart';
import '../services/owner_data.dart';
import '../services/owner_service.dart';
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
                onTap: () => _showSheet(context, const _PasswordSheet()),
              ),
            ),
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
    this.danger = false,
  });
  final IconData icon;
  final String title;
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
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
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
