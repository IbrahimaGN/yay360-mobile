import 'package:flutter/material.dart';

import 'app.dart';
import 'state/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthController();
  await auth.restoreSession();
  runApp(Yay360App(auth: auth));
}
