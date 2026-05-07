# === ARCHIVO: ESTADO_PROYECTO.md ===

# ESTADO DEL PROYECTO — Conectamos / ConectamOS

> **Propósito:** Documento vivo que describe el estado actual del proyecto. Debe leerse al inicio de cada conversación nueva.
> **Última actualización:** 2026-05-06 <!-- ACTUALIZADO: sesión de seguridad 2026-05-06 -->
> **Actualizado por:** Actualización incremental — sprints 2026-05-03 a 2026-05-06 + fixes de seguridad 2026-05-06 + auditoría de rutas go_router 2026-05-06

---

## 1. Contexto general

ConectamOS (también "Conectamos Platform") es una plataforma SaaS multi-tenant para supervisión de operadores de campo vía WhatsApp y Telegram. Permite a supervisores gestionar conversaciones, reportes de campo mediante flujos configurables, broadcasts segmentados y AI Workers que automatizan comunicaciones con operadores. Fase actual: MVP funcional con dos tenants operativos (`tmr-prixz` productivo, `conectamos-demo` de pruebas). Canales WhatsApp y Telegram operativos. Permisos IAM dinámicos por tenant implementados. <!-- ACTUALIZADO: AI_ROUTER_CALLBACK_SECRET ahora es obligatorio — HTTP 503 si no configurado; cron endpoints protegidos con CRON_SECRET + hmac.compare_digest -->

---

## 2. Arquitectura actual (alto nivel)

### Repositorios

- **conectamos-platform** — https://github.com/jomikohn8/conectamos-platform — Frontend Flutter Web.
- **conectamos_meta_api** — https://github.com/conectamos-mx/conectamos_meta_api — Backend FastAPI + integración Meta API. (Anteriormente `skohn311/poc_api` — deprecado).
- **conectamos-emails** — Repo público con templates React Email. Compila HTML estático a `/dist` vía GitHub Actions.

### Stack tecnológico

- **Frontend:** Flutter Web + Riverpod + go_router. Fuentes: Onest (títulos) + Geist (cuerpo). Design system basado en Brightcell/JCR.
- **Backend:** FastAPI (Python) en Vercel serverless. Middleware de autenticación BaseHTTPMiddleware de Starlette con JWT de Supabase Auth.
- **Base de datos:** PostgreSQL en Supabase (project `atqmtsmjpjtrqooibubm`).
- **Auth:** Supabase Auth (JWT, invitaciones, recovery tokens).
- **Realtime:** Supabase Realtime (stream sobre `wa_messages`).
- **Storage:** Supabase Storage (bucket público `wa-media` para multimedia y assets).
- **Emails transaccionales:** Resend. HTMLs compilados en repo `conectamos-emails`, consumidos desde `raw.githubusercontent.com`, variables inyectadas con `str.replace()`.
- **Hosting frontend:** Firebase Hosting. CI/CD con GitHub Actions usando `FIREBASE_TOKEN` (Service Accounts bloqueadas por políticas de la org Google).
- **CI/CD backend:** Vercel auto-deploy desde el repo.
- **Integraciones externas:** Meta WhatsApp Cloud API (texto, multimedia, plantillas, webhooks, read receipts, reactions), Telegram Bot API (texto, multimedia, ubicación, webhook automático, reactions, reply), Twilio SMS (vinculación Telegram — funcional), Resend (emails), conversor de audio imageio-ffmpeg.

### Versión actual del backend <!-- ACTUALIZADO: confirmado en main.py -->

- **`version="0.1.8"`** — declarado en `FastAPI(version="0.1.8")` y en `GET /` response.

### URLs

- **Frontend (prod POC):** https://conectamos-platform-poc.web.app
- **Backend (prod):** https://conectamos-meta-api.vercel.app
- **Supabase dashboard:** proyecto `atqmtsmjpjtrqooibubm`

### Tenants operativos

| Slug | Propósito | Estado |
|---|---|---|
| `tmr-prixz` | Caso de uso real (productivo) | Limpio, listo para producción |
| `conectamos-demo` | Pruebas del equipo | Con datos seed (6 operadores mock, mensajes de prueba) |
| `home-prueba` | Tenant de pruebas permanente | Vivo, no eliminar |

### WABA / Phone ID

- **WABA activo productivo:** `1744815743186774`
- **WABA viejo (deprecar):** `1288630306559645` — plantillas `bienvenida_operador`, `incio_dia` quedaron huérfanas en Supabase.
- **Display Name:** pendiente de aprobación por Meta — bloquea envío a números nuevos y broadcasts a contactos sin ventana de 24h abierta.

---

## 3. Estado por módulo

### Frontend (conectamos-platform)

#### Rutas del router (`lib/core/router/app_router.dart`) <!-- ACTUALIZADO: sección nueva — auditoría completa de rutas go_router 2026-05-06 -->

El router usa `StatefulShellRoute.indexedStack` con 13 branches dentro del `AppShell`. Las 4 rutas de auth son `GoRoute` independientes que bypasean el shell.

| Ruta | Widget | Auth | Branch # | Permiso requerido | Subrutas |
|---|---|---|---|---|---|
| `/login` | `LoginScreen` | Pública | — | — | — |
| `/activate?token=` | `ActivateScreen` | Pública | — | — | — |
| `/forgot-password` | `ForgotPasswordScreen` | Pública | — | — | — |
| `/reset-password?token=` | `ResetPasswordScreen` | Pública | — | — | — |
| `/overview` | `OverviewScreen` | Autenticada | 0 | — | — |
| `/conversations` | `ConversationsScreen` | Autenticada | 1 | — | — |
| `/broadcast` | `BroadcastScreen` | Autenticada | 2 | `broadcasts.send` | — |
| `/dashboard` | `DashboardScreen` | Autenticada | 3 | — | — |
| `/operators` | `OperatorsScreen` | Autenticada | 4 | `operators.view` | `/operators/:id` → `OperatorDetailScreen` |
| `/executions` | `AllExecutionsScreen` | Autenticada | 5 | — | `/executions/:executionId` → `ExecutionDetailScreen` |
| `/tareas` | `ExecutionsScreen` | Autenticada | 6 | — | — |
| `/escalaciones` | `EscalacionesScreen` | Autenticada | 7 | `escalations.view` | — |
| `/flows` | `WorkflowsScreen` | Autenticada | 8 | `flows.view` | `/flows/:flowId` → `FlowDetailScreen` |
| `/workers` | `AiWorkersScreen` | Autenticada | 9 | `settings.manage` | — |
| `/channels` | `ChannelsScreen` | Autenticada | 10 | `settings.view` | `/channels/:channelId` → `ChannelDetailScreen` |
| `/connections` | `ConnectionsScreen` | Autenticada | 11 | `settings.view` | — |
| `/settings` | `SettingsScreen` | Autenticada | 12 | `settings.view` | `/settings/operator-fields` → `OperatorFieldsScreen` |

**Notas del router:**
- Ruta inicial: `/overview`.
- Redirect `/ → /overview` para bare root.
- `kMockMode = false` — usuarios no autenticados redirigen a `/login`; usuarios autenticados en `/login` redirigen a `/overview`.
- Guard de permisos aplica sobre prefijo de ruta: si permisos cargaron y el usuario no tiene el permiso, redirige a `/overview`.
- `pendingRedirect` preserva la ruta destino en deep-link/reload para restaurarla tras login.
- Todas las páginas usan `NoTransitionPage` (sin animaciones de transición).

#### Módulos por estado

| Módulo | Estado | Notas |
|---|---|---|
| Auth (login, forgot, reset, activate) | Cerrado | JWT interceptor Dio; `/activate?token=` funcional |
| Sidebar definitivo | Cerrado v2 | Dark navy (`#0E1829`). `StatefulShellRoute.indexedStack` con 13 branches. Badge Realtime en Escalaciones. Selector tenant funcional con `showMenu()` — ID-100 cerrado. |
| Vista general + KPIs | Cerrado | `GET /tenants/{id}/kpis` con asyncio.gather |
| Conversaciones | Cerrado v4 | Sistema `panel_read_at`. `_chatReadOverrideProvider` para race condition no-leídos. Fix 422 en `panel_read` (tenant_id → header). `window_open` calculado desde backend (último inbound). Panel archivadas para `unregistered=true`. `PATCH /conversations/assign`. Fix filtro flujos dinámico. ADR-202. |
| Feed global | Cerrado v3 | Burbujas por origen. Multimedia real. Filtros dinámicos desde `flow_number` de mensajes cargados. `_DateFilterModal` custom (CalendarDatePicker + showTimePicker). Auto-scroll con umbral 150px — no fuerza scroll si usuario subió >150px. Fix separadores UTC→local. |
| Multimedia (imagen, doc, voice note, ubicación) | Cerrado | Voice note en mp3; ubicación auto-detecta URL Google Maps |
| Reacciones / Reply | Cerrado parcial | Reactions outbound WhatsApp y Telegram. Reply outbound Telegram commiteado. E2e Telegram pendiente confirmar (ID-054). |
| Mis Workers | Cerrado | Catálogo con `already_hired` calculado en runtime. Sin `worker_catalog_tenant_visibility` en prod (ver nota en BASE_DE_DATOS). |
| Canales (CRUD) | Cerrado | Stepper bifurcado por `channel_type`. WhatsApp: verify→activate→save (3 llamadas Meta). Telegram: tarjeta habilitada, guía BotFather inline. `channel_detail_screen` con 4 tabs (Plantillas/Bienvenida ocultas en Telegram). Embedded Signup activado. **Nuevo: botón "+ Nueva plantilla" con modal `template_create_dialog.dart`** — bug activo: `Invalid parameter` de Meta al enviar desde modal [NO CONFIRMADO]. |
| Flujos | Cerrado v3 | Editor 4 tabs. Slug y field_key read-only derivados del nombre/etiqueta. `send_proactive` toggle. Tipo `select` con `data_source`. Selector destino AL CERRAR limitado al mismo worker. Autoguardado silencioso. Hard delete. |
| Vista general + KPIs | Cerrado v2 | `_HeroBand` con donut `CustomPainter`. Métricas redefinidas (computed_status, operators_active desde flow_executions, events_processed_today desde flow_field_values). `_LastUpdatedLabel` + botón reload. Chips con `_formatElapsed`. `OperatorAvatar` widget público. ADR-203. |
| Dashboards (nuevo) | Cerrado v1 | 3 tablas BD (`dashboard_definitions`, `dashboard_widgets`, `dashboard_action_logs`). 5 endpoints. Rendering declarativo con `_buildRows` por `layout_hint`. fl_chart 0.69.2. ADR-196. Dashboard `jcr-ops-intelligence` en prod. |
| Pantalla Ejecuciones | Cerrado v2 | Worker = filtro maestro (Nivel 0). Cascada Worker→Flow→Operador. Búsqueda avanzada por campo metadata multi-valor (máx 200). Exportación XLSX 3 hojas (openpyxl, máx 2500 filas). `omni_datetime_picker` con selector campo fecha. |
| Tareas | Cerrado | Pantalla `/tareas` con `flow_executions` pendientes. `_ExecutionDetailSheet` con campos heredados y submit. Gateada por `flow_executions.execute_dashboard`. |
| Ejecución Detail (nuevo) | Cerrado | `ExecutionDetailScreen` en `/executions/:executionId` con campos ordenados por tipo, `_TimelineSidebar` con cronología agrupada, exportación PDF+XLS client-side, botón "Abrir hilo completo". Commits a971b32, 54daf8a, 3dfae32. <!-- ACTUALIZADO: ruta confirmada /executions/:executionId --> |
| Escalaciones (nuevo) | Cerrado | Pantalla `/escalaciones` en Operaciones. Badge Realtime. Panel lateral detalle. Asignar/Resolver/Reabrir con guards permiso. Fix `resolved_by` FK. |
| AppShell | Cerrado v2 | Topbar light (52px, superficie blanca). Sidebar dark navy `#0E1829`. `StatefulShellRoute.indexedStack` con **13 branches** para persistencia de estado — no `ShellRoute` plain. Selector tenant dinámico. Campana sin badge (TODO notificaciones). ADR-195. <!-- ACTUALIZADO: especificado StatefulShellRoute.indexedStack con 13 branches --> |
| Design System v1.0 | Cerrado | `ctTeal=#59E0CC`, `ctNavy=#0B132B`. 10 tokens nuevos. `AppTextStyles` const completo. `google_fonts` eliminado. ~150 TextStyle inline migrados en 26 pantallas. |
| Operadores | Cerrado v2 | Ficha con 4 tabs (DATOS, FLUJOS, PERMISOS, HISTORIAL). Soft delete. Foto de perfil. Campos dinámicos por tenant. Normalización E.164. Validación identidad por país. Errores semánticos OP_E001–OP_E017. |
| Ajustes | Cerrado | Info general + Dirección, Facturación, Usuarios, Comunicación. Tab "Permisos". Panel de permisos dinámicos. Ajustes → Operador: gestión de `operator_field_definitions` inline en `_SectionPanel`. |
| Comunicación WhatsApp (tabs) | Migrado | `whatsapp_config_screen.dart` eliminado; contenido vive en `channel_detail_screen.dart`. |
| Conexiones | Cerrado v2 | Tab "Integraciones API" con CRUD real a nivel tenant (ADR-189). 12 logos locales en `assets/logos/`. `SvgPicture.asset`/`Image.asset` por extensión. |
| Broadcast segmentado | Cerrado v2 | Fotos de perfil reales. Chips Abierta/Cerrada por operador. Bloqueo envío texto libre + WhatsApp con ventanas cerradas. `last_inbound_at` y `profile_picture_url` en GET /operators. |
| Gestión de usuarios | Cerrado | Invitación con token, reset password, sync auth.users. "Gestionar canales" en menú ⋮. `POST /iam/users/{id}/resend-invite` — reenvío actualiza fila existente. |
| Permisos / IAM | Cerrado | Guards de rutas en go_router. Sidebar oculta items sin permiso. `userPermissionsProvider` con shortcut admin. `role_permissions_panel.dart` con cascada de prerequisitos. |
| Login | Cerrado | Leyenda legal (Términos/Privacidad) con `TapGestureRecognizer` (URLs como TODO, ID-041). Fuentes Onest+Geist correctamente declaradas. |
| UI Campos de operador | Cerrado | Implementado en Ajustes → Operador inline. Drag-to-reorder. Sección deshabilitados con rehabilitar. ID-042 cerrado (C-046). |
| Detalle de operador `/sessions` | En progreso | Tab HISTORIAL muestra empty state; endpoint real pendiente (ID-009). |
| Editor visual de campos de flujos | Pendiente | Diferido a sesión dedicada (ID-003). |
| Barra de status de flow activo | Pendiente | Requiere `GET /flows/active` y polling/Realtime (ID-004). |
| Botón "Intervenir" | Cerrado parcial | Llama `SessionsApi.patchStatus`; input deshabilitado por default. Barra de status pendiente. |
| Import/export operadores UI | Pendiente | Backend implementado; sin UI en frontend (ID-059). |
| Dashboards | Back burner | Esperar maduración. |
| Grupos WhatsApp | Back burner | 100% mock. |

### Backend (conectamos_meta_api)

| Módulo | Estado | Notas |
|---|---|---|
| Webhook Meta (inbound + status + media) | Cerrado v2 | 4 checks. Bifurcación por `worker_type`. `_find_operator` con `phone+tenant_id+status=active`. `_find_operator_by_telegram_chat_id` con `tenant_id`. Tenant isolation corregido. ADR-199. |
| `/operators` CRUD | Cerrado v2 | Normalización E.164, validación identidad por país, errores semánticos OP_E001–OP_E017, soft delete, import/export con plantilla dinámica, CRUD de `operator_field_definitions`, `profile_picture_url` en response. `POST /operators/{id}/send-telegram-invite` — Twilio funcional (ID-046 cerrado). |
| `/operator_fields` | Cerrado | CRUD completo de `operator_field_definitions`; `custom_fields` en response de operadores; `RESERVED_METADATA_KEYS`. |
| `/tenants` CRUD + kpis | Cerrado (sin credentials) | `PATCH /tenants/{id}/credentials` eliminado. `POST /tenants` ya no tiene lógica Meta. |
| `/channels` CRUD | Cerrado | Credenciales JSONB. `POST /channels/verify-credentials` (público). `POST /channels/activate-whatsapp` (público). `POST /channels/embedded-signup` (autenticado). Telegram: `setWebhook` con await, `getMe` guarda `bot_username`. |
| `/operator_channels` | Deprecado | RENAME a `_deprecated_operator_channels`. Reemplazado por `operator_flows`. |
| `/templates` | Actualizado | `GET /templates` acepta `channel_id`. Sync filtra por `waba_id` del canal. `CreateTemplateBody` extendido con header (TEXT/IMAGE/VIDEO/DOCUMENT), footer, botones QUICK_REPLY (máx 3). Variables en formato dual `{index, example}` (nuevo) y `{slot, type, key}` (legacy). **Bug activo: Meta retorna `Invalid parameter`** (ID-061). |
| `/broadcasts` | Cerrado v2 | Bifurcación por `channel_type`. `_resolve_system_vars()` y `_resolve_template_body()`. INSERT en `wa_messages` con `origin='broadcast'` y `broadcast_id`. `GET /broadcasts/{id}` ahora requiere `get_current_user` + `assert_tenant_access`. <!-- ACTUALIZADO: fix seguridad get_broadcast --> |
| `/messages/send` | Cerrado | Bifurcación por `channel_type`. Reply support. Reacciones outbound WhatsApp y Telegram. Voice note detectada por `voice_note.*` → sendVoice. `GET /messages` filtra por `tenant_id`; super_admin bypass preservado. <!-- ACTUALIZADO: fix seguridad tenant isolation GET /messages --> |
| `/webhook/telegram/{bot_token}` | Cerrado | Lookup por `bot_token`, flujo `/start TOKEN`, guardado en `wa_messages`, bifurcación por `worker_type`. `allowed_updates` incluye `message_reaction`. |
| `/conversations` | Cerrado | Agrupa por `chat_id`. `display_name`, `last_message`, `unread_count`. Timestamp: `received_at`. Pendiente: `profile_picture_url` (ID-055). |
| `/supervisor-channel-access` | Cerrado | GET/POST/DELETE. Bypass admin; supervisores/viewers solo ven canales asignados. `_get_allowed_channel_ids()` acepta objeto `user` completo con super_admin bypass. <!-- ACTUALIZADO: fix seguridad _get_allowed_channel_ids --> |
| `/iam` — permisos dinámicos + emails | Cerrado con fixes | `requires_permission()` + reenvío invitaciones. Fix URL hardcodeada → `FRONTEND_URL`. Fix `nombreInvitador`. `PUT /iam/roles/{id}` y `DELETE /iam/roles/{id}` verifican `role.tenant_id == caller tenant_id` (fix 403). `PATCH /iam/users/{id}/status` verifica membership en `tenant_users` antes de actualizar. <!-- ACTUALIZADO: fixes de seguridad IAM roles y users --> |
| `/ai_worker_catalog` + `/tenant_workers` | Cerrado | `list_catalog_workers` sin `worker_catalog_tenant_visibility` — query directo + campo `already_hired`. |
| `/flow_definitions` | Cerrado v3 | CRUD completo. `GET /flows/{id}`. `GET /flows/active`. Slug generado con `_slugify()`. `send_proactive bool`. Hard delete con validación executions activas. Validación `target_flow_slug` en on_complete. |
| `/flow_executions` | Cerrado (bug resuelto) | Guard ID-002 en `checkpoint_started`. `active_channel_id` FK→channels. `actor_type`, `flow_definition_snapshot`. `pending_completion` status para executions de `actor_type='system'`. Columnas legacy `fields_status`, `attempts`, `escalated_at`, `escalated_to` dropeadas (migration 46). `idx_flow_executions_unique_active` reemplazado por `idx_flow_executions_unique_active_idempotency` (migration 43). ADR-179/180. |
| `/escalations` | Cerrado | CRUD completo. `GET /escalations/{id}` aplica `.eq("tenant_id", tenant_id)` — previene cross-tenant access. Permisos `escalations.view` y `escalations.manage`. ADR-143. <!-- ACTUALIZADO: fix seguridad tenant_id filter en get_escalation --> |
| `/flow-ingest/{flow_slug}` | Nuevo | Endpoint externo `POST /api/v1/flow-ingest/{slug}`. Auth por `X-Api-Key` con bcrypt. Idempotency. Rate limit. Crea execution en `pending_completion`. ADR-175. |
| `/api/v1/dashboard/` | Nuevo | 4 endpoints: list, detail, assign, submit sobre `flow_executions`. Permisos `execute_dashboard` y `view_all`. |
| `/api/v1/admin/flow-executions/{id}/trace` | Nuevo | Timeline completo: ancestors recursivos, children, events, field_values, actions_log. Permiso `view_all`. |
| `tenant_id` query→header global | Cerrado | 34 endpoints migrados de `tenant_id: Query(...)` a `Depends(get_current_tenant_id)`. Interceptor Flutter inyecta `X-Tenant-ID` desde localStorage. ADR-197. Commits: refactor(routers), d4c60f4, 4c668c0. |
| `super_admin` bypass | Cerrado | `_is_super_admin()` en `auth.py` — lee **exclusivamente** `app_metadata.role` (no `user_metadata`, que puede ser escrita por el cliente). `assert_tenant_access()` movido a `app/dependencies/auth.py` como helper compartido. ADR-114 implementado. <!-- ACTUALIZADO: _is_super_admin solo app_metadata; assert_tenant_access en auth.py --> |
| `/tenants` KPIs | Cerrado v2 | `operators_active` desde flow_executions completadas hoy. `events_processed_today` desde flow_field_values. `computed_status` ('active'|'incident'|'off'). `completion_rate` devuelve 0.0 cuando no hay flujos. Excluye `status='deleted'` de `operators_total`. ADR-203. |
| `/dashboard` configs | Cerrado | 5 endpoints: `GET /configurations`, `/configurations/{slug}`, `/kpis`, `/charts`, `/activity`. Timezone `America/Mexico_City` para filtros de fecha. ADR-196. |
| `/conversations` | Cerrado v2 | `include_unregistered` query param. `unregistered` en response. `PATCH /conversations/assign`. `window_open` calculado desde último inbound. ADR-202. |
| `/wa-messages` DELETE | Nuevo | `DELETE /wa-messages` con guard doble (`operator_id IS NULL AND unregistered=true`). Solo `admin`. |
| Motor Flows v2 — Fase A/B/C | Cerrado | Migrations 33–47 aplicadas. Tablas: `flow_integrations`, `flow_actions_log`, `webhook_outbox`. Servicios: `flow_engine.py`, `flow_chain.py`, `flow_ingest_service.py`, `flow_dashboard_service.py`, `flow_trace_service.py`, `condition_parser.py`, `crypto_utils.py`, `webhook_processor.py`. Cron Vercel cada minuto. |
| Worker Mock (`/_mock_worker/receive`) | **DESHABILITADO** | Router importado pero **comentado** en `main.py` (`# app.include_router(mock_worker.router)`). Solo habilitado localmente si se descomenta. <!-- ACTUALIZADO: confirmado DISABLED en main.py --> |
| Mock Webhook Receiver (`/_mock_webhook/receive`) | **DESHABILITADO** | Router importado pero **comentado** en `main.py` (`# app.include_router(mock_webhook_receiver.router)`). Solo habilitado localmente si se descomenta. <!-- ACTUALIZADO: confirmado DISABLED en main.py --> |
| `/flow_integrations` | Cerrado v2 (ADR-189) | Endpoints a nivel TENANT: `GET/POST/DELETE /integrations`. Endpoints viejos `/flows/{id}/integrations` → HTTP 410. `name` y `api_key_prefix` agregados. `_SAFE_COLUMNS` select. |
| Cron Jobs | Cerrado con seguridad | `GET /api/cron/process-webhook-outbox` y `GET /api/cron/process-pending-completions` en `app/routers/cron.py`. Auth: header `X-Cron-Secret` validado con `hmac.compare_digest`. HTTP 500 si `CRON_SECRET` no configurado; HTTP 401 si valor incorrecto. `CRON_SECRET` en `app/config.py`. <!-- ACTUALIZADO: cron protegido con X-Cron-Secret + hmac.compare_digest; 500 si no configurado --> |
| `/ai-worker/events` | Cerrado v2 + seguridad | `event_type` opcional/null. `_save_field_values()` con validación de schema (ADR-174) + `captured_by`. `_save_flow_event()` con `execution_id`. **Secret obligatorio:** HTTP 503 si `AI_ROUTER_CALLBACK_SECRET` no configurado; HTTP 401 si `X-AI-Router-Secret` incorrecto (`hmac.compare_digest`). ADR-168/169/170. <!-- ACTUALIZADO: AI callback secret ahora 503/401; hmac.compare_digest --> |
| `/messages/ai-callback` | Legado activo | Mantener sin deprecar hasta confirmar si algún worker activo lo usa. Solo texto libre. |
| `/ai-router` (servicio) | Cerrado v2 | Sin fallback `AI_ROUTER_URL` — HTTP 503 si `webhook_url` es null (ADR-192). `auth_config JSONB` desde BD (ADR-191). `worker_can_resume` y `escalation_id` en `contexto_extra` (ADR-194). `tenant_worker_id` en `contexto_extra`. |
| `/operators` | Cerrado v3 | `PUT /{id}` acepta `preferred_channel_types list[str]`. `GET /{id}/available-channel-types`. Tenant isolation completo en todos los lookups/updates (ADR-201). Reactivación de operador deleted (ADR-198). 29 tests de aislamiento. |
| `/escalaciones` backend | Cerrado | Fix `resolved_by`: lookup previo a `tenant_users.id`. Fallo → warning, no 500. |
| `flow_dashboard_service.py` | Cerrado v2 | `get_execution_detail()` enriquecido con `events[]` (SELECT `flow_execution_events`) y `messages[]` (SELECT `wa_messages`). |
| Credenciales (helpers) | Cerrado | `get_channel_credentials()` para WhatsApp, `get_telegram_credentials()` para Telegram. Sin fallback. |
| Telegram (servicios) | Cerrado | `telegram_credentials.py`, `telegram_linking.py`, `telegram_sender.py`, `telegram_media.py`. `media_service.py` genérico compartido con WhatsApp. |
| AuthMiddleware | Cerrado | `verify-credentials`, `activate-whatsapp`, `/webhook/telegram/*` en rutas públicas. `/ai-worker/events` y `/messages/ai-callback` — auth por secret `X-AI-Router-Secret` dentro del handler. |
| EmailService con HTML de GitHub raw | Cerrado | `str.replace()` para `{{variable}}` |
| Conversión audio a mp3 | Cerrado | imageio-ffmpeg + subprocess con libmp3lame |
| Middleware de permisos por rol | Cerrado | `requires_permission()` implementado. ADR-099. |
| Migración 000002 (DROP credenciales Meta en tenants) | Diferida | Backend ya no depende de estas columnas. DROP pendiente hasta ADR-045. |

---

## 4. Variables de entorno <!-- ACTUALIZADO: CRON_SECRET añadida; AI_ROUTER_CALLBACK_SECRET ahora obligatoria en prod -->

| Variable | Requerida | Notas |
|---|---|---|
| `SUPABASE_URL` | Sí | URL del proyecto Supabase |
| `SUPABASE_KEY` | Sí | **Debe ser service_role** — anon key causa errores 42501 RLS |
| `WHATSAPP_VERIFY_TOKEN` | Sí | Token de verificación del webhook Meta |
| `WHATSAPP_ACCESS_TOKEN` | Sí | Token de acceso a Graph API |
| `WHATSAPP_PHONE_NUMBER_ID` | Sí | ID del número de teléfono Meta |
| `AI_ROUTER_CALLBACK_SECRET` | **Obligatoria en prod** | `/ai-worker/events` devuelve HTTP 503 si ausente; HTTP 401 si incorrecto. Comparación con `hmac.compare_digest`. <!-- ACTUALIZADO: ahora obligatoria con 503 si no configurada --> |
| `CRON_SECRET` | **Obligatoria en prod** | Endpoints cron devuelven HTTP 500 si ausente; HTTP 401 si incorrecto. Comparación con `hmac.compare_digest`. <!-- ACTUALIZADO: variable nueva en app/config.py --> |
| `RESEND_API_KEY` | Opcional | Emails silenciosamente omitidos si ausente |
| `RESEND_FROM_EMAIL` | Opcional | Default: `noreply@conectamos.ai` |
| `FRONTEND_URL` | Opcional | Default: `https://poc.web.app`; usado en links de emails de invitación y reset password |
| `AI_ROUTER_CALLBACK_URL` | Opcional | URL para callbacks al AI Router |
| `AI_ROUTER_TIMEOUT_SECONDS` | Opcional | Default: `10` segundos |
| `WHAPI_WEBHOOK_SECRET` | Opcional | Si vacío, router no rechaza por secreto |
| `TWILIO_ACCOUNT_SID` / `TWILIO_AUTH_TOKEN` / `TWILIO_FROM_NUMBER` | Opcionales | SMS para invites Telegram |

---

## 5. Routers activos en main.py <!-- ACTUALIZADO: mock_worker y mock_webhook_receiver confirmados DISABLED en main.py -->

Los siguientes routers están registrados con `app.include_router(...)`:

| Router | Prefix | Estado |
|---|---|---|
| `webhook` | `/webhook` | Activo |
| `webhook_telegram` | `/webhook/telegram/{channel_id}` | Activo |
| `messages` | `/messages` | Activo |
| `operators` | `/operators` | Activo |
| `ai_workers` | (propio) | Activo |
| `ai_worker_events` | `/ai-worker` | Activo |
| `escalations` | `/escalations` | Activo |
| `sessions` | (propio) | Activo |
| `conversations` | (propio) | Activo |
| `tenants` | `/tenants` | Activo |
| `read_receipts` | (propio) | Activo |
| `media` | (propio) | Activo |
| `iam` | `/iam` | Activo |
| `templates` | (propio) | Activo |
| `broadcasts` | `/broadcasts` | Activo |
| `channels` | (propio) | Activo |
| `ai_worker_catalog` | (propio) | Activo |
| `tenant_workers` | `/workers` | Activo |
| `flow_definitions` | (propio) | Activo |
| `flow_integrations` | (propio) | Activo |
| `flow_integrations._flows_router` | legacy `/flows/{id}/integrations` → 410 | Activo |
| `supervisor_channel_access` | `/supervisor-channel-access` | Activo |
| `operator_fields` | `/operator-fields` | Activo |
| `panel_read` | (propio) | Activo |
| `mock_worker` | `/_mock_worker` | **DISABLED** — comentado: `# app.include_router(mock_worker.router)` |
| `flow_ingest` | `/api/v1` | Activo |
| `cron` | `/api/cron` | Activo |
| `mock_webhook_receiver` | `/_mock_webhook` | **DISABLED** — comentado: `# app.include_router(mock_webhook_receiver.router)` |
| `flow_dashboard` | (propio) | Activo |
| `flow_trace` | (propio) | Activo |
| `wa_messages` | `/wa-messages` | Activo |

---

## 6. Rutas públicas (sin autenticación JWT) <!-- ACTUALIZADO: lista actual de _PUBLIC_ROUTES en auth.py -->

Las siguientes rutas bypass el `AuthMiddleware`:

- `GET /`
- `GET /health`
- `POST /webhook`, `GET /webhook`
- `POST /iam/password-reset`
- `POST /iam/password-reset/confirm`
- `GET /iam/invite/{token}`
- `POST /iam/invite/{token}/accept`
- `GET /docs`, `GET /redoc`, `GET /openapi.json`
- `POST /messages/ai-callback`
- `POST /ai-worker/events` (auth por `X-AI-Router-Secret` dentro del handler)
- `POST /channels/verify-credentials`
- `POST /channels/activate-whatsapp`
- `POST /webhook/telegram/{channel_id}`
- `POST /_mock_worker/receive` (router DISABLED)
- `GET /api/cron/process-webhook-outbox` (auth por `X-Cron-Secret` dentro del handler)
- `GET /api/cron/process-pending-completions` (auth por `X-Cron-Secret` dentro del handler)
- `POST /_mock_webhook/receive` (router DISABLED)
- `POST /api/v1/flow-ingest/{flow_slug}` (auth por `X-Api-Key` dentro del handler)
- `GET /operators/{id}/conversational-flows`

---

## 7. Fixes de seguridad aplicados en sesión 2026-05-06 <!-- ACTUALIZADO: sección nueva -->

Los siguientes cambios de seguridad fueron aplicados en la sesión del 2026-05-06:

1. **`GET /messages` filtra por `tenant_id`** — el endpoint ahora requiere que los mensajes pertenezcan al tenant del header `X-Tenant-ID`. Super_admin bypass preservado.

2. **`GET /broadcasts/{id}` requiere `get_current_user` + `assert_tenant_access`** — antes el endpoint no verificaba tenant. Ahora llama `assert_tenant_access(svc, user, broadcast["tenant_id"])`.

3. **`GET /escalations/{id}` tiene `.eq("tenant_id", tenant_id)`** — la query ahora incluye filtro de tenant_id, previniendo acceso cross-tenant por UUID.

4. **`PUT /iam/roles/{id}` y `DELETE /iam/roles/{id}` verifican ownership** — comparan `role.tenant_id` con el `tenant_id` del header. Si no coincide → HTTP 403.

5. **`PATCH /iam/users/{id}/status` verifica membership** — verifica que el `tenant_user` pertenece al tenant del header antes de actualizar su status. Si no → HTTP 403.

6. **`_is_super_admin()` lee solo `app_metadata`** — se eliminó lectura de `user_metadata` (escribible por el cliente). Solo `app_metadata` (escrita con service_role key) es fuente segura. ADR-114.

7. **`assert_tenant_access()` movido a `app/dependencies/auth.py`** — helper compartido disponible para todos los routers. Verifica membership en `tenant_users`; super_admin bypassa.

8. **`_get_allowed_channel_ids()` acepta objeto `user` completo** — recibe el objeto `user` (no solo `user_id`) para verificar super_admin antes del lookup de rol.

9. **`mock_worker` y `mock_webhook_receiver` DISABLED en `main.py`** — los routers se importan (para hot-reload local) pero no se registran. Comentados con `# DISABLED: testing only — enable locally via env flag if needed`.

10. **Cron endpoints con `X-Cron-Secret` + `hmac.compare_digest`** — `_verify_cron_secret()` en `app/routers/cron.py`. HTTP 500 si `CRON_SECRET` no configurado; HTTP 401 si incorrecto. Previene timing attacks.

11. **AI callback secrets obligatorios** — `POST /ai-worker/events` devuelve HTTP 503 si `AI_ROUTER_CALLBACK_SECRET` es falsy; HTTP 401 si `X-AI-Router-Secret` no coincide (`hmac.compare_digest`).

12. **`CRON_SECRET` añadido a `app/config.py`** — leído desde variable de entorno con default vacío string.

---

## 8. Bloqueadores actuales

- **`WHATSAPP_APP_SECRET` expuesto** — quedó visible en conversación de Sprint Embedded Signup. Rotar en Meta for Developers → App Settings → Reset App Secret y actualizar en Vercel. **URGENTE.** Responsable: Miguel.
- **`AI_ROUTER_CALLBACK_SECRET` en Vercel** — si no está configurado, `/ai-worker/events` devuelve HTTP 503. **URGENTE antes de producción.** Responsable: Miguel / Santiago.
- **`CRON_SECRET` en Vercel** — si no está configurado, endpoints cron devuelven HTTP 500. **URGENTE antes de producción.** Responsable: Miguel / Santiago. <!-- ACTUALIZADO: nuevo bloqueador -->
- **Bug `Invalid parameter` de Meta en creación de plantillas** — modal falla en algunos casos; causa sospechosa: acentos en header text o `_normalize_name()`. Responsable: backend (ID-061).
- **URL de ngrok de Gustavo temporal** — `webhook_url` del Worker transporte apunta a ngrok; actualizar cuando Gustavo pase a producción (ID-070).
- **`data_update`/`checkpoint_complete` de Gustavo** — `flow_field_values` sigue en 0 rows al cierre. Responsable: equipo Gustavo.
- **Display Name WA pendiente de aprobación en Meta** — bloquea envío de plantillas a números fuera de ventana 24h. Responsable: Miguel / Meta Business Manager.
- **Verificación de negocio Meta ("Conectamos México")** — bloqueante para Embedded Signup en producción. Sin verificación, popup muestra "no puede incorporar clientes actualmente". 2–5 días hábiles. Responsable: Miguel.
- **Meta App en Development (no Live)** — Embedded Signup solo funciona con admins/testers hasta pasar a Live. Requiere App Review con permisos `whatsapp_business_management` y `whatsapp_business_messaging`.
- **Acceso Vercel para José Miguel** — repo pertenece a Santiago Kohn; redeploys requieren coordinación. Responsable: Santiago / Miguel (ID-008).
- **`welcome_template_id` no viene en GET /channels** — dropdown de Bienvenida siempre vacío al reabrir el tab (ID-036).
- **Reacciones y reply outbound Telegram e2e** — commiteados pero sin confirmación explícita de prueba exitosa (ID-054). [NO CONFIRMADO]
- **`created_by`/`updated_by` en operators** — columnas en BD pero nunca se escriben desde el backend (siempre null). Responsable: backend (ID-058).
- **Migrations 33–40 + 48–55 pendientes en producción** — aplicadas en sandbox/demo. Aplicar en prod (ID-077).
- **Worker Marco: `checkpoint_started` + `set_field_value` no implementados** — executions no se crean, `flow_field_values` queda vacío. Responsable: equipo externo Marco (ID-093).
- **`assigned_flows` y `active_flows` en envelope no implementados** — docs decían que existían; auditoría confirma que son pendientes. [REVISAR CON EQUIPO]
- **Bug `chat_id` duplicados en `wa_messages`** — formato `521XXXXXXXXXX` coexiste con `52XXXXXXXXXX` (E.164). Fix de datos pendiente (ID-075).
- **URL ngrok de Marco temporal** — actualizar `webhook_url` en `ai_worker_catalog` cuando pase a producción (ID-096).
- **`GET /tenants` sin guard** — cualquier usuario autenticado puede ver todos los tenants. TODO en tenants.py:105,128. [REVISAR CON EQUIPO]
- **Conflicto Firebase Auth multi-tenant** — un email ya registrado globalmente no puede reinvitarse a otro tenant. Resolución arquitectónica pendiente.

---

## 9. Próximos hitos

1. **Rotar `WHATSAPP_APP_SECRET`** — urgente, credencial expuesta.
2. **Configurar `AI_ROUTER_CALLBACK_SECRET` en Vercel** — URGENTE antes de producción (ID-094).
3. **Configurar `CRON_SECRET` en Vercel** — URGENTE antes de producción. <!-- ACTUALIZADO: nuevo hito -->
4. **Activar super_admin en Supabase** — ejecutar UPDATE en `auth.users` para `miguel@conectamos.mx` (ID-104). [NO CONFIRMADO si ya se hizo]
5. **Aplicar migrations 33–40 + 48–55 en producción** (ID-077).
6. **Worker Marco/Gustavo implementar `checkpoint_started` + `set_field_value`** (ID-093).
7. **Fix `chat_id` duplicados en `wa_messages`** (ID-075).
8. **Completar plantillas**: badges de estado, probar header IMAGE/VIDEO/DOCUMENT (ID-109).
9. **Auto-refresh 45s en dashboards** — subtitle dice "45s" pero Timer no implementado (ID-108).
10. **Verificación de negocio Meta** — Embedded Signup (Miguel, ID-047).
11. **Aprobación Display Name Meta** — desbloqueante para broadcasts (ID-001).

---

## 10. Links útiles

- Repo plataforma: https://github.com/jomikohn8/conectamos-platform
- Repo Meta API: https://github.com/conectamos-mx/conectamos_meta_api
- Repo emails: conectamos-emails (público, en org conectamos-mx)
- Frontend prod: https://conectamos-platform-poc.web.app
- Backend prod: https://conectamos-meta-api.vercel.app
- Supabase project: `atqmtsmjpjtrqooibubm`

---

## 11. Historial de actualizaciones

| Fecha | Quién | Qué se actualizó |
|---|---|---|
| 2026-04-17 | Miguel Kohn | Consolidación inicial desde 11 conversaciones históricas de abril 2026 |
| 2026-04-20 | Miguel Kohn | Sprints 04-17 a 04-20: refactor credenciales WA, modelo Operador→Flujo, restructura conversaciones por canal+chat_id, fixes canales y fuentes, 8 migrations nuevas. |
| 2026-04-21 | Miguel Kohn | Sprints 04-21: Telegram operativo, IAM completo, onboarding WhatsApp, Embedded Signup, fixes catálogo workers y operadores. Plataforma ya no es WhatsApp-only. |
| 2026-04-24 | Miguel Kohn | Sprints 04-22 a 04-24: Operadores v2, Conversaciones refactor, Broadcast mejorado, fixes IAM/emails, Telegram completado (Twilio funcional). |
| 2026-04-26 | Miguel Kohn | Sprints 04-24 a 04-26: escalaciones, Feed Global v2, modal plantillas, AI Worker Gustavo e2e, routing por BD, bugs de chat_id y tenant resueltos. |
| 2026-04-28 | Miguel Kohn | Fases A/B/C Motor Flows v2 completadas, Frente C frontend (editor flows, Tareas, Integraciones, pill activo), ADR-153–182, bug duplicate key resuelto. |
| 2026-05-03 | Miguel Kohn | Sprints 1–3: Design System v1.0, AppShell rediseño, pantallas Escalaciones y Ejecución Detail, ADR-183–195, integraciones a nivel tenant (ADR-189), Worker Marco integrado, auth_config JSONB. |
| 2026-05-06 | Miguel Kohn | Dashboards, Ejecuciones v2, Vista General v2, Fix templates, tenant isolation operators, super_admin, Conversaciones v4, ADR-196–203. |
| 2026-05-06 | Claude Code | Auditoría de rutas go_router: tabla completa de 17 rutas (4 auth públicas + 13 branches StatefulShellRoute.indexedStack). Confirmado uso de StatefulShellRoute.indexedStack (no ShellRoute). Rutas nuevas documentadas: /executions/:executionId → ExecutionDetailScreen, /flows/:flowId → FlowDetailScreen, /channels/:channelId → ChannelDetailScreen, /settings/operator-fields → OperatorFieldsScreen. <!-- ACTUALIZADO: entrada nueva auditoría rutas 2026-05-06 --> |
| 2026-05-06 | Claude (Cowork) | Fixes de seguridad: tenant isolation GET /messages y GET /escalations/{id}; GET /broadcasts/{id} con assert_tenant_access; PUT/DELETE /iam/roles/{id} con ownership check; PATCH /iam/users/{id}/status con membership check; _is_super_admin solo lee app_metadata; assert_tenant_access movido a auth.py; _get_allowed_channel_ids con super_admin bypass; mock_worker y mock_webhook_receiver DISABLED en main.py; cron con X-Cron-Secret + hmac.compare_digest (500 si no configurado); AI callback 503/401 obligatorio; CRON_SECRET en config.py. Versión backend 0.1.8 documentada. |
