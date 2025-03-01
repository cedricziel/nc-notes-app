import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'providers/notes_provider.dart';
import 'screens/responsive_notes_layout.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'widgets/platform/platform_app.dart';
import 'widgets/platform/platform_service.dart';
import 'widgets/platform/platform_theme.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Check if user is already authenticated
  final authService = AuthService();
  final isAuthenticated = await authService.isAuthenticated();

  debugPrint(
      'Starting app with authentication state: ${isAuthenticated ? 'authenticated' : 'not authenticated'}');

  runApp(MyApp(isAuthenticated: isAuthenticated));
}

class MyApp extends StatelessWidget {
  final bool isAuthenticated;

  const MyApp({super.key, required this.isAuthenticated});

  // Helper method to check if we're running on iOS
  bool get isIOS {
    return PlatformService.isIOS;
  }

  @override
  Widget build(BuildContext context) {
    // Define page transitions for iOS style
    final pageTransitions = PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        // Default for other platforms
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      },
    );

    // Create Material theme for Android and other platforms
    final lightTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFFD700), // Gold accent color
        brightness: Brightness.light,
        background: const Color(0xFFF5F5F5), // Light gray background
        surface: const Color(0xFFF5F5F5),
        onSurface: Colors.black87,
        primary: const Color(0xFF007bff), // Blue for selected items
      ),
      useMaterial3: true,
      fontFamily: 'SF Pro Text',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF5F5F5),
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'SF Pro Text',
          fontWeight: FontWeight.w500,
          fontSize: 17,
          color: Colors.black87,
        ),
        toolbarHeight: 56,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0E0E0),
        thickness: 0.5,
      ),
      listTileTheme: const ListTileThemeData(
        dense: true,
        visualDensity: VisualDensity(horizontal: 0, vertical: -2),
      ),
      scrollbarTheme: ScrollbarThemeData(
        radius: const Radius.circular(10),
        thickness: MaterialStateProperty.all(6),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF007bff),
          textStyle: const TextStyle(
            fontFamily: 'SF Pro Text',
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      pageTransitionsTheme: pageTransitions,
    );

    final darkTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFFD700),
        brightness: Brightness.dark,
        background: const Color(0xFF2D2D2D),
        surface: const Color(0xFF2D2D2D),
        onSurface: Colors.white,
        primary: const Color(0xFF007bff),
      ),
      useMaterial3: true,
      fontFamily: 'SF Pro Text',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF2D2D2D),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'SF Pro Text',
          fontWeight: FontWeight.w500,
          fontSize: 17,
          color: Colors.white,
        ),
        toolbarHeight: 56,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF3D3D3D),
        thickness: 0.5,
      ),
      listTileTheme: const ListTileThemeData(
        dense: true,
        visualDensity: VisualDensity(horizontal: 0, vertical: -2),
      ),
      scrollbarTheme: ScrollbarThemeData(
        radius: const Radius.circular(10),
        thickness: MaterialStateProperty.all(6),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF007bff),
          textStyle: const TextStyle(
            fontFamily: 'SF Pro Text',
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      pageTransitionsTheme: pageTransitions,
    );

    // Create Cupertino theme for iOS
    final cupertinoTheme = CupertinoThemeData(
      brightness: MediaQuery.platformBrightnessOf(context),
      primaryColor: const Color(0xFF007bff),
      barBackgroundColor:
          MediaQuery.platformBrightnessOf(context) == Brightness.dark
              ? const Color(0xFF2D2D2D)
              : const Color(0xFFF5F5F5),
      scaffoldBackgroundColor:
          MediaQuery.platformBrightnessOf(context) == Brightness.dark
              ? const Color(0xFF2D2D2D)
              : const Color(0xFFF5F5F5),
      textTheme: const CupertinoTextThemeData(
        navTitleTextStyle: TextStyle(
          fontFamily: 'SF Pro Text',
          fontWeight: FontWeight.w600,
          fontSize: 17,
        ),
        textStyle: TextStyle(
          fontFamily: 'SF Pro Text',
          fontWeight: FontWeight.w400,
          fontSize: 16,
        ),
      ),
    );

    // Create the home widget based on authentication state
    Widget homeWidget = isAuthenticated
        ? FutureBuilder(
            // Initialize the NotesProvider when the app starts with authentication
            future: Future.delayed(Duration.zero, () async {
              final notesProvider =
                  Provider.of<NotesProvider>(context, listen: false);
              if (!notesProvider.isAuthenticated) {
                debugPrint('Auto-initializing NotesProvider on app start');
                await notesProvider.login();
              }
              return true;
            }),
            builder: (context, snapshot) {
              // Show loading indicator while initializing
              if (snapshot.connectionState == ConnectionState.waiting) {
                return PlatformService.useCupertino
                    ? CupertinoPageScaffold(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              CupertinoActivityIndicator(),
                              SizedBox(height: 16),
                              Text('Loading your notes...'),
                            ],
                          ),
                        ),
                      )
                    : Scaffold(
                        body: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Loading your notes...'),
                            ],
                          ),
                        ),
                      );
              }

              // Show the responsive notes layout once initialized
              return const ResponsiveNotesLayout();
            },
          )
        : const LoginScreen();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => NotesProvider()),
        ChangeNotifierProvider(create: (context) => MobileNavigationProvider()),
      ],
      child: PlatformApp(
        title: 'Flutter Notes',
        theme: lightTheme,
        darkTheme: darkTheme,
        cupertinoTheme: cupertinoTheme,
        debugShowCheckedModeBanner: false,
        home: homeWidget,
      ),
    );
  }
}
