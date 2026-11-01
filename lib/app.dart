import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/auth_screen.dart';
import 'screens/mobile_shell.dart';
import 'state/auth_controller.dart';
import 'theme.dart';

class Yay360App extends StatefulWidget {
  const Yay360App({super.key, required this.auth});

  final AuthController auth;

  @override
  State<Yay360App> createState() => _Yay360AppState();
}

class _Yay360AppState extends State<Yay360App> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.auth,
      builder: (context, _) => MaterialApp(
        title: 'YAY360',
        debugShowCheckedModeBanner: false,
        theme: YayTheme.light,
        darkTheme: YayTheme.dark,
        themeMode: _themeMode,
        locale: const Locale('fr', 'FR'),
        supportedLocales: const [Locale('fr', 'FR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: widget.auth.isRestoring
            ? const _LoadingScreen()
            : widget.auth.session == null
            ? AuthScreen(auth: widget.auth, onToggleTheme: _toggleTheme)
            : MobileShell(auth: widget.auth, onToggleTheme: _toggleTheme),
      ),
    );
  }

  void _toggleTheme() => setState(
    () => _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light,
  );
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
