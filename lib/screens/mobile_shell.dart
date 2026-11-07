import 'package:flutter/material.dart';

import '../state/auth_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'appointments_screen.dart';
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
      FollowupScreen(auth: widget.auth),
      AppointmentsScreen(api: widget.auth.api),
      FamilyScreen(auth: widget.auth),
    ];
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        toolbarHeight: 64,
        title: const YayBrand(size: 36),
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
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Semantics(
              label: 'Compte de ${session.firstName} ${session.lastName}',
              excludeSemantics: true,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: context.yay.tealDark,
                child: Text(
                  session.firstName.isNotEmpty ? session.firstName[0].toUpperCase() : 'Y',
                  style: TextStyle(color: context.yay.onStrong, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.5),
          child: Container(height: 1.5, color: context.yay.borderLight),
        ),
      ),
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
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
}
