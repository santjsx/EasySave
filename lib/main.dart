import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'providers/system_provider.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  // 1. Ensure Flutter framework bindings are fully initialized before native code calls
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Lock screen orientation to Portrait only (highly predictable for elderly users)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // 3. Configure a custom global Flutter error interceptor (Rule 14)
  // Ensures exceptions are caught, formatted, and logged without showing red screen crashes.
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('-----------------------------------------');
    debugPrint('GLOBAL ERROR INTERCEPTED:');
    debugPrint(details.exceptionAsString());
    debugPrint(details.stack?.toString());
    debugPrint('-----------------------------------------');
  };

  // 4. Wrap everything in a Zone to catch asynchronous platform channel exceptions
  runZonedGuarded(() async {
    // Initialize SharedPreferences asynchronously
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final StorageService storage = StorageService(prefs);

    runApp(
      ProviderScope(
        overrides: [
          // Override the throw singleton with the actual loaded StorageService (DI pattern)
          storageServiceProvider.overrideWithValue(storage),
        ],
        child: const AmmaNannaApp(),
      ),
    );
  }, (error, stackTrace) {
    debugPrint('-----------------------------------------');
    debugPrint('UNCAUGHT ASYNC EXCEPTION ENCOUNTERED:');
    debugPrint(error.toString());
    debugPrint(stackTrace.toString());
    debugPrint('-----------------------------------------');
  });
}
