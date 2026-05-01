# CLAUDE.md — conectamos-platform

This file is the single source of guidance for Claude Code working in this repository.
Read it fully before touching any file. Do not invent patterns not described here.

---

## Commands

```bash
# Install dependencies
flutter pub get

# Run in Chrome (only supported target — Flutter Web)
flutter run -d chrome

# Analyze (run before every commit — fix all warnings before delivering)
flutter analyze

# Build for production
flutter build web --release

# Deploy to Firebase Hosting
firebase deploy --only hosting

# Run code generation (Riverpod generators)
dart run build_runner build --delete-conflicting-outputs
```

There are no unit or widget tests in this project.

---

## Architecture overview

**Flutter Web SPA** targeting Chrome only. No mobile/desktop targets.

### Data flow

```
Supabase Realtime (stream)  ──→  ConsumerStatefulWidget (setState)  ──→  ListView.builder
FastAPI backend (Dio)        ──→  fire-and-forget or await in handler
```

All authenticated requests go through `ApiClient` (Dio, `lib/core/api/api_client.dart`),
which injects `Authorization: Bearer {supabase_access_token}` via `InterceptorsWrapper`.
Backend base URL: `https://conectamos-meta-api.vercel.app`.

Supabase is used directly for:
- Auth (email+password)
- Realtime message streams (`wa_messages` table via `.stream()`)
- Read receipts (`supabase_read_receipts.dart`)

### Multi-tenancy

Every screen and query is scoped by `activeTenantIdProvider` (Riverpod `Provider<String>`).
When it changes, all streams re-subscribe and all lists reload.
**Never hardcode tenant IDs** — always `ref.read(activeTenantIdProvider)`.

Superadmin (`miguel@conectamos.mx`) can switch tenants; other users see only their own.
Tenant selection persists in `localStorage` key `conectamos_active_tenant`.

### Shell layout

`AppShell` (`lib/shared/widgets/app_shell.dart`) wraps all authenticated routes via
`StatefulShellRoute.indexedStack` in go_router (13 branches). Navigation state is preserved
per branch via `goBranch()`. Collapsible sidebar + topbar.
Auth screens (`/login`, `/forgot-password`, `/reset-password`, `/activate`) bypass the shell.

`_kRouteBranchIndex` map in `app_shell.dart` links route path prefixes to branch indices —
update it whenever a new top-level route is added.

Screens inject title/subtitle/actions via providers (`topbarTitleProvider`, etc.).

---

## Directory structure & file naming

```
lib/
  core/
    api/          — static API classes, one file per domain: [domain]_api.dart
    router/
      app_router.dart   — single go_router instance
    theme/
      colors.dart       — AppColors constants
      app_theme.dart    — AppFonts helpers + AppTextStyles tokens
  features/
    config/       — configuration screens (channels, flows, operators)
    settings/     — tenant settings
    [module]/     — one folder per feature
  shared/
    widgets/      — shared widgets (AppShell, etc.)
```

**Naming rules:**
- Screens: `[name]_screen.dart`
- Detail screens with tabs: `[name]_detail_screen.dart`
- API classes: `[domain]_api.dart` in `lib/core/api/`

---

## Routing (go_router)

**File:** `lib/core/router/app_router.dart`

The router uses `StatefulShellRoute.indexedStack` with 13 named branches. Each branch
corresponds to a top-level route and preserves scroll/state independently.

```dart
GoRoute(
  path: '/flows/:flowId',
  pageBuilder: (context, state) {
    final flowId = state.pathParameters['flowId'] ?? '';
    return NoTransitionPage(
      child: FlowDetailScreen(flowId: flowId),
    );
  },
),
```

**Rules:**
- All authenticated routes go inside `StatefulShellRoute` branches.
- Sub-routes (e.g. `/flows/:flowId`) are nested inside the parent branch route.
- Always use `NoTransitionPage` — no transition animations.
- Extract path params with `state.pathParameters['key'] ?? ''`.
- Add new routes next to others in the same domain.
- Update `_kRouteBranchIndex` in `app_shell.dart` for any new top-level path.

`kMockMode = false` (in `lib/core/config.dart`) — when false, unauthenticated users redirect
to `/login`; authenticated users at `/login` go to `/overview`. Public auth routes skip guard.

---

## API classes

**Reference file:** `lib/core/api/flows_api.dart`

```dart
static Future<Map<String, dynamic>> getFlow({
  required String tenantId,
  required String flowId,
}) async {
  final resp = await ApiClient.dio.get(
    '/flows/$flowId',
    queryParameters: {'tenant_id': tenantId},
  );
  return resp.data as Map<String, dynamic>;
}
```

**Rules:**
- Methods are always static — never instantiate the class.
- `tenant_id` always as query parameter (`queryParameters:`), never in the body.
- Use `ApiClient.dio` — never create Dio instances directly.
- Return types by method type:
  - `list*` → `List<Map<String, dynamic>>`
  - `get*`, `create*`, `update*` → `Map<String, dynamic>`
  - `delete*` → `void`

---

## Detail screens with tabs (canonical pattern)

**Reference:** `OperatorDetailScreen`, `ChannelDetailScreen`

```dart
class FlowDetailScreen extends ConsumerStatefulWidget {
  const FlowDetailScreen({super.key, required this.flowId});
  final String flowId;

  @override
  ConsumerState<FlowDetailScreen> createState() => _FlowDetailScreenState();
}

class _FlowDetailScreenState extends ConsumerState<FlowDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }
}
```

**AppBar with TabBar:**
```dart
appBar: AppBar(
  bottom: TabBar(
    controller: _tabCtrl,
    labelColor: AppColors.ctTeal,
    unselectedLabelColor: AppColors.ctText2,
    indicatorColor: AppColors.ctTeal,
    labelStyle: const TextStyle(
      fontFamily: 'Geist',
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
    tabs: const [Tab(text: 'INFO'), Tab(text: 'CAMPOS'), ...],
  ),
),
```

**Body:**
```dart
body: Column(
  children: [
    _ScreenHeader(data: _data),
    Expanded(
      child: TabBarView(
        controller: _tabCtrl,
        children: [_InfoTab(...), _CamposTab(...), ...],
      ),
    ),
  ],
),
```

> If the number of tabs varies by condition, create `TabController` inside `_load()` instead of `initState()`.

---

## Async state pattern

Every screen with async data uses this exact pattern — no variations:

```dart
bool _loading = true;
String? _error;
Map<String, dynamic>? _flow; // replace type as needed

Future<void> _load() async {
  setState(() { _loading = true; _error = null; });
  try {
    final tenantId = ref.read(activeTenantIdProvider);
    final data = await FlowsApi.getFlow(tenantId: tenantId, flowId: widget.flowId);
    setState(() { _flow = data; _loading = false; });
  } catch (e) {
    setState(() { _error = e.toString(); _loading = false; });
  }
}
```

**Loading state:** `Center(child: CircularProgressIndicator(color: AppColors.ctTeal))`
**Error state:** `Center(child: Text(_error!, style: TextStyle(color: AppColors.ctDanger)))`

---

## Drag-to-reorder

Use `SliverReorderableList` — **never** `ReorderableListView`.
**Reference:** `lib/features/settings/operator_fields_screen.dart:502`

```dart
SliverReorderableList(
  itemCount: _fields.length,
  onReorder: canManage ? _onReorder : (oldIndex, newIndex) {},
  itemBuilder: (context, i) {
    final field = _fields[i];
    final id = field['id'] as String? ?? i.toString();
    return _FieldCard(
      key: ValueKey(id),  // REQUIRED — must be unique and stable
      field: field,
      index: i,
      canManage: canManage,
      onEdit: () => _openEdit(field),
    );
  },
),
```

**Drag handle inside item:**
```dart
ReorderableDragStartListener(
  index: index,
  child: Icon(Icons.drag_handle),
)
```

**onReorder logic:**
```dart
void _onReorder(int oldIndex, int newIndex) {
  setState(() {
    if (newIndex > oldIndex) newIndex--;
    final item = _fields.removeAt(oldIndex);
    _fields.insert(newIndex, item);
  });
}
```

When `canManage` is false, pass `(_, __) {}` to disable without breaking the widget.

---

## Design System v1.0

Cascade: **Tokens → AppShell → Screen archetypes → Components**

### Color tokens (`lib/core/theme/colors.dart`)

**Never inline hex values** — always `AppColors.*`.

| Token | Hex | Use |
|---|---|---|
| `ctTeal` | `#59E0CC` | Primary accent, active state, primary buttons |
| `ctNavy` | `#0B132B` | AppBar background, primary button bg, sidebar bg |
| `ctTealLight` | `#CCFBF1` | Active nav bg, badge teal bg |
| `ctBg` | `#F9FAFB` | Page background |
| `ctSurface` | `#FFFFFF` | Card, dialog, input backgrounds |
| `ctSurface2` | `#F3F4F6` | Secondary surface, table header bg |
| `ctBorder` | `#E5E7EB` | Default borders |
| `ctBorder2` | `#D1D5DB` | Input borders |
| `ctText` | `#111827` | Primary text |
| `ctText2` | `#6B7280` | Secondary labels, inactive tabs |
| `ctText3` | `#9CA3AF` | Tertiary / placeholder text |
| `ctOk` | `#10B981` | Success indicator |
| `ctOkBg` | `#D1FAE5` | Success badge / background |
| `ctWarn` | `#F59E0B` | Warning indicator |
| `ctWarnBg` | `#FEF3C7` | Warning badge / background |
| `ctDanger` | `#EF4444` | Errors, destructive actions |
| `ctRedBg` | `#FEE2E2` | Error badge / background |
| `ctInfoBg` | `#DBEAFE` | Info badge background |
| `ctOrangeBg` | `#FFEDD5` | Orange badge background |
| `ctSidebarBg` | `#0E1829` | Sidebar dark background (AppShell) |

### Typography (`lib/core/theme/app_theme.dart`)

**Two font families only — no google_fonts, no Inter:**
- `Onest` (variable font, local) → display, titles, KPI values, card headings, buttons ≥13px w600+
- `Geist` (variable font, local) → body, labels, metadata, inputs, code

```dart
// Helpers
AppFonts.onest({required double size, FontWeight weight = FontWeight.w400, Color? color, ...})
AppFonts.geist({required double size, FontWeight weight = FontWeight.w400, Color? color, ...})
```

### AppTextStyles tokens (`lib/core/theme/app_theme.dart`)

All tokens are `const TextStyle`. Import `app_theme.dart` to use them.

| Token | Family | Size | Weight | Color | Use |
|---|---|---|---|---|---|
| `AppTextStyles.pageTitle` | Onest | 15 | w700 | ctText | Screen headings |
| `AppTextStyles.pageSubtitle` | Geist | 12 | w400 | ctText2 | Screen subtitles |
| `AppTextStyles.cardTitle` | Onest | 13 | w600 | ctText | Card / section headings |
| `AppTextStyles.topbarTitle` | Onest | 13 | w700 | white | Topbar title |
| `AppTextStyles.topbarSubtitle` | Geist | 10 | w400 | white45 | Topbar subtitle |
| `AppTextStyles.navItem` | Geist | 12 | w500 | ctText2 | Sidebar nav items |
| `AppTextStyles.navItemActive` | Geist | 12 | w600 | tealText | Sidebar active nav |
| `AppTextStyles.navSectionLabel` | Geist | 10 | w600 | ctText3 | Sidebar section labels |
| `AppTextStyles.formLabel` | Geist | 12 | w600 | ctText | Form field labels |
| `AppTextStyles.body` | Geist | 13 | w400 | ctText | Body text, list items |
| `AppTextStyles.bodySmall` | Geist | 11 | w400 | ctText2 | Small body text |
| `AppTextStyles.caption` | Geist | 10 | w400 | ctText3 | Captions, timestamps |
| `AppTextStyles.badge` | Geist | 11 | w600 | — | Badge text (apply color via copyWith) |
| `AppTextStyles.tenantLabel` | Geist | 9 | w600 | ctText3 | Tenant selector label |
| `AppTextStyles.tenantName` | Onest | 12 | w700 | white | Tenant name in topbar |
| `AppTextStyles.btnPrimary` | Geist | 13 | w700 | ctNavy | Primary button label |
| `AppTextStyles.btnSecondary` | Geist | 13 | w500 | ctText | Secondary button label |
| `AppTextStyles.kpiValue` | Onest | 28 | w700 | ctText | KPI large number |
| `AppTextStyles.kpiLabel` | Geist | 10 | w600 | ctText2 | KPI label (letterSpacing 0.07) |

**Migration rule for existing inline TextStyles:**
- Color-only diff → use `AppTextStyles.X.copyWith(color: AppColors.Y)`
- Multiple diffs (size + color + weight) → leave inline
- **Skip** these contexts — never replace: `Theme`, `InputDecoration`, `ButtonStyle`, `AppBar`, `TabBar`, `AlertDialog`
- When using `.copyWith()` in a widget tree, remove `const` from the parent widget (`.copyWith()` is non-const)

### Border radius tokens

| Token | Value | Use |
|---|---|---|
| `rSm` | 6px | Badges, filter chips |
| `rMd` | 10px | Cards, inputs, buttons |
| `rLg` | 14px | Modals, panels |
| `rXl` | 20px | Full-screen overlays |

### Spacing scale

4, 8, 12, 16, 20, 24, 32, 40, 48 — use multiples of 4.

### AppShell anatomy

**Topbar** (`height: 52px`, background: `ctNavy`):
- Left: isotipo SVG + wordmark "Conectam**OS**" (OS in ctTeal)
- Divider + screen title/subtitle (injected via providers)
- Right: KPI chips, tenant selector, bell icon, avatar

**Sidebar** (`width: 220px expanded / 56px collapsed`, background: `ctSidebarBg` = `#0E1829`):
- Dark navy background (not light surface)
- Section labels: `navSectionLabel` style
- Nav items: `navItem` style; active: tealLight bg + teal left border + `navItemActive` style
- Collapse toggle at bottom

**Navigation via `goBranch()`** — never `context.go()` for top-level shell nav.

### Components

**Badges:**
```dart
// Semantic variants via color combinations
// ok: ctOkBg bg / ok-text color
// warn: ctWarnBg bg / warn-text color
// danger: ctRedBg bg / danger-text color
// teal: ctTealLight bg / teal-text color
// navy: ctNavy bg / ctTeal text
// neutral: ctSurface2 bg / ctText2 text
```

**Primary button:** navy bg + ctTeal text + Geist 13 w700
**Ghost button:** ctSurface2 bg + ctBorder border + ctText text

**Input focus ring:** `ctTeal` border + `rgba(89,224,204,.2)` box-shadow

**KPI card:** white surface, 3px colored top bar, kpiLabel + kpiValue tokens

**Table header:** ctSurface2 bg, Geist 10 w700 uppercase letterSpacing 0.07, ctText2 color

**Filter chips:** active = ctNavy bg + ctTeal text; inactive = transparent + ctBorder border

---

## Permissions & guards

```dart
final perms = ref.watch(userPermissionsProvider);
final canManage = perms.contains('flows.manage');
```

Relevant permission strings:
- `flows.view` — view list and detail
- `flows.manage` — create, edit, delete
- `flow_executions.execute_dashboard` — view and act on "Tareas"
- `flow_integrations.manage` — manage flow integrations

---

## Screen-specific notes

### Conversations (`lib/features/conversations/conversations_screen.dart`, ~3500 lines)

- `_TabOperador`: sidebar `_ConvoList` (240px fixed) + `_ChatPanel` (flexible). Outer `Row` uses `CrossAxisAlignment.stretch`.
- `_ChatPanelState` subscribes to `SupabaseMessages.streamMessages()`. On first emit: determines `_firstUnreadMessageId`, schedules two `addPostFrameCallback` jumps to scroll bottom. On subsequent emits: auto-scrolls only if `_atBottom` threshold ≤ 100px.
- `_windowOpen` (`bool?`): `null` = loading, `true` = last inbound < 24h, `false` = closed. Input disabled when `!= true`. Badge/banner hidden for non-WhatsApp channels.
- Read receipts sent sequentially (50ms delay) to avoid burst POSTs.
- `_pendingReactions`: optimistic emoji state keyed by `wa_message_id`. Updated before POST, reverted on catch.
- `selectedChannelIdProvider` / `selectedChannelTypeProvider` — global `StateProvider<String?>` in this file. `_ActionBar` passes them as query params to `/broadcast`.
- 422 errors from `/messages/send` surface the backend `detail` field in the UI snackbar.

### Broadcasts (`lib/features/broadcasts/broadcast_screen.dart`)

- Receives `channel_id` and `channel_type` via go_router query params.
- `isTelegram` flag (from `channel_type == 'telegram'`) hides mode toggle and template dropdown.
- `channel_id` required in POST body; submit blocked with snackbar if empty.

### Channels & WhatsApp Embedded Signup (`lib/features/config/channels_screen.dart`)

- FB SDK injected at runtime via `dart:html` in `_initFbSdk()` (once, guarded by `static bool _fbSdkInitialized`).
- `@JS('_fbLaunchSignup')` binding uses `dart:js_interop`; callbacks passed with `.toJS`.
- `FB.login()` **must** be called synchronously from the user gesture (`onTap`) — no `async` gap.
- Config: `appId: '4149613485350757'`, `config_id: '2145617199565998'`, `response_type: 'code'`, `override_default_response_type: true`.
- On success: `POST /channels/embedded-signup` with `{code, tenant_id}`.
- `_embeddedSignupInProgress` guards against duplicate calls.
- Credential flow stepper: `verify-credentials` → `activate-whatsapp` → save. Both must succeed.

### Operators (`lib/features/config/operators_screen.dart`)

- Flow pre-population handles both string IDs and map objects (`op['flows']` can be either).
- `metadata` key omitted entirely when `telegramChatId == null` — never send explicit null.
- "Vincular vía Telegram" button: appears when operator has Telegram flow but no chat ID (edit mode only). Calls `POST /operators/{id}/send-telegram-invite` per unique Telegram channel. Telegram validation is warning-only, not blocking.

### Flows list (`lib/features/config/workflows_screen.dart`)

- `_FlowCard.onTap` navigates to `/flows/${flow['id']}` via `context.go(...)` — no more edit dialog.
- Create dialog (`_openForm(flow: null)`) is kept for quick creation.
- Edit dialog removed — editing lives in `FlowDetailScreen`.

---

## CI/CD

Push to `main` → GitHub Actions → `flutter build web --release` → `firebase deploy --only hosting`.
Production URL: `https://conectamos-platform-poc.web.app`.
Requires `FIREBASE_TOKEN` secret in GitHub Actions.
