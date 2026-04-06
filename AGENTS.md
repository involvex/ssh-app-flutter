# AGENTS.md - SSH App Development Guide

Guidelines for agents operating on this Flutter SSH application codebase.

## Project Overview

- **Type**: Flutter Desktop/Mobile Application (SSH Server & Client)
- **State Management**: Provider
- **Architecture**: Screen/Widget/Provider separation in `lib/`

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
flutter build web          # Web

# Build in debug/release mode
flutter build apk --debug
flutter build apk --release
```

## Lint & Analysis

```bash
# Run static analysis (required before commits)
flutter analyze
flutter analyze --fix
```

## Testing

```bash
# Run all tests
flutter test

# Run single test file
flutter test test/widget_test.dart

# Run tests matching a name pattern
flutter test --name "smoke test"

# Run tests in a specific directory
flutter test test/

# Run tests with verbose output
flutter test -v
```

## Code Style Guidelines

### Import Conventions

- Use `package:` prefix for project imports
- Group imports: Dart SDK -> external packages -> project imports
- Use empty line between groups
- Sort alphabetically within groups

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Classes | PascalCase | `SSHProvider`, `HomeScreen` |
| Enums | PascalCase | `ConnectionState` |
| Methods | camelCase | `connectClient()`, `startServer()` |
| Variables | camelCase | `isConnected`, `serverPort` |
| Private members | prefix with `_` | `_client`, `_session` |
| Constants | `k` prefix | `kDefaultPort` |
| Files | snake_case | `ssh_provider.dart` |

### Type Annotations

- Specify return types for methods
- Prefer `final` over `var`
- Use `const` constructors where possible

```dart
final SSHClient? _client;
Terminal terminal = Terminal();
Future<void> connectClient({required String host, required int port}) async {}
```

### Widgets & UI

- Extract widgets into separate files
- Use `const` constructors for static widgets
- Follow Material Design guidelines

```dart
class SSHServerForm extends StatelessWidget {
  const SSHServerForm({super.key});
  @override
  Widget build(BuildContext context) { ... }
}
```

### Error Handling

- Use try-catch for async operations
- Log errors before rethrowing
- Handle specific exception types when possible

```dart
try {
  addLog('Connecting to $host:$port...');
  final socket = await SSHSocket.connect(host, port);
} catch (e) {
  addLog('Connection failed: $e');
  rethrow;
}
```

### State Management (Provider)

- Extend `ChangeNotifier`
- Call `notifyListeners()` after state changes
- Use `Consumer` or `Provider.of`
- Dispose resources in `dispose()`

```dart
class SSHProvider extends ChangeNotifier {
  bool isConnected = false;
  void connect() { isConnected = true; notifyListeners(); }
  @override void dispose() { _client?.close(); super.dispose(); }
}
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── screens/home_screen.dart  # Screen widgets
├── widgets/                  # Reusable widgets
│   ├── ssh_client_form.dart
│   ├── ssh_server_form.dart
│   └── log_viewer.dart
├── providers/ssh_provider.dart
test/widget_test.dart
```

## Working with SSH Provider

- `connectClient()` - Connect to remote SSH server
- `startServer()` - Start local SSH server
- `stopServer()` - Stop local server
- `disconnectClient()` - Disconnect from server
- `terminal` - xterm terminal for PTY
- `connectionLog` - List of connection events

## Best Practices

1. Run `flutter analyze` before committing
2. Test changes on at least one platform
3. Use meaningful variable/method names
4. Keep widgets small and focused
5. Handle loading and error states
6. Clean up resources in `dispose()` methods