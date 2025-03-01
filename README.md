# Nextcloud Notes Flutter App

A cross-platform Flutter application that integrates with Nextcloud Notes, allowing users to create, edit, and manage their notes across devices. The app features a clean, modern interface inspired by the Nextcloud Notes desktop application.

![Nextcloud Notes Flutter App](screenshots/app_screenshot.png)

## Key Features

- **Nextcloud Integration**: Seamless synchronization with Nextcloud Notes server
- **Authentication**: Secure login flow using WebView and token-based authentication
- **Note Management**: Create, edit, delete, and organize notes
- **Markdown Support**: Full markdown editing with preview mode
- **Folder Organization**: Group notes into folders for better organization
- **Conflict Resolution**: Sophisticated handling of edit conflicts between devices
- **Offline Support**: Work with notes even when offline
- **Cross-Platform**: Works on iOS and macOS (with potential for Android and other platforms)

## Technical Highlights

- **Authentication**: Secure WebView-based authentication flow with Nextcloud
- **Data Synchronization**: ETag-based synchronization to efficiently update notes
- **Conflict Resolution**: Sophisticated three-way merge for handling edit conflicts
- **State Management**: Provider pattern for efficient state management
- **Responsive UI**: Adapts to different screen sizes and platforms
- **CI/CD Integration**: GitHub Actions for automated testing and building
- **Dependency Management**: Dependabot for keeping dependencies up-to-date

## UI Features

- Modern, clean interface matching Nextcloud desktop application
- Three-panel layout (folders, notes list, editor)
- Time-based grouping of notes ("Last 7 Days", "Last 30 Days", etc.)
- Section headers for better organization
- Compact, efficient layout optimized for productivity
- Dark and light mode support
- Content-specific icons based on note content
- Yellow accent bar for active notes
- Markdown toolbar for quick formatting

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Xcode for iOS/macOS development
- A Nextcloud server with the Notes app installed

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/flutter_notes.git
   cd flutter_notes
   ```

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Run the app:
   ```
   flutter run
   ```

## Future Development

- Implement full CRUD operations with the Nextcloud API
- Enhance offline mode support
- Add support for attachments
- Expand to additional desktop platforms (Windows, Linux)
- Add visual indicators for unsaved changes
- Implement search functionality
- Add syntax highlighting for code blocks

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the AGPL-3.0 License - see the [LICENSE](LICENSE) file for details.
