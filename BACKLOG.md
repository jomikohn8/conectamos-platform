# BACKLOG — Conectamos / ConectamOS <!-- ACTUALIZADO: última consolidación 2026-05-06 -->

> **Propósito:** Lista viva de trabajo priorizado, consolidada desde 11 conversaciones históricas.
> **Disciplina:** Cuando un item se mueve a "En progreso", se asigna responsable y fecha objetivo. Cuando se cierra, se mueve a "Cerrado reciente" por 2 semanas antes de archivarlo.
> **Última consolidación:** 2026-05-06 <!-- ACTUALIZADO: fecha actualizada desde 2026-04-21 -->

---

## 1. En progreso

_Items con trabajo activo reciente o bloqueadores inmediatos._

### [ID-001] Aprobación de Display Name Meta para WABA productivo
- **Área:** Legal / Producto (externo)
- **Prioridad:** Alta
- **Responsable:** Miguel (Meta Business Manager)
- **Contexto:** Sin Display Name aprobado no se pueden enviar plantillas a números fuera de la ventana de 24h. Bloquea broadcasts masivos y onboarding de operadores nuevos.
- **Criterios de aceptación:**
  - [ ] Display Name visible como "Approved" en Meta Business Manager para WABA `1744815743186774`.
  - [ ] Broadcast segmentado funciona a números sin conversación previa.
- **Dependencias:** Externo (revisión de Meta).

### ~~[ID-002] Fix `duplicate key` en `flow_executions`~~ → **CERRADO** (ver C-064)

> Guard implementado en `checkpoint_started`: SELECT antes del INSERT busca execution `active` para mismo `(operator_id, flow_definition_id)`. Si existe, retorna existente con HTTP 200 + `already_existed: true`. Commit Fase 0 (2026-04-26).

### ~~[ID-003] Editor visual de campos de flujos~~ → **CERRADO** (ver C-073)

> Implementado en `FlowDetailScreen` con 4 tabs (INFO, CAMPOS, COMPORTAMIENTO, AL CERRAR). Drag-to-reorder en CAMPOS. Editor mini-DSL de condiciones. Editor declarativo `on_complete.actions`. ADR-181. Commits ded828c, 3671c47 (2026-04-27/28).

### ~~[ID-004] Barra de status de flow activo en conversaciones~~ → **CERRADO** (ver C-074)

> `_ActiveFlowPill` implementado en header de conversación con polling Timer 30s + `didUpdateWidget`. Llama `GET /flows/active?tenant_id=&operator_id=`. Commit 287d497 (2026-04-27/28).

### ~~[ID-035] Estabilización post-sprint modelo Operador→Flujo~~ → **CERRADO** (ver C-036)

> Sprint de operadores 2026-04-21 completó la estabilización: `PUT /operators/{id}` escribe en `operator_flows`, columna legacy dropeada, botón "Vincular Telegram" operativo. ADR-102.

### [ID-036] Fix `welcome_template_id` no viene en GET /channels
- **Área:** Backend
- **Prioridad:** Media
- **Responsable:** TBD
- **Contexto:** Dropdown de Bienvenida en `channel_detail_screen` siempre vacío al reabrir el tab porque el campo no viene en la respuesta del canal.
- **Criterios de aceptación:**
  - [ ] `GET /channels/{id}` incluye `welcome_template_id` en la respuesta.
  - [ ] Dropdown de Bienvenida pre-selecciona la plantilla guardada al reabrir el tab.

---

### ~~[ID-005] Guards de rutas por rol en frontend~~ → **CERRADO** (ver C-037)

### ~~[ID-006] Middleware de permisos por rol en backend~~ → **CERRADO** (ver C-038)

### ~~[ID-007] Mover tokens Meta fuera del bundle Flutter~~ → **CERRADO** (ver C-025)

### [ID-008] Acceso de José Miguel a Vercel del backend
- **Área:** Infra
- **Prioridad:** Media
- **Contexto:** Repo `conectamos_meta_api` está bajo la org `conectamos-mx`, pero el proyecto Vercel sigue ligado a la cuenta de Santiago Kohn. Cualquier redeploy requiere coordinación con Santiago.
- **Criterios de aceptación:**
  - [ ] Transfer del proyecto Vercel a la Team de conectamos-mx, o invitar a José Miguel como Owner.
- **Dependencias:** Santiago disponible.

### [ID-009] Fix pantalla de detalle de operador `/sessions`
- **Área:** Frontend
- **Prioridad:** Media
- **Contexto:** La navegación está deshabilitada porque la pantalla aparece vacía. Hay datos mock pero la integración con la API real nunca se conectó.
- **Criterios de aceptación:**
  - [ ] `/operators/:id/sessions` renderiza lista real de `sessions` del operador.
  - [ ] Cada sesión muestra flujo asociado, campos capturados, timestamps.

### ~~[ID-010] Conexión real de "canales asignados" en Operadores~~ → **CERRADO** (ver C-026)

### [ID-011] Refactor de `conversations_screen.dart`
- **Área:** Frontend (deuda técnica)
- **Prioridad:** Media-Alta
- **Contexto:** El archivo tiene 5600+ líneas, sin tipos fuertes, con lógica de UI, estado, API, cache y business rules mezclados.
- **Criterios de aceptación:**
  - [ ] Separar en `conversations_screen.dart` (orquestador) + widgets/providers individuales.
  - [ ] `_windowOpen`, `_sessionStartAt` y demás estados locales movidos a providers tipados de Riverpod.
  - [ ] Zero warnings del analyzer.

### [ID-012] Migración 000002 (DROP columnas Meta legacy en `tenants`)
- **Área:** BD
- **Prioridad:** Media
- **Contexto:** Las columnas `wa_waba_id`, `wa_phone_number_id`, `wa_access_token` en `tenants` son legacy.
- **Criterios de aceptación:**
  - [ ] Todos los tenants activos tienen ≥1 `channel` con credenciales.
  - [ ] Migration `20260501XXXXXX_drop_tenant_wa_cols.sql` aplicada.
- **Dependencias:** Workers activos en producción.

### [ID-013] Procesamiento LLM de mensajes entrantes para clasificación automática por flujo
- **Área:** Backend + Producto
- **Prioridad:** Media

### ~~[ID-037] Endpoints de gestión de `operator_flows`~~ → **CERRADO** (incluido en ADR-102, PUT /operators/{id})

### [ID-038] Endpoint `POST /flow-executions/{id}/request-escalation` <!-- ACTUALIZADO: ya existe PATCH /escalations/{id} con assign/resolve/reopen — revisar si este item sigue pendiente -->
- **Área:** Backend
- **Prioridad:** Media-Alta
- **Contexto:** ADR-075 define Modelo A de intervención. `PATCH /escalations/{id}` con assign/resolve/reopen existe. Verificar si endpoint de request-escalation desde supervisor es distinto del `checkpoint_incomplete` del Worker.
- **Criterios de aceptación:**
  - [ ] Confirmar si el flujo de escalación iniciado por supervisor (no por Worker) está cubierto.

### [ID-039] Confirmar `_verifyAndNext()` ejecuta en paso correcto del stepper de canales
- **Área:** Frontend
- **Prioridad:** Media
- **Notas:** [NO CONFIRMADO: verificar en producción]

### ~~[ID-040] Flujos pre-seleccionados en form de editar operador~~ → **CERRADO** (ver C-039)

### [ID-041] URLs de Términos y Condiciones / Política de Privacidad en login
- **Área:** Frontend / Legal
- **Prioridad:** Media
- **Responsable:** Miguel (proveer URLs).

### ~~[ID-042] UI "Campos de operador" en Ajustes del tenant~~ → **CERRADO** (ver C-046)

### [ID-043] Limpieza de datos legacy `operator_flows` hardcodeados
- **Área:** BD
- **Prioridad:** Baja

### [ID-044] DROP de `_deprecated_operator_channels`
- **Área:** BD
- **Prioridad:** Baja

### [ID-045] Implementar captura de mensajes outbound externos (`smb_message_echoes`)
- **Área:** Backend / Infra
- **Prioridad:** Back burner
- **Dependencias:** Certificación Meta (externo, bloqueante).

### ~~[ID-046] Prueba end-to-end flujo Twilio SMS + Telegram vinculación~~ → **CERRADO** (ver C-045)

### [ID-047] Verificación de negocio Meta y App en Live para Embedded Signup
- **Área:** Infra / Legal (externo)
- **Prioridad:** Alta
- **Responsable:** Miguel

### [ID-048] Rotar `WHATSAPP_APP_SECRET` expuesto
- **Área:** Seguridad
- **Prioridad:** Crítica
- **Responsable:** Miguel
- **Contexto:** App Secret quedó expuesto en conversación del Sprint Embedded Signup (2026-04-21).
- **Criterios de aceptación:**
  - [ ] App Secret rotado en Meta for Developers → App Settings → Basic → Reset App Secret.
  - [ ] Nueva ENV `WHATSAPP_APP_SECRET` actualizada en Vercel.

### [ID-049] Eliminar prints de diagnóstico en `POST /channels/embedded-signup`
- **Área:** Backend
- **Prioridad:** Media

### [ID-050] Canal SMS operativo completo (webhook, envío, conversaciones)
- **Área:** Backend + Frontend
- **Prioridad:** Back burner

### [ID-051] Caso A frontend Telegram — botón "Enviar invitación" al asignar flujo sin chat_id
- **Área:** Frontend
- **Prioridad:** Media

### [ID-052] Caso B frontend Telegram — wizard de canal con invitaciones bulk
- **Área:** Frontend
- **Prioridad:** Media

### [ID-053] Ocultar tabs Plantillas y Bienvenida en `channel_detail_screen` para Telegram
- **Área:** Frontend
- **Prioridad:** Media

### [ID-054] Confirmar reacciones y reply outbound Telegram e2e
- **Área:** Backend + Frontend
- **Prioridad:** Alta
- **Notas:** [NO CONFIRMADO al cierre de Chat 13]

### [ID-055] `GET /conversations` no devuelve `profile_picture_url`
- **Área:** Backend
- **Prioridad:** Media

### ~~[ID-056] Feed Global — rediseño tipo grupo WhatsApp~~ → **CERRADO** (ver C-054)

### [ID-057] Chips de flujos en header de Conversaciones
- **Área:** Mixto
- **Prioridad:** Media

### [ID-058] `created_by`/`updated_by` escritos desde backend en POST/PUT de operadores
- **Área:** Backend
- **Prioridad:** Media

### [ID-059] Import/export de operadores — UI en frontend
- **Área:** Frontend
- **Prioridad:** Media
- **Contexto:** Backend implementado (`operator_import_service.py`, `operator_export_service.py`) pero sin UI en frontend.

### [ID-060] DROP de columnas huérfanas en `wa_messages`
- **Área:** BD
- **Prioridad:** Baja
- **Contexto:** `reactions JSONB` y `_deprecated_reply_to_message_id` son columnas candidatas a DROP.
- **Criterios de aceptación:**
  - [ ] Verificar cero referencias en código a `reactions` como columna de escritura.
  - [ ] Verificar cero referencias a `_deprecated_reply_to_message_id`.
  - [ ] Migrations de DROP aplicadas.

### ~~[ID-061] Fix bug `Invalid parameter` de Meta en creación de plantillas~~ → **CERRADO** (ver C-095)

### ~~[ID-062] Migration `wa_templates` — columnas header/footer/buttons~~ → **CERRADO** (ver C-096)

### ~~[ID-063] Pantalla de tickets de escalaciones en Flutter~~ → **CERRADO** (ver C-080)

### [ID-064] Asignar `escalations.view` y `escalations.manage` a roles en seeds de `POST /tenants` <!-- ACTUALIZADO: parcialmente cubierto por migration 55 -->
- **Área:** Backend / BD
- **Prioridad:** Media
- **Contexto:** Migration 55 ya incluye `dashboards.view`, `dashboards.manage` y `escalations` en seed. Verificar si la asignación a `supervisor` está completa.
- **Criterios de aceptación:**
  - [ ] Confirmar que migration 55 asigna `escalations.view` a `supervisor` y `escalations.manage` a `admin`.

### [ID-065] Implementar normalizador `ChannelMessage` (ADR-138)
- **Área:** Backend
- **Prioridad:** Media
- **Responsable:** Santiago

### [ID-066] Implementar lógica de `active_channel_id` en pipeline (ADR-139)
- **Área:** Backend
- **Prioridad:** Media
- **Responsable:** Santiago

### [ID-067] Implementar lógica de retry con `is_processed` (ADR-141)
- **Área:** Backend
- **Prioridad:** Media
- **Responsable:** Santiago

### [ID-068] Implementar `POST /worker/trigger` (ADR-147)
- **Área:** Backend
- **Prioridad:** Media
- **Contexto:** Worker-initiated trigger propuesto pero no implementado. Bloqueado por decisión de autenticación.

### [ID-069] Verificar y limpiar duplicado `CREAR_VIAJE` en `flow_definitions`
- **Área:** BD
- **Prioridad:** Baja

### [ID-070] Actualizar URL definitiva de Worker Gustavo en `ai_worker_catalog`
- **Área:** BD / Infra
- **Prioridad:** Alta
- **Responsable:** Miguel (al recibir URL de Gustavo)
- **Contexto:** `webhook_url` del Worker transporte apunta a ngrok — temporal.

### [ID-071] Confirmar y limpiar logs temporales en backend
- **Área:** Backend
- **Prioridad:** Media
- **Criterios de aceptación:**
  - [ ] Eliminar `print("=== META PAYLOAD ===")` en `templates.py`.
  - [ ] Eliminar logging `AI_WORKER_EVENT_RECEIVED` en `ai_worker_events.py`.
  - [ ] Eliminar log temporal `_resolve_channel_by_phone` en `webhook.py`.

### [ID-072] Documentar y versionar contrato ADR-140 (AI_WORKER_INTEGRATION.md)
- **Área:** Producto / Docs
- **Prioridad:** Media

### ~~[ID-073] Decidir: `operator_flows` vs `find_flow_definition_for_channel()`~~ → **CERRADO** (ver C-097)

### ~~[ID-074] Definir threshold de inactividad para `flow_executions.status = 'paused'`~~ → **CERRADO** (ver C-065)

### [ID-086] Prueba E2E completa desde frontend
- **Área:** QA / Frontend
- **Prioridad:** Alta

### ~~[ID-087] Reemplazar `httpbin.org` por receptor propio de webhook outbound~~ → **CERRADO** (ver C-081)

### ~~[ID-088] Proteger o eliminar `GET /api/cron/debug-execution/{id}`~~ → **CERRADO** (ver C-082)

### ~~[ID-089] Implementar `preferred_channel_id` en `operators`~~ → **DESCARTADO** (ver D-043)

### [ID-090] Backfill `parent_execution_id` en executions existentes (Step 11 Fase B)
- **Área:** BD
- **Prioridad:** Baja

### ~~[ID-091] Tab AL CERRAR funcional — validar con flows reales~~ → **CERRADO** (ver C-083)

### [ID-092] Pantalla de control de flows activos por supervisor (ADR-167)
- **Área:** Frontend
- **Prioridad:** Alta

### [ID-093] Worker Marco implementar `checkpoint_started` + `set_field_value`
- **Área:** Worker externo (Marco)
- **Prioridad:** Crítica
- **Responsable:** Equipo externo de Marco

### [ID-094] Configurar `AI_ROUTER_CALLBACK_SECRET` en Vercel
- **Área:** Infra
- **Prioridad:** Crítica
- **Responsable:** Miguel / Santiago

### [ID-095] Implementar ADR-190 — filtrar flujos conversacionales en selector de operador
- **Área:** Frontend + Backend
- **Prioridad:** Media

### [ID-096] URL definitiva de Worker Marco
- **Área:** BD / Infra
- **Prioridad:** Alta
- **Responsable:** Miguel (al recibir URL de Marco)

### [ID-097] Implementar `assigned_flows` y `active_flows` en envelope del Worker
- **Área:** Backend
- **Prioridad:** Media
- **Notas:** [REVISAR CON EQUIPO — confirmar si ya implementado en ADR-145 o pendiente]

### [ID-098] Ampliar `AppTextStyles` con tokens faltantes
- **Área:** Frontend
- **Prioridad:** Baja

### [ID-099] Agregar colores WA hardcodeados a tokens de canal
- **Área:** Frontend
- **Prioridad:** Baja

### ~~[ID-100] Implementar selector de tenant (switcher funcional)~~ → **CERRADO** (ver C-098)

### [ID-101] Módulo de notificaciones — badge campana
- **Área:** Frontend + Backend
- **Prioridad:** Baja

### [ID-102] Renombrar `ondrive.svg` → `onedrive.svg` por consistencia
- **Área:** Frontend
- **Prioridad:** Baja

### ~~[ID-103] Seed `POST /tenants` — asignar permisos `escalations.view` y `escalations.manage`~~ → **CERRADO** (ver C-099)

### [ID-104] Activar super_admin en Supabase para `miguel@conectamos.mx` <!-- ACTUALIZADO: bypass implementado en código; confirmar si UPDATE ya ejecutado en prod -->
- **Área:** Infra
- **Prioridad:** Alta
- **Responsable:** Miguel
- **Contexto:** El bypass `super_admin` está implementado en `_is_super_admin()` (commit 093af4c). Requiere ejecutar UPDATE en `auth.users`. [NO CONFIRMADO si ya se ejecutó]
- **Criterios de aceptación:**
  - [ ] `UPDATE auth.users SET raw_app_meta_data = raw_app_meta_data || '{"role": "super_admin"}' WHERE email = 'miguel@conectamos.mx'` ejecutado.
  - [ ] Login con miguel@conectamos.mx puede ver todos los tenants.

### [ID-105] Implementar auto-refresh 45s en dashboards
- **Área:** Frontend
- **Prioridad:** Media
- **Contexto:** Subtitle dice "actualiza cada 45s" pero `Timer.periodic` no está implementado.

### [ID-106] `flow_action_button` — disparar flow real desde dashboard
- **Área:** Frontend / Backend
- **Prioridad:** Media

### [ID-107] `execution_table` y `operator_status_grid` — rendering real
- **Área:** Frontend
- **Prioridad:** Media

### [ID-108] `_DayThread` en Vista General — nutrir con datos reales
- **Área:** Frontend / Backend
- **Prioridad:** Media

### [ID-109] Pantalla de lista de templates — badges de estado 7 colores + probar header multimedia
- **Área:** Frontend / QA
- **Prioridad:** Media

### [ID-110] Row hover con acciones en pantalla Ejecuciones (pause/abandon/reassign)
- **Área:** Frontend
- **Prioridad:** Media
- **Contexto:** Backend endpoints ya implementados (ADR-206). Falta UI con validación de permisos.

### [ID-111] Operadores en sidebar de Ejecuciones — filtrar por worker seleccionado (V2)
- **Área:** Mixto
- **Prioridad:** Baja

### [ID-112] `GET /feed` con filtros agregados Nivel 2 (date, operator, channel)
- **Área:** Backend
- **Prioridad:** Media

### [ID-113] `GET /conversations` sin paginación — agregar límite
- **Área:** Backend
- **Prioridad:** Media

### [ID-114] Fix tests pre-existentes en `test_conversational_flows.py` (7 failures)
- **Área:** Backend / QA
- **Prioridad:** Media

### [ID-115] `AppTextStyles.pageTitle` — normalizar a 20px o crear token `pageTitleLarge`
- **Área:** Frontend / Design System
- **Prioridad:** Baja

### [ID-116] Limpiar `debugPrint` en `all_executions_screen.dart`
- **Área:** Frontend
- **Prioridad:** Baja

### [ID-117] `GET /tenants` sin guard de autorización — decisión de producto
- **Área:** Backend / Seguridad
- **Prioridad:** Media
- **Contexto:** Cualquier usuario autenticado puede llamar `GET /tenants` sin `user_id` y recibir todos los tenants. TODO en tenants.py:105,128. [REVISAR CON EQUIPO]

### [ID-118] Habilitar mock_worker y mock_webhook_receiver en producción si se requiere <!-- ACTUALIZADO: nuevo item — ambos routers están comentados en main.py -->
- **Área:** Backend / Infra
- **Prioridad:** Baja
- **Contexto:** `mock_worker` y `mock_webhook_receiver` están comentados en `app/main.py` (líneas 46-51). No están disponibles en producción.
- **Criterios de aceptación:**
  - [ ] Decisión documentada: ¿habilitar para ambiente de QA o dejar comentados permanentemente?

---


### [ID-119] Actualizar CLAUDE.md — corregir ApiClient.dio → ApiClient.instance, ShellRoute → StatefulShellRoute, localStorage key, FlowsApi.getFlow signature <!-- ACTUALIZADO: nuevo item detectado en auditoría frontend -->
- **Área:** Frontend / Docs
- **Prioridad:** Alta
- **Contexto:** CLAUDE.md tiene al menos 4 discrepancias críticas con el código real: (1) `ApiClient.dio` debe ser `ApiClient.instance`; (2) `ShellRoute` debe ser `StatefulShellRoute.indexedStack`; (3) localStorage key `conectamos_active_tenant` debe ser `conectamos_active_tenant_id`; (4) `FlowsApi.getFlow(tenantId:, flowId:)` — la firma real no tiene `tenantId` param. Ver ADR-210, ADR-212.
- **Criterios de aceptación:**
  - [ ] `ApiClient.dio` → `ApiClient.instance` en sección "API classes".
  - [ ] `ShellRoute` → `StatefulShellRoute.indexedStack` en sección "Shell layout".
  - [ ] `conectamos_active_tenant` → `conectamos_active_tenant_id` en sección "Multi-tenancy".
  - [ ] `FlowsApi.getFlow` signature corregida (sin `tenantId:` param).
  - [ ] Sección "API classes" añade nota sobre header `X-Tenant-ID` inyectado automáticamente (no pasar como query param).

### [ID-120] Documentar `AppTextStyles`, `ScreenHeader` y `PageHeader` en CLAUDE.md <!-- ACTUALIZADO: nuevo item detectado en auditoría frontend -->
- **Área:** Frontend / Docs
- **Prioridad:** Media
- **Contexto:** CLAUDE.md menciona `AppFonts.onest()` / `AppFonts.geist()` pero no documenta `AppTextStyles` (20 estilos nombrados const) ni los dos patrones de header canónicos `ScreenHeader` (Pattern A) y `PageHeader` (Pattern B). Cualquier desarrollador nuevo creará headers inconsistentes sin esta guía.
- **Criterios de aceptación:**
  - [ ] Sección "Theme & design tokens" en CLAUDE.md incluye tabla de estilos `AppTextStyles` con los tokens principales.
  - [ ] Sección nueva "Header widgets canónicos" describe Pattern A (`ScreenHeader`) vs Pattern B (`PageHeader`) con criterio de uso.


## 3. Back burner

- [ID-014] Dashboards analíticos por tenant — esperar maduración del producto y volumen de datos.
- [ID-015] Grupos WhatsApp — actualmente 100% mock; requiere confirmación de viabilidad API.
- [ID-016] Reply (responder mensaje específico) — UI pendiente; el endpoint ya soporta `context.message_id`.
- [ID-017] Threading / hilos de conversación — mejoraría UX en feed global.
- [ID-018] Editor WYSIWYG de plantillas de WhatsApp dentro del producto.
- [ID-019] Soft delete generalizado en `operators`, `channels`, `tenant_workers`.
- [ID-020] Auditoría (tabla `audit_log`) para cambios sensibles.
- [ID-021] Multi-idioma en frontend (ES / EN / PT).
- [ID-022] Soporte de envío de videos en conversaciones.
- [ID-023] Soporte de stickers entrantes (mostrar como emoji placeholder).
- [ID-024] Exportación de conversaciones a CSV / PDF por operador o rango de fechas.
- [ID-025] Ventana configurable de retención de mensajes por tenant (compliance).
- [ID-026] Marketplace público de AI Worker Catalog con precios visibles antes de login.
- [ID-027] Precios y billing automatizado por uso de mensajes / workers activos.
- [ID-028] Integraciones con Zapier / n8n / Make para flows salientes desde ConectamOS.
- [ID-029] SSO con Google Workspace / Microsoft 365 para tenants enterprise.
- [ID-030] Modo oscuro en frontend.
- [ID-031] Atajos de teclado en conversaciones (como WhatsApp Web).
- [ID-032] Indicador "escribiendo…" bidireccional.
- [ID-033] Pinneo de conversaciones o sesiones destacadas.
- [ID-034] Plantillas de mensajes de supervisor (respuestas rápidas reutilizables).

---

## 4. Cerrado reciente (desde abril 2026)

| ID | Título | Cerrado | Notas |
|---|---|---|---|
| C-001 | Autenticación completa (login, forgot, reset, activate con token) | 2026-04-05 | JWT Dio interceptor + `/activate?token=`. |
| C-002 | Sidebar definitivo con 4 secciones | 2026-04-06 | |
| C-003 | Vista general + KPIs | 2026-04-07 | `GET /tenants/{id}/kpis` con asyncio.gather. |
| C-004 | Conversaciones por operador (burbujas, tabs, read receipts, reacciones optimistas) | 2026-04-09 | |
| C-005 | Feed global rediseñado tipo grupo WhatsApp | 2026-04-09 | |
| C-006 | Multimedia: imagen, doc, voice note (mp3), ubicación | 2026-04-10 | imageio-ffmpeg + libmp3lame. |
| C-007 | Mis Workers (catálogo + contratación como dialog) | 2026-04-11 | |
| C-008 | Canales CRUD + paleta de color + asignación a operadores | 2026-04-11 | |
| C-009 | Flujos CRUD conectado a API real | 2026-04-12 | |
| C-010 | Submenú Ajustes con 4 secciones | 2026-04-12 | |
| C-011 | Comunicación WhatsApp con tabs | 2026-04-13 | |
| C-012 | Broadcast segmentado con banner tricolor + filtros | 2026-04-15 | |
| C-013 | Gestión de usuarios (invitación con token, reset password, sync auth.users) | 2026-04-13 | |
| C-014 | Backend webhook Meta (inbound, status, media síncrona timeout 8s) | 2026-04-07 | |
| C-015 | Backend `/operators` + `/tenants` + `/channels` + `/templates` CRUD completo | 2026-04-10 | |
| C-016 | `/messages/send` unificado con firma automática | 2026-04-14 | |
| C-017 | `/read-receipts` migrado de Supabase directo a backend | 2026-04-14 | |
| C-018 | `/iam` con invite, accept, password-reset | 2026-04-13 | |
| C-019 | AuthMiddleware BaseHTTPMiddleware con OPTIONS excluidos | 2026-04-08 | |
| C-020 | EmailService con HTML desde GitHub raw (Opción B1) | 2026-04-13 | |
| C-021 | Conversión de audio a mp3 con imageio-ffmpeg | 2026-04-10 | |
| C-022 | Repo backend migrado a `conectamos-mx/conectamos_meta_api` | 2026-04-11 | |
| C-023 | Dominio backend migrado a `conectamos-meta-api.vercel.app` | 2026-04-11 | |
| C-024 | 11 migraciones formales aplicadas | 2026-04-16 | |
| C-025 | Refactor credenciales WA: centralización en `channel_config.credentials` | 2026-04-17 | ADR-077, ADR-078, ADR-079. |
| C-026 | Columna CANALES reemplazada por FLUJOS ASIGNADOS | 2026-04-18 | ADR-070. |
| C-027 | `whatsapp_config_screen.dart` eliminado; migrado a `channel_detail_screen.dart` | 2026-04-17 | |
| C-028 | Modelo asignación Operador→Flujo: migration, tabla `operator_flows`, RENAME | 2026-04-18 | ADR-070. |
| C-029 | Webhook inbound reescrito con 4 checks + bifurcación por `worker_type` | 2026-04-20 | ADR-073, ADR-088. |
| C-030 | `GET /conversations` reescrito por `chat_id`; restructura pantalla | 2026-04-20 | ADR-090, ADR-093. |
| C-031 | 8 migrations aplicadas en prod (migrations 12–19, abril 17–20) | 2026-04-20 | |
| C-032 | `supervisor_channel_access`: tabla + endpoints + dialog "Gestionar canales" | 2026-04-20 | ADR-092. |
| C-033 | Verificación de credenciales Meta pre-guardado + `_mask_channel_token()` | 2026-04-20 | ADR-097. |
| C-034 | Fuentes Onest+Geist como variable fonts; 450 refs `'Inter'`→`'Geist'` | 2026-04-20 | ADR-098. |
| C-035 | `ai_worker_catalog` actualizado: Worker paquete, Worker transporte | 2026-04-20 | ADR-095. |
| C-036 | Estabilización Operador→Flujo: `PUT /operators/{id}` escribe en `operator_flows` | 2026-04-21 | ADR-102. |
| C-037 | Guards de rutas por rol en go_router + sidebar oculta items sin permiso | 2026-04-21 | |
| C-038 | Middleware `requires_permission()` implementado en todos los endpoints | 2026-04-21 | Commit 6b5c19e. ADR-099. |
| C-039 | Flujos pre-seleccionados al editar operador | 2026-04-21 | |
| C-040 | Sprint IAM completo: permisos dinámicos, `role_permissions_panel.dart`, cascada | 2026-04-21 | ADR-099, ADR-114, ADR-115, ADR-116. |
| C-041 | Sprint Telegram: canal, webhook automático, mensajes inbound/outbound, broadcast | 2026-04-21 | ADR-103 a ADR-108. Migration 21. |
| C-042 | Onboarding WhatsApp verify→activate→save | 2026-04-21 | ADR-117. Commit 10a7820. |
| C-043 | Embedded Signup v2 activado | 2026-04-21 | ADR-109 a ADR-113. Commit 4b2dfdd. |
| C-044 | Catálogo AI Workers corregido: error 500 resuelto | 2026-04-21 | ADR-100, ADR-101. Migration 20. |
| C-045 | Twilio SMS e2e funcional: vinculación Telegram operador | 2026-04-22 | ADR-107. |
| C-046 | UI "Campos de operador" completa: drag-to-reorder, deshabilitados, inline Ajustes | 2026-04-23 | ADR-137. |
| C-047 | Sprint Operadores v2: soft delete, foto perfil, ficha 4 tabs, import/export, E.164 | 2026-04-23 | ADR-130 a ADR-135. |
| C-048 | Refactor completo Conversaciones: `panel_read_at`, AppShell topbar navy | 2026-04-23 | ADR-136. |
| C-049 | Fixes broadcast: fotos reales, chips ventana 24h, bloqueo texto libre WA | 2026-04-24 | ADR-120, ADR-121, ADR-122. |
| C-050 | Auditoría emails: 5 bugs corregidos, `resend-invite` endpoint nuevo | 2026-04-22 | ADR-119. Commit c6b204b. |
| C-051 | Telegram completado: vinculación, `telegram_link_status`, media, reply, reacciones | 2026-04-22 | ADR-123 a ADR-129. |
| C-052 | `media_service.py` genérico compartido WhatsApp + Telegram | 2026-04-22 | ADR-126. |
| C-053 | `context_message_id` canónico; `reply_to_message_id` deprecada | 2026-04-22 | ADR-128. |
| C-054 | Feed Global v2: burbujas por origen, multimedia real, sticky headers, filtros | 2026-04-25 | |
| C-055 | Modal `template_create_dialog.dart`: creación de plantillas con preview | 2026-04-25 | |
| C-056 | Escalaciones sistema completo: tabla, endpoints CRUD, permisos, callback | 2026-04-24 | ADR-143. Migrations 30, 31. |
| C-057 | `_save_field_values()` y `_save_flow_event()` activos | 2026-04-26 | ADR-142. Commit c046cd5. |
| C-058 | Routing condicional de Workers por `webhook_url` en BD | 2026-04-26 | ADR-149. |
| C-059 | Bug aislamiento tenant corregido: `channel["tenant_id"]` prioridad | 2026-04-26 | ADR-151. Commit c362e0b. |
| C-060 | Normalización cambiada a `normalize_to_e164` en `_find_operator()` | 2026-04-26 | |
| C-061 | `is_processed=True` actualizado post-INSERT con `routing_request_id` | 2026-04-26 | ADR-141. |
| C-062 | Bug `chat_id` con `+` corregido para `origin='ai_worker'` | 2026-04-26 | |
| C-063 | Integración e2e con Worker de Gustavo: auth bidireccional, payload ADR-140 | 2026-04-26 | ADR-149, ADR-150. |
| C-064 | Guard ID-002: `checkpoint_started` SELECT antes de INSERT | 2026-04-26 | |
| C-065 | Decisión: `status='paused'` es manual, sin threshold automático | 2026-04-26 | ADR-166. |
| C-066 | Worker Mock deployado: `/_mock_worker/receive`, 4 flows de prueba | 2026-04-26 | |
| C-067 | Fase A Motor Flows v2 en sandbox: migrations 33–40 | 2026-04-27 | ADR-168/169/170. |
| C-068 | Auditoría pipeline Flows v2: 8 de 13 gaps corregidos | 2026-04-27 | |
| C-069 | Fix scroll conversaciones: `ListView reverse: true` | 2026-04-27 | |
| C-070 | Migration 41: `flow_events.execution_id` y `flow_field_values.captured_by` | 2026-04-27 | |
| C-071 | Schema estricto `flow_field_values`: validación contra schema, `_notas` reservada | 2026-04-27 | ADR-172/173/174. |
| C-072 | Fase B Steps 2–6: ingest externo → chaining → proactivo → confirmación → webhook_out | 2026-04-27 | ADR-175/176/177/178. |
| C-073 | Editor visual de flows `FlowDetailScreen` 4 tabs + drag-to-reorder | 2026-04-28 | ADR-181. |
| C-074 | `_ActiveFlowPill` con polling 30s en header de conversación | 2026-04-28 | |
| C-075 | Pantalla `ExecutionsScreen` (/tareas) con `_ExecutionDetailSheet` y submit | 2026-04-28 | |
| C-076 | Pantalla `flow_integrations_screen` — CRUD inbound/outbound | 2026-04-28 | |
| C-077 | Fase B Steps 7–10 + Fase C cerrada: dashboard, snapshot, trace, hardening | 2026-04-27 | Migrations 42–47. |
| C-078 | `GET /flows/{id}`, `GET /flows/active`, CRUD `/flows/{id}/integrations` | 2026-04-28 | |
| C-079 | `DateFormat` con locale eliminado; reemplazado por formato manual | 2026-04-28 | ADR-182. |
| C-080 | Pantalla Escalaciones: badge Realtime, panel detalle, Asignar/Resolver/Reabrir | 2026-04-28 | |
| C-081 | `/_mock_webhook/receive` con HMAC desde BD via `delivery_id` | 2026-04-29 | ADR-193. |
| C-082 | `GET /api/cron/debug-execution/{id}` protegido con `CRON_SECRET` | 2026-04-28 | Commit 33d1443. |
| C-083 | Tab AL CERRAR funcional: dropdown flows mismo worker, validación backend | 2026-04-29 | ADR-186. |
| C-084 | Sprint 1 Platform Debug: 7 bloqueadores E2E resueltos | 2026-04-28 | Migrations 50, 51, 52. |
| C-085 | Sprint 2 Configuración E2E: 7 flows configurados, integraciones configuradas | 2026-04-29 | ADR-184–190. |
| C-086 | Worker Marco integrado e2e con ngrok: auth migrada a BD, 3 bugs pipeline corregidos | 2026-04-29/30 | ADR-191/192. |
| C-087 | ADR-189 implementado: integraciones nivel tenant, endpoints 410, logos locales | 2026-04-30 | |
| C-088 | Sprint 3 Mock Worker: 4 handlers nuevos, `worker_can_resume`/`escalation_id` | 2026-04-29 | ADR-193/194. |
| C-089 | `preferred_channel_types text[]` en operators + índice único `channels_unique_active_type_per_worker` | 2026-04-28 | Migration 51. |
| C-090 | `slug` read-only en flows: `_slugify()` en backend + frontend | 2026-04-29 | ADR-184. |
| C-091 | `field_key` read-only derivado de etiqueta + tipo `select` con `data_source` | 2026-04-29 | ADR-185/188. |
| C-092 | Hard delete de flows con validación executions activas (409) | 2026-04-29 | |
| C-093 | `ExecutionDetailScreen` con cronología sidebar, export PDF+XLS | 2026-05-03 | |
| C-094 | Design System v1.0: tokens corregidos, AppShell rediseño, StatefulShellRoute | 2026-05-01 | ADR-195. |
| C-095 | Fix 422 templates: `tenant_id` via header, `_normalize_name()` con unicodedata | 2026-05-04 | Commit ef1c5e7. |
| C-096 | Migration wa_templates: columnas `header_type`, `header_text`, `footer_text`, `buttons` | 2026-05-04 | Migration 54. |
| C-097 | `operator_flows` como lookup primario en pipeline conversacional | 2026-04-28 | |
| C-098 | Selector de tenant funcional: `showMenu()`, `TenantNotifier.select()` | 2026-05-05 | ADR (DS). Commit 9a58082. |
| C-099 | Permisos `dashboards.view` y `dashboards.manage` + `escalations` en seed migration 55 | 2026-05-03 | |
| C-100 | Dashboards v1: 3 tablas BD, 5 endpoints, rendering declarativo | 2026-05-03 | ADR-196. Migration 55. |
| C-101 | `tenant_id` query→header global: 34 endpoints migrados + interceptor Flutter | 2026-05-03 | ADR-197. |
| C-102 | Tenant isolation completo en operators: 8 endpoints, 29 tests | 2026-05-05 | Migrations 56. ADR-198/199/200/201. |
| C-103 | `super_admin` bypass implementado: `_is_super_admin()`, impersonación via X-Tenant-ID | 2026-05-05 | ADR-114. Commit 093af4c. |
| C-104 | Vista General v2: HeroBand, computed_status, métricas redefinidas | 2026-05-05 | ADR-203. |
| C-105 | Pantalla Ejecuciones v2: filtro maestro Worker, búsqueda avanzada, XLSX 3 hojas | 2026-05-04 | |
| C-106 | Conversaciones v4: panel archivadas, `PATCH /conversations/assign`, `window_open` desde backend | 2026-05-06 | ADR-202. |
| C-107 | Feed Global v3: filtros dinámicos desde flow_number, auto-scroll 150px | 2026-05-06 | |
| C-108 | Fix `panel_read.py` — `tenant_id` de body a header (422) | 2026-05-06 | Commit 47772c2. |
| C-109 | `DELETE /wa-messages` con guard doble para unregistered | 2026-05-06 | Commit 71de9f0. |
| C-110 | `saved_views` CRUD: tabla + 4 endpoints GET/POST/PATCH/DELETE en `/flow-dashboard/saved-views` | 2026-05-04 | ADR-204. Migration `20260504000001`. <!-- ACTUALIZADO: nuevo cierre no documentado --> |
| C-111 | `prerequisite_flow_slug` en `flow_definitions` + validación en `start_execution()` | 2026-05-05 | ADR-207. Migration `20260505000001`. <!-- ACTUALIZADO: nuevo cierre no documentado --> |

---

## 5. Descartados

| ID | Título | Fecha | Motivo |
|---|---|---|---|
| D-001 | Next.js para el frontend | 2026-04-05 | Se eligió Flutter Web. |
| D-002 | React Native para mobile | 2026-04-05 | Flutter cubre el caso. |
| D-003 | Inter como fuente principal | 2026-04-06 | Reemplazado por Onest + Geist. |
| D-004 | Hostear frontend en Vercel / Cloudflare Pages / Netlify | 2026-04-06 | Firebase Hosting seleccionado. |
| D-005 | Voice notes en formato webm | 2026-04-10 | WhatsApp rechaza con error 131053. |
| D-006 | Voice notes en ogg/opus | 2026-04-10 | Inestable en WhatsApp; formato final es mp3. |
| D-007 | Supabase Auth invite nativo | 2026-04-13 | Sistema propio de `invitations` con token. |
| D-008 | OAuth social (Google, Apple) en login | 2026-04-13 | Fuera de scope del MVP. |
| D-009 | Schema-per-tenant en PostgreSQL | 2026-04-07 | Complejidad; row-level con `tenant_id`. |
| D-010 | EAV puro para definiciones de flujos | 2026-04-12 | Rechazado por performance. |
| D-011 | FK directa `operators.ai_worker_id` | 2026-04-12 | Reemplazado por modelo de canales. |
| D-012 | `verify_otp` con `token_hash` para reset de password | 2026-04-13 | Reemplazado por `access_token` JWT. |
| D-013 | Pantalla `/catalog` separada para contratar Workers | 2026-04-11 | Dialog dentro de "Mis Workers". |
| D-014 | Pantalla "Coming Soon" genérica | 2026-04-06 | Sidebar ya indica "PRÓXIMAMENTE". |
| D-015 | Fallback "Agente" cuando no hay Worker asignado | 2026-04-11 | Canal requiere Worker explícito. |
| D-016 | Opción A (templates de Resend dashboard) | 2026-04-13 | Incompatible con versionado por código. |
| D-017 | Opción B2 (templates vía GitHub Releases) | 2026-04-13 | `raw.githubusercontent.com` es suficiente. |
| D-018 | Logo de emails embebido en base64 | 2026-04-13 | Migrado a PNG en Supabase Storage. |
| D-019 | Logo SVG en emails | 2026-04-13 | Clientes email no renderizan SVG. |
| D-020 | Firebase Auth multi-tenant nativo | 2026-04-13 | Conflicto con Supabase Auth ya implementado. |
| D-021 | Asignación directa operador→canal como modelo principal | 2026-04-18 | Reemplazado por Operador→Flujo (ADR-070). |
| D-022 | Broadcast multicanal implícito | 2026-04-17 | Canal único requerido (ADR-080). |
| D-023 | ENV vars WA como fallback en backend | 2026-04-17 | Eliminadas completamente (ADR-078). |
| D-024 | Reactivación automática de operador `inactive` al recibir mensaje | 2026-04-20 | Comportamiento sorpresa; se loguea warning (ADR-089). |
| D-025 | Captura de mensajes outbound externos vía polling Graph API | 2026-04-20 | Solo via `smb_message_echoes` de Tech Provider. |
| D-026 | Bot único de Telegram compartido por Conectamos | 2026-04-21 | Cada tenant crea su propio bot (ADR-104). |
| D-027 | `asyncio.create_task` para `setWebhook` en Vercel | 2026-04-21 | Vercel cancela tasks; se usa `await` directo (ADR-105). |
| D-028 | Embedded Signup con `configuration_id: 1290590206469350` | 2026-04-21 | Reemplazado por `2145617199565998` (ADR-110). |
| D-029 | `phone_telegram` como campo separado en operadores | 2026-04-23 | Telegram usa `telegram_chat_id` (ADR-131). |
| D-030 | Ruta `/settings/operator-fields` como pantalla separada | 2026-04-23 | Integrado inline en Ajustes (ADR-137). |
| D-031 | `reply_to_message_id` (UUID FK) como campo canónico para replies | 2026-04-22 | Reemplazado por `context_message_id TEXT` (ADR-128). |
| D-032 | UPDATE de JSONB `reactions` en mensaje original | 2026-04-22 | Reemplazado por fila nueva `message_type='reaction'` (ADR-127). |
| D-033 | Opción A y Opción C para vinculación Telegram | 2026-04-22 | Reemplazados por Opción B (ADR-123). |
| D-034 | Draft local de plantillas sin llamar a Meta Graph API | 2026-04-25 | Plantilla sin aprobación Meta no es funcional. |
| D-035 | Simulador de teléfono estilo ManyChat para preview de plantillas | 2026-04-25 | Miguel rechazó; se usa preview tipo burbuja. |
| D-036 | Deprecar `POST /messages/ai-callback` explícitamente | 2026-04-26 | No confirmado si algún Worker activo lo usa. |
| D-037 | API Key separada por worker para auth de Workers externos | 2026-04-26 | Se usa `AI_ROUTER_CALLBACK_SECRET` compartido. |
| D-038 | Filtro client-side sobre batch de 200 mensajes para filtros de fecha | 2026-04-25 | Reemplazado por `_fetchFeedStatic` con query estática. |
| D-039 | Threshold automático de inactividad para `status='paused'` | 2026-04-26 | Paused es manual en Fase 1 (ADR-166). |
| D-040 | Tenant `conectamos-sandbox` nuevo para pruebas | 2026-04-26 | Reemplazado por `conectamos-demo` (ADR-165). |
| D-041 | `asyncio.ensure_future` para `complete_execution` inline en Vercel | 2026-04-27 | Vercel cancela; se usa cron + `pending_completion` (ADR-175). |
| D-042 | `/_mock_webhook/receive` como receptor del webhook outbox en Vercel | 2026-04-27 | Self-call causa timeout; reemplazado por `httpbin.org` temporal. |
| D-043 | `preferred_channel_id` UUID absoluto en `operators` | 2026-04-28 | Reemplazado por `preferred_channel_types text[]`. |
| D-044 | Tab bar Chrome-style en AppShell con `IndexedStack` manual | 2026-05-01 | GlobalKey duplicada bugs. Reemplazado por `StatefulShellRoute` (ADR-195). |
| D-045 | `tabs_provider.dart` — tabs persistido en `localStorage['ct.tabs']` | 2026-05-01 | Redundante con `StatefulShellRoute`. |
| D-046 | `_kColorPalette` en `ai_workers_screen` | 2026-05-01 | El catálogo lo controla Conectamos. |
| D-047 | `excel 4.0.6` para exportación XLS en Flutter Web | 2026-05-03 | Bug de serialización — archivos corruptos. Reemplazado por OOXML manual. |
| D-048 | Accent bar izquierdo por status en rows de Ejecuciones | 2026-05-04 | Miguel no lo aprobó visualmente. Commit revertido (5290e32). |

---

## 6. Historial de consolidaciones

| Fecha | Quién | Notas |
|---|---|---|
| 2026-04-17 | Miguel Kohn | Consolidación inicial desde 11 extracciones históricas de abril 2026 |
| 2026-04-20 | Miguel Kohn | Sprints 04-17 a 04-20: ID-007 e ID-010 cerrados; ID-035 a ID-045 nuevos; C-025 a C-035; D-021 a D-025. |
| 2026-04-21 | Miguel Kohn | ID-035, ID-005, ID-006, ID-040 cerrados; ID-046 a ID-053 nuevos; C-036 a C-044; D-026 a D-028. ID-048 crítico (App Secret). |
| 2026-04-24 | Miguel Kohn | ID-046 e ID-042 cerrados; ID-054 a ID-060 nuevos; C-045 a C-053; D-029 a D-033. |
| 2026-04-26 | Miguel Kohn | ID-056 cerrado; ID-061 a ID-074 nuevos; C-054 a C-063; D-034 a D-038. |
| 2026-04-28 | Miguel Kohn | ID-002/003/004/074 cerrados; ID-086 a ID-092 nuevos; C-064 a C-079; D-039 a D-042. |
| 2026-05-03 | Miguel Kohn | ID-063/087/088/089/091 cerrados; ID-093 a ID-103 nuevos; C-080 a C-094; D-043 a D-047. |
| 2026-05-06 | Miguel Kohn | ID-061/062/073/100/103 cerrados; ID-104 a ID-117 nuevos; C-095 a C-109; D-048. |
| 2026-05-06 | Claude Code | ID-118 nuevo; C-110 y C-111 agregados (saved_views, prerequisite_flow_slug). Cierres parciales revisados. |
| 2026-05-06 | Claude Code | ID-119 e ID-120 nuevos — discrepancias CLAUDE.md vs código real detectadas en auditoría frontend. ADR-210 a ADR-214 referenciados. <!-- ACTUALIZADO: auditoría frontend --> |
