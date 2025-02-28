import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'nextcloud_config.dart';

/// Service for managing Nextcloud authentication
class AuthService {
  static const String _serverUrlKey = 'nextcloud_server_url';
  static const String _usernameKey = 'nextcloud_username';
  static const String _passwordKey = 'nextcloud_password';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Saves authentication credentials securely
  Future<void> saveCredentials({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    await _storage.write(key: _serverUrlKey, value: serverUrl);
    await _storage.write(key: _usernameKey, value: username);
    await _storage.write(key: _passwordKey, value: password);
  }

  /// Checks if the user is authenticated
  Future<bool> isAuthenticated() async {
    final serverUrl = await _storage.read(key: _serverUrlKey);
    final username = await _storage.read(key: _usernameKey);
    final password = await _storage.read(key: _passwordKey);

    return serverUrl != null && username != null && password != null;
  }

  /// Gets the Nextcloud configuration with stored credentials
  Future<NextcloudConfig?> getConfig() async {
    final serverUrl = await _storage.read(key: _serverUrlKey);
    final username = await _storage.read(key: _usernameKey);
    final password = await _storage.read(key: _passwordKey);

    if (serverUrl != null && username != null && password != null) {
      return NextcloudConfig(
        serverUrl: serverUrl,
        username: username,
        password: password,
      );
    }

    return null;
  }

  /// Clears all stored credentials (logout)
  Future<void> logout() async {
    await _storage.delete(key: _serverUrlKey);
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _passwordKey);
  }

  /// Extracts credentials from a Nextcloud login flow redirect URL
  ///
  /// The URL format is: nc://server:https://server.com&user:username&password:password
  Map<String, String>? extractCredentialsFromUrl(String url) {
    if (!url.startsWith('nc://')) {
      return null;
    }

    final Uri uri = Uri.parse(url);
    if (uri.scheme != 'nc') {
      return null;
    }

    final String path = uri.path;
    final List<String> pathItems = path.split('&');

    String? serverUrl;
    String? username;
    String? password;

    for (final item in pathItems) {
      if (item.startsWith('/server:')) {
        serverUrl = item.substring(8);
      } else if (item.startsWith('user:')) {
        username = item.substring(5);
      } else if (item.startsWith('password:')) {
        password = item.substring(9);
      }
    }

    if (serverUrl != null && username != null && password != null) {
      return {
        'serverUrl': serverUrl,
        'username': username,
        'password': password,
      };
    }

    return null;
  }
}
