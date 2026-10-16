import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'core/router.dart';

void main() {
  // Адреса без решётки: /books?page=2 вместо /#/books?page=2
  usePathUrlStrategy();
  runApp(AppProviders(child: LibraryApp(router: createRouter())));
}
