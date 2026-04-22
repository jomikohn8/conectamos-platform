# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Install dependencies
flutter pub get

# Run in Chrome (only supported target — Flutter Web)
flutter run -d chrome

# Analyze (run before every commit)
flutter analyze

# Build for production
flutter build web --release

# Deploy to Firebase Hosting
firebase deploy --only hosting

# Run code generation (Riverpod generators)
dart run build_runner build --delete-conflicting-outputs
```

There are no unit or widget tests in this project.

## Architecture

**Flutter Web SPA** targeting Chrome. No mobile/desktop targets.

### Data flow

```
Supabase Realtime (stream)  ──→  ConsumerStatefulWidget (setState)  ──→  ListView.builder
FastAPI backend (Dio)        ──→  fire-and-forget or await in handler
```

All authenticated requests go through `ApiClient` (Dio, `lib/core/api/api_client.dart`), which injects `Authorization: Bearer {supabase_access_token}` via an `InterceptorsWrapper`. The backend base URL is `https://conectamos-meta-api.vercel.app`.

Supabase is used directly for:
- Auth (email+password)
- Realtime message streams (`wa_messages` table via `.stream()`)
- Read receipts (`supabase_read_receipts.dart`)

### Multi-tenancy

Every screen and query is scoped by `activeTenantIdProvider` (a Riverpod `Provider<String>`). When `activeTenantIdProvider` changes (user switches tenant), all streams re-subscribe and all lists reload. Never hardcode tenant IDs — always `ref.read(activeTenantIdProvider)`.

The superadmin (`miguel@conectamos.mx`) can switch tenants; all other users see only their own tenant. Tenant selection persists in `localStorage` key `conectamos_active_tenant`.

### Shell layout

`AppShell` (`lib/shared/widgets/app_shell.dart`) wraps all authenticated routes via `ShellRoute` in go_router. It renders a collapsible sidebar + topbar. Screens inject title/subtitle/actions via providers (`topbarTitleProvider`, etc.). Auth screens (`/login`, `/forgot-password`, `/reset-password`, `/activate`) bypass the shell entirely.

### Conversations screen

`lib/features/conversations/conversations_screen.dart` (~3500 lines) is the most complex file. Key architecture:

- `_TabOperador`: sidebar `_ConvoList` (240px, fixed) + `_ChatPanel` (flexible). The outer `Row` uses `CrossAxisAlignment.stretch` to ensure both panels fill the available height.
- `_ChatPanelState` subscribes to `SupabaseMessages.streamMessages()` via `StreamSubscription`. On first emit: determines `_firstUnreadMessageId`, schedules two `addPostFrameCallback` jumps to reach the true scroll bottom. On subsequent emits: auto-scrolls only if already at bottom (`_atBottom` threshold ≤ 100px).
- `_windowOpen` (`bool?`): `null` = stream loading, `true` = last inbound < 24h ago, `false` = window closed. Input and send button are disabled when `!= true`. Badge and banner are hidden for non-WhatsApp channels.
- Read receipts are sent sequentially (50ms delay between) to avoid burst POSTs.
- Outbound message origin is visualized via `_outboundOriginStyle()` → `_OriginBadge` (IA / Sistema / green name for human).
- `_pendingReactions` holds optimistic emoji state, keyed by `wa_message_id`. Updated before the POST, reverted in `catch`.
- Active channel is exposed via `selectedChannelIdProvider` / `selectedChannelTypeProvider` (global `StateProvider<String?>` in the same file). `_ActionBar` reads these as a `ConsumerWidget` and passes them as query params when navigating to `/broadcast`.
- 422 errors from `/messages/send` surface the backend `detail` field directly in the UI snackbar.

### Broadcasts screen

`lib/features/broadcasts/broadcast_screen.dart` receives `channel_id` and `channel_type` via go_router query parameters (set by `_ActionBar` in conversations). Key behavior:

- `isTelegram` flag (derived from `channel_type == 'telegram'`) hides the mode toggle and template dropdown — Telegram only supports free-text.
- `channel_id` is required in the POST body; submit is blocked with a snackbar if empty.
- A channel context banner (color-coded by type) is shown above the form.

### Channels & WhatsApp Embedded Signup

`lib/features/config/channels_screen.dart` — the "Conectar con WhatsApp Business" button uses the Facebook Embedded Signup flow:

- FB SDK (`connect.facebook.net/en_US/sdk.js`) and a JS wrapper `_fbLaunchSignup` are injected at runtime via `dart:html` in `_initFbSdk()` (called once via `static bool _fbSdkInitialized`).
- The `@JS('_fbLaunchSignup')` binding uses `dart:js_interop`; callbacks are passed with `.toJS`.
- `FB.login()` must be called **synchronously from the user gesture** (`onTap`) — no `async` gap before it.
- Config: `appId: '4149613485350757'`, `config_id: '2145617199565998'`, `response_type: 'code'`, `override_default_response_type: true`.
- On success, calls `POST /channels/embedded-signup` with `{code, tenant_id}`.
- `_embeddedSignupInProgress` guards against duplicate calls.
- WhatsApp credential flow (stepper + channel detail): `verify-credentials` → `activate-whatsapp` → save. Both steps must succeed before proceeding.

### Operators screen

`lib/features/config/operators_screen.dart` — key behaviors:

- Flow pre-population handles both string IDs and map objects from the backend (`op['flows']` can be either).
- `metadata` key is omitted entirely when `telegramChatId == null` — never send explicit null (backend would overwrite existing value).
- "Vincular vía Telegram" button appears when the operator has a Telegram flow selected but no chat ID entered (edit mode only). Calls `POST /operators/{id}/send-telegram-invite` for each unique Telegram channel in the selected flows. Telegram validation is warning-only, not blocking.

### Routing & auth guards

`lib/core/router/app_router.dart`: `kMockMode = false` (in `lib/core/config.dart`) bypasses all auth. When `false`, unauthenticated users are redirected to `/login`; authenticated users at `/login` go to `/overview`. Public auth routes (`/forgot-password`, `/reset-password`, `/activate`) skip the guard.

### Theme & design tokens

Always use `AppColors` constants (`lib/core/theme/colors.dart`) — never inline hex values. Typography: `Onest` for headings/buttons ≥ 15px or w600+; `Geist` (local font) for body text. `AppFonts.onest(...)` and `AppFonts.geist(...)` helpers are in `app_theme.dart`.

### CI/CD

Push to `main` → GitHub Actions → `flutter build web --release` → `firebase deploy --only hosting`. Production URL: `https://conectamos-platform-poc.web.app`. Requires `FIREBASE_TOKEN` secret in GitHub Actions.
