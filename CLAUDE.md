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
- `_windowOpen` (`bool?`): `null` = stream loading, `true` = last inbound < 24h ago, `false` = window closed. Input and send button are disabled when `!= true`.
- Read receipts are sent sequentially (50ms delay between) to avoid burst POSTs.
- Outbound message origin is visualized via `_outboundOriginStyle()` → `_OriginBadge` (IA / Sistema / green name for human).
- `_pendingReactions` holds optimistic emoji state, keyed by `wa_message_id`. Updated before the POST, reverted in `catch`.

### Routing & auth guards

`lib/core/router/app_router.dart`: `kMockMode = false` (in `lib/core/config.dart`) bypasses all auth. When `false`, unauthenticated users are redirected to `/login`; authenticated users at `/login` go to `/overview`. Public auth routes (`/forgot-password`, `/reset-password`, `/activate`) skip the guard.

### Theme & design tokens

Always use `AppColors` constants (`lib/core/theme/colors.dart`) — never inline hex values. Typography: `Onest` for headings/buttons ≥ 15px or w600+; `Geist` (local font) for body text. `AppFonts.onest(...)` and `AppFonts.geist(...)` helpers are in `app_theme.dart`.

### CI/CD

Push to `main` → GitHub Actions → `flutter build web --release` → `firebase deploy --only hosting`. Production URL: `https://conectamos-platform-poc.web.app`. Requires `FIREBASE_TOKEN` secret in GitHub Actions.
