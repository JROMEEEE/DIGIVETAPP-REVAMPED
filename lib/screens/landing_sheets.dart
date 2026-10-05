import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme.dart';

const _facebookUrl = 'https://www.facebook.com/profile.php?id=100063921050657';
const _contactEmail = 'lipacityvet@gmail.com';

const _steps = [
  (
    'Get your pet vaccinated',
    'Visit an LCVO vaccination drive or the City Veterinary Office. The vet records every shot.',
  ),
  (
    'Receive your Pet Code',
    'The office gives you a one-time Pet Code that links your account to your pets.',
  ),
  (
    'Sign up and view records',
    'Enter your Pet Code in this app, set a password, and your pets appear on your dashboard.',
  ),
];

const _faqs = [
  (
    'I don’t have a Pet Code. What do I do?',
    'Pet Codes are issued by the City Veterinary Office after your pet has been registered. Visit the office or a vaccination drive, or message us on Facebook, and we’ll help you get one.',
  ),
  (
    'Can I add or edit my pet’s vaccinations myself?',
    'No. Vaccinations are recorded by LCVO staff so the records stay official. You can request a correction to your pet’s profile details (name, breed, color, sex, birth date) and the office will review it.',
  ),
  (
    'How soon do new vaccinations show up?',
    'Field records are entered offline at the drive and synced afterwards, so a new shot may take a little while to appear.',
  ),
  (
    'Is my information safe?',
    'Yes. You can only see your own pets, and your data is handled in line with the Data Privacy Act (RA 10173).',
  ),
  (
    'Does it cost anything?',
    'Viewing your pet’s records is free for Lipa pet owners.',
  ),
];

Future<void> _showSheet(
  BuildContext context,
  Widget Function(BuildContext) builder,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.88,
    ),
    builder: builder,
  );
}

void showHowItWorksSheet(BuildContext context) =>
    _showSheet(context, (_) => const _HowItWorks());

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.eyebrow, this.title);
  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: Brand.inkSoft,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            fontFamily: Brand.serif,
            fontSize: 24,
            height: 1.15,
            fontWeight: FontWeight.w700,
            color: Brand.maroon900,
          ),
        ),
      ],
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        const _SheetTitle('How it works', 'From the vet’s table to your phone'),
        const SizedBox(height: 18),
        for (var i = 0; i < _steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Brand.maroon700,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      fontFamily: Brand.serif,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _steps[i].$1,
                        style: const TextStyle(
                          fontFamily: Brand.serif,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Brand.maroon900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _steps[i].$2,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: Brand.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        const _SheetTitle('Questions', 'Frequently asked'),
        const SizedBox(height: 8),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Brand.border),
          child: Column(
            children: [
              for (final f in _faqs)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 14),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  iconColor: Brand.maroon700,
                  collapsedIconColor: Brand.maroon700,
                  title: Text(
                    f.$1,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Brand.ink,
                    ),
                  ),
                  children: [
                    Text(
                      f.$2,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.55,
                        color: Brand.inkSoft,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _Contact(),
      ],
    );
  }
}

class _Contact extends StatelessWidget {
  const _Contact();

  Future<void> _launch(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open that link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SheetTitle('Need help?', 'Lipa City Veterinary Office'),
          const SizedBox(height: 10),
          const Text(
            'Need a Pet Code, or have a question about your pet’s record? Reach out to us.',
            style: TextStyle(fontSize: 14.5, height: 1.5, color: Brand.inkSoft),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Brand.maroon700,
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () => _launch(context, Uri.parse(_facebookUrl)),
              icon: const Icon(Icons.facebook),
              label: const Text('Message us on Facebook'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Brand.maroon700,
                side: const BorderSide(color: Brand.maroon700, width: 1.5),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () =>
                  _launch(context, Uri(scheme: 'mailto', path: _contactEmail)),
              icon: const Icon(Icons.mail_outline),
              label: const Text(_contactEmail),
            ),
          ),
        ],
      ),
    );
  }
}
