import 'package:flutter/material.dart';

import '../theme.dart';
import '../services/owner_data.dart';
import '../services/push_service.dart';
import '../services/reminder_service.dart';
import 'home_tab.dart';
import 'my_pets_tab.dart';
import 'pet_care_tab.dart';
import 'settings_tab.dart';

/// The signed-in app: four bottom tabs, matching the web owner portal's
/// sections.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Ask for notification permission once the owner is signed in, not on
    // first launch, so the prompt has context.
    PushService.instance.requestPermission();
    OwnerData.instance.addListener(_syncReminders);
  }

  // Keep the on-phone reminder schedule in step with the loaded pets.
  void _syncReminders() =>
      ReminderService.instance.sync(OwnerData.instance.pets);

  @override
  void dispose() {
    OwnerData.instance.removeListener(_syncReminders);
    super.dispose();
  }

  static const _tabs = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.pets_outlined, Icons.pets, 'My Pets'),
    (Icons.event_available_outlined, Icons.event_available, 'Pet Care'),
    (Icons.settings_outlined, Icons.settings, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps Home's data and scroll position when switching tabs.
      body: IndexedStack(
        index: _index,
        children: [
          const HomeTab(),
          const MyPetsTab(),
          const PetCareTab(),
          const SettingsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Brand.maroon100,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: states.contains(WidgetState.selected)
                  ? Brand.maroon700
                  : Brand.inkSoft,
            ),
          ),
        ),
        child: NavigationBar(
          height: 66,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            for (final t in _tabs)
              NavigationDestination(
                icon: Icon(t.$1, color: Brand.inkSoft),
                selectedIcon: Icon(t.$2, color: Brand.maroon700),
                label: t.$3,
              ),
          ],
        ),
      ),
    );
  }
}
