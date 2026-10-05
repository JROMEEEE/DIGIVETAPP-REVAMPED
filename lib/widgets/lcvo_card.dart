import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme.dart';

const lcvoFacebookUrl =
    'https://www.facebook.com/profile.php?id=100063921050657';

/// Last page of the Home carousel: a card pointing to the City Veterinary
/// Office's Facebook page for announcements and vaccination-drive schedules.
///
/// Nothing is loaded from Facebook inside the app (no embedded feed, so no
/// Facebook cookies or tracking); the button just opens the page in the
/// Facebook app or browser.
class LcvoCard extends StatelessWidget {
  const LcvoCard({super.key});

  Future<void> _open(BuildContext context) async {
    final ok = await launchUrl(
      Uri.parse(lcvoFacebookUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open Facebook.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Brand.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: Brand.gold500, width: 2),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/digivet_logo.png',
                              cacheWidth: 120,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'UPDATES FROM LCVO',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.9,
                                  color: Brand.inkSoft,
                                ),
                              ),
                              Text(
                                'Lipa City Veterinary Office',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: Brand.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Announcements, vaccination drive schedules and news from the office.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: Brand.inkSoft,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1877F2),
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: () => _open(context),
                        icon: const Icon(Icons.facebook, size: 22),
                        label: const Text('Open on Facebook'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
