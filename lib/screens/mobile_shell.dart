import 'package:flutter/material.dart';

import '../state/auth_controller.dart';
import '../theme.dart';
import 'appointments_screen.dart';
import 'assistant_screen.dart';
import 'dashboard_screen.dart';
import 'family_screen.dart';
import 'followup_screen.dart';

class MobileShell extends StatefulWidget {
  const MobileShell({super.key, required this.auth, this.onToggleTheme});
  final AuthController auth;
  final VoidCallback? onToggleTheme;

  @override
  State<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<MobileShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final session = widget.auth.session!;
    final screens = <Widget>[
      DashboardScreen(auth: widget.auth, onOpenTab: _openTab),
      FollowupScreen(api: widget.auth.api),
      AppointmentsScreen(api: widget.auth.api),
      FamilyScreen(auth: widget.auth),
    ];
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/images/yay360-logo.png',
                width: 31,
                height: 31,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 9),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'YAY',
                    style: TextStyle(color: context.yayInk),
                  ),
                  TextSpan(
                    text: '360',
                    style: TextStyle(color: YayColors.rose),
                  ),
                ],
              ),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.7,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: Theme.of(context).brightness == Brightness.dark
                ? 'Activer le thème clair'
                : 'Activer le thème sombre',
            onPressed: widget.onToggleTheme,
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: context.yayRoseContainer,
              child: Text(
                session.firstName.isNotEmpty
                    ? session.firstName[0].toUpperCase()
                    : 'Y',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: screens),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAssistant,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Assistant IA'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: Theme.of(context).colorScheme.primaryContainer,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Suivi',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Rendez-vous',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Famille',
          ),
        ],
      ),
    );
  }

  void _openTab(int index) => setState(() => _index = index);

  Future<void> _openAssistant() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      height: MediaQuery.sizeOf(context).height * .92,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(top: false, child: AssistantScreen(api: widget.auth.api)),
    ),
  );
}
