import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:library_web/app.dart';
import 'package:library_web/core/router.dart';
import 'package:library_web/state/auth_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<GoRouter> pumpApp(
  WidgetTester tester, {
  String location = '/books',
  Size size = const Size(1440, 900),
  SharedPreferences? prefs,
  bool useApi = false,
  Dio? dio,
  AuthNotifier? auth,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final router = createRouter(initialLocation: location, auth: auth);
  await tester.pumpWidget(
    AppProviders(
      prefs: prefs,
      useApi: useApi,
      dio: dio,
      authNotifier: auth,
      child: LibraryApp(router: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

Uri currentUri(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri;

Finder get rows =>
    find.byWidgetPredicate((w) => w.key.toString().contains('row-menu'));
