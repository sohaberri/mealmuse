// import 'package:flutter/material.dart';
// import 'screens/homepage.dart';
// import 'firebase_service.dart';
// // import 'screens/expiring.dart';

// Future<void> main() async {
//   // Ensure Flutter bindings are initialized
//   WidgetsFlutterBinding.ensureInitialized();
  
//   // Initialize Firebase
//   await FirebaseService.initialize();
  
//   runApp(const FigmaLoginLab());
// }

// class FigmaLoginLab extends StatelessWidget {
//  const FigmaLoginLab({super.key});
//  @override
//  Widget build(BuildContext context) {
//  return MaterialApp(
//  debugShowCheckedModeBanner: false,
//  home: HomePage(),
//  );
//  }
// }

// -----------------------------------------


import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/homepage.dart';
import 'firebase_service.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// import 'screens/expiring.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  bool envLoaded = false;
  bool firebaseInitialized = false;
  
  // Initialize ThemeProvider (load saved preference from SharedPreferences)
  await ThemeProvider().initialize();
  // Initialize LocaleProvider (load saved locale)
  await LocaleProvider().initialize();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    envLoaded = true;
    print('✅ Environment variables loaded successfully');
    
    // Check for essential keys
    final essentialKeys = ['SPOONACULAR_API_KEY'];
    for (final key in essentialKeys) {
      if (dotenv.maybeGet(key) == null) {
        print('⚠️  Essential key missing: $key');
      }
    }
  } catch (e, stackTrace) {
    print('❌ Failed to load .env file: $e');
    print('Stack trace: $stackTrace');
    envLoaded = false;
  }
  
  // Initialize Firebase
  try {
    await FirebaseService.initialize();
    firebaseInitialized = true;
    print('✅ Firebase initialized successfully');
  } catch (e, stackTrace) {
    print('❌ Failed to initialize Firebase: $e');
    print('Stack trace: $stackTrace');
    firebaseInitialized = false;
  }
  
  // Log overall initialization status
  print('🚀 App initialization complete:');
  print('   - Environment: ${envLoaded ? "✅" : "❌"}');
  print('   - Firebase: ${firebaseInitialized ? "✅" : "❌"}');
  
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use ValueListenableBuilder so the MaterialApp rebuilds when locale changes
    return ValueListenableBuilder<Locale?>(
      valueListenable: LocaleProvider().localeNotifier,
      builder: (context, locale, _) {
        final isDark = ThemeProvider().darkModeEnabled;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: const HomePage(),
          locale: locale,
          supportedLocales: const [Locale('en'), Locale('ur')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: isDark ? ThemeData.dark() : ThemeData.light(),
        );
      },
    );
  }
}
