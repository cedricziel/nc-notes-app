/// Configuration for connecting to a Nextcloud server
class NextcloudConfig {
  /// The base URL of the Nextcloud server
  /// Example: https://yournextcloud.com
  final String serverUrl;

  /// The username for authentication
  final String username;

  /// The password for authentication
  final String password;

  /// Creates a new Nextcloud configuration
  NextcloudConfig({
    required this.serverUrl,
    required this.username,
    required this.password,
  });

  /// Returns the full API URL for the Nextcloud Notes API v1
  String get apiUrl => '$serverUrl/index.php/apps/notes/api/v1';
}
