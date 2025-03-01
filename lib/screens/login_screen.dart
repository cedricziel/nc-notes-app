import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../services/auth_service.dart';
import '../services/nextcloud_auth_service.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _serverController = TextEditingController();
  final AuthService _authService = AuthService();
  late final NextcloudAuthService _nextcloudAuthService;

  bool _isLoading = false;
  bool _hasServerUrl = false;
  String? _errorMessage;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _nextcloudAuthService = NextcloudAuthService(_authService);

    // Add listener to text controller to update state when text changes
    _serverController.addListener(() {
      setState(() {
        _hasServerUrl = _serverController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    // Remove listener when disposing
    _serverController.removeListener(() {});
    _serverController.dispose();
    super.dispose();
  }

  Future<void> _startLoginFlow() async {
    if (_serverController.text.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusMessage = 'Connecting to server...';
    });

    try {
      debugPrint('Starting login flow for server: ${_serverController.text}');

      final success = await _nextcloudAuthService.login(
        serverUrl: _serverController.text,
        onCredentialsReceived: (serverUrl, username, password) {
          debugPrint(
              'Credentials received for server: $serverUrl, username: $username');
          setState(() {
            _statusMessage = 'Login successful! Returning to app...';
          });
        },
        onError: (error) {
          debugPrint('Login error: $error');
          setState(() {
            _isLoading = false;
            _errorMessage = error;
            _statusMessage = null;
          });
        },
      );

      if (success && mounted) {
        debugPrint('Login successful, returning to main screen');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful!')),
        );

        // Add a small delay to ensure the user sees the success message
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          // Check if we can pop (if there's a screen to go back to)
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(true); // Return success
          } else {
            // If we can't pop, we need to rebuild the app from scratch
            // This happens when we've used pushReplacement to get to the login screen
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const MyApp(isAuthenticated: true),
              ),
              (route) => false,
            );
          }
        }
      } else if (mounted) {
        debugPrint('Login failed or timed out');
        setState(() {
          _isLoading = false;
          _errorMessage ??= 'Login timed out. Please try again.';
          _statusMessage = null;
        });
      }
    } catch (e) {
      debugPrint('Exception during login: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: $e';
          _statusMessage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMacOS = Platform.isMacOS;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login to Nextcloud'),
      ),
      body: Padding(
        padding:
            isMacOS ? const EdgeInsets.all(24.0) : const EdgeInsets.all(16.0),
        child: _buildLoginForm(isMacOS),
      ),
    );
  }

  Widget _buildLoginForm(bool isMacOS) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter your Nextcloud server address',
          style: TextStyle(
              fontSize: isMacOS ? 22 : 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'You will be redirected to your browser to complete the login process.',
          style: TextStyle(
            fontSize: isMacOS ? 16 : 14,
            color: Colors.grey[700],
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isMacOS ? 30 : 20),
        TextField(
          controller: _serverController,
          decoration: const InputDecoration(
            labelText: 'Server URL',
            hintText: 'https://yournextcloud.com',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.cloud),
          ),
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.go,
          onSubmitted: (_) {
            if (_serverController.text.isNotEmpty) {
              _startLoginFlow();
            }
          },
          enabled: !_isLoading,
          // Explicitly enable text selection and paste functionality
          enableInteractiveSelection: true,
          // Disable autocorrect and suggestions which can interfere with pasting URLs
          autocorrect: false,
          enableSuggestions: false,
          // Use default context menu to ensure paste option is available
          contextMenuBuilder: (context, editableTextState) {
            return AdaptiveTextSelectionToolbar.editableText(
              editableTextState: editableTextState,
            );
          },
        ),
        SizedBox(height: isMacOS ? 30 : 20),
        SizedBox(
          width: isMacOS ? 200 : double.infinity,
          child: ElevatedButton.icon(
            onPressed: (_hasServerUrl && !_isLoading) ? _startLoginFlow : null,
            icon: const Icon(Icons.login),
            label: const Text('Login with Browser'),
          ),
        ),
        if (_isLoading) ...[
          const SizedBox(height: 30),
          const Center(child: CircularProgressIndicator()),
          if (_statusMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _statusMessage!,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ],
        if (_errorMessage != null && !_isLoading) ...[
          const SizedBox(height: 20),
          Text(
            _errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
