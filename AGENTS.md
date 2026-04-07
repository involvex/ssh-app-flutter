# AGENTS.md - SSH App Development Guide

Guidelines for agents operating on this Flutter SSH application codebase.

## Project Overview

- **Type**: Flutter Desktop/Mobile Application (SSH Server & Client)
- **State Management**: Provider
- **Persistence**: shared_preferences (via ConfigService)
- **Architecture**: Separated models, services, providers, screens, and widgets.

## Build Commands

```bash
# Install dependencies
flutter pub get

# Run development app
flutter run

# Build for specific platforms
flutter build apk          # Android
flutter build ios          # iOS
flutter build windows      # Windows
flutter build macos        # macOS
flutter build linux        # Linux
flutter build web          # Web (if supported)
```

## Lint & Analysis

```bash
# Run static analysis (required before commits)
flutter analyze
```

## Testing

```bash
# Run all tests
flutter test

# Run tests in a specific directory
flutter test test/
```

## Code Style Guidelines

### Import Conventions

- Use `package:` prefix for all project imports.
- Grouping: Dart SDK -> external packages -> project imports.
- Sort alphabetically within groups.

### Naming Conventions

- **Classes**: PascalCase (e.g., `SSHProvider`).
- **Methods/Variables**: camelCase (e.g., `connectClient()`).
- **Private members**: Prefix with `_` (e.g., `_client`).
- **Constants**: `k` prefix (e.g., `kDefaultPort`).
- **Files**: snake_case (e.g., `ssh_provider.dart`).

### Type Annotations

- Explicit return types for methods.
- Prefer `final` over `var`.
- Use `const` constructors for static widgets and constant data.

## Project Structure

```text
lib/
├── models/             # Data Models (SSHProfile, SSHKey, KeyboardShortcut, Snippet)
├── services/           # Services (ConfigService, NetworkDiscoveryService, SSHKeyGenerator)
├── providers/          # State Management (SSHProvider, SettingsProvider, SnippetProvider)
├── screens/            # Main Screens (HomeScreen, SettingsScreen, SplashScreen)
├── widgets/            # Reusable Widgets (KeyManager, ProfileManager, LogViewer, forms)
└── main.dart           # App Entry Point
```

## Working with Providers

### SSHProvider
- `connectClient({required SSHProfile profile})` - Connect to a remote SSH server using a profile.
- `startServer({required int port})` - Start local SSH server.
- `terminal` - The current active `Terminal` instance (xterm).
- `connectionLog` - List of strings for displaying logs in UI.

### SettingsProvider
- `themeMode` - Current application theme (Light/Dark/System).
- `accentColor` - Primary application accent color.
- `updateTheme(ThemeMode mode)` - Change app theme.

### SnippetProvider
- `snippets` - List of saved command fragments.
- `addSnippet(Snippet snippet)` - Create new snippet.

## Best Practices

1. **Always use ConfigService** for persistence. Do not call `shared_preferences` directly from widgets.
2. **Handle Async Safety**: Use `try-catch` for all SSH and network operations.
3. **Notify Listeners**: Ensure `notifyListeners()` is called in providers after state changes.
4. **UI Decoupling**: Keep business logic in providers/services; widgets should only handle display and user interaction.
5. **Clean Resources**: Always implement `dispose()` in providers to close sockets, PTYs, and timers.
6. **Strict Typing**: Maintain `strict-casts` and `strict-raw-types` compliance.
