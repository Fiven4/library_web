import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Адреса без решётки: /books?page=2 вместо /#/books?page=2
  usePathUrlStrategy();
  // На web shared_preferences пишет в localStorage: данные переживают
  // перезагрузку страницы.
  final prefs = await SharedPreferences.getInstance();
  runApp(
    AppProviders(
      prefs: prefs,
      child: LibraryApp(router: createRouter()),
    ),
  );
}
