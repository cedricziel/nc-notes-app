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
            seedColor: Colors.orange,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'SF Pro Text', // Apple-like font
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.orange,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          fontFamily: 'SF Pro Text', // Apple-like font
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
