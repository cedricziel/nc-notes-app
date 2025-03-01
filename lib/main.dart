import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/notes_provider.dart';
import 'screens/notes_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Check if user is already authenticated
  final authService = AuthService();
  final isAuthenticated = await authService.isAuthenticated();

  debugPrint('Starting app with authentication state: ${isAuthenticated ? 'authenticated' : 'not authenticated'}');

  runApp(MyApp(isAuthenticated: isAuthenticated));
}

class MyApp extends StatelessWidget {
  final bool isAuthenticated;

  const MyApp({super.key, required this.isAuthenticated});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => NotesProvider(),
      child: MaterialApp(
        title: 'Flutter Notes',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFFD700), // Gold accent color
            brightness: Brightness.light,
            background: const Color(0xFFF5F5F5), // Light gray background like in screenshot
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
              fontSize: 14, // Smaller font size for more compact UI
              color: Colors.black87,
            ),
            toolbarHeight: 36, // More compact toolbar
          ),
          dividerTheme: const DividerThemeData(
            color: Color(0xFFE0E0E0), // Slightly darker divider
            thickness: 1.0, // Slightly thicker divider
          ),
          listTileTheme: const ListTileThemeData(
            dense: true, // More compact list tiles
            visualDensity: VisualDensity(horizontal: 0, vertical: -2),
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFFD700),
            brightness: Brightness.dark,
            background: const Color(0xFF2D2D2D),
            surface: const Color(0xFF2D2D2D),
            onSurface: Colors.white,
            primary: const Color(0xFF007bff), // Blue for selected items
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
              fontSize: 14, // Smaller font size for more compact UI
              color: Colors.white,
            ),
            toolbarHeight: 36, // More compact toolbar
          ),
          dividerTheme: const DividerThemeData(
            color: Color(0xFF3D3D3D),
            thickness: 1.0, // Slightly thicker divider
          ),
          listTileTheme: const ListTileThemeData(
            dense: true, // More compact list tiles
            visualDensity: VisualDensity(horizontal: 0, vertical: -2),
          ),
        ),
        themeMode: ThemeMode.system,
        home: isAuthenticated
          ? FutureBuilder(
              // Initialize the NotesProvider when the app starts with authentication
              future: Future.delayed(Duration.zero, () async {
                final notesProvider = Provider.of<NotesProvider>(context, listen: false);
                if (!notesProvider.isAuthenticated) {
                  debugPrint('Auto-initializing NotesProvider on app start');
                  await notesProvider.login();
                }
                return true;
              }),
              builder: (context, snapshot) {
                // Show loading indicator while initializing
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(
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

                // Show the notes screen once initialized
                return const NotesScreen();
              },
            )
          : const LoginScreen(),
      ),
    );
  }
}
