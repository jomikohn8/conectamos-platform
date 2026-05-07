# REGISTRO DE DECISIONES — Conectamos <!-- ACTUALIZADO: título sin cambio -->

> **Propósito:** Log append-only de decisiones del proyecto. Una decisión no se edita: si cambia, se agrega una entrada nueva que la supersede.
> **Regla de oro:** Si una decisión no está aquí, se considera que no se tomó.

---

## Formato por entrada

```
### [ADR-XXX] Título corto

- **Fecha:** YYYY-MM-DD
- **Estado:** Vigente | Superseded por ADR-YYY | Revertida
- **Área:** Arquitectura | Producto | Backend | Frontend | BD | Infra | Emails | UX
- **Decidido por:**
- **Contexto:**
- **Decisión:**
- **Alternativas consideradas:**
- **Conversación origen:**
```

---

## Decisiones (orden cronológico — más reciente abajo)

### [ADR-001] Stack frontend Flutter Web + Riverpod + go_router

- **Fecha:** 2026-04-08
- **Estado:** Vigente
- **Área:** Arquitectura
- **Decidido por:** Equipo técnico (José Miguel, Santiago)
- **Contexto:** Mobile-friendly para dueños de negocio; un solo codebase web+mobile a futuro.
- **Decisión:** Flutter Web con Riverpod para estado y go_router para navegación.
- **Alternativas consideradas:** Next.js (recomendado por Claude), React Native con Expo — descartados por preferencia del equipo.
- **Conversación origen:** Proyecto nuevo ConectamOS — contexto, arquitectura.

### [ADR-002] Fuentes Onest + Geist

- **Fecha:** 2026-04-08
- **Estado:** Vigente
- **Área:** UX
- **Decidido por:** Miguel
- **Contexto:** Identidad visual de Conectamos.
- **Decisión:** Onest para títulos/bold, Geist para cuerpo.
- **Alternativas consideradas:** Inter (proyecto anterior Brightcell).
- **Conversación origen:** Proyecto nuevo ConectamOS.

### [ADR-003] Design system basado en Brightcell/JCR

- **Fecha:** 2026-04-08
- **Estado:** Vigente
- **Área:** UX
- **Contexto:** Capitalizar trabajo previo; colores CT ya definidos.
- **Decisión:** Reutilizar frontend existente de Brightcell/JCR como base del design system.
- **Conversación origen:** Proyecto nuevo ConectamOS.

### [ADR-004] Deploy frontend en Firebase Hosting

- **Fecha:** 2026-04-10
- **Estado:** Vigente
- **Área:** Infra
- **Contexto:** Vercel ya usado por backend; permisos de organización Google impidieron crear Service Accounts, se usa `FIREBASE_TOKEN` via GitHub Actions.
- **Decisión:** Firebase Hosting en `conectamos-platform-poc.web.app`.
- **Alternativas consideradas:** Vercel, Cloudflare Pages, Netlify.
- **Conversación origen:** Proyecto nuevo ConectamOS.

### [ADR-005] `kMockMode = false` en producción

- **Fecha:** 2026-04-12
- **Estado:** Vigente
- **Área:** Frontend
- **Contexto:** Backend y Supabase funcionales.
- **Decisión:** Datos reales desde Supabase en producción.
- **Conversación origen:** Proyecto nuevo ConectamOS.

### [ADR-006] Acceso directo a Supabase desde Flutter para mensajes y operadores

- **Fecha:** 2026-04-12
- **Estado:** Superseded por ADR-060
- **Área:** Arquitectura
- **Contexto:** CORS de Vercel bloqueaba llamadas desde Firebase Hosting a FastAPI; Supabase Realtime disponible.
- **Decisión:** Flutter lee/escribe directo en Supabase; FastAPI solo para envío Meta y webhook.
- **Alternativas consideradas:** FastAPI en Vercel, ngrok, proxy.
- **Conversación origen:** Proyecto nuevo ConectamOS.

### [ADR-007] `user_read_receipts` en Supabase para `last_read_at`

- **Fecha:** 2026-04-12
- **Estado:** Superseded por ADR-136
- **Área:** BD
- **Contexto:** `SharedPreferences`/`localStorage` se pierden entre sesiones.
- **Decisión:** Persistir last_read_at por usuario en tabla Supabase.
- **Conversación origen:** Proyecto nuevo ConectamOS.

### [ADR-008] Feed global tipo grupo WhatsApp con burbujas

- **Fecha:** 2026-04-13
- **Estado:** Vigente
- **Área:** Producto
- **Contexto:** "El objetivo final es quitar el vicio de los grupos de WhatsApp operativos".
- **Decisión:** Feed global rediseñado como burbujas inbound/outbound con filtros bidireccionales (from_phone inbound, chat_id outbound porque to_phone es null).
- **Alternativas consideradas:** Vista tabular.
- **Conversación origen:** Proyecto nuevo ConectamOS / Sesión Apr 13–16.

### [ADR-009] Contador de no leídos con `_sessionStartAt` como cutoff

- **Fecha:** 2026-04-14
- **Estado:** Vigente
- **Área:** Frontend
- **Contexto:** Cutoff de 24h generaba badges falsos al recargar en incógnito.
- **Decisión:** Usar `_sessionStartAt` como cutoff cuando no hay `last_read_at`.
- **Conversación origen:** Sesión Apr 13–16.

### [ADR-010] Multi-tenancy completo desde el inicio

- **Fecha:** 2026-04-13
- **Estado:** Vigente
- **Área:** Arquitectura
- **Contexto:** Plataforma SaaS requiere aislamiento de datos.
- **Decisión:** Multi-tenant con tabla `tenants` y `tenant_id` en tablas relevantes. Dos tenants iniciales: `tmr-prixz` (productivo) y `conectamos-demo` (pruebas). Todos los datos de prueba migrados a `conectamos-demo`.
- **Conversación origen:** Sesión Apr 13–16.

### [ADR-011] Roles granulares del sistema por tenant

- **Fecha:** 2026-04-14
- **Estado:** Vigente
- **Área:** Arquitectura
- **Contexto:** Diferentes tenants necesitan distintas estructuras de acceso.
- **Decisión:** Roles `admin` (13 permisos), `supervisor` (7), `viewer` (6). Seed automático al crear tenant vía `_seed_system_roles()`. Tabla `user_roles` legacy queda sin uso.
- **Alternativas consideradas:** Roles fijos hardcodeados.
- **Conversación origen:** Sesión Apr 13–16.

### [ADR-012] Invitación de usuarios con Resend desde `noreply@conectamos.ai`

- **Fecha:** 2026-04-14
- **Estado:** Vigente
- **Área:** Emails
- **Contexto:** Dominio `conectamos.mx` no verificado en Resend; `conectamos.ai` sí aprobado.
- **Decisión:** `from` hardcoded a `noreply@conectamos.ai` ignorando `RESEND_FROM_EMAIL`. TODO para unificar cuando migre dominio.
- **Alternativas consideradas:** Supabase Auth invite nativo.
- **Conversación origen:** Sesión Apr 13–16 / Integración emails.

### [ADR-013] Pantalla `/activate` pública con token

- **Fecha:** 2026-04-14
- **Estado:** Vigente
- **Área:** Frontend
- **Decisión:** Ruta pública `/activate?token=UUID` para completar cuenta (nombre, teléfono, contraseña).
- **Conversación origen:** Sesión Apr 13–16.

### [ADR-014] `usePathUrlStrategy()` en go_router

- **Fecha:** 2026-04-14
- **Estado:** Vigente
- **Área:** Frontend
- **Contexto:** Links de activación por email no funcionan con hash routing.
- **Decisión:** URLs limpias sin `#`.
- **Conversación origen:** Sesión Apr 13–16.

### [ADR-015] Multimedia descargada síncronamente con timeout 8s a `wa-media` bucket

- **Fecha:** 2026-04-14
- **Estado:** Vigente
- **Área:** Backend
- **Contexto:** `asyncio.create_task` no completa en Vercel serverless.
- **Decisión:** Descarga síncrona con timeout 8s; archivos guardados en Supabase Storage bucket público `wa-media`.
- **Alternativas consideradas:** Background task async, worker externo.
- **Conversación origen:** Sesión Apr 13–16.

### [ADR-016] Sidebar en 4 secciones

- **Fecha:** 2026-04-16
- **Estado:** Vigente
- **Área:** UX
- **Decisión:** OPERACIONES (Vista general, Conversaciones) / WORKERS (Mis Workers, Flujos de trabajo) / CONFIGURACIÓN (Canales, Operadores, Conexiones, Ajustes) / PRÓXIMAMENTE (Dashboards, Catálogo). Ítems disabled con tooltip "Próximamente".
- **Alternativas consideradas:** Sección GESTIÓN separada; pantalla "coming soon".
- **Conversación origen:** Sesión arquitectura frontend/backend.

### [ADR-017] Ajustes con submenú lateral vertical

- **Fecha:** 2026-04-14
- **Estado:** Vigente
- **Área:** UX
- **Decisión:** Submenú con 4 secciones: Info general + Dirección (fusionadas), Facturación, Usuarios, Comunicación. Tabs horizontales descartadas.
- **Conversación origen:** Sesión Apr 13–16.

### [ADR-018] `show_supervisor_name` configurable por tenant

- **Fecha:** 2026-04-14
- **Estado:** Vigente
- **Área:** Producto
- **Decisión:** Toggle por tenant; si `true`, outbound lleva `"Nombre: mensaje"`.
- **Conversación origen:** Sesión Apr 13–16.

### [ADR-019] Variables de plantillas Meta con catálogo del sistema + libres

- **Fecha:** 2026-04-14
- **Estado:** Vigente
- **Área:** Producto
- **Decisión:** Variables sistema (`nombre_operador`, `nombre_tenant`, `telefono_operador`, `fecha_hoy`, `hora_actual`) autorresueltas + variables libres.
- **Conversación origen:** Sesión Apr 13–16.

### [ADR-020] Plantilla de bienvenida creada automáticamente al crear tenant

- **Fecha:** 2026-04-14
- **Estado:** Superseded por ADR-076
- **Área:** Backend
- **Decisión:** `POST /tenants` crea la plantilla `bienvenida_{slug}` en Meta automáticamente.
- **Conversación origen:** Sesión Apr 13–16.

### [ADR-021] Broadcast agrupado en feed global

- **Fecha:** 2026-04-14
- **Estado:** Vigente
- **Área:** UX
- **Decisión:** Un broadcast se muestra como un mensaje agrupado en el feed, no como N mensajes individuales, para evitar saturación.
- **Conversación origen:** Sesión Apr 13–16.

### [ADR-022] `sent_by_user_id` en `wa_messages`

- **Fecha:** 2026-04-14
- **Estado:** Vigente
- **Área:** BD
- **Decisión:** Trazabilidad de quién envió cada mensaje outbound.
- **Conversación origen:** Sesión Apr 13–16.

### [ADR-023] CI/CD con GitHub Actions + `FIREBASE_TOKEN`

- **Fecha:** 2026-04-14
- **Estado:** Vigente
- **Área:** Infra
- **Contexto:** Políticas de Google Cloud impiden crear Service Accounts.
- **Decisión:** Deploy automático a Firebase Hosting en cada push a main. Migración a Service Account queda como propuesta a futuro.
- **Conversación origen:** Sesión Apr 13–16 / Sesión fixes multimedia.

### [ADR-024] Validación de operadores por `(tenant_id, phone)`

- **Fecha:** 2026-04-14
- **Estado:** Vigente
- **Área:** Backend
- **Contexto:** Un mismo número puede ser operador en múltiples tenants.
- **Decisión:** Unicidad por par, no global.
- **Conversación origen:** Sesión Apr 13–16.

### [ADR-025] Colores WhatsApp nativo en burbujas de conversación

- **Fecha:** 2026-04-14
- **Estado:** Vigente
- **Área:** UX
- **Decisión:** Blanco inbound, verde `#D9FDD3` outbound, fondo `#EBEBE9`. Teal/navy del design system descartados aquí.
- **Conversación origen:** Sesión Apr 13–16.

### [ADR-026] `NoTransitionPage` en todas las rutas de go_router

- **Fecha:** 2026-04-14
- **Estado:** Vigente
- **Área:** Frontend
- **Contexto:** Transiciones de Flutter Web se veían lentas vs React.
- **Decisión:** Navegación instantánea sin transiciones.
- **Conversación origen:** Sesión Apr 13–16.

### [ADR-027] Filtrado de plantillas por `waba_id` del WABA activo

- **Fecha:** 2026-04-15
- **Estado:** Vigente
- **Área:** Backend / Frontend
- **Contexto:** Al cambiar credenciales Meta, las plantillas del WABA anterior seguían apareciendo y causaban errores.
- **Decisión:** Todas las pantallas filtran plantillas por `waba_id == activeWabaId OR waba_id == null`; broadcast valida `template.waba_id == tenant.wa_waba_id` antes de enviar (422 si difieren).
- **Conversación origen:** Sesión fixes y multimedia.

### [ADR-028] Auto-sync de templates al cambiar credenciales

- **Fecha:** 2026-04-15
- **Estado:** Vigente
- **Área:** Backend
- **Decisión:** `PATCH /tenants/{id}/credentials` dispara `_do_sync_templates` automáticamente; errores loggeados como warning sin bloquear.
- **Conversación origen:** Sesión fixes y multimedia.

### [ADR-029] Silenciar 400 de `/messages/read` para wamids del phone anterior

- **Fecha:** 2026-04-15
- **Estado:** Vigente
- **Área:** Backend
- **Contexto:** Mensajes históricos del phone ID viejo no pueden marcarse como leídos en el phone ID nuevo — Meta siempre rechaza.
- **Decisión:** Backend responde 200 con `{"status": "skipped", "reason": "message_not_found_in_current_phone"}`.
- **Conversación origen:** Sesión fixes y multimedia.

### [ADR-030] Banner tricolor en broadcast

- **Fecha:** 2026-04-15
- **Estado:** Vigente
- **Área:** UX
- **Decisión:** Verde (todos ok), amarillo (parcial), rojo (todos fallaron). Antes mostraba verde aunque todos fallaran.
- **Conversación origen:** Sesión fixes y multimedia.

### [ADR-031] Voice notes en mp3 (libmp3lame) — PTT descartado

- **Fecha:** 2026-04-15
- **Estado:** Vigente (supersede intentos con ogg/opus)
- **Área:** Backend
- **Contexto:** Meta rechaza webm; ogg/opus generado por imageio-ffmpeg era rechazado como `application/octet-stream` a pesar de header OggS válido.
- **Decisión:** Convertir cualquier `audio/*` → mp3 con `libmp3lame` usando imageio-ffmpeg + subprocess. El audio se entrega como archivo descargable, no como PTT nativo.
- **Alternativas consideradas:** pydub (no funciona en Vercel), ogg/opus, envío por URL pública de Supabase con content-type audio/ogg — todas rechazadas por Meta.
- **Conversación origen:** Fix voice notes + Meta API audio pipeline.

### [ADR-032] Frontend graba voice notes en `audio/mp4`

- **Fecha:** 2026-04-15
- **Estado:** Vigente
- **Área:** Frontend
- **Contexto:** Chrome no soporta `audio/ogg;codecs=opus` en MediaRecorder; `audio/mp4` sí.
- **Decisión:** Orden de preferencia en `_pickRecorderMimeType`: `ogg;codecs=opus → mp4;codecs=mp4a.40.2 → mp4 → webm;codecs=opus`, fallback `audio/mp4`.
- **Conversación origen:** Fix voice notes.

### [ADR-033] `content-type` explícito en `MultipartFile.fromBytes` (Dio)

- **Fecha:** 2026-04-15
- **Estado:** Vigente
- **Área:** Frontend
- **Contexto:** Dio infería `video/mp4` del filename `voice_note.mp4` rompiendo la detección en backend.
- **Decisión:** Pasar `contentType: MediaType.parse(...)` con `http_parser`.
- **Conversación origen:** Fix voice notes.

### [ADR-034] Micrófono en barra de mensajes, envío inmediato sin preview

- **Fecha:** 2026-04-16
- **Estado:** Vigente
- **Área:** UX
- **Decisión:** Reemplaza botón enviar cuando campo vacío; al detener grabación se envía sin modal de preview (estilo WhatsApp nativo).
- **Conversación origen:** Fix voice notes / Sprint multimedia outbound.

### [ADR-035] Detección automática de URLs Google Maps en TextField

- **Fecha:** 2026-04-16
- **Estado:** Vigente
- **Área:** UX
- **Contexto:** Opción "Ubicación" del menú era redundante con pegar URL.
- **Decisión:** Eliminar entrada del menú; detectar URL en TextField y enviar como mensaje de ubicación automáticamente.
- **Conversación origen:** Sprint multimedia outbound.

### [ADR-036] Schema híbrido JSONB (Opción C)

- **Fecha:** 2026-04-16
- **Estado:** Vigente
- **Área:** Arquitectura
- **Contexto:** Balance entre flexibilidad por tenant y performance.
- **Decisión:** Un solo schema Postgres con JSONB donde haga falta. Schema por tenant descartado por límites de Supabase; EAV puro descartado por performance.
- **Conversación origen:** Decisiones arquitectura AI Workers.

### [ADR-037] Un AI Worker = un número de WhatsApp

- **Fecha:** 2026-04-16
- **Estado:** Vigente
- **Área:** Arquitectura
- **Decisión:** El `phone_number_id` del webhook identifica al Worker directamente. Símil: cada Worker tiene su propio teléfono.
- **Conversación origen:** Decisiones arquitectura AI Workers.

### [ADR-038] Modelo `Operador → Canal ← AI Worker`

- **Fecha:** 2026-04-16
- **Estado:** Superseded por ADR-070
- **Área:** Arquitectura
- **Decisión:** Tabla pivote `operator_channels`. FK directa `operators.ai_worker_id` deprecada (renombrada `_deprecated_ai_worker_id`).
- **Conversación origen:** Decisiones arquitectura AI Workers.

### [ADR-039] Historial de conversación en Redis, gestionado por el AI Worker

- **Fecha:** 2026-04-16
- **Estado:** Parcialmente supersedido por ADR-145
- **Área:** Arquitectura
- **Decisión:** La plataforma solo envía mensaje nuevo + estado del flow_execution. Historial no se replica en la plataforma.
- **Conversación origen:** Decisiones arquitectura AI Workers.

### [ADR-040] Plataforma ejecutora, AI Worker cerebro

- **Fecha:** 2026-04-16
- **Estado:** Vigente
- **Área:** Arquitectura
- **Decisión:** Plataforma recibe, guarda, enruta, ejecuta. AI Worker externo hace clasificación de intención y lógica de flow.
- **Conversación origen:** Decisiones arquitectura AI Workers.

### [ADR-041] `flow_executions` como fuente de verdad del estado del flow

- **Fecha:** 2026-04-16
- **Estado:** Vigente
- **Área:** BD
- **Decisión:** Estado persistido en Supabase; si Worker reinicia, estado sobrevive.
- **Conversación origen:** Decisiones arquitectura AI Workers.

### [ADR-042] Permisos a nivel `tenant_worker_id`

- **Fecha:** 2026-04-16
- **Estado:** Vigente
- **Área:** Arquitectura
- **Decisión:** Supervisor de logística solo ve conversaciones de ese Worker. Aislamiento natural.
- **Conversación origen:** Decisiones arquitectura AI Workers.

### [ADR-043] UI de conversaciones agrupada por operador, tabs por Worker

- **Fecha:** 2026-04-16
- **Estado:** Vigente
- **Área:** UX
- **Decisión:** Supervisor piensa en personas, no en números. Tab por canal con color del Worker y botón "Intervenir".
- **Conversación origen:** Decisiones arquitectura AI Workers.

### [ADR-044] Catálogo global de Workers gestionado por Conectamos

- **Fecha:** 2026-04-16
- **Estado:** Vigente
- **Área:** Producto
- **Decisión:** Tabla `ai_worker_catalog` (gestionada por Conectamos) + `tenant_workers` (contratación). Los tenants no crean Workers, solo los contratan. Catálogo inicial: logística (publicado), ventas (no publicado), cobranza (no publicado).
- **Conversación origen:** Decisiones arquitectura AI Workers.

### [ADR-045] Migración 000002 diferida hasta que haya Workers reales

- **Fecha:** 2026-04-16
- **Estado:** Vigente
- **Área:** BD
- **Contexto:** Sin Workers, el INSERT en `channels` produce 0 filas y el DROP de `wa_phone_number_id`/`wa_waba_id`/`wa_token` en `tenants` eliminaría credenciales reales.
- **Decisión:** No ejecutar la migración de DROP hasta que query de verificación devuelva 0 tenants sin `channels`. Marcado con `TODO 000002` en 5 archivos Python.
- **Conversación origen:** Decisiones arquitectura AI Workers.

### [ADR-046] `channels` soporta multi-canal (whatsapp/telegram/sms)

- **Fecha:** 2026-04-16
- **Estado:** Vigente
- **Área:** Arquitectura
- **Decisión:** Columna `channel_type` + `channel_config JSONB`. `phone_number_id` nullable para canales no-WhatsApp.
- **Conversación origen:** Decisiones arquitectura AI Workers.

### [ADR-047] Desarrollo en fases: pantallas existentes → nuevas → conversaciones

- **Fecha:** 2026-04-16
- **Estado:** Vigente
- **Área:** Producto
- **Decisión:** Evitar inconsistencias tocando conversaciones antes de tener el modelo reflejado en configuración.
- **Conversación origen:** Sesión arquitectura frontend/backend.

### [ADR-048] Cero mocks nuevos — todo consume API real

- **Fecha:** 2026-04-16
- **Estado:** Vigente
- **Área:** Producto
- **Decisión:** Instrucción explícita de Miguel al iniciar la fase de Canales.
- **Conversación origen:** Sesión arquitectura frontend/backend.

### [ADR-049] Catálogo de Workers dentro de Mis Workers como dialog

- **Fecha:** 2026-04-16
- **Estado:** Vigente
- **Área:** UX
- **Decisión:** Dialog "+ Contratar worker" en la pantalla Mis Workers. Pantalla `/catalog` separada descartada.
- **Conversación origen:** Sesión arquitectura frontend/backend.

### [ADR-050] Dashboards para el final

- **Fecha:** 2026-04-16
- **Estado:** Vigente
- **Área:** Producto
- **Decisión:** Esperar maduración de Mis Workers, flujos, conversaciones y vista general antes de construir dashboards.
- **Conversación origen:** Sesión arquitectura frontend/backend.

### [ADR-051] Ítems disabled en sidebar con tooltip "Próximamente"

- **Fecha:** 2026-04-16
- **Estado:** Vigente
- **Área:** UX
- **Decisión:** Opción A (tooltip + cursor forbidden, sin navegación). Pantalla "coming soon" descartada.
- **Conversación origen:** Sesión arquitectura frontend/backend.

### [ADR-052] Editor visual de campos de flujos diferido

- **Fecha:** 2026-04-16
- **Estado:** Vigente
- **Área:** Producto
- **Decisión:** Form builder con tipos, reordenamiento y validaciones es complejo; sesión dedicada posterior.
- **Conversación origen:** Sesión arquitectura frontend/backend.

### [ADR-053] Arquitectura emails "Opción B1"

- **Fecha:** 2026-04-14
- **Estado:** Vigente (supersede uso de `templateId` de Resend)
- **Área:** Emails
- **Contexto:** Resend no tiene API de templates (`POST /emails/templates` devuelve 405).
- **Decisión:** Repo `conectamos-emails` compila templates React Email a HTML estático en `/dist` vía GitHub Actions. Backend carga HTMLs desde `raw.githubusercontent.com`, cachea en memoria, inyecta variables con `str.replace()` sobre placeholders `{{variable}}`.
- **Alternativas consideradas:** Opción A (templates manuales en dashboard Resend), Opción B2 (publicar HTMLs en GitHub Releases).
- **Conversación origen:** Integración emails / Gestión usuarios tenant.

### [ADR-054] Repo `conectamos-emails` hecho público

- **Fecha:** 2026-04-15
- **Estado:** Vigente
- **Área:** Infra
- **Contexto:** `raw.githubusercontent.com` no sirve archivos de repos privados sin auth.
- **Decisión:** Repo público; sin GitHub token en backend.
- **Conversación origen:** Gestión usuarios tenant.

### [ADR-055] Logo de emails como PNG en Supabase Storage

- **Fecha:** 2026-04-15
- **Estado:** Vigente (con fix de dimensiones pendiente)
- **Área:** Emails
- **Contexto:** Gmail bloquea SVGs; GitHub raw bloqueado en clientes de email.
- **Decisión:** PNG en `wa-media/Assets/logo.png`. Queda pendiente ajustar width/height en `<Img>` del layout (se ve estirado).
- **Conversación origen:** Gestión usuarios tenant.

### [ADR-056] SDK oficial `resend` en lugar de `httpx` manual

- **Fecha:** 2026-04-14
- **Estado:** Vigente
- **Área:** Backend
- **Decisión:** `EmailService` usa SDK `resend>=2.0.0`. `iam.py` eliminó `_send_invite_email()` con HTML hardcodeado.
- **Conversación origen:** Integración emails.

### [ADR-057] Flujo de invitación propio con Resend (no Supabase Auth nativo)

- **Fecha:** 2026-04-15
- **Estado:** Vigente
- **Área:** Arquitectura
- **Decisión:** Usar templates propios y control total del flujo.
- **Conversación origen:** Gestión usuarios tenant.

### [ADR-058] Google y Microsoft OAuth fuera de scope inicial

- **Fecha:** 2026-04-15
- **Estado:** Vigente
- **Área:** Producto
- **Decisión:** Priorizar flujo end-to-end propio con Supabase primero.
- **Conversación origen:** Gestión usuarios tenant.

### [ADR-059] `POST /tenants` auto-crea roles y envía invitación al primer admin

- **Fecha:** 2026-04-15
- **Estado:** Vigente
- **Área:** Backend
- **Decisión:** Helper idempotente `_seed_system_roles()` crea admin/supervisor/viewer; luego crea invitación con token y envía `send_bienvenida(url_activacion=...)`. El email de bienvenida incluye `{{urlActivacion}}` con `/activate?token=`.
- **Conversación origen:** Gestión usuarios tenant.

### [ADR-060] Backend consume mensajes/lecturas (no Supabase directo)

- **Fecha:** 2026-04-15
- **Estado:** Vigente (supersede ADR-006)
- **Área:** Arquitectura
- **Decisión:** Migración de Flutter leyendo/escribiendo Supabase directo a endpoints del backend con middleware de autenticación JWT. `read_receipts` migrado a `GET/POST /read-receipts`. `messages_api.dart` migrado a `POST /messages/send`.
- **Conversación origen:** Sesión Apr 13–16 / Gestión usuarios tenant.

### [ADR-061] `POST /iam/password-reset/confirm` recibe `access_token` (JWT), no `token_hash`

- **Fecha:** 2026-04-16
- **Estado:** Vigente
- **Área:** Backend
- **Contexto:** `verify_otp` con `token_hash` fallaba con service_role key.
- **Decisión:** Frontend canjea el recovery token con Supabase SDK (`verifyOTP(tokenHash:)`) y manda el JWT resultante al backend.
- **Conversación origen:** Gestión usuarios tenant.

### [ADR-062] `AuthMiddleware` como `BaseHTTPMiddleware` de Starlette

- **Fecha:** 2026-04-16
- **Estado:** Vigente
- **Área:** Backend
- **Decisión:** Middleware central en vez de `Depends(get_current_user)` por endpoint. Rutas públicas y OPTIONS preflight excluidos para no bloquear CORS.
- **Conversación origen:** Gestión usuarios tenant.

### [ADR-063] `FRONTEND_URL` en Vercel = `https://conectamos-platform-poc.web.app`

- **Fecha:** 2026-04-16
- **Estado:** Vigente
- **Área:** Infra
- **Contexto:** Estaba hardcodeado como `https://poc.web.app` (dominio inexistente) — los links de email llevaban a 404.
- **Decisión:** Variable de entorno en Vercel apuntando al dominio correcto.
- **Conversación origen:** Gestión usuarios tenant.

### [ADR-064] `_windowOpen` como `bool?` (null = cargando)

- **Fecha:** 2026-04-17
- **Estado:** Vigente
- **Área:** Frontend
- **Contexto:** Getter evaluaba `_apiMessages` vacío durante la carga y retornaba `false`, deshabilitando input incorrectamente.
- **Decisión:** Campo `bool?`; input deshabilitado también durante la carga.
- **Conversación origen:** Mejoras pantalla de Mensajes.

### [ADR-065] Scroll automático solo si usuario está en los últimos 100px

- **Fecha:** 2026-04-17
- **Estado:** Vigente
- **Área:** UX
- **Contexto:** Scroll incondicional jalaba al usuario mientras leía historial.
- **Decisión:** Threshold 100px; si está arriba, mostrar badge teal "↓ Nuevo mensaje". Scroll siempre al fondo al enviar.
- **Conversación origen:** Mejoras pantalla de Mensajes.

### [ADR-066] `_sendReadReceipts` en cola secuencial con 50ms de delay

- **Fecha:** 2026-04-17
- **Estado:** Vigente
- **Área:** Frontend
- **Contexto:** Primer emit disparaba 50-100 POSTs simultáneos.
- **Decisión:** Cola secuencial con delay; batch endpoint descartado (no existe en backend).
- **Conversación origen:** Mejoras pantalla de Mensajes.

### [ADR-067] TextField multi-line con Enter/Shift+Enter vía `FocusNode.onKeyEvent`

- **Fecha:** 2026-04-17
- **Estado:** Vigente
- **Área:** Frontend
- **Contexto:** `maxLines > 1` rompe `onSubmitted` en Flutter.
- **Decisión:** `minLines: 1`, `maxLines: 5`; Enter envía, Shift+Enter inserta salto.
- **Conversación origen:** Mejoras pantalla de Mensajes.

### [ADR-068] `_outboundSenderName()` helper + diferenciación visual por `origin`

- **Fecha:** 2026-04-17
- **Estado:** Vigente
- **Área:** Frontend
- **Decisión:** Helper centraliza lógica del nombre del remitente outbound (elimina "Supervisor" hardcoded en 4 lugares). Estilo por `origin`: `human` (verde `#065F46`, sin badge), `ai_worker` (azul `#1e40af` + badge "IA"), `null/otro` (gris `#6B7280` + badge "Sistema").
- **Conversación origen:** Mejoras pantalla de Mensajes.

### [ADR-069] Corregir `from_name` vía DB (no cambiar fallback backend)

- **Fecha:** 2026-04-17
- **Estado:** Vigente
- **Área:** BD
- **Contexto:** Backend ya hacía lookup correcto con `_get_sender_name`; el problema eran `tenant_users.nombre = NULL`.
- **Decisión:** UPDATE directo en Supabase. El cambio propuesto de fallback a "Agente" en `_get_sender_name` se descartó. Sin migration formal.
- **Conversación origen:** Mejoras pantalla de Mensajes.

### [ADR-070] Modelo de asignación Operador→Flujo (reemplaza Operador→Canal)

- **Fecha:** 2026-04-21
- **Estado:** Vigente (cierra ID-005, ID-006)
- **Área:** Backend / Seguridad
- **Decidido por:** Miguel Kohn
- **Contexto:** El modelo `roles`, `permissions`, `role_permissions` existía en BD pero no se consultaba en runtime. Cualquier usuario con token válido podía hacer cualquier request.
- **Decisión:** `requires_permission(module, action)` como `Depends()` en FastAPI. Admin bypasea sin consultar BD. 403 bien formado con `{error, required, message}`. Aplicado en todos los endpoints de todos los routers. Corregidos 4 endpoints que no tenían autenticación: `/iam/invite`, `/iam/users/{id}/role`, `/tenants`, `/supervisor-channel-access`.
- **Alternativas consideradas:** Permisos fijos hardcodeados por rol.
- **Conversación origen:** Sprint de permisos/IAM (2026-04-21).

### [ADR-071] Mensajes de números desconocidos guardados con `unregistered=true`

- **Fecha:** 2026-04-20
- **Estado:** Vigente
- **Área:** Backend / BD
- **Decidido por:** Miguel Kohn
- **Contexto:** Sin operador registrado, el webhook fallaba con FK violation o descartaba el mensaje.
- **Decisión:** Mensajes inbound de números no registrados se insertan en `wa_messages` con `operator_id=null` y `unregistered=true`. No se despachan al Worker.
- **Conversación origen:** Sesión fixes canales y fuentes (2026-04-20).

### [ADR-072] `GET /conversations` agrupa por `chat_id` (no por `operator_id`)

- **Fecha:** 2026-04-20
- **Estado:** Vigente
- **Área:** Backend / Producto
- **Decidido por:** Miguel Kohn
- **Contexto:** Canales de ventas no tienen operador registrado; el agrupador natural es el número externo.
- **Decisión:** `GET /conversations` devuelve una entrada por `chat_id` único, con último mensaje, `window_open` calculado, y metadatos del operador si existe.
- **Conversación origen:** Sesión fixes canales y fuentes (2026-04-20).

### [ADR-073] Webhook reescrito con 4 checks en orden + bifurcación por `worker_type`

- **Fecha:** 2026-04-20
- **Estado:** Vigente
- **Área:** Backend
- **Decidido por:** Miguel Kohn
- **Contexto:** Pipeline caía en casos edge (número sin canal, canal sin worker, worker inactivo).
- **Decisión:** 4 checks secuenciales: (1) resolver canal por `phone_number_id`, (2) resolver tenant, (3) resolver operador, (4) resolver worker. Bifurcación por `worker_type` para canales operativos vs. ventas.
- **Conversación origen:** Webhook reescrito (2026-04-20).

### [ADR-074] Broadcast requiere `channel_id` explícito — no inferido del tenant

- **Fecha:** 2026-04-20
- **Estado:** Vigente
- **Área:** Backend
- **Decidido por:** Miguel Kohn
- **Decisión:** `POST /broadcasts` requiere `channel_id` en el body. Sin inferencia automática del canal "principal".
- **Conversación origen:** Sesión fixes canales y fuentes (2026-04-20).

### [ADR-075] Modelo A de intervención — stop total del Worker

- **Fecha:** 2026-04-20
- **Estado:** Vigente
- **Área:** Producto / Arquitectura
- **Decidido por:** Miguel Kohn
- **Contexto:** Tres modelos considerados (A: stop total, B: coexistencia, C: handoff explícito).
- **Decisión:** Modelo A: `session.status='supervisor'` bloquea dispatch al Worker. Worker retoma al desintervenir. Modelo C documentado para futuro.
- **Alternativas consideradas:** Modelo B (coexistencia), Modelo C (handoff explícito).
- **Conversación origen:** Sesión fixes canales y fuentes (2026-04-20).

### [ADR-076] Sync de templates ocurre al crear canal WhatsApp (no al crear tenant)

- **Fecha:** 2026-04-20
- **Estado:** Vigente (supersede ADR-020)
- **Área:** Backend
- **Decidido por:** Miguel Kohn
- **Contexto:** Al crear tenant no existe canal todavía — sin `phone_number_id` no se puede llamar a Meta.
- **Decisión:** `_do_sync_templates()` se llama desde `POST /channels` y `POST /channels/embedded-signup` al crear canal WhatsApp.
- **Conversación origen:** Sesión fixes canales y fuentes (2026-04-20).

### [ADR-077] `channel_config JSONB` como fuente única de credenciales de canal

- **Fecha:** 2026-04-17
- **Estado:** Vigente
- **Área:** Arquitectura / BD
- **Decidido por:** Miguel Kohn
- **Contexto:** Credenciales fragmentadas entre `tenants` (legacy) y `channels`. Inconsistencia en qué campo leer.
- **Decisión:** `channel_config JSONB` con estructura `{channel_type, credentials{...}, capabilities[]}`. `get_channel_credentials()` es el único acceso.
- **Conversación origen:** Refactor credenciales WA (2026-04-17).

### [ADR-078] ENV vars WA eliminadas de Vercel — solo `WHATSAPP_VERIFY_TOKEN` permanece

- **Fecha:** 2026-04-17
- **Estado:** Vigente
- **Área:** Infra / Seguridad
- **Decidido por:** Miguel Kohn
- **Contexto:** `WHATSAPP_ACCESS_TOKEN`, `WHATSAPP_PHONE_NUMBER_ID`, `WHATSAPP_WABA_ID` eliminadas. Solo `WHATSAPP_VERIFY_TOKEN` permanece para la verificación del webhook de Meta.
- **Conversación origen:** Refactor credenciales WA (2026-04-17).

### [ADR-079] `_resolve_wa_credentials()` con fallback legacy para migration 000002

- **Fecha:** 2026-04-17
- **Estado:** Vigente hasta ejecutar migration 000002
- **Área:** Backend
- **Decidido por:** Miguel Kohn
- **Contexto:** Durante la transición, algunos tenants pueden no tener canal con credenciales.
- **Decisión:** `_resolve_wa_credentials(svc, tenant_id)` intenta `channels` primero, fallback a columnas legacy en `tenants`. Marcado `TODO 000002`.
- **Conversación origen:** Refactor credenciales WA (2026-04-17).

### [ADR-080] Broadcast con canal único requerido

- **Fecha:** 2026-04-17
- **Estado:** Vigente
- **Área:** Backend / Producto
- **Decidido por:** Miguel Kohn
- **Decisión:** Un broadcast solo puede ejecutarse sobre un canal específico. No hay broadcast multicanal implícito.
- **Conversación origen:** Refactor credenciales WA (2026-04-17).

### [ADR-081] `channel_id` requerido en todos los envíos de mensajes

- **Fecha:** 2026-04-17
- **Estado:** Vigente
- **Área:** Backend
- **Decidido por:** Miguel Kohn
- **Decisión:** `POST /messages/send` requiere `channel_id` en el body. Sin inferencia automática.
- **Conversación origen:** Refactor credenciales WA (2026-04-17).

### [ADR-082] `_mask_channel_token()` en todas las respuestas de canales

- **Fecha:** 2026-04-20
- **Estado:** Vigente
- **Área:** Backend / Seguridad
- **Decidido por:** Miguel Kohn
- **Decisión:** `access_token` reemplazado con `"••••••••"` en todas las respuestas de `GET /channels`. El token nunca se devuelve en claro.
- **Conversación origen:** Sesión fixes canales y fuentes (2026-04-20).

### [ADR-083] Embedded Signup deshabilitado hasta certificación Tech Provider

- **Fecha:** 2026-04-20
- **Estado:** Superseded por ADR-109
- **Área:** Producto / Infra
- **Decidido por:** Miguel Kohn
- **Decisión:** Badge "Requiere certificación" en UI. Funcionalidad presente pero no accesible.
- **Conversación origen:** Sesión fixes canales y fuentes (2026-04-20).

### [ADR-084] `backfill-telegram-usernames` como endpoint de mantenimiento

- **Fecha:** 2026-04-21
- **Estado:** Vigente
- **Área:** Backend
- **Decidido por:** Miguel Kohn
- **Decisión:** `POST /channels/backfill-telegram-usernames` itera canales Telegram sin `bot_username` y llama `getMe` para resolverlo. Idempotente.
- **Conversación origen:** Sprint Telegram (2026-04-21).

### [ADR-085] Paleta de color configurable por canal

- **Fecha:** 2026-04-18
- **Estado:** Vigente
- **Área:** BD / UX
- **Decidido por:** Miguel Kohn
- **Decisión:** Columna `color` en `channels` almacena hex string. Usado para identificar visualmente el canal en tabs de conversaciones.
- **Conversación origen:** Sesión canales (2026-04-18).

### [ADR-086] `tenant_workers` como instancia de contratación con config por tenant

- **Fecha:** 2026-04-18
- **Estado:** Vigente
- **Área:** BD / Arquitectura
- **Decidido por:** Miguel Kohn
- **Decisión:** `tenant_workers` es la instancia de un Worker del catálogo contratado por un tenant. Permite config diferente por tenant (nombre visible, webhook override, etc.).
- **Conversación origen:** Sesión canales / Workers (2026-04-18).

### [ADR-087] `sort_order` en `flow_definitions` para prioridad de flows

- **Fecha:** 2026-04-20
- **Estado:** Vigente
- **Área:** BD / Backend
- **Decidido por:** Miguel Kohn
- **Decisión:** Columna `sort_order` controla qué flow se asigna primero cuando hay múltiples opciones. Editable en UI.
- **Conversación origen:** Sesión fixes canales (2026-04-20).

### [ADR-088] Bifurcación del pipeline por `worker_type`: operativo vs. ventas

- **Fecha:** 2026-04-20
- **Estado:** Vigente
- **Área:** Backend / Arquitectura
- **Decidido por:** Miguel Kohn
- **Contexto:** Canales operativos validan operador; canales de ventas aceptan cualquier número.
- **Decisión:** `worker_type in (logistics, collections)` → canal operativo (valida `operator_id`). `worker_type in (sales, custom)` → canal de ventas (acepta número libre, `operator_id=null`).
- **Conversación origen:** Webhook reescrito (2026-04-20).

### [ADR-089] Operador `inactive` no se reactiva automáticamente al recibir mensaje

- **Fecha:** 2026-04-20
- **Estado:** Vigente
- **Área:** Backend / Producto
- **Decidido por:** Miguel Kohn
- **Decisión:** Si el operador tiene `status='inactive'`, el webhook loguea warning y no cambia el status. Reactivación solo manual.
- **Conversación origen:** Sesión fixes canales (2026-04-20).

### [ADR-090] `GET /conversations` reescrito por `chat_id` con join a operadores

- **Fecha:** 2026-04-20
- **Estado:** Vigente
- **Área:** Backend
- **Decidido por:** Miguel Kohn
- **Decisión:** Query agrupa `wa_messages` por `chat_id` y hace LEFT JOIN a `operators` para enriquecer con nombre, foto, status.
- **Conversación origen:** Restructura de pantalla de conversaciones (2026-04-20).

### [ADR-091] `chat_id` como llave natural universal de conversación

- **Fecha:** 2026-04-20
- **Estado:** Vigente
- **Área:** Arquitectura / Producto
- **Decidido por:** Miguel Kohn
- **Decisión:** `chat_id` (número en E.164) es el agrupador universal. Funciona para canales operativos (hay operador) y de ventas (no hay operador).
- **Conversación origen:** Restructura de pantalla de conversaciones (2026-04-20).

### [ADR-092] `supervisor_channel_access` controla visibilidad de canales por usuario

- **Fecha:** 2026-04-20
- **Estado:** Vigente
- **Área:** BD / Backend / Seguridad
- **Decidido por:** Miguel Kohn
- **Contexto:** Supervisor de logística no debe ver canales de ventas del mismo tenant.
- **Decisión:** Tabla `supervisor_channel_access` + endpoints `GET/POST/DELETE`. Admin tiene bypass total. Gestionable en Ajustes → Usuarios.
- **Conversación origen:** Sesión fixes canales (2026-04-20).

### [ADR-093] Pantalla de conversaciones restructurada con tabs por canal

- **Fecha:** 2026-04-20
- **Estado:** Vigente
- **Área:** Frontend / UX
- **Decidido por:** Miguel Kohn
- **Decisión:** Tab por canal con color del worker. Tab "Feed global" separado. Sin mezcla de canales en una sola vista.
- **Conversación origen:** Restructura de pantalla de conversaciones (2026-04-20).

### [ADR-094] `operator_flows` filtrado por `tenant_worker_id` en conversaciones

- **Fecha:** 2026-04-20
- **Estado:** Vigente
- **Área:** Backend
- **Decidido por:** Miguel Kohn
- **Decisión:** Al buscar flujo activo para un operador en conversaciones, se filtra `operator_flows` por el `tenant_worker_id` del canal activo.
- **Conversación origen:** Sesión fixes canales (2026-04-20).

### [ADR-095] `visible_to_all` en `ai_worker_catalog` — control de visibilidad del catálogo

- **Fecha:** 2026-04-20
- **Estado:** Vigente [REVISAR CON EQUIPO — `worker_catalog_tenant_visibility` puede no existir en prod]
- **Área:** BD / Backend
- **Decidido por:** Miguel Kohn
- **Decisión:** Flag `visible_to_all` en `ai_worker_catalog`. Cuando `false`, solo tenants en `worker_catalog_tenant_visibility` pueden ver el worker. `list_catalog_workers` reescrito para consultar `ai_worker_catalog WHERE is_published=true` directamente (ADR-100).
- **Conversación origen:** Catálogo AI Workers (2026-04-20/21).

### [ADR-096] `smb_message_echoes` requiere certificación Tech Provider

- **Fecha:** 2026-04-20
- **Estado:** Vigente
- **Área:** Producto / Infra
- **Decidido por:** Miguel Kohn
- **Decisión:** La captura de mensajes outbound externos (enviados desde WA Business App) requiere `smb_message_echoes` webhook — disponible solo para Tech Providers o Solution Partners certificados.
- **Conversación origen:** Sesión fixes canales (2026-04-20).

### [ADR-097] `POST /channels/verify-credentials` valida contra Graph API antes de guardar

- **Fecha:** 2026-04-20
- **Estado:** Vigente
- **Área:** Backend / UX
- **Decidido por:** Miguel Kohn
- **Decisión:** Endpoint público que llama `GET /{phone_number_id}` en Graph API con el `access_token` provisto. 422 con mensaje específico si inválido. Obligatorio antes de guardar en BD.
- **Conversación origen:** Onboarding WhatsApp (2026-04-20).

### [ADR-098] Fuentes Onest + Geist como variable fonts `.ttf` en repo Flutter

- **Fecha:** 2026-04-20
- **Estado:** Vigente
- **Área:** Frontend
- **Decidido por:** Miguel Kohn
- **Contexto:** `google_fonts` causaba FOUC y referencias externas en producción. 450 referencias a `'Inter'` reemplazadas.
- **Decisión:** Variable fonts `.ttf` bundleadas. `google_fonts` eliminado del repo.
- **Conversación origen:** Fuentes y DS (2026-04-20).

### [ADR-099] `requires_permission(module, action)` como `Depends()` en todos los endpoints

- **Fecha:** 2026-04-21
- **Estado:** Vigente
- **Área:** Backend / Seguridad
- **Decidido por:** Miguel Kohn
- **Decisión:** Patrón centralizado de permisos. Admin bypasea. Non-admin consulta `role_permissions`. 403 con `{error, required, message}`. Commit `6b5c19e`.
- **Conversación origen:** Sprint IAM (2026-04-21).

### [ADR-100] `list_catalog_workers` reescrito sin `worker_catalog_tenant_visibility`

- **Fecha:** 2026-04-21
- **Estado:** Vigente
- **Área:** Backend / BD
- **Decidido por:** Miguel Kohn
- **Contexto:** La tabla `worker_catalog_tenant_visibility` no existe en prod; causaba error 500 en `GET /catalog/workers`.
- **Decisión:** Query directo a `ai_worker_catalog WHERE is_published=true` + LEFT JOIN lógico sobre `tenant_workers` para campo `already_hired`. Sin dependencia de `worker_catalog_tenant_visibility`.
- **Alternativas consideradas:** Crear la tabla faltante en prod.
- **Conversación origen:** Corrección endpoint catálogo AI Workers (2026-04-21).

### [ADR-101] Worker logística renombrado a "Worker paquetería"; nuevo "Worker transporte"

- **Fecha:** 2026-04-21
- **Estado:** Vigente
- **Área:** Producto / BD
- **Decidido por:** Miguel Kohn
- **Contexto:** Reenfoque del catálogo hacia tipos de operación reales.
- **Decisión:** UPDATE `name = 'Worker paquetería'` (mismo `id`, mismo `worker_type: logistics`). INSERT `Worker transporte` con `is_published: true`, `is_active: true`, 5 skills.
- **Conversación origen:** Corrección endpoint catálogo AI Workers (2026-04-21).

### [ADR-102] `PUT /operators/{id}` gestiona flujos via DELETE+INSERT en `operator_flows`

- **Fecha:** 2026-04-21
- **Estado:** Vigente
- **Área:** Backend
- **Decidido por:** Miguel Kohn
- **Contexto:** El endpoint escribía en columna array legacy `operators.flows`, ignorando la tabla canónica `operator_flows`.
- **Decisión:** `PUT /operators/{id}` hace DELETE+INSERT en `operator_flows`. `POST /operators` también inserta en `operator_flows`. La columna legacy `operators.flows` fue eliminada via DROP COLUMN (migration `20260422000000`).
- **Conversación origen:** Auditoría pantalla de operadores (2026-04-21).

### [ADR-103] `telegram_chat_id` en `operators.metadata` JSONB; lookup por metadata, no por phone

- **Fecha:** 2026-04-21
- **Estado:** Vigente
- **Área:** BD / Backend
- **Decidido por:** Miguel Kohn
- **Contexto:** El `chat_id` de Telegram no es número de teléfono; el lookup por `phone = chat_id` era incorrecto.
- **Decisión:** `telegram_chat_id` persiste en `operators.metadata` via merge JSONB. Lookup de operador en canal Telegram usa `metadata->>'telegram_chat_id' = chat_id`.
- **Conversación origen:** Sprint Telegram (2026-04-21).

### [ADR-104] 1 bot de Telegram por canal, gestionado por el tenant via BotFather

- **Fecha:** 2026-04-21
- **Estado:** Vigente
- **Área:** Arquitectura / Producto
- **Decidido por:** Miguel Kohn
- **Decisión:** Cada tenant crea su propio bot de Telegram vía BotFather. 1 bot = 1 canal = 1 tenant. Conectamos no opera bots compartidos.
- **Alternativas consideradas:** Bot único compartido por Conectamos.
- **Conversación origen:** Sprint Telegram (2026-04-21).

### [ADR-105] `setWebhook` con await directo en Vercel, nunca `asyncio.create_task`

- **Fecha:** 2026-04-21
- **Estado:** Vigente
- **Área:** Backend / Infra
- **Decidido por:** Miguel Kohn
- **Contexto:** Vercel serverless cancela `asyncio.create_task` antes de ejecutarse — confirmado en producción.
- **Decisión:** `_register_telegram_webhook()` con `await` directo al crear canal Telegram. `BACKEND_URL` como variable de entorno en Vercel.
- **Conversación origen:** Sprint Telegram (2026-04-21).

### [ADR-106] Vinculación Telegram via token UUID con expiración 72h y deep link

- **Fecha:** 2026-04-21
- **Estado:** Vigente
- **Área:** Arquitectura / Producto
- **Decidido por:** Miguel Kohn
- **Decisión:** Token único con expiración 72h en `telegram_linking_tokens`. Deep link `t.me/{bot_username}?start={TOKEN}`. Al recibir `/start TOKEN`, el webhook valida y persiste `telegram_chat_id` en `operators.metadata`.
- **Conversación origen:** Sprint Telegram (2026-04-21).

### [ADR-107] SMS vía Twilio solo para onboarding Telegram; canal SMS operativo diferido

- **Fecha:** 2026-04-21
- **Estado:** Vigente
- **Área:** Producto / Infra
- **Decidido por:** Miguel Kohn
- **Decisión:** Twilio integrado solo para enviar SMS de onboarding con deep link. Canal SMS operativo completo diferido (ID-050). ENV vars: `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_FROM_NUMBER=+15075547835`.
- **Conversación origen:** Sprint Telegram (2026-04-21).

### [ADR-108] Broadcast Telegram: texto libre sin templates, destinatarios por `telegram_chat_id`

- **Fecha:** 2026-04-21
- **Estado:** Vigente
- **Área:** Producto / Backend
- **Decidido por:** Miguel Kohn
- **Decisión:** Broadcast Telegram sin `template_id`. Destinatarios filtrados por `telegram_chat_id` en `operators.metadata`. `status='failed'` para operadores sin vincular.
- **Conversación origen:** Sprint Telegram (2026-04-21).

### [ADR-109] Embedded Signup activado en modo Development para obtener certificación Tech Provider

- **Fecha:** 2026-04-21
- **Estado:** Vigente (supersede ADR-083)
- **Área:** Producto / Infra
- **Decidido por:** Miguel Kohn
- **Decisión:** Badge "Requiere certificación" eliminado. Flujo activo con `configuration_id: 2145617199565998`, `response_type: 'code'`, `override_default_response_type: true`. Canal creado con `signup_source='embedded_signup'`.
- **Conversación origen:** Sprint Embedded Signup Meta (2026-04-21).

### [ADR-110] `configuration_id` activo es `2145617199565998` (variación WhatsApp onboarding)

- **Fecha:** 2026-04-21
- **Estado:** Vigente
- **Área:** Infra / Frontend
- **Decidido por:** Miguel Kohn
- **Decisión:** `configuration_id = 2145617199565998` ("Configuración de registro insertado en WhatsApp con token de caducidad de 60").
- **Alternativas consideradas:** `1290590206469350` con variación General.
- **Conversación origen:** Sprint Embedded Signup Meta (2026-04-21).

### [ADR-111] Exchange de `code` → `access_token` usa POST a `/oauth/access_token` con form data

- **Fecha:** 2026-04-21
- **Estado:** Vigente
- **Área:** Backend
- **Decidido por:** Miguel Kohn
- **Decisión:** `POST /v19.0/oauth/access_token` con form data. Embedded Signup v2 con `response_type: 'code'` requiere POST, no GET.
- **Conversación origen:** Sprint Embedded Signup Meta (2026-04-21).

### [ADR-112] `override_default_response_type: true` en `FB.login()`

- **Fecha:** 2026-04-21
- **Estado:** Vigente
- **Área:** Frontend
- **Decidido por:** Miguel Kohn
- **Decisión:** Parámetro obligatorio en `FB.login()`. Sin él Meta ignora el `response_type: 'code'` del `config_id`.
- **Conversación origen:** Sprint Embedded Signup Meta (2026-04-21).

### [ADR-113] Flag `_embeddedSignupInProgress` para evitar doble llamada al endpoint

- **Fecha:** 2026-04-21
- **Estado:** Vigente
- **Área:** Frontend
- **Decidido por:** Miguel Kohn
- **Decisión:** Flag booleano que previene que el callback `onCode` doble dispare el endpoint dos veces.
- **Conversación origen:** Sprint Embedded Signup Meta (2026-04-21).

### [ADR-114] Permisos dinámicos por tenant para roles supervisor y viewer; admin inmutable <!-- ACTUALIZADO: marcado como implementado 2026-05-05 en documento original -->

- **Fecha:** 2026-04-21
- **Estado:** Vigente — implementado 2026-05-05 (`super_admin` bypass via `_is_super_admin()`, commit 093af4c)
- **Área:** Producto / Backend
- **Decidido por:** Miguel Kohn
- **Decisión:** `GET/PATCH /iam/roles/{role_id}/permissions` permite modificar permisos de supervisor y viewer por tenant. Admin siempre tiene todos los permisos (inmutable en backend). `super_admin` bypass total vía `app_metadata.role == "super_admin"`.
- **Conversación origen:** Sprint IAM (2026-04-21). Implementado en auditoría tenant isolation (2026-05-05).

### [ADR-115] Grafo de prerequisitos de permisos en backend (validación) y frontend (cascada visual)

- **Fecha:** 2026-04-21
- **Estado:** Vigente
- **Área:** Backend / Frontend
- **Decidido por:** Miguel Kohn
- **Decisión:** Prerequisitos manejados en backend (validación al PATCH) y en frontend (`role_permissions_panel.dart` con cascada visual + SnackBar explicativo).
- **Conversación origen:** Sprint IAM (2026-04-21).

### [ADR-116] `currentUserProvider` observa `authStateProvider` para invalidarse en `signedIn`

- **Fecha:** 2026-04-21
- **Estado:** Vigente
- **Área:** Frontend
- **Decidido por:** Miguel Kohn
- **Decisión:** `currentUserProvider` observa `authStateProvider`. `hasPermission` usa `ref.watch` (no `ref.read`) para suscribirse y reconstruirse cuando cargan los permisos.
- **Conversación origen:** Sprint IAM (2026-04-21).

### [ADR-117] Onboarding WhatsApp: flujo obligatorio verify → activate → save

- **Fecha:** 2026-04-21
- **Estado:** Vigente
- **Área:** Backend / UX
- **Decidido por:** Miguel Kohn
- **Decisión:** `POST /channels/activate-whatsapp` (público, sin JWT) ejecuta `/{waba_id}/subscribed_apps` y `/{phone_number_id}/register`. Obligatorio entre `verify-credentials` y guardado en BD. Idempotente.
- **Conversación origen:** Onboarding WhatsApp (2026-04-21).

### [ADR-118] UI de campos de operador (ID-042) vive en Ajustes del tenant como subsección

- **Fecha:** 2026-04-21
- **Estado:** Vigente
- **Área:** UX / Producto
- **Decidido por:** Miguel Kohn
- **Decisión:** La UI de `operator_field_definitions` vive como subsección del submenú de Ajustes. Complementada por ADR-137.
- **Conversación origen:** Auditoría pantalla de operadores (2026-04-21).

### [ADR-119] `resend-invite` actualiza fila existente en `invitations`, no crea nueva

- **Fecha:** 2026-04-22
- **Estado:** Vigente
- **Área:** Backend
- **Decidido por:** Miguel Kohn
- **Decisión:** `POST /iam/users/{user_id}/resend-invite` hace UPDATE de `token + expires_at` en la fila existente. El `user_id` del path es `invitation.id` para usuarios con `_is_invitation: true`.
- **Conversación origen:** Auditoría emails + fix reenvío invitaciones (2026-04-22).

### [ADR-120] Bloqueo de envío broadcast en texto libre + WhatsApp con ventanas cerradas

- **Fecha:** 2026-04-24
- **Estado:** Vigente
- **Área:** Producto / Frontend
- **Decidido por:** Miguel Kohn
- **Decisión:** El botón "Confirmar envío" se bloquea (no solo advierte) cuando hay ≥1 destinatario seleccionado con `window_open=false` en modo texto libre + canal WhatsApp.
- **Conversación origen:** Fixes de Broadcast (2026-04-24).

### [ADR-121] `window_open = true` siempre para canales no-WhatsApp

- **Fecha:** 2026-04-24
- **Estado:** Vigente
- **Área:** Frontend / Producto
- **Decidido por:** Miguel Kohn
- **Decisión:** Para Telegram, SMS y otros canales no-WhatsApp, `window_open = true` siempre — no se calcula ni se muestra chip de ventana.
- **Conversación origen:** Fixes de Broadcast (2026-04-24).

### [ADR-122] `GET /operators` enriquecido con `profile_picture_url` y `last_inbound_at`

- **Fecha:** 2026-04-24
- **Estado:** Vigente
- **Área:** Backend
- **Decidido por:** Miguel Kohn
- **Decisión:** `GET /operators` incluye `profile_picture_url` y `last_inbound_at` (MAX received_at de wa_messages inbound para ese operador, 1 query por tenant, merge en Python).
- **Conversación origen:** Fixes de Broadcast (2026-04-24).

### [ADR-123] Flujo de vinculación Telegram: vincular antes de guardar flujos (Opción B)

- **Fecha:** 2026-04-22
- **Estado:** Vigente
- **Área:** UX / Producto
- **Decidido por:** Miguel Kohn
- **Decisión:** El modal de vinculación permite enviar la invitación antes de guardar los flujos. Sin bloquear el guardado.
- **Alternativas consideradas:** Opción A (guardar primero), Opción C (flujos Telegram en estado pendiente).
- **Conversación origen:** Pendientes Telegram (2026-04-22).

### [ADR-124] `telegram_link_status` y `telegram_link_expires_at` en `operators.metadata`

- **Fecha:** 2026-04-22
- **Estado:** Vigente
- **Área:** BD / Frontend
- **Decidido por:** Miguel Kohn
- **Decisión:** `telegram_link_status` en `operators.metadata` con valores `none | pending | linked`. `telegram_link_expires_at` como ISO8601. La fuente de verdad para UI es metadata, no `telegram_linking_tokens`.
- **Conversación origen:** Pendientes Telegram (2026-04-22).

### [ADR-125] `telegram_chat_id` se guarda como `string` en `operators.metadata`

- **Fecha:** 2026-04-22
- **Estado:** Vigente
- **Área:** Backend
- **Decidido por:** Miguel Kohn
- **Decisión:** `telegram_chat_id` guardado con `str()` en el webhook de vinculación para evitar crash en Flutter al hacer `as String?` sobre un `int`.
- **Conversación origen:** Pendientes Telegram (2026-04-22).

### [ADR-126] `media_service.py` genérico compartido entre WhatsApp y Telegram

- **Fecha:** 2026-04-22
- **Estado:** Vigente
- **Área:** Backend / Arquitectura
- **Decidido por:** Miguel Kohn
- **Decisión:** `media_service.py` genérico para descarga de binario y upload a Supabase Storage. `telegram_media.py` resuelve `file_id → URL` via `getFile`. Compartido entre canales.
- **Conversación origen:** Pendientes Telegram (2026-04-22).

### [ADR-127] Modelo de reacciones unificado — fila nueva con `message_type='reaction'`

- **Fecha:** 2026-04-22
- **Estado:** Vigente
- **Área:** Backend / Arquitectura
- **Decidido por:** Miguel Kohn
- **Decisión:** Reacciones = fila nueva con `message_type='reaction'` en `wa_messages`. Para WhatsApp y Telegram. JSONB `reactions` columna en BD está deprecado (nadie escribe ni lee).
- **Conversación origen:** Pendientes Telegram (2026-04-22).

### [ADR-128] `context_message_id` (TEXT) como campo canónico para replies; `reply_to_message_id` (UUID FK) deprecado

- **Fecha:** 2026-04-22
- **Estado:** Vigente
- **Área:** BD / Backend
- **Decidido por:** Miguel Kohn
- **Decisión:** `context_message_id TEXT` es el campo canónico para replies. `reply_to_message_id` renombrada a `_deprecated_reply_to_message_id`.
- **Conversación origen:** Pendientes Telegram (2026-04-22).

### [ADR-129] `allowed_updates` en `setWebhook` de Telegram debe incluir `message_reaction`

- **Fecha:** 2026-04-22
- **Estado:** Vigente
- **Área:** Backend / Infra
- **Decidido por:** Miguel Kohn
- **Decisión:** `allowed_updates` en `setWebhook` incluye `message_reaction` explícitamente.
- **Conversación origen:** Pendientes Telegram (2026-04-22).

### [ADR-130] Normalización de teléfono en E.164; transformación +521 solo para WhatsApp Cloud API al enviar

- **Fecha:** 2026-04-23
- **Estado:** Vigente
- **Área:** Backend / BD
- **Decidido por:** Miguel Kohn
- **Decisión:** `phone` en BD siempre en E.164 (`+52XXXXXXXXXX`). La transformación `+521` se hace en `phone_normalizer.py` solo al momento de enviar a WhatsApp Cloud API.
- **Conversación origen:** Sprint Operadores (2026-04-23).

### [ADR-131] `phone_secondary[]` en `operators.metadata` JSONB con estructura `{label, number, channel}`

- **Fecha:** 2026-04-23
- **Estado:** Vigente
- **Área:** BD / Producto
- **Decidido por:** Miguel Kohn
- **Decisión:** Teléfonos secundarios en `operators.metadata.phone_secondary` como array de `{label, number, channel}`. `phone_telegram` eliminado del modelo.
- **Conversación origen:** Sprint Operadores (2026-04-23).

### [ADR-132] Soft delete con `status='deleted'` para operadores

- **Fecha:** 2026-04-23
- **Estado:** Vigente
- **Área:** Backend / BD
- **Decidido por:** Miguel Kohn
- **Decisión:** `DELETE /operators/{id}` hace soft delete — `status='deleted'`. 405 en PATCH con `status='deleted'`. `include_deleted` como query param en GET. Hard delete solo administrativo.
- **Conversación origen:** Sprint Operadores (2026-04-23).

### [ADR-133] `nationality` deriva `identity_type` automáticamente via mapeo en código

- **Fecha:** 2026-04-23
- **Estado:** Vigente
- **Área:** Backend / Frontend
- **Decidido por:** Miguel Kohn
- **Decisión:** `nationality` (ISO 3166-1 alpha-2) determina `identity_type` automáticamente. Mapeo en `identity_config.dart` (frontend) e `identity_validator.py` (backend). Solo MX activo.
- **Conversación origen:** Sprint Operadores (2026-04-23).

### [ADR-134] Import de operadores con plantilla dinámica por país y estrategias `all_or_nothing`/`skip_errors`

- **Fecha:** 2026-04-23
- **Estado:** Vigente
- **Área:** Backend / Producto
- **Decidido por:** Miguel Kohn
- **Decisión:** Import vía `operator_import_service.py`. Export vía `operator_export_service.py` con config en `tenants.operator_export_config JSONB`. Plantilla dinámica por país.
- **Conversación origen:** Sprint Operadores (2026-04-23).

### [ADR-135] `RESERVED_METADATA_KEYS` — claves reservadas en `operators.metadata`

- **Fecha:** 2026-04-23
- **Estado:** Vigente
- **Área:** Backend
- **Decidido por:** Miguel Kohn
- **Decisión:** `RESERVED_METADATA_KEYS = {telegram_chat_id, telegram_link_status, telegram_link_expires_at, phone_secondary}`. El backend rechaza estas claves en `operator_field_definitions`.
- **Conversación origen:** Sprint Operadores (2026-04-23).

### [ADR-136] Sistema de lectura de conversaciones basado en `panel_read_at` en `wa_messages`

- **Fecha:** 2026-04-23
- **Estado:** Vigente (supersede ADR-007)
- **Área:** Frontend / BD
- **Decidido por:** Miguel Kohn
- **Decisión:** `panel_read_at` (columna en `wa_messages`) como base del sistema de no-leídos persistente. `channelUnreadProvider` mantiene conteo por `channel_id` para todos los canales simultáneamente.
- **Conversación origen:** Refactor conversaciones (2026-04-23).

### [ADR-137] UI de campos de operador integrada inline en `_SectionPanel` de Ajustes, no como ruta separada

- **Fecha:** 2026-04-23
- **Estado:** Vigente (complementa ADR-118)
- **Área:** Frontend / UX
- **Decidido por:** Miguel Kohn
- **Decisión:** `operator_fields_screen.dart` integrado como sección inline dentro del `_SectionPanel` de Ajustes. Label en sidebar: "Operador". Sin ruta `/settings/operator-fields` separada.
- **Conversación origen:** Sprint Operadores (2026-04-23).

### [ADR-138] Normalizador `ChannelMessage`: objeto estándar antes del pipeline

- **Fecha:** 2026-04-24
- **Estado:** Pendiente de implementación — asignado a Santiago
- **Área:** Arquitectura / Backend
- **Decidido por:** Miguel Kohn
- **Decisión:** Todo mensaje entrante se convierte a un objeto `ChannelMessage` estándar antes de llegar al pipeline. Adaptadores por canal producen este objeto.
- **Conversación origen:** Diagnóstico arquitectura + escalaciones (2026-04-24).

### [ADR-139] La unidad de conversación es el operador, no el canal

- **Fecha:** 2026-04-24
- **Estado:** Migration aplicada — lógica de pipeline pendiente (Santiago)
- **Área:** Arquitectura / Producto
- **Decidido por:** Miguel Kohn
- **Decisión:** `active_channel_id` en `flow_executions` registra el canal activo actual. Se actualiza si el operador migra de canal durante un flujo activo.
- **Conversación origen:** Diagnóstico arquitectura + escalaciones (2026-04-24).

### [ADR-140] Contrato de datos fijo con el AI Worker (envelope)

- **Fecha:** 2026-04-24
- **Estado:** Implementado en `ai_router.py`
- **Área:** Arquitectura / Backend
- **Decidido por:** Miguel Kohn
- **Decisión:** El payload al Worker incluye `mensaje`, `historial` (últimos 20), `flujo`, `campos_actuales`, `ejecucion_id`. Sin flujo activo: `flujo=null`, `campos_actuales={}`.
- **Conversación origen:** Diagnóstico arquitectura (2026-04-24).

### [ADR-141] Resiliencia con `is_processed`, `processed_at`, `parse_error` en `wa_messages`

- **Fecha:** 2026-04-24
- **Estado:** Columnas existentes. `is_processed=True` actualizado post-INSERT usando `routing_request_id`. Lógica de retry pendiente.
- **Área:** Backend / BD
- **Decidido por:** Miguel Kohn
- **Decisión:** `is_processed` actualizado después del INSERT usando `routing_request_id` como clave (fix de race condition con `wa_message_id`).
- **Conversación origen:** Diagnóstico arquitectura (2026-04-24).

### [ADR-142] `flow_field_values` y `flow_events` como fuente de verdad persistente

- **Fecha:** 2026-04-24
- **Estado:** Implementado — commit c046cd5 (2026-04-26)
- **Área:** Backend / BD
- **Decidido por:** Miguel Kohn
- **Decisión:** `_save_field_values()` hace UPSERT en `flow_field_values` por campo. `_save_flow_event()` registra hitos en `flow_events`. Se llaman desde todos los handlers de `/ai-worker/events`.
- **Conversación origen:** Diagnóstico arquitectura (2026-04-24).

### [ADR-143] Tabla `escalations` separada de `flow_executions`

- **Fecha:** 2026-04-24
- **Estado:** Vigente — migration aplicada, endpoints implementados
- **Área:** Arquitectura / BD
- **Decidido por:** Miguel Kohn
- **Decisión:** Tabla `escalations` separada. `checkpoint_incomplete` en `/ai-worker/events` crea el ticket. `PATCH /escalations/{id}` soporta `assign/resolve/reopen`. Callback al worker al resolver. Migrations 30 y 31.
- **Conversación origen:** Diagnóstico arquitectura + escalaciones (2026-04-24).

### [ADR-144] Intervención tripartita sin endpoint de estado

- **Fecha:** 2026-04-24
- **Estado:** Pendiente de implementación — asignado a Santiago
- **Área:** Arquitectura / Producto
- **Decidido por:** Miguel Kohn
- **Decisión:** Supervisor y AI Worker coexisten en la conversación. Flag de intervención vive en el frontend. Escalación formal usa tabla `escalations`.
- **Conversación origen:** Diagnóstico arquitectura + escalaciones (2026-04-24).

### [ADR-145] Protocolo Plataforma ↔ Worker: envelope estructurado + acciones declarativas

- **Fecha:** 2026-04-26
- **Estado:** Vigente (parcialmente supersede ADR-039)
- **Área:** Arquitectura / Backend
- **Decidido por:** Miguel Kohn
- **Decisión:** El envelope incluye `message` (o `trigger`), `operator`, `session`, `active_flows`, `assigned_flows`. El Worker responde con acciones declarativas tipadas: `open_flow`, `close_flow`, `set_field_value`, `escalate`.
- **Conversación origen:** Protocolo Plataforma ↔ AI Worker (2026-04-26).

### [ADR-146] Acciones inválidas del Worker retornan HTTP 422 con `failed_actions`; reply se envía igual

- **Fecha:** 2026-04-26
- **Estado:** Vigente
- **Área:** Backend / Producto
- **Decidido por:** Miguel Kohn
- **Decisión:** Acciones inválidas → 422 con `{error, failed_actions: [{action, reason}]}`. El reply al operador se envía aunque haya acciones fallidas.
- **Conversación origen:** Protocolo Plataforma ↔ AI Worker (2026-04-26).

### [ADR-147] El Worker puede iniciar conversaciones proactivas vía `POST /worker/trigger`

- **Fecha:** 2026-04-26
- **Estado:** Propuesto — sin implementar. Bloqueado por decisión de autenticación.
- **Área:** Backend / Producto
- **Decidido por:** Miguel Kohn
- **Decisión:** Endpoint `POST /worker/trigger`. Autenticación pendiente (opción A: API key por `tenant_worker`; B: JWT; C: shared secret).
- **Conversación origen:** Protocolo Plataforma ↔ AI Worker (2026-04-26).

### [ADR-148] Redis del Worker es privado; la plataforma no replica el historial

- **Fecha:** 2026-04-26
- **Estado:** Vigente (reafirma ADR-039)
- **Área:** Arquitectura
- **Decidido por:** Miguel Kohn
- **Decisión:** La plataforma no lee ni replica el historial de Redis del Worker.
- **Conversación origen:** Protocolo Plataforma ↔ AI Worker (2026-04-26).

### [ADR-149] Routing de Workers por `webhook_url` en BD (condicional sobre `AI_ROUTER_URL` global)

- **Fecha:** 2026-04-26
- **Estado:** Superseded por ADR-192
- **Área:** Backend / Arquitectura
- **Decidido por:** Miguel Kohn
- **Decisión:** Si `webhook_url` definido → usar esa URL. Si no → fallback a `AI_ROUTER_URL`.
- **Conversación origen:** Integración AI Worker Gustavo (2026-04-26).

### [ADR-150] `event_type` en `/ai-worker/events` es opcional con default `"message"`

- **Fecha:** 2026-04-26
- **Estado:** Vigente
- **Área:** Backend
- **Decidido por:** Miguel Kohn
- **Decisión:** `event_type` es campo opcional con default `"message"`. `event_type: message` envía texto al operador sin crear ni modificar `flow_executions`.
- **Conversación origen:** Integración AI Worker Gustavo (2026-04-26).

### [ADR-151] Bug de aislamiento de tenant corregido: `channel["tenant_id"]` tiene prioridad

- **Fecha:** 2026-04-26
- **Estado:** Vigente
- **Área:** Backend
- **Decidido por:** Miguel Kohn
- **Decisión:** `channel["tenant_id"]` tiene prioridad sobre `default_tenant_id` siempre que el canal esté resuelto. Commit c362e0b.
- **Conversación origen:** Integración AI Worker Gustavo (2026-04-26).

### [ADR-152] Broadcasts escriben en `wa_messages` con `origin='broadcast'` y texto expandido

- **Fecha:** 2026-04-25
- **Estado:** Vigente
- **Área:** Backend / Producto
- **Decidido por:** Miguel Kohn
- **Decisión:** Broadcasts exitosos insertan en `wa_messages` con `origin='broadcast'`, `broadcast_id`, texto expandido (variables resueltas).
- **Conversación origen:** Feed Global — auditoría y fixes (2026-04-25).

### [ADR-153] Arquitectura Flows v2 — pipeline normalizado con ChannelMessage

- **Fecha:** 2026-04-26
- **Estado:** Pendiente de implementación completa
- **Área:** Arquitectura / Backend
- **Decidido por:** Miguel Kohn
- **Decisión:** El pipeline normaliza todos los mensajes entrantes a `ChannelMessage` antes del dispatch al Worker.
- **Conversación origen:** Blueprint Flows V2 — Fase 0 (2026-04-26).

### [ADR-154] pgcrypto para encryption at-rest de HMAC secrets

- **Fecha:** 2026-04-26
- **Estado:** Vigente — migration `20260427000004_enable_pgcrypto.sql` aplicada
- **Área:** Infra / Seguridad
- **Decidido por:** Miguel Kohn
- **Decisión:** AES-256-CBC via pgcrypto para `hmac_secret_encrypted`. Implementado en `crypto_utils.py`. Fallback a texto plano si `PGCRYPTO_KEY` no está definida.
- **Alternativas consideradas:** Supabase Vault.
- **Conversación origen:** Blueprint Flows V2 — Fase 0 (2026-04-26).

### [ADR-165] `conectamos-demo` como sandbox de Fase 0

- **Fecha:** 2026-04-26
- **Estado:** Vigente
- **Área:** Infra / Producto
- **Decidido por:** Miguel Kohn
- **Decisión:** `conectamos-demo` (UUID `4ea0c9d8`) como sandbox de Fase 0. Tenant `conectamos-sandbox` no se crea.
- **Conversación origen:** Blueprint Flows V2 — Fase 0 (2026-04-26).

### [ADR-166] `status='paused'` en `flow_executions` es manual — sin cron de inactividad en Fase 1

- **Fecha:** 2026-04-26
- **Estado:** Vigente (cierra ID-074)
- **Área:** Producto / Backend
- **Decidido por:** Miguel Kohn
- **Decisión:** `status='paused'` solo cambia manualmente vía acción del supervisor. Sin cron automático en Fase 1.
- **Conversación origen:** Blueprint Flows V2 — Fase 0 (2026-04-26).

### [ADR-167] Control completo del supervisor sobre flows activos

- **Fecha:** 2026-04-26
- **Estado:** Vigente
- **Área:** Producto / Frontend
- **Decidido por:** Miguel Kohn
- **Decisión:** El supervisor puede ver, reasignar, abandonar, pausar manualmente y retomar cualquier flow activo.
- **Conversación origen:** Blueprint Flows V2 — Fase 0 (2026-04-26).

### [ADR-168] Dos capas de resolución de flows: plataforma define universo, Worker elige por intención

- **Fecha:** 2026-04-27
- **Estado:** Vigente
- **Área:** Arquitectura / Producto
- **Decidido por:** Miguel Kohn
- **Decisión:** (1) La plataforma define el universo via `operator_flows`. (2) El Worker elige por intención y manda `flow_definition_id` en `checkpoint_started`.
- **Conversación origen:** Blueprint Flows V2 — Fase A (2026-04-27).

### [ADR-169] `event_type=null` o `"none"` válido — backend solo envía mensaje sin tocar BD

- **Fecha:** 2026-04-27
- **Estado:** Vigente
- **Área:** Backend / Contrato Worker
- **Decidido por:** Miguel Kohn
- **Decisión:** `event_type=null` o `"none"` es válido. El backend solo envía el mensaje al operador y no modifica ninguna tabla.
- **Conversación origen:** Blueprint Flows V2 — Fase A (2026-04-27).

### [ADR-170] `data_update` con `event_data: {}` registra `campo_rechazado` sin UPSERT en `flow_field_values`

- **Fecha:** 2026-04-27
- **Estado:** Vigente
- **Área:** Backend / Contrato Worker
- **Decidido por:** Miguel Kohn
- **Decisión:** `data_update` con `event_data: {}` vacío registra evento `campo_rechazado` en `flow_events` sin hacer UPSERT en `flow_field_values`.
- **Conversación origen:** Blueprint Flows V2 — Fase A (2026-04-27).

### [ADR-171] `chat_id` en `wa_messages` debe ser E.164 — normalización inconsistente detectada

- **Fecha:** 2026-04-27
- **Estado:** Vigente [REVISAR CON EQUIPO — fix pendiente]
- **Área:** Backend / BD
- **Decidido por:** Miguel Kohn
- **Decisión:** `chat_id` en `wa_messages` también debe ser E.164. Requiere fix en webhook + backfill.
- **Conversación origen:** Bugs pantalla Conversaciones (2026-04-27).

### [ADR-172] `carry_fields` filtrado por schema del flow hijo antes de persistir

- **Fecha:** 2026-04-27
- **Estado:** Vigente
- **Área:** Backend / Motor de flows
- **Decidido por:** Miguel Kohn
- **Decisión:** `carry_fields` heredados del padre se filtran contra el schema del flow hijo antes del `_save_field_values(..., source="inherited")`.
- **Conversación origen:** Auditoría modelo de datos flows (2026-04-27).

### [ADR-173] `_notas` como field_key reservada universal en cualquier flow

- **Fecha:** 2026-04-27
- **Estado:** Vigente
- **Área:** Producto / Backend
- **Decidido por:** Miguel Kohn
- **Decisión:** `_notas` siempre válido en cualquier flow sin declararse en `flow_definition.fields`. Una sola fila por execution.
- **Conversación origen:** Auditoría modelo de datos flows (2026-04-27).

### [ADR-174] Schema estricto para `flow_field_values` — solo `field_keys` declarados en `flow_definition.fields`

- **Fecha:** 2026-04-27
- **Estado:** Vigente
- **Área:** Backend / Motor de flows
- **Decidido por:** Miguel Kohn
- **Decisión:** Para `source="captured"`, solo field_keys declaradas en `flow_definition.fields` se persisten. Campos inválidos se descartan con `logger.warning`. Excepción: `_notas`. Commit 8d5631d.
- **Conversación origen:** Auditoría modelo de datos flows (2026-04-27).

### [ADR-175] `pending_completion` como status intermedio para executions de `actor_type='system'`

- **Fecha:** 2026-04-27
- **Estado:** Vigente
- **Área:** Backend / Arquitectura
- **Decidido por:** Miguel Kohn
- **Decisión:** Ingest externo crea execution con `status='pending_completion'`. El cron `process_pending_completions` la recoge, aplica optimistic lock, y ejecuta `complete_execution → run_on_complete → chaining`.
- **Alternativas consideradas:** `asyncio.ensure_future` inline (probado y descartado por timeout en Vercel).
- **Conversación origen:** Fase B — Motor Flows v2 E2E (2026-04-27).

### [ADR-176] Vercel Cron Jobs para procesamiento de outbox y pending_completion <!-- ACTUALIZADO: dos cron entries independientes confirmadas en vercel.json -->

- **Fecha:** 2026-04-27
- **Estado:** Vigente
- **Área:** Infra / Backend
- **Decidido por:** Miguel Kohn
- **Contexto:** Ya se tiene todo en Vercel. Supabase Edge Functions añade runtime extra sin ventaja.
- **Decisión:** `vercel.json` con dos entradas cron schedule `* * * * *`: (1) `/api/cron/process-webhook-outbox` que ejecuta tanto `process_outbox` como `process_pending_completions`; (2) `/api/cron/process-pending-completions` como endpoint standalone. Ambas autenticadas con `CRON_SECRET`.
- **Alternativas consideradas:** Supabase Edge Functions con pg_cron.
- **Conversación origen:** Fase B — Motor Flows v2 E2E (2026-04-27).

### [ADR-177] `channel_id` para flow hijo se resuelve internamente por `tenant_worker_id` del flow hijo

- **Fecha:** 2026-04-27
- **Estado:** Vigente
- **Área:** Backend / Motor de flows
- **Decidido por:** Miguel Kohn
- **Decisión:** `resolve_operator_channel()` busca el canal por `tenant_worker_id` del flow hijo. Fallback al primer canal activo del tenant por `created_at`. Complementado por ADR-183 con `preferred_channel_types`.
- **Conversación origen:** Fase B — Motor Flows v2 E2E (2026-04-27).

### [ADR-178] Secrets de integraciones viven en BD (`flow_integrations`), nunca en Vercel env vars

- **Fecha:** 2026-04-27
- **Estado:** Vigente
- **Área:** Infra / Seguridad
- **Decidido por:** Miguel Kohn
- **Decisión:** `api_key_hash` y `hmac_secret_encrypted` en `flow_integrations`. `CRON_SECRET` sí es env var de infraestructura.
- **Conversación origen:** Fase B — Motor Flows v2 E2E (2026-04-27).

### [ADR-179] `idx_flow_executions_unique_active` reemplazado por constraint con `idempotency_key`

- **Fecha:** 2026-04-27
- **Estado:** Vigente
- **Área:** BD / Backend
- **Decidido por:** Miguel Kohn
- **Decisión:** DROP `idx_flow_executions_unique_active` + CREATE `idx_flow_executions_unique_active_idempotency` — UNIQUE `(operator_id, flow_definition_id, idempotency_key)` WHERE `status='active' AND idempotency_key IS NOT NULL`. Migration `20260427000003`.
- **Conversación origen:** Fase B + C — Motor Flows v2 (2026-04-27).

### [ADR-180] Fase C (Contract) ejecutada sin esperar 30 días — sin clientes reales en producción

- **Fecha:** 2026-04-27
- **Estado:** Vigente
- **Área:** Infra / Arquitectura
- **Decidido por:** Miguel Kohn
- **Decisión:** Fase C aplicada el mismo día que Fase B. Columnas `fields_status`, `attempts`, `escalated_at`, `escalated_to` dropeadas de `flow_executions`.
- **Conversación origen:** Fase B + C — Motor Flows v2 (2026-04-27).

### [ADR-181] Editor de flows en pantalla dedicada `/flows/:flowId` con 4 tabs

- **Fecha:** 2026-04-27
- **Estado:** Vigente (cierra ID-003)
- **Área:** Frontend / UX
- **Decidido por:** Miguel Kohn
- **Decisión:** `FlowDetailScreen` en ruta `/flows/:flowId` con 4 tabs: INFO, CAMPOS (drag-to-reorder), COMPORTAMIENTO (editor condiciones mini-DSL), AL CERRAR (editor declarativo `on_complete.actions`).
- **Conversación origen:** Frente C — Frontend Flows v2 (2026-04-27/28).

### [ADR-182] Prohibir `DateFormat` con locale en Flutter Web — usar formato manual

- **Fecha:** 2026-04-27
- **Estado:** Vigente
- **Área:** Frontend
- **Decidido por:** Miguel Kohn
- **Decisión:** Eliminar todos los `DateFormat` con locale del repo. Reemplazar por formato manual con `DateTime`. Elimina `NoSuchMethodError: gam` en release mode.
- **Conversación origen:** Frente C — Frontend Flows v2 (2026-04-27/28).

### [ADR-183] Flag `send_proactive` en `flow_definitions` — controla mensaje proactivo al operador

- **Fecha:** 2026-04-28
- **Estado:** Vigente — migration `20260428000010` aplicada
- **Área:** Backend / Producto
- **Decidido por:** Miguel Kohn
- **Decisión:** ADD COLUMN `send_proactive boolean NOT NULL DEFAULT true` en `flow_definitions`. Toggle en tab COMPORTAMIENTO (visible solo cuando `trigger_sources` contiene 'conversational').
- **Conversación origen:** Sprint 1 — Platform Debug (2026-04-28).

### [ADR-184] Slug de flow derivado del nombre — read-only en UI

- **Fecha:** 2026-04-29
- **Estado:** Vigente
- **Área:** Frontend / Backend
- **Decidido por:** Miguel Kohn
- **Decisión:** Slug generado desde nombre con algoritmo slugify (lowercase, acentos→ASCII, no-alfanuméricos→guiones). Read-only en UI. Colisión → HTTP 409.
- **Conversación origen:** Sprint 2 — Configuración E2E (2026-04-29).

### [ADR-185] `field_key` derivado de etiqueta — read-only, guiones bajos, máx 63 chars

- **Fecha:** 2026-04-29
- **Estado:** Vigente
- **Área:** Frontend / Backend
- **Decidido por:** Miguel Kohn
- **Decisión:** `field_key` derivado de la etiqueta con slugify de guiones bajos. Read-only en UI. Límite 63 chars (límite de identificadores en PostgreSQL).
- **Conversación origen:** Sprint 2 — Configuración E2E (2026-04-29).

### [ADR-186] Selector flujo destino en AL CERRAR limitado al mismo `tenant_worker_id`

- **Fecha:** 2026-04-29
- **Estado:** Vigente
- **Área:** Frontend / Backend
- **Decidido por:** Miguel Kohn
- **Decisión:** Dropdown en tab AL CERRAR solo muestra flows del mismo `tenant_worker_id`. Backend valida `target_flow_slug`; retorna HTTP 422 si no existe.
- **Conversación origen:** Sprint 2 — Configuración E2E (2026-04-29).

### [ADR-187] `carry_fields` eliminado de UI — acceso a campos del padre vía `parent_execution_id`

- **Fecha:** 2026-04-29
- **Estado:** Vigente (parcialmente supersede ADR-172)
- **Área:** Producto / Frontend
- **Decidido por:** Miguel Kohn
- **Decisión:** Eliminar campo `carry_fields` del tab AL CERRAR en `FlowDetailScreen`. Se mantiene en schema por compatibilidad pero no se expone en UI.
- **Conversación origen:** Sprint 2 — Configuración E2E (2026-04-29).

### [ADR-188] Tipo de campo `select` con `data_source` configurable

- **Fecha:** 2026-04-29
- **Estado:** Vigente
- **Área:** Producto / Frontend / Backend
- **Decidido por:** Miguel Kohn
- **Decisión:** Nuevo tipo `select` con `data_source` configurable. Fuentes: `system:operators`, `system:operators_with_flow:{slug}`. Valor guardado siempre es UUID.
- **Conversación origen:** Sprint 2 — Configuración E2E (2026-04-29).

### [ADR-189] Integraciones a nivel tenant — `flow_definition_id` → `_deprecated_flow_definition_id`

- **Fecha:** 2026-04-30
- **Estado:** Implementado — migration `20260430000001` aplicada
- **Área:** BD / Backend / Frontend
- **Decidido por:** Miguel Kohn
- **Decisión:** Integraciones migradas de nivel flow a nivel tenant. `flow_definition_id` → `_deprecated_flow_definition_id` (nullable). Endpoints viejos `/flows/{id}/integrations` → HTTP 410. Nuevos endpoints bajo `/integrations`.
- **Conversación origen:** ADR-189 — Integraciones a nivel tenant (2026-04-30).

### [ADR-190] Selector de operador filtra por `trigger_sources='conversational'`

- **Fecha:** 2026-04-29
- **Estado:** Pendiente de implementación
- **Área:** Frontend / Backend
- **Decidido por:** Miguel Kohn
- **Decisión:** Selector de flujos en ficha de operador (tab FLUJOS) filtra por `trigger_sources contains 'conversational'`.
- **Conversación origen:** Sprint 2 — Configuración E2E (2026-04-29).

### [ADR-191] Autenticación de Workers migrada a `auth_config JSONB` en `ai_worker_catalog`

- **Fecha:** 2026-04-29
- **Estado:** Vigente — migration `20260429000001` aplicada
- **Área:** Backend / Seguridad
- **Decidido por:** Miguel Kohn
- **Decisión:** Columna `auth_config JSONB` en `ai_worker_catalog`. Schema: `{"type": "bearer|jwt|api_key|basic", "credentials": {...}}`. `_mask_auth_config()` enmascara credentials en GET. `AI_ROUTER_URL`, `AI_ROUTER_API_KEY`, `WORKER_JWT` marcados como deprecated.
- **Conversación origen:** Integración AI Worker Marco (2026-04-29/30).

### [ADR-192] Sin fallback `AI_ROUTER_URL` — HTTP 503 si `webhook_url` es null (Supersede ADR-149)

- **Fecha:** 2026-04-29
- **Estado:** Vigente
- **Área:** Backend
- **Decidido por:** Miguel Kohn
- **Decisión:** Si `webhook_url` es null en `ai_worker_catalog` → HTTP 503 con `worker_not_configured`. Sin fallback.
- **Conversación origen:** Integración AI Worker Marco (2026-04-29/30).

### [ADR-193] HMAC secret en `/_mock_webhook/receive` obtenido desde BD via `delivery_id`

- **Fecha:** 2026-04-29
- **Estado:** Vigente — commit ae9a568
- **Área:** Backend / Seguridad
- **Decidido por:** Miguel Kohn
- **Decisión:** `delivery_id` → lookup en `webhook_outbox` → `flow_integrations.hmac_secret_encrypted` → `pgcrypto_decrypt`. `MOCK_WEBHOOK_SECRET` eliminado.
- **Conversación origen:** Sprint 3 — Mock Worker y Mock Webhook (2026-04-29).

### [ADR-194] `worker_can_resume` y `escalation_id` incluidos en `contexto_extra` del envelope

- **Fecha:** 2026-04-29
- **Estado:** Vigente — commit 9ecb393
- **Área:** Backend / Contrato Worker
- **Decidido por:** Miguel Kohn
- **Decisión:** `ai_router.py` consulta `escalations` en cada llamada al Worker. `worker_can_resume` y `escalation_id` se incluyen en `contexto_extra`.
- **Conversación origen:** Sprint 3 — Mock Worker y Mock Webhook (2026-04-29).

### [ADR-195] Design System v1.0 como fuente única de verdad visual — adopción top-down

- **Fecha:** 2026-05-01
- **Estado:** Vigente
- **Área:** Frontend
- **Decidido por:** Miguel Kohn
- **Decisión:** `ctTeal=#59E0CC` (antes `#2DD4BF`). `ctNavy=#0B132B` (antes `#0F2937`). Topbar light 52px. Sidebar dark `#0E1829`. `StatefulShellRoute.indexedStack` con 13 branches. `google_fonts` eliminado. `AppTextStyles` const completo.
- **Alternativas consideradas:** Tab bar Chrome-style con `IndexedStack` manual (descartada por GlobalKey bugs).
- **Conversación origen:** Design System Standardization (2026-05-01).

### [ADR-196] Dashboards configurables por tenant — arquitectura declarativa

- **Fecha:** 2026-05-03
- **Estado:** Vigente — Fase 1 implementada. Fase 2 (editor nocode) diferida.
- **Área:** Producto / BD / Backend / Frontend
- **Decidido por:** Miguel Kohn
- **Decisión:** Dashboards configurables por tenant en tablas `dashboard_definitions` + `dashboard_widgets`. Fase 1 = curados por Conectamos vía SQL. Rendering declarativo en frontend por `widget_type` y `layout_hint`. Filtro de fecha default = medianoche `America/Mexico_City`.
- **Alternativas consideradas:** Pantallas hardcodeadas por tenant.
- **Conversación origen:** Dashboard arquitectura e implementación (2026-05-03).

### [ADR-197] `tenant_id` migrado de query param a header `X-Tenant-ID` en todos los endpoints

- **Fecha:** 2026-05-03
- **Estado:** Vigente — 34 endpoints migrados
- **Área:** Backend / Frontend / Seguridad
- **Decidido por:** Miguel Kohn
- **Decisión:** Migración completa e inmediata. `Depends(get_current_tenant_id)` en todos los endpoints autenticados. Interceptor Dio inyecta `X-Tenant-ID` desde `localStorage['conectamos_active_tenant_id']`.
- **Alternativas consideradas:** Mantener query param en nuevos endpoints.
- **Conversación origen:** Dashboard arquitectura e implementación (2026-05-03).

### [ADR-198] `POST /operators` reactiva operador `deleted` en lugar de INSERT nuevo

- **Fecha:** 2026-05-05
- **Estado:** Vigente — commit dd612cc
- **Área:** Backend
- **Decidido por:** Miguel Kohn
- **Decisión:** Si `status='deleted'` en mismo tenant → UPDATE (reactiva), mismo `operator_id`, historial preservado, retorna 200 + `reactivated: true`. Si `status != 'deleted'` → 409 OP_E002.
- **Conversación origen:** Auditoría tenant isolation operators (2026-05-05).

### [ADR-199] `_find_operator` filtra por `phone + tenant_id + status='active'`

- **Fecha:** 2026-05-05
- **Estado:** Vigente — commit 4101205
- **Área:** Backend / Seguridad
- **Decidido por:** Miguel Kohn
- **Decisión:** `_find_operator(svc, phone, tenant_id)` filtra por `phone + tenant_id + status='active'`. Mismo fix en `_find_operator_by_telegram_chat_id`.
- **Conversación origen:** Auditoría tenant isolation operators (2026-05-05).

### [ADR-200] `operator_flows` UNIQUE incluye `tenant_id`

- **Fecha:** 2026-05-05
- **Estado:** Vigente — migration `20260505000001` aplicada en prod
- **Área:** BD
- **Decidido por:** Miguel Kohn
- **Decisión:** `UNIQUE(tenant_id, operator_id, flow_definition_id)`. Sin partial index porque `operator_flows` usa DELETE+INSERT, no soft-delete.
- **Conversación origen:** Auditoría tenant isolation operators (2026-05-05).

### [ADR-201] Tenant isolation completo en todos los endpoints de operators

- **Fecha:** 2026-05-05
- **Estado:** Vigente — commit dd612cc. 29 tests passing.
- **Área:** Backend / Seguridad
- **Decidido por:** Miguel Kohn
- **Decisión:** Todo lookup e update incluye `tenant_id` del JWT. Si el recurso no pertenece al tenant del caller → 404. Nunca revelar existencia en otro tenant.
- **Conversación origen:** Auditoría tenant isolation operators (2026-05-05).

### [ADR-202] Conversaciones de números desconocidos van a panel archivadas — sin columna nueva en BD

- **Fecha:** 2026-05-06
- **Estado:** Vigente
- **Área:** Producto / Frontend / Backend
- **Decidido por:** Miguel Kohn
- **Decisión:** Conversaciones `unregistered=true` ocultas del sidebar por default. Aparecen en panel `_ArchivedPanel` colapsable. Restore = asignar operador. Hard delete = `DELETE /wa-messages` con guard doble, solo `admin`, confirmación doble.
- **Alternativas consideradas:** Flag `archived` en BD; tabla separada; pestaña global.
- **Conversación origen:** Bugs pantalla Conversaciones y Feed Global (2026-05-06).

### [ADR-203] Vista General — métricas operativas redefinidas

- **Fecha:** 2026-05-05
- **Estado:** Vigente
- **Área:** Producto / Backend
- **Decidido por:** Miguel Kohn
- **Decisión:** `computed_status` dinámico: incident > active > off. `operators_active` = COUNT con flow_execution completed hoy. `events_processed_today` = COUNT flow_field_values.captured_at hoy. `flows_active` = creadas hoy. `operators_total` excluye `status='deleted'`. `completion_rate` devuelve 0.0 cuando no hay flujos. `db_status` se preserva.
- **Conversación origen:** Refactor Vista General (2026-05-05).

### [ADR-204] `saved_views` — vistas persistentes de filtros de Ejecuciones por usuario <!-- ACTUALIZADO: nuevo ADR para patrón no documentado encontrado en código -->

- **Fecha:** 2026-05-04
- **Estado:** Vigente — migration `20260504000001_create_saved_views.sql` aplicada
- **Área:** BD / Backend / Frontend
- **Decidido por:** Miguel Kohn
- **Contexto:** Pantalla Ejecuciones tiene filtros complejos (worker, flows, operadores, status, búsqueda avanzada). Supervisores necesitan guardar combinaciones frecuentes sin reconfigurar cada vez.
- **Decisión:** Tabla `saved_views` con `(id, tenant_id, user_id, name, filters JSONB, is_default boolean)`. CRUD completo: `GET /flow-dashboard/saved-views`, `POST`, `PATCH /{id}`, `DELETE /{id}`. Scoped por `(tenant_id, user_id)` — cada usuario tiene sus propias vistas. RLS enforced.
- **Alternativas consideradas:** Filtros en localStorage (no persiste entre dispositivos); filtros globales por tenant (colisión entre usuarios).
- **Conversación origen:** Implementación Ejecuciones v2 (2026-05-04).

### [ADR-205] Dos cron endpoints independientes en vercel.json — process-webhook-outbox y process-pending-completions <!-- ACTUALIZADO: nuevo ADR para patrón no documentado encontrado en vercel.json -->

- **Fecha:** 2026-05-04
- **Estado:** Vigente
- **Área:** Infra / Backend
- **Decidido por:** Miguel Kohn
- **Contexto:** ADR-176 documentaba un solo cron. El `vercel.json` real tiene dos entradas independientes. El endpoint `/api/cron/process-webhook-outbox` llama tanto `process_outbox()` como `process_pending_completions()`. El endpoint `/api/cron/process-pending-completions` es standalone.
- **Decisión:** Mantener dos entradas cron en `vercel.json` con schedule `* * * * *`. El endpoint `process-webhook-outbox` es el procesador principal (llama ambas funciones). El endpoint `process-pending-completions` permite triggear completions independientemente para debugging o reintento manual.
- **Alternativas consideradas:** Un solo endpoint (reduce redundancia pero elimina flexibilidad de trigger manual).
- **Conversación origen:** Revisión vercel.json y cron.py (2026-05-04).

### [ADR-206] Lifecycle management completo de flow_executions — pause/resume/abandon/reassign <!-- ACTUALIZADO: nuevo ADR para patrón no documentado encontrado en código -->

- **Fecha:** 2026-04-28
- **Estado:** Vigente — implementado en `flow_dashboard.py`
- **Área:** Backend / Producto
- **Decidido por:** Miguel Kohn
- **Contexto:** ADR-167 definió el control del supervisor. Los endpoints van más allá de assign/submit.
- **Decisión:** Endpoints en `/flow-dashboard/executions/{id}/`:
  - `POST .../pause` → `status='paused'`, `actor='supervisor'`
  - `POST .../resume` → `status='active'` desde `paused`
  - `POST .../abandon` → `status='abandoned'`
  - `POST .../reassign` → cambia `operator_id`
  Todos registran eventos en `flow_execution_events`. Requieren permiso `flows.manage`.
- **Alternativas consideradas:** Solo pause/resume (insuficiente para casos edge de reasignación).
- **Conversación origen:** Sprint backend flow_dashboard (2026-04-28).

### [ADR-207] `prerequisite_flow_slug` — prerrequisito de flow en `flow_definitions` <!-- ACTUALIZADO: nuevo ADR para patrón no documentado encontrado en código -->

- **Fecha:** 2026-05-05
- **Estado:** Vigente — migration `20260505000001_prerequisite_flow_slug.sql` aplicada
- **Área:** BD / Backend / Producto
- **Decidido por:** Miguel Kohn
- **Contexto:** Algunos flows solo tienen sentido si un flow previo fue completado (ej: "cerrar orden" requiere "crear orden" completada).
- **Decisión:** Columna nullable `prerequisite_flow_slug TEXT` en `flow_definitions`. El motor valida en `start_execution()` que exista una execution `completed` del flow prerrequisito para el mismo operador antes de crear la nueva. Sin prerrequisito = sin validación.
- **Alternativas consideradas:** Validación en frontend exclusivamente (insegura); prerequisito por `flow_definition_id` (frágil ante renombrados).
- **Conversación origen:** Implementación Ejecuciones v2 (2026-05-05).

### [ADR-208] Mensajes WhatsApp interactivos (button/list) en flow_engine — `_send_whatsapp_interactive()` <!-- ACTUALIZADO: nuevo ADR para patrón no documentado encontrado en código -->

- **Fecha:** 2026-04-28
- **Estado:** Vigente — implementado en `flow_engine.py`
- **Área:** Backend / Producto
- **Decidido por:** Miguel Kohn
- **Contexto:** Campos de tipo `select` en flows pueden beneficiarse de mensajes interactivos de WhatsApp (botones o listas) en lugar de texto libre.
- **Decisión:** `_send_whatsapp_interactive(channel_id, to, body_text, options, svc)` en `flow_engine.py`. Si `len(options) <= 3` → tipo `button`; si `> 3` → tipo `list`. Fallback a `_interactive_fallback_text()` cuando el canal es Telegram (no soporta interactivos de WA) o cuando `options` está vacío.
- **Alternativas consideradas:** Solo texto enumerado (menos UX); interactivos solo para botones (ignora listas).
- **Conversación origen:** Motor Flows v2 — mensajes de campo select (2026-04-28).

### [ADR-209] `_resolve_inbound_message_id` con retry 3 intentos / 500ms en `ai_worker_events.py` <!-- ACTUALIZADO: nuevo ADR para patrón no documentado encontrado en código -->

- **Fecha:** 2026-04-28
- **Estado:** Vigente — implementado en `ai_worker_events.py`
- **Área:** Backend
- **Decidido por:** Miguel Kohn
- **Contexto:** Al recibir un evento del Worker, la plataforma intenta vincular el evento con el `wa_message_id` del mensaje inbound que lo desencadenó. En Vercel serverless existe una ventana de latencia de escritura donde el mensaje aún no está en BD cuando llega el callback del Worker.
- **Decisión:** `_resolve_inbound_message_id(svc, operator_id, tenant_id)` hace hasta 3 intentos con 500ms de espera entre cada uno antes de retornar `None` y continuar sin el vínculo. No bloquea el flujo si no se resuelve.
- **Alternativas consideradas:** Un solo intento sin retry (pierde vínculos por latencia); retry sin límite (timeout en Vercel).
- **Conversación origen:** Auditoría pipeline ai_worker_events (2026-04-28).

### [ADR-210] `ApiClient.instance` como singleton Dio con header `X-Tenant-ID` inyectado desde localStorage <!-- ACTUALIZADO: nuevo ADR — patrón no documentado en CLAUDE.md -->

- **Fecha:** 2026-05-03
- **Estado:** Vigente
- **Área:** Frontend / Arquitectura
- **Decidido por:** Equipo técnico
- **Contexto:** CLAUDE.md documenta `ApiClient.dio` como getter del singleton. El código real usa `ApiClient.instance`. Además, el interceptor inyecta `X-Tenant-ID` desde `localStorage['conectamos_active_tenant_id']` — no solo `Authorization: Bearer`.
- **Decisión:** El getter canónico del singleton Dio es `ApiClient.instance`. El interceptor `InterceptorsWrapper` inyecta dos headers en cada request: `Authorization: Bearer {supabase_access_token}` y `X-Tenant-ID: {localStorage['conectamos_active_tenant_id']}`. No pasar `tenant_id` como query param ni en body — usar el header.
- **Alternativas consideradas:** `ApiClient.dio` (nombre anterior, no es el getter real del código).
- **Conversación origen:** Auditoría frontend 2026-05-06.

### [ADR-211] Dos widgets de header canónicos: `ScreenHeader` (Pattern A) y `PageHeader` (Pattern B) <!-- ACTUALIZADO: nuevo ADR — patrón no documentado encontrado en código -->

- **Fecha:** 2026-05-01
- **Estado:** Vigente
- **Área:** Frontend / UX
- **Decidido por:** Equipo técnico
- **Contexto:** CLAUDE.md menciona `ScreenHeader` brevemente pero no documenta `PageHeader` ni la distinción semántica entre ambos.
- **Decisión:** Dos widgets de header para contextos distintos:
  - **Pattern A — `ScreenHeader`** (`lib/shared/widgets/screen_header.dart`): sub-bar bajo el AppBar, 20px title, subtitle, actions. Usado en: ConversationsScreen, OperatorsScreen, WorkflowsScreen, AllExecutionsScreen, EscalacionesScreen, OverviewScreen.
  - **Pattern B — `PageHeader`** (`lib/shared/widgets/page_header.dart`): eyebrow (uppercase teal caption), 28px title, description text, optional actions row. Usado en: ChannelsScreen, AiWorkersScreen, SettingsScreen.
  Usar Pattern A para pantallas operativas con acciones inline. Usar Pattern B para pantallas de configuración con descripción contextual.
- **Conversación origen:** Auditoría frontend 2026-05-06.

### [ADR-212] `StatefulShellRoute.indexedStack` con 13 branches — no `ShellRoute` plain <!-- ACTUALIZADO: nuevo ADR — corrección de CLAUDE.md -->

- **Fecha:** 2026-05-01
- **Estado:** Vigente (corrige documentación en CLAUDE.md)
- **Área:** Frontend / Arquitectura
- **Decidido por:** Equipo técnico
- **Contexto:** CLAUDE.md documenta el shell como `ShellRoute`. El código real usa `StatefulShellRoute.indexedStack` con 13 `StatefulShellBranch`. La diferencia es que `StatefulShellRoute` preserva el estado de cada rama (scroll position, form state) mientras el usuario navega entre secciones del sidebar.
- **Decisión:** El shell route canónico es `StatefulShellRoute.indexedStack`. Cada sección del sidebar es una `StatefulShellBranch` independiente. El `AppShell` recibe `StatefulNavigationShell navigationShell`. Nunca usar `ShellRoute` plain para el shell principal.
- **Conversación origen:** Auditoría frontend 2026-05-06.

### [ADR-213] `ConnectionsScreen` usa catálogo estático local — sin API para listar integraciones <!-- ACTUALIZADO: nuevo ADR — patrón no documentado encontrado en código -->

- **Fecha:** 2026-04-30
- **Estado:** Vigente
- **Área:** Frontend / Producto
- **Decidido por:** Miguel Kohn
- **Contexto:** La pantalla Conexiones muestra un catálogo de apps integrables (Salesforce, HubSpot, Google Sheets, etc.). No existe un endpoint de backend que devuelva este catálogo.
- **Decisión:** `_kApps` es una lista `const` local en `connections_screen.dart` con los logos y metadatos de cada integración. Las acciones de CRUD real (crear/eliminar integraciones por tenant) sí llaman a la API (`GET/POST/DELETE /integrations`). Solo el catálogo de apps disponibles es estático.
- **Conversación origen:** Auditoría frontend 2026-05-06.

### [ADR-214] `BroadcastScreen` con constructor de parámetros opcionales — usable como modal <!-- ACTUALIZADO: nuevo ADR — patrón no documentado encontrado en código -->

- **Fecha:** 2026-04-24
- **Estado:** Vigente
- **Área:** Frontend / UX
- **Decidido por:** Miguel Kohn
- **Contexto:** Desde ConversationsScreen el supervisor puede iniciar un broadcast al canal activo. La ruta `/broadcast` existe como pantalla standalone, pero el mismo widget puede montarse como modal con contexto pre-rellenado.
- **Decisión:** `BroadcastScreen` acepta parámetros opcionales `channelId` y `channelType` en su constructor. Cuando se usa como ruta standalone (`/broadcast`), los parámetros son null y el usuario selecciona canal manualmente. Cuando se monta como modal desde ConversationsScreen, se pasan `selectedChannelIdProvider` y `selectedChannelTypeProvider` como valores iniciales.
- **Conversación origen:** Auditoría frontend 2026-05-06.

---

## Decisiones superseded explícitas

- ADR-006 (Supabase directo desde Flutter) → ADR-060 (Backend consume todo).
- ADR-007 (`user_read_receipts` y `last_read_at`) → supersedido por ADR-136 (`panel_read_at` en `wa_messages`).
- ADR-020 (POST /tenants crea template en Meta) → ADR-076 (sync de templates ocurre al crear canal WhatsApp).
- ADR-038 (modelo Operador→Canal como asignación) → ADR-070 (modelo Operador→Flujo→Worker→Canal).
- ADR-039 (la plataforma solo envía mensaje + estado del flow_execution al Worker) → parcialmente supersedido por ADR-145.
- ADR-052 (editor visual diferido) → ADR-181 (implementado en FlowDetailScreen).
- ADR-083 (Embedded Signup deshabilitado hasta certificación) → ADR-109 (Embedded Signup activado en modo Development).
- ADR-149 (routing condicional con fallback a `AI_ROUTER_URL`) → ADR-192 (sin fallback, HTTP 503 si `webhook_url` es null).
- ADR-172 (carry_fields filtrado por schema hijo) → parcialmente supersedido por ADR-187 (carry_fields eliminado de UI).
- ADR-177 (channel_id resuelto por tenant_worker_id del flow hijo) → complementado por ADR-183 con `preferred_channel_types`.

## Decisiones marcadas como no vigentes al cierre

- Exploración de Firebase Auth para multi-tenant — el proyecto usa Supabase Auth, no Firebase Auth.

---

_Agregar nuevas entradas debajo, incrementando el número ADR. No editar entradas existentes._

---

## Historial de actualizaciones

| Fecha | Quién | Qué se actualizó |
|---|---|---|
| 2026-04-17 | Miguel Kohn | Consolidación inicial desde 11 conversaciones (ADR-001 a ADR-069). |
| 2026-04-20 | Miguel Kohn | ADR-070 a ADR-098: refactor credenciales, modelo asignación, restructura conversaciones, fixes canales y fuentes. ADR-020 supersedida por ADR-076. |
| 2026-04-21 | Miguel Kohn | ADR-099 a ADR-118: IAM dinámico, Telegram, Embedded Signup, onboarding WhatsApp, catálogo workers. ADR-083 supersedida por ADR-109. |
| 2026-04-24 | Miguel Kohn | ADR-119 a ADR-137: fixes IAM/emails, broadcast, Telegram completo, conversaciones refactor, operadores v2. |
| 2026-04-26 | Miguel Kohn | ADR-138 a ADR-152: arquitectura escalaciones, contrato AI Worker, protocolo envelope, routing por BD, bugs de tenant/chat_id, broadcasts en wa_messages. ADR-039 parcialmente supersedido por ADR-145. |
| 2026-04-28 | Miguel Kohn | ADR-153 a ADR-182: Blueprint Flows v2 completo (Fases 0, A, B, C), contrato Worker, schema estricto, frontend flows, DateFormat. |
| 2026-05-03 | Miguel Kohn | ADR-183 a ADR-195: sprints E2E, Design System, Worker Marco, ADR-189 integraciones, auth_config. ADR-149 supersedido por ADR-192. |
| 2026-05-06 | Miguel Kohn | ADR-196 a ADR-203: dashboards, X-Tenant-ID header global, tenant isolation operators, super_admin implementado, conversaciones archivadas, KPIs redefinidos. ADR-007 supersedido por ADR-136. |
| 2026-05-06 | Claude Code | ADR-204 a ADR-209: saved_views, dos cron entries en vercel.json, lifecycle management executions, prerequisite_flow_slug, mensajes interactivos WA, retry resolve_inbound_message_id. |
| 2026-05-06 | Claude Code | ADR-210 a ADR-214: ApiClient.instance getter canónico, ScreenHeader/PageHeader Pattern A/B, StatefulShellRoute.indexedStack corrige ShellRoute en CLAUDE.md, ConnectionsScreen catálogo estático, BroadcastScreen modal pattern. <!-- ACTUALIZADO: nuevos ADRs de auditoría frontend --> |
