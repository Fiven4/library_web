import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/api_client.dart';
import 'core/auth_api.dart';
import 'core/router.dart';
import 'state/auth_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final prefs = await SharedPreferences.getInstance();

  late final AuthNotifier auth;
  final dio = buildDio(
    tokenProvider: () => auth.accessToken,
    onRefreshToken: () => auth.refreshTokens(),
  );
  auth = AuthNotifier(prefs, AuthApi(dio));
  await auth.restore();

  final router = createRouter(auth: auth);

  runApp(
    AppProviders(
      useApi: true,
      prefs: prefs,
      dio: dio,
      authNotifier: auth,
      child: LibraryApp(router: router),
    ),
  );
}
