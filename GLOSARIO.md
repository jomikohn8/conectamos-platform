# === ARCHIVO: GLOSARIO.md ===

# GLOSARIO — Conectamos / ConectamOS <!-- ACTUALIZADO: última consolidación 2026-05-06 -->

> **Propósito:** Diccionario compartido de términos del proyecto. Si aparece en código, UI o conversaciones del equipo y puede causar ambigüedad, va aquí.
> **Regla:** Si un término empieza a aparecer en 3+ conversaciones sin estar aquí, toca agregarlo.
> **Última consolidación:** 2026-05-06 <!-- ACTUALIZADO: auditoría frontend añade 12 términos nuevos -->

---

## Términos de dominio (producto)

- **Tenant** — Cliente (empresa) de ConectamOS. Unidad principal de aislamiento: cada tenant tiene sus propios operadores, canales, plantillas, workers, usuarios y credenciales Meta. Slugs actuales: `tmr-prixz`, `conectamos-demo`, `home-prueba`.
- **Operador** — Persona de campo que recibe supervisión vía WhatsApp (ej. técnico, repartidor, inspector). No es usuario de la plataforma: se le contacta por su número de teléfono.
- **Supervisor** — Usuario de la plataforma con permisos para ver y responder conversaciones de operadores. Es un `tenant_user` con rol `supervisor` o superior.
- **Superadmin** — Rol transversal con acceso a todos los tenants (equipo Conectamos interno). Detectado por `app_metadata.role == "super_admin"` en Supabase. Distinto de `admin` que es rol dentro de un tenant. Ver ADR-114.
- **Canal** — Entidad que agrupa operadores bajo un `tenant_worker` específico y una configuración visual (color, nombre). Es la "pista" por la que fluyen los mensajes y sobre la que corre el AI Worker.
- **Sesión (`sessions`)** — Conversación activa entre un operador y un flujo. Tiene inicio, fin y puede estar en estado `worker`, `supervisor` (intervenida) o `closed`.
- **Flujo (`flow_definitions`)** — Plantilla de preguntas estructuradas que el worker formula al operador. Cada flujo tiene campos (`flow_field_definitions`) con tipo y validación.
- **Ejecución de flujo (`flow_executions`)** — Instancia de un flujo corriendo para un operador en una fecha. Ciclo de vida: `created` → `active` → `paused` → `completed` / `abandoned`. `pending_completion` es status intermedio para executions creadas por ingest externo. Ver ADR-175, ADR-206.
- **Broadcast** — Envío masivo de una plantilla de WhatsApp a un conjunto filtrado de operadores. Segmentable por status, flujos, canales.
- **Feed global** — Vista tipo "grupo de WhatsApp" donde el supervisor ve todos los mensajes del tenant en un stream único, con filtros bidireccionales (inbound/outbound).
- **Intervenir** — Acción del supervisor que pausa al AI Worker en una sesión específica y toma control manual del chat.
- **Ventana 24h** — Ventana de Meta WhatsApp Business: después del último mensaje entrante del cliente, el negocio tiene 24 horas para responder con mensajes de texto libre. Fuera de la ventana solo se pueden enviar plantillas aprobadas.
- **AI Worker** — Agente conversacional automatizado que atiende operadores en un canal. Definido en `ai_worker_catalog` y contratado por un tenant como `tenant_worker`.
- **Catálogo de Workers** — Listado de plantillas de workers (`ai_worker_catalog`) que un tenant puede contratar.
- **Contratación** — Proceso de vincular un worker del catálogo al tenant, creando un row en `tenant_workers`.
- **Plantilla / Template** — Mensaje pre-aprobado por Meta (`wa_templates`) que se puede enviar fuera de la ventana 24h. Tiene nombre, idioma, categoría, `waba_id` asociado, y opcionalmente `header_type`, `header_text`, `footer_text`, `buttons`. Ver migration 54.
- **Mensaje de bienvenida** — Primer mensaje que el tenant envía automáticamente a un operador recién dado de alta. Configurable en Ajustes → Comunicación.
- **Firma del supervisor** — Prefijo `"*Nombre*: "` que se antepone al mensaje enviado por el supervisor, si el tenant tiene `show_supervisor_name = true`. Resuelta por `_get_sender_name()` en backend.
- **Outbound / Inbound** — Dirección del mensaje. Outbound = del tenant hacia el operador; inbound = del operador hacia el tenant.

---

## Términos técnicos (código y arquitectura)

- **`_windowOpen`** — Booleano nullable en estado de conversaciones Flutter que indica si la ventana 24h está abierta para el operador actual. Controla disponibilidad del input de texto libre.
- **`_sessionStartAt`** — Timestamp local del inicio de la sesión activa, usado para calcular tiempo transcurrido en el pill de status.
- **`kMockMode`** — Constante global en Flutter que, cuando es `true`, reemplaza llamadas reales al backend por datos mock.
- **`wa_status`** — Columna en `wa_messages` con el ciclo de vida del mensaje: `queued`, `sent`, `delivered`, `read`, `failed`.
- **`origin`** — Columna en `wa_messages` que distingue `inbound` (operador → tenant) de `outbound` (tenant → operador). También puede ser `broadcast`, `ai_worker`, `human`.
- **`NoTransitionPage`** — Widget de go_router usado en ConectamOS para evitar animaciones entre rutas del sidebar.
- **`AuthMiddleware`** — Middleware BaseHTTPMiddleware de Starlette en FastAPI que valida el JWT de Supabase en `Authorization: Bearer ...`. Excluye OPTIONS para CORS preflight.
- **`BaseHTTPMiddleware`** — Clase de Starlette usada en lugar de `@app.middleware("http")`.
- **`TODO 000002`** — Marcador en código que referencia la migración pendiente de drop de columnas Meta legacy en `tenants`. Ver ID-012 en BACKLOG.md.
- **`_get_sender_name()`** — Función helper en backend que, dado un `user_id` y un tenant, devuelve el nombre a firmar en outbound.
- **`_flatten_channel()`** — Helper que aplana el resultado del join entre `channels`, `tenant_workers` y `ai_worker_catalog` en un solo dict.
- **`str.replace()` templates** — Técnica usada en EmailService para inyectar variables `{{variable}}` en HTML compilado.
- **Opción B1** — Decisión arquitectónica para consumir HTML de emails desde `raw.githubusercontent.com` del repo `conectamos-emails`.
- **`asyncio.gather`** — Patrón usado en `/tenants/{id}/kpis` para paralelizar queries independientes a Supabase.
- **Row-level tenant isolation** — Patrón arquitectónico: todas las tablas transaccionales llevan `tenant_id` y las queries filtran por él.
- **`get_channel_credentials()`** — Helper centralizado en `app/services/wa_credentials.py`. Resuelve credenciales WhatsApp desde `channels.channel_config.credentials`. Lanza 404 si el canal no existe, 503 si las credenciales están incompletas.
- **`channel_config`** — JSONB en tabla `channels` con estructura `{channel_type, credentials{...}, capabilities[]}`. Fuente única de verdad para credenciales de canal. Ver ADR-077.
- **`capabilities[]`** — Array en `channel_config` que declara funcionalidades del canal: `["text","media","templates","reactions","location"]` para WhatsApp; `["text","media","location"]` para Telegram; `["text"]` para SMS.
- **`_mask_channel_token()`** — Helper en `channels.py` que reemplaza `channel_config.credentials.access_token` con `"••••••••"` en todas las respuestas de API.
- **`operator_flows`** — Tabla de asignación directa operador↔flujo. Reemplaza `_deprecated_operator_channels`. UNIQUE `(tenant_id, operator_id, flow_definition_id)`. Ver ADR-070, ADR-200.
- **`operator_field_definitions`** — Tabla de campos configurables por tenant para la ficha del operador. Valores almacenados en `operators.metadata`.
- **`channelStateVersionProvider`** — `StateProvider<int>` en Flutter que se incrementa al cambiar el estado de un canal. Usado para invalidar caché de canales sin recargar toda la pantalla. <!-- ACTUALIZADO: tipo corregido a StateProvider<int> -->
- **`channel_detail_screen`** — Pantalla de detalle de un canal con 4 tabs: Información, Credenciales, Plantillas, Bienvenida.
- **`supervisor_channel_access`** — Tabla que controla qué canales puede ver cada `tenant_user`. Admin tiene bypass total. Ver ADR-092.
- **`chat_id`** — Número de teléfono del contacto externo. Llave natural de una conversación. Ver ADR-091.
- **`verify-credentials`** — Endpoint `POST /channels/verify-credentials` (sin JWT) que valida `phone_number_id + access_token` contra Meta Graph API. Ver ADR-097.
- **variable font** — Archivo `.ttf` único que contiene todos los pesos de una tipografía. Usado para Onest y Geist. Ver ADR-098.
- **Canal operativo** — Canal con `worker_type in (logistics, collections)`. Valida que el número entrante sea un operador registrado. Ver ADR-088.
- **Canal de ventas/CX** — Canal con `worker_type in (sales, custom)`. Acepta cualquier número entrante sin validación de operador. Ver ADR-088.
- **Modelo A de intervención** — Stop total del worker al intervenir el supervisor. `session.status='supervisor'` bloquea dispatch. Ver ADR-075.
- **Modelo C de intervención** — Handoff explícito entre plataforma y worker vía eventos. Documentado para futuro, no implementado.
- **Embedded Signup** — Flujo OAuth oficial de Meta para Tech Partners. Ver ADR-083 (supersedido por ADR-109).
- **Tech Provider / Solution Partner** — Categorías de partner certificado de Meta. Habilitan `smb_message_echoes`. Ver ADR-096.
- **`smb_message_echoes`** — Webhook de Meta que captura mensajes enviados desde WA Business App. Solo para Tech Providers. Ver ADR-096.
- **`panel_read_at`** — Columna `TIMESTAMPTZ` en `wa_messages`. Base del sistema de no-leídos persistente. Ver ADR-136.
- **`channelUnreadProvider`** — `StateProvider<Map<String, int>>` en Flutter. Mantiene conteo de no-leídos por `channel_id`.
- **`_OperatorAvatar`** — Widget Flutter reutilizable. Foto circular con `profile_picture_url`; fallback a iniciales sobre fondo teal.
- **`context_message_id`** — Campo `TEXT` en `wa_messages`. Referencia al mensaje al que se responde. Ver ADR-128.
- **`_deprecated_reply_to_message_id`** — Columna `UUID FK` deprecada. Candidata a DROP.
- **`reactions JSONB`** — Columna en `wa_messages`. Huérfana — candidata a DROP. Las reacciones se modelan como fila nueva con `message_type='reaction'` (ADR-127).
- **`media_service.py`** — Servicio genérico de descarga de binario y upload a Supabase Storage. Compartido entre WhatsApp y Telegram. Ver ADR-126.
- **`telegram_media.py`** — Servicio que resuelve `file_id → URL` via `getFile` de Telegram Bot API.
- **`closedWindowCount`** — Variable calculada en frontend (broadcast). Determina bloqueo del botón de envío. Ver ADR-120.
- **`last_inbound_at`** — Campo calculado en `GET /operators`. MAX de `received_at` de `wa_messages` donde `direction='inbound'`. Ver ADR-122.
- **`_is_invitation: true`** — Flag en la respuesta de `GET /iam/users`. Indica que el registro corresponde a una invitación pendiente. Ver ADR-119.
- **`RESERVED_METADATA_KEYS`** — Conjunto de claves reservadas en `operators.metadata`: `{telegram_chat_id, telegram_link_status, telegram_link_expires_at, phone_secondary}`. Ver ADR-135.
- **`operator_export_config`** — JSONB en `tenants`. Define qué columnas aparecen en el export de operadores. Ver ADR-134.
- **`custom_fields`** — Array en el response de operadores con definición + valor de cada campo tenant-defined.
- **`custom_field_values`** — Dict `{field_key: value}` enviado en POST/PUT de operadores.
- **`OP_E001–OP_E017`** — Códigos de error semánticos del módulo de operadores.
- **`OF_E001–OF_E003`** — Códigos de error semánticos del módulo de campos de operador.
- **`worker_catalog_tenant_visibility`** — Tabla pivote que controla qué tenants ven workers del catálogo con `visible_to_all=false`. Ver ADR-095. **[REVISAR CON EQUIPO — puede no existir en prod]**
- **`already_hired`** — Campo booleano calculado en runtime por `list_catalog_workers`. Ver ADR-100.
- **`get_telegram_credentials()`** — Helper análogo a `get_channel_credentials()` para Telegram.
- **`telegram_sender.py`** — Módulo de envío outbound Telegram. Timeout 10s. HTTPException 502 si Telegram responde `ok=false`.
- **`telegram_linking_tokens`** — Tabla de tokens UUID con expiración 72h para vincular operador con su `telegram_chat_id`. Ver ADR-106.
- **`requires_permission(module, action)`** — Dependencia FastAPI (`Depends()`) que verifica el permiso `module.action`. Admin bypasea. 403 si falta permiso. Ver ADR-099.
- **`userPermissionsProvider`** — `FutureProvider<Set<String>>` de Riverpod que retorna los permisos activos del usuario autenticado. <!-- ACTUALIZADO: tipo corregido a FutureProvider<Set<String>> -->
- **`hasPermission(ref, module, action)`** — Función helper Flutter en `permissions_provider.dart` que lee `userPermissionsProvider` y retorna `bool`. Uso: `hasPermission(ref, 'flows', 'manage')`. Ver ADR-116. <!-- ACTUALIZADO: ubicación de archivo documentada -->
- **`prerequisito de permiso`** — Permiso que debe estar activo para que otro pueda otorgarse. Manejado en backend y frontend.
- **`role_permissions_panel.dart`** — Widget Flutter con tres columnas (admin deshabilitada, supervisor, viewer), checkboxes por módulo, cascada de prerequisitos.
- **`activate-whatsapp`** — Endpoint `POST /channels/activate-whatsapp` (público) que ejecuta `subscribed_apps` y `register` contra Meta. Ver ADR-117.
- **`subscribed_apps`** — Llamada Meta `POST /{waba_id}/subscribed_apps` que suscribe la app al WABA.
- **`signup_source`** — Columna en `channels`. Valores: `'manual'` | `'embedded_signup'`.
- **`bot_username`** — Nombre público del bot de Telegram, obtenido via `getMe`. Guardado en `channel_config.credentials.bot_username`.
- **Embedded Signup v2** — Versión actual del flujo OAuth de Meta. Usa `configuration_id: 2145617199565998`. Ver ADR-109 a ADR-113.
- **Verificación de negocio Meta** — Proceso de validación en Meta Business Manager. Bloqueante para Conectamos (ID-047).
- **Flujo de vinculación Telegram** — Proceso: supervisor genera token → SMS con deep link → operador abre bot → webhook captura `/start TOKEN` → `telegram_chat_id` guardado. Ver ADR-106, ADR-107.
- **`escalations`** — Tabla de tickets generados cuando `checkpoint_incomplete` llega de un AI Worker. Ciclo de vida: open → assigned → resolved/reopened. Ver ADR-143.
- **`trigger_messages`** — Array de UUIDs de `wa_messages` que causaron la escalación.
- **`worker_can_resume`** — Flag booleano en `escalations`. El backend lo activa al resolver un ticket.
- **`ChannelMessage`** — Objeto normalizado estándar al que se convierte todo mensaje entrante. Aún no implementado (ADR-138, pendiente Santiago).
- **`active_channel_id`** — Columna en `flow_executions`. Canal activo actual del operador. Ver ADR-139.
- **Intervención tripartita** — Modalidad de supervisión donde coexisten el operador, el AI Worker y el supervisor. Ver ADR-144.
- **Unidad de conversación** — El operador (no el canal). Un operador tiene un flujo activo a la vez. Ver ADR-139.
- **`checkpoint_incomplete`** — Evento enviado por el AI Worker que dispara la creación automática de un ticket en `escalations`.
- **Envelope / Sobre estructurado** — Payload completo que la plataforma envía al Worker en cada interacción. Incluye `message` (o `trigger`), `operator`, `session`, `active_flows`, `assigned_flows`. Ver ADR-145.
- **Acciones declarativas** — Respuesta del Worker a la plataforma. Instrucciones tipadas: `open_flow`, `close_flow`, `set_field_value`, `escalate`. Ver ADR-145.
- **`failed_actions`** — Campo en respuesta 422 que detalla qué acciones del Worker fueron inválidas. Ver ADR-146.
- **Worker-initiated trigger** — Llamada proactiva del Worker a `POST /worker/trigger` para iniciar conversación sin mensaje inbound. Ver ADR-147.
- **`WORKER_JWT`** — Variable de entorno deprecada. Reemplazada por `auth_config JSONB` en `ai_worker_catalog`. Ver ADR-191.
- **`_send_message_if_present()`** — Helper en `ai_worker_events.py`. Envía `message_text` al operador vía canal. Solo actúa si `message_text` no es nulo.
- **`_resolve_message_text()`** — Helper en `ai_worker_events.py`. Prioridad: `message_text` explícito > `event_data.respuesta` > None.
- **`_save_field_values()`** — Helper en `flow_engine.py` (no `ai_worker_events.py`). UPSERT en `flow_field_values` por campo. Tipado automático: número → `value_numeric`, URL → `value_media_url`, dict/list → `value_jsonb`, resto → `value_text`.
- **`_save_flow_event()`** — Helper en `flow_engine.py`. INSERT en `flow_execution_events` con hitos del ciclo de vida.
- **`origin='broadcast'`** — Valor en `wa_messages.origin` para mensajes enviados vía broadcast. Ver ADR-152.
- **`broadcast_id`** — Columna en `wa_messages` que referencia `broadcasts.id`. Migration 32.
- **`_fetchFeedStatic`** — Método en Flutter que usa query estática cuando hay filtro de fecha activo en el Feed Global.
- **Gustavo** — Nombre del AI Worker de transporte/logística del equipo externo. `webhook_url` apunta a ngrok (temporal, ID-070).
- **`normalize_mx_phone`** — Función legacy en `phone_normalizer.py`. Reemplazada por `normalize_to_e164`. Candidata a deprecar.
- **`pending_completion`** — Status intermedio de `flow_executions` para `actor_type='system'`. El cron `process_pending_completions` lo procesa. Ver ADR-175.
- **`process_pending_completions`** — Función en `flow_engine.py` llamada por el cron. SELECT de executions `pending_completion`, optimistic lock, llama `complete_execution`.
- **`resolve_operator_channel()`** — Función en `flow_chain.py`. Resuelve `channel_id` para flow hijo. Ver ADR-177.