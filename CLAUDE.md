# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get          # Install dependencies
flutter run              # Run in debug mode
flutter analyze          # Static analysis (primary quality gate — run before committing)
flutter test             # Run tests (test/ is currently a placeholder stub)

flutter build apk        # Android APK
flutter build ios        # iOS
flutter build windows    # Windows desktop
flutter build macos      # macOS desktop
flutter build linux      # Linux desktop
```

## Architecture

Flutter SSH client + server app. Layers:

```
lib/
├── models/     — Plain Dart data classes (SSHProfile, SSHKey, KeyboardShortcut, Snippet)
├── services/   — Business logic / external I/O (ConfigService, SSHKeyGenerator, NetworkDiscoveryService, BackupService)
├── providers/  — ChangeNotifier state managers (SSHProvider, SettingsProvider, SnippetProvider)
├── screens/    — Top-level pages (SplashScreen, HomeScreen, SettingsScreen, SnippetConfigScreen)
└── widgets/    — Reusable UI components
```

**Startup sequence:** `SplashScreen` → `ConfigService.init()` (must complete before any `ConfigService` call, throws `StateError` otherwise) → `HomeScreen` → `SSHProvider.loadConfig()`.

**State management:** Three `ChangeNotifier` providers registered at app root via `MultiProvider` in `main.dart`:

| Provider | Responsibility |
|----------|----------------|
| `SSHProvider` | SSH client/server connection, xterm `Terminal` instance, profiles, connection log (100-entry cap), network scan |
| `SettingsProvider` | Theme (`AppTheme` enum), accent color, keyboard shortcuts |
| `SnippetProvider` | Command snippet CRUD |

All state mutations must call `notifyListeners()`.

**Persistence:** All persistence goes through `ConfigService` — a static wrapper around `shared_preferences`. Never call SharedPreferences directly from widgets or providers. Keys: `ssh_profiles`, `last_session`, `app_settings`, `ssh_keys`, `snippets`.

**SSH + terminal wiring:** `SSHProvider.terminal` is an xterm `Terminal`; reset to a new instance on disconnect. stdout/stderr pipe into `terminal.write()`; `terminal.onOutput` sends keystrokes back to `_session!.stdin`. Startup commands are sent after a 3-second wait for first stdout, using `\r` as line terminator. `connectionLog` is capped at 100 entries (oldest pruned on overflow).

## Model Conventions

- IDs use `uuid`: `id = id ?? const Uuid().v4()` — pass explicit `id` only when deserialising.
- `toJson()` / `fromJson()` factory on all models; `SSHKeyType` serialised as **integer index** (not name).
- All models implement `copyWith()`.
- `Snippet` and `KeyboardShortcut` have `static List<T> get defaults` for first-run init.
- `KeyboardShortcut.row` groups buttons: row 0 = navigation, 1 = arrows, 2 = ctrl combos.

## Theme System

`AppTheme` enum: `system`, `light`, `dark`, `hacker`. `hacker` uses `ThemeMode.dark` but overrides to black/green terminal colours. Stored as string under the `appTheme` key. Accent colours are named strings: `blue`, `green`, `purple`, `orange`, `red`.

## Coding Conventions

**Linting** (`analysis_options.yaml` — strict, must stay satisfied):
- `strict-casts: true` and `strict-raw-types: true` — explicit casts required.
- `always_declare_return_types` — every method/function needs a return type.
- `prefer_single_quotes` — `'...'` not `"..."`.
- `prefer_const_constructors` / `prefer_final_fields` / `prefer_final_locals`.
- `use_build_context_synchronously` — guard `BuildContext` usage after `await` with `if (!mounted) return`.
- `cancel_subscriptions` / `close_sinks` — cancel/close in `dispose()`.
- `unawaited_futures` — annotate intentionally unawaited calls with `// ignore: unawaited_futures`.

**Imports:** Dart SDK → external packages → `package:ssh_app/...`. Alphabetical within groups.

**Naming:** `PascalCase` classes, `camelCase` methods/variables, `_` prefix for private, `k` prefix for constants, `snake_case` files.

**Async safety:** Wrap all SSH and network calls in `try-catch`. Guard `BuildContext` after any `await` with `if (!mounted) return`.

**Logging:** Use `SSHProvider.addLog(String message)` for all user-visible events — applies `HH:MM:SS` timestamps and enforces the 100-entry cap.

**Provider access:** `Provider.of<T>(context, listen: false)` for one-shot reads in callbacks. `Consumer<T>` or `context.watch<T>()` in build methods that rebuild on state change.

## Key Files

| File | Purpose |
|------|---------|
| `lib/main.dart` | App root; `MultiProvider` registration; all theme definitions including hacker theme |
| `lib/providers/ssh_provider.dart` | Core SSH state: client/server connection, terminal, logs, profiles |
| `lib/providers/settings_provider.dart` | `AppTheme` enum, accent colors, keyboard shortcuts |
| `lib/providers/snippet_provider.dart` | Snippet CRUD via `ConfigService` |
| `lib/services/config_service.dart` | Single persistence gateway; must call `ConfigService.init()` at startup |
| `lib/screens/splash_screen.dart` | Initialises `ConfigService`; entry point before `HomeScreen` |
| `lib/screens/home_screen.dart` | Main UI; keyboard shortcuts (`Ctrl+N/P/D/K`); terminal display |
| `analysis_options.yaml` | Strict lint rules; must remain satisfied after any change |
