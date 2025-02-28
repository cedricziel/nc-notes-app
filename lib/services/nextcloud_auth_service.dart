import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

/// Service for handling Nextcloud Login Flow v2
class NextcloudAuthService {
  final AuthService _authService;

  NextcloudAuthService(this._authService);

  /// Initiates the Nextcloud Login Flow v2
  ///
  /// Makes a POST request to the server to start the login flow
  /// Returns a map containing the poll token, poll endpoint, and login URL
  Future<Map<String, dynamic>> initiateLoginFlow(String serverUrl) async {
    // Clean up the server URL
    String cleanServerUrl = serverUrl.trim();
    if (cleanServerUrl.endsWith('/')) {
      cleanServerUrl = cleanServerUrl.substring(0, cleanServerUrl.length - 1);
    }
    if (!cleanServerUrl.startsWith('http')) {
      cleanServerUrl = 'https://$cleanServerUrl';
    }
    cleanServerUrl = cleanServerUrl.replaceAll('/index.php', '');

    try {
      final response = await http.post(
        Uri.parse('$cleanServerUrl/index.php/login/v2'),
        headers: {'OCS-APIREQUEST': 'true'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'pollToken': data['poll']['token'],
          'pollEndpoint': data['poll']['endpoint'],
          'loginUrl': data['login'],
        };
      } else {
        throw Exception('Failed to initiate login flow: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Error initiating login flow: $e');
      throw Exception('Failed to connect to Nextcloud server: $e');
    }
  }

  /// Opens the login URL in the system browser
  Future<bool> openLoginUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      throw Exception('Could not launch $url');
    }
  }

  /// Polls the server for authentication completion
  ///
  /// Repeatedly checks the poll endpoint until authentication is complete
  /// or the timeout is reached
  Future<bool> pollForCredentials({
    required String pollEndpoint,
    required String pollToken,
    required Function(String, String, String) onCredentialsReceived,
    int timeoutSeconds = 300, // 5 minutes timeout
  }) async {
    final stopTime = DateTime.now().add(Duration(seconds: timeoutSeconds));

    while (DateTime.now().isBefore(stopTime)) {
      try {
        final response = await http.post(
          Uri.parse(pollEndpoint),
          body: {'token': pollToken},
          headers: {'OCS-APIREQUEST': 'true'},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          final serverUrl = data['server'];
          final username = data['loginName'];
          final password = data['appPassword'];

          // Save credentials
          await _authService.saveCredentials(
            serverUrl: serverUrl,
            username: username,
            password: password,
          );

          // Notify caller
          onCredentialsReceived(serverUrl, username, password);

          return true;
        }
      } catch (e) {
        // Ignore errors and continue polling
        debugPrint('Polling error (will retry): $e');
      }

      // Wait before trying again
      await Future.delayed(const Duration(seconds: 2));
    }

    return false; // Timeout
  }

  /// Complete login flow
  ///
  /// Initiates the login flow, opens the browser, and polls for credentials
  Future<bool> login({
    required String serverUrl,
    required Function(String, String, String) onCredentialsReceived,
    required Function(String) onError,
  }) async {
    try {
      // Step 1: Initiate login flow
      final flowData = await initiateLoginFlow(serverUrl);

      // Step 2: Open login URL in browser
      final browserOpened = await openLoginUrl(flowData['loginUrl']);
      if (!browserOpened) {
        onError('Could not open browser');
        return false;
      }

      // Step 3: Poll for credentials
      return await pollForCredentials(
        pollEndpoint: flowData['pollEndpoint'],
        pollToken: flowData['pollToken'],
        onCredentialsReceived: onCredentialsReceived,
      );
    } catch (e) {
      onError('Login failed: $e');
      return false;
    }
  }
}
