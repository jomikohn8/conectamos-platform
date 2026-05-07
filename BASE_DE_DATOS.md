# === ARCHIVO: BASE_DE_DATOS_PLATFORM.md ===

# BASE DE DATOS — Conectamos

> **Propósito:** Estado actual del esquema, migrations aplicadas y convenciones.
> **Auditoría 2026-05-06:** Sin diferencias detectadas respecto a esta versión. Schema, migrations y convenciones confirmados. <!-- ACTUALIZADO: auditoría frontend 2026-05-06 confirma documento vigente --> Consultar **antes** de proponer cualquier cambio de esquema.
> **Regla del proyecto:** Todo cambio de BD debe tener su migration correspondiente. Sin migration, el cambio no existe — salvo excepciones marcadas abajo.
> **Fuente de verdad del schema:** `information_schema.columns` del proyecto Supabase `atqmtsmjpjtrqooibubm`, consultado 2026-04-26. <!-- ACTUALIZADO: migrations 57–64 añadidas al historial -->

---

## 1. Motor y entorno

- **Motor:** PostgreSQL (Supabase managed)
- **Project ID:** `atqmtsmjpjtrqooibubm`
- **ORM / cliente:** Supabase Python SDK (backend) + Supabase Flutter SDK (frontend cuando aplica; la mayoría migrada a backend vía ADR-060)
- **Hosting:** Supabase Cloud
- **Entornos:** prod único — sin staging separado al momento. Dev local contra el mismo proyecto de Supabase.
- **Migration path:** archivos `.sql` versionados en `conectamos_meta_api/supabase/migrations/`. **Aplicación manual** vía Supabase SQL Editor (no hay runner automático).

---

## 2. Convenciones

- **Nombres de tablas:** `snake_case` plural (`tenants`, `operators`, `wa_messages`).
- **Nombres de columnas:** `snake_case`.
- **Llaves primarias:** `uuid` con `gen_random_uuid()` por defecto (casos recientes); algunas tablas legacy con `bigint`.
- **Timestamps:** `created_at`, `updated_at` como `timestamptz` con UTC explícito (`timezone.utc` desde Python).
- **Foreign keys:** `<tabla>_id` — ej. `operator_id`, `tenant_id`, `channel_id`.
- **JSONB:** para configuración flexible (`variables`, `segment_filters`, `fields_status`, `channel_config`).
- **Deprecación en BD:** columnas deprecadas se renombran con prefijo `_deprecated_` antes de eliminarse, para romper referencias en código a tiempo de compilación.

**Tablas con RLS habilitado:** `wa_messages`, `operators`, `operator_flows`, `operator_field_definitions`, `escalations`, `supervisor_channel_access`, `telegram_linking_tokens`, `flow_definitions`, `flow_executions`, `flow_field_values`, `flow_integrations`, `webhook_outbox`, `dashboard_definitions`, `dashboard_widgets`, `dashboard_action_logs`.

---

## 3. Esquema actual (tablas principales)

> ⚠️ **Verificado contra `information_schema` el 2026-04-26.** Columnas marcadas con `[PROD-DIFF]` difieren del schema documentado anteriormente.

### `tenants`
- **Propósito:** Organización cliente de Conectamos.
- **Columnas reales en prod:** `id uuid PK`, `slug text UNIQUE NOT NULL`, `display_name text NOT NULL`, `legal_name text`, `address text`, `logo_url text`, `status text DEFAULT 'active'`, `wa_phone_number_id text`, `wa_waba_id text`, `wa_token text`, `created_at timestamptz`, `rfc text`, `email_contacto text`, `telefono text`, `calle text`, `numero_exterior text`, `numero_interior text`, `colonia text`, `ciudad text`, `estado_cliente text`, `codigo_postal text`, `requiere_cfdi bool DEFAULT false`, `regimen_fiscal text`, `uso_cfdi text`, `welcome_template_id uuid`, `show_supervisor_name bool DEFAULT false`, `operator_export_config jsonb`.
- **Notas:** Las columnas `wa_*` son transitorias — migrarán a `channels` en migración 000002. `operator_export_config` define qué columnas aparecen en el export de operadores, configurable por admin. Migration `20260423000001`.

### `tenant_users`
- **Propósito:** Usuarios de la plataforma (panel web) por tenant.
- **Columnas reales en prod:** `id uuid PK`, `tenant_id uuid NOT NULL`, `user_id uuid` (auth.users, nullable), `role_id uuid NOT NULL`, `status text DEFAULT 'invited'`, `invited_by uuid`, `created_at timestamptz`, `nombre text`, `telefono text`.
- **Notas:** Tabla M:N entre `auth.users` y `tenants`. `nombre` y `telefono` se sincronizan con `auth.users.user_metadata` al aceptar invitación.

### `user_roles` [LEGACY]
- **Propósito:** Superadmin/admin global (diferente de `tenant_users`).
- **Columnas reales en prod:** `id uuid PK`, `user_id uuid`, `tenant_id uuid`, `role text`, `created_at timestamptz`.
- **Estado:** Sin uso en el código actual. Superseded por `tenant_users + roles`. Candidato a DROP.

### `roles`
- **Propósito:** Roles del sistema por tenant.
- **Columnas reales en prod:** `id uuid PK`, `tenant_id uuid`, `name text`, `description text`, `is_system bool DEFAULT false`, `created_at timestamptz`.
- **Notas:** 3 roles por tenant (`admin`, `supervisor`, `viewer`) creados por `_seed_system_roles()` en `POST /tenants`. Seed automático al crear tenant.

### `permissions`
- **Propósito:** Catálogo global de permisos.
- **Columnas reales en prod:** `id uuid PK`, `module text NOT NULL`, `action text NOT NULL`, `description text`.
- **Notas:** Formato de nombre: `module.action` (ej. `escalations.view`, `escalations.manage`). 13 permisos en seed inicial + 2 de escalaciones (migration 31) + 6 flows (migration 40) + 2 dashboards (migration 55).

### `role_permissions`
- **Propósito:** Join M:N entre roles y permisos.
- **Columnas reales en prod:** `role_id uuid`, `permission_id uuid`.
- **Notas:** Sin PK explícita — PK compuesta implícita.

### `invitations`
- **Propósito:** Tokens de invitación a usuarios de plataforma.
- **Columnas reales en prod:** `id uuid PK`, `tenant_id uuid`, `email text NOT NULL`, `role_id uuid NOT NULL`, `token uuid UNIQUE DEFAULT gen_random_uuid()`, `expires_at timestamptz DEFAULT now()+7d`, `accepted_at timestamptz`, `invited_by uuid`, `created_at timestamptz`, `nombre text`, `telefono text`.
- **Notas:** `accepted_at NULL` = pendiente.

### `operators`
- **Propósito:** Operadores de campo del tenant.
- **Columnas reales en prod:** `id uuid PK`, `name text NOT NULL` (**nota: `name`, no `nombre`**), `phone text NOT NULL`, `whatsapp_verified bool DEFAULT false`, `status text DEFAULT 'inactive'` (active/suspended/inactive/deleted — CHECK), `last_event_at timestamptz`, `created_at timestamptz`, `tenant_id uuid`, `_deprecated_ai_worker_id uuid`, `_deprecated_ai_enabled bool DEFAULT false`, `metadata jsonb NOT NULL DEFAULT '{}'`, `email text`, `profile_picture_url text`, `nationality text`, `identity_type text`, `identity_number text`, `created_by uuid`, `updated_at timestamptz`, `updated_by uuid`, `preferred_channel_types text[] NOT NULL DEFAULT '{}'`.
- **Unicidad:** `(tenant_id, phone)` — no global. Partial unique index `operators_identity_unique` sobre `(tenant_id, identity_type, identity_number)` cuando ambos no son NULL.
- **`preferred_channel_types`:** lista ordenada de tipos de canal preferidos (ej. `['telegram', 'whatsapp']`). Migration 51.
- **Notas:** `metadata` almacena: `telegram_chat_id` (string), `telegram_link_status` (none/pending/linked), `telegram_link_expires_at`, `phone_secondary[]`, y valores de `operator_field_definitions`. Claves reservadas: ver ADR-135. Columna legacy `flows` (array) eliminada via migration `20260422000000`.

### `_deprecated_operator_channels` [RENOMBRADA — EN DEPRECACIÓN]
- **Columnas reales en prod:** `id uuid PK`, `operator_id uuid NOT NULL`, `channel_id uuid NOT NULL`, `tenant_id uuid NOT NULL`, `granted_at timestamptz DEFAULT now()`, `granted_by uuid`.
- **Estado:** RENAME de `operator_channels` (migration `20260418000001`). DROP diferido.

### `operator_flows` [CANONICAL]
- **Propósito:** Fuente de verdad de asignación operador ↔ flujo.
- **Columnas reales en prod:** `id uuid PK`, `tenant_id uuid`, `operator_id uuid`, `flow_definition_id uuid`, `assigned_at timestamptz DEFAULT now()`, `assigned_by_user_id uuid`, `is_active bool DEFAULT true`.
- **Unicidad:** `UNIQUE(tenant_id, operator_id, flow_definition_id)` — migration `20260505000001` (ADR-200). <!-- ACTUALIZADO: constraint actualizado a 3 columnas con tenant_id -->
- **Notas:** RLS habilitado. Migration `20260418000001_operator_flows_and_fields.sql`.

### `operator_field_definitions`
- **Propósito:** Campos configurables por tenant para la ficha del operador.
- **Columnas reales en prod:** `id uuid PK`, `tenant_id uuid`, `field_key text NOT NULL`, `label text NOT NULL`, `field_type text NOT NULL`, `required bool DEFAULT false`, `display_order int DEFAULT 0`, `options jsonb`, `is_active bool DEFAULT true`, `created_at timestamptz`.
- **Unicidad:** `UNIQUE(tenant_id, field_key)`.
- **Notas:** DELETE es soft delete (`is_active=false`). CRUD completo en `app/routers/operator_fields.py`. Tipos válidos: `text|number|date|boolean|select|photo|document`.

### `channels`
- **Propósito:** Conexión entre un tenant_worker y un canal de mensajería (WhatsApp, Telegram, SMS).
- **Columnas reales en prod:** `id uuid PK`, `tenant_id uuid NOT NULL`, `channel_type text DEFAULT 'whatsapp'`, `display_name text NOT NULL`, `color text`, `channel_config jsonb NOT NULL DEFAULT '{}'`, `is_active bool DEFAULT true`, `created_at timestamptz`, `updated_at timestamptz`, `tenant_worker_id uuid`, `signup_source varchar(20) DEFAULT 'manual'`.
- **`signup_source` valores:** `'manual'` | `'embedded_signup'`. Migration `20260421000003`.
- **`channel_config` estructura WhatsApp:** `{channel_type, credentials{phone_number_id, waba_id, access_token}, capabilities[]}`.
- **`channel_config` estructura Telegram:** `{channel_type, credentials{bot_token, bot_username}, capabilities[]}`.
- **Índice:** `channels_unique_active_type_per_worker` — UNIQUE `(tenant_worker_id, channel_type) WHERE is_active = true`. Migration 51.
- **Notas:** Credenciales viven exclusivamente en `channel_config.credentials`. Tokens enmascarados en GET (`_mask_channel_token()`). Nunca devueltos en claro.

### `ai_worker_catalog`
- **Propósito:** Catálogo global de Workers gestionado por Conectamos.
- **Columnas reales en prod:** `id uuid PK`, `name text NOT NULL`, `description text`, `worker_type text NOT NULL`, `webhook_url text` (obligatoria en runtime — si null, HTTP 503), `color text`, `icon_url text`, `skills text[] DEFAULT '{}'`, `is_published bool DEFAULT false`, `is_active bool DEFAULT true`, `sort_order int DEFAULT 0`, `created_at timestamptz`, `updated_at timestamptz`, `auth_config JSONB` (nullable; migration 49; ADR-191).
- **Nota:** `visible_to_all` y `worker_catalog_tenant_visibility` **no existen en prod** (ADR-100). El código no depende de ellas.

### `worker_catalog_tenant_visibility` [NO EXISTE EN PROD]
- **Estado:** Documentada en migration `20260420000003` pero **confirmado que no existe en prod**. No crear ni referenciar.

### `tenant_workers`
- **Propósito:** Contratación de Workers del catálogo por un tenant.
- **Columnas reales en prod:** `id uuid PK`, `tenant_id uuid NOT NULL`, `catalog_worker_id uuid NOT NULL`, `display_name text`, `is_active bool DEFAULT true`, `contracted_at timestamptz DEFAULT now()`, `contracted_by uuid`, `metadata jsonb DEFAULT '{}'`.
- **Unicidad:** `UNIQUE(tenant_id, catalog_worker_id)`.

### `ai_workers` [EN DEPRECACIÓN]
- **Columnas reales en prod:** `id uuid PK`, `tenant_id uuid NOT NULL`, `name text NOT NULL`, `routing_key text NOT NULL`, `is_active bool DEFAULT true`, `metadata jsonb DEFAULT '{}'`, `created_at timestamptz`, `worker_type text DEFAULT 'custom'`, `webhook_url text`, `color text`.
- **Estado:** Siendo reemplazada gradualmente por `ai_worker_catalog + tenant_workers`. Mantener por ahora.

### `flow_definitions`
- **Propósito:** Plantilla de flujo configurable por tenant sobre un `tenant_worker`.
- **Columnas reales en prod:** `id uuid PK`, `tenant_id uuid NOT NULL`, `name text NOT NULL`, `slug text UNIQUE` (generado con `_slugify(name)` al crear — read-only), `description text`, `fields jsonb NOT NULL DEFAULT '[]'`, `behavior jsonb NOT NULL DEFAULT '{}'`, `on_complete jsonb`, `trigger_sources text[] DEFAULT '{}'`, `send_proactive boolean NOT NULL DEFAULT true` (migration 50, ADR-183), `is_active bool DEFAULT true`, `sort_order int DEFAULT 0`, `created_at timestamptz`, `updated_at timestamptz`, `tenant_worker_id uuid`, `prerequisite_flow_slug text DEFAULT NULL` (migration `20260505000001`). <!-- ACTUALIZADO: prerequisite_flow_slug añadida -->
- **Unicidad:** `UNIQUE(tenant_id, tenant_worker_id, name)`.

### `flow_executions`
- **Propósito:** Instancia activa de un `flow_definition` para un operador específico.
- **Columnas post-Fase C (migrations 34+46):** `id uuid PK`, `tenant_id uuid NOT NULL`, `flow_definition_id uuid NOT NULL`, `operator_id uuid` (nullable), `channel_id uuid` (nullable), `status text DEFAULT 'active'` (active/paused/completed/abandoned/escalated/pending_completion/pending_dashboard/pending_input/created — CHECK actualizado), `completed_at timestamptz`, `created_at timestamptz`, `updated_at timestamptz`, `active_channel_id uuid FK→channels`, `actor_type text NOT NULL CHECK IN ('operator','system','tenant_user')`, `flow_definition_snapshot jsonb NOT NULL`, `idempotency_key text`, `parent_execution_id uuid FK→flow_executions`, `trigger_message_id uuid`.
- **Status `created`:** status intermedio para executions pre-creadas por `on_complete` (open_flow) que esperan `checkpoint_started` para promover a `active`. Migration `20260505200000`. <!-- ACTUALIZADO: status 'created' añadido -->
- **Columnas dropeadas en Fase C (migration 46):** `fields_status`, `attempts`, `escalated_at`, `escalated_to`.
- **Índice:** `idx_flow_executions_unique_active_idempotency` — UNIQUE `(operator_id, flow_definition_id, idempotency_key)` WHERE `status='active' AND idempotency_key IS NOT NULL`.
- **Bug resuelto (ID-002):** Guard en `checkpoint_started` — SELECT antes del INSERT. `already_existed: true` en response.

### `flow_field_values`
- **Propósito:** Valores capturados por el AI Worker para cada campo de un `flow_execution`.
- **Columnas reales en prod:** `id uuid PK`, `execution_id uuid NOT NULL FK→flow_executions`, `tenant_id uuid NOT NULL`, `field_key text NOT NULL`, `value_text text`, `value_numeric numeric`, `value_jsonb jsonb`, `value_media_url text`, `captured_at timestamptz DEFAULT now()`, `wa_message_id uuid`, `source VARCHAR DEFAULT 'captured'`, `captured_by uuid FK→operators` (nullable).
- **Notas:** UPSERT desde `_save_field_values()`. Schema estricto (ADR-174): para `source="captured"`, solo field_keys declarados en `flow_definition.fields` se persisten; inválidos se descartan con `logger.warning`. Excepción: `_notas` siempre válido (ADR-173).

### `flow_execution_events` (nombre real en prod)
- **⚠️ CORRECCIÓN CRÍTICA:** La tabla se llama **`flow_execution_events`** en prod (no `flow_events`). La columna de tipo es `event_type` (no `event_id`).
- **Columnas reales en prod:** `id uuid PK`, `execution_id uuid FK→flow_executions` (nullable), `event_type text`, `operator_id uuid`, `flow_definition_id uuid`, `tenant_id uuid`, `data jsonb DEFAULT '{}'`, `created_at timestamptz`.
- **Tipos definidos:** `flujo_iniciado | campo_capturado | campo_rechazado | supervisor_intervino | flujo_pausado | flujo_retomado | worker_escaló | ticket_asignado | ticket_resuelto | ticket_reabierto | flujo_completado | flujo_abandonado`.

### `escalations`
- **Propósito:** Tickets de escalación generados cuando el AI Worker no puede completar un flujo.
- **Columnas reales en prod:** `id uuid PK`, `tenant_id uuid NOT NULL`, `flow_execution_id uuid NOT NULL FK→flow_executions`, `operator_id uuid NOT NULL FK→operators`, `reason text NOT NULL`, `trigger_messages jsonb NOT NULL DEFAULT '[]'`, `status text DEFAULT 'open'` (open/assigned/resolved/reopened — CHECK), `opened_at timestamptz DEFAULT now()`, `assigned_to uuid FK→tenant_users`, `assigned_at timestamptz`, `resolved_at timestamptz`, `resolved_by uuid`, `resolution_notes text`, `worker_can_resume bool DEFAULT false`, `resumed_at timestamptz`, `created_at timestamptz`, `updated_at timestamptz` (trigger automático).
- **Nota:** La columna `channel_id` mencionada en documentación anterior **no existe en prod**.
- **Notas:** RLS habilitada. 7 índices incluyendo compuesto `(tenant_id, status)`. Permisos: `escalations.view` y `escalations.manage`. Migration `20260424000001`. ADR-143.

### `flow_integrations` [ADR-189 — nivel tenant]
- **Propósito:** Integraciones externas a nivel tenant.
- **Columnas reales en prod:** `id uuid PK`, `tenant_id uuid NOT NULL`, `tenant_worker_id uuid FK→tenant_workers`, `_deprecated_flow_definition_id uuid` (nullable — renombrada en migration 48), `integration_type` (inbound/outbound), `name TEXT NOT NULL`, `endpoint_url`, `api_key_hash`, `api_key_prefix TEXT`, `hmac_secret_encrypted`, `rate_limit_per_minute`, `is_active`, `created_at`.
- **CRUD activo (tenant-level):** `GET /integrations`, `POST /integrations`, `DELETE /integrations/{id}`. Endpoints legacy `/flows/{id}/integrations` → HTTP 410.

### `flow_actions_log` [Flows v2 Fase A]
- **Propósito:** Log de acciones declarativas ejecutadas por el backend en respuesta al Worker.
- **Columnas clave:** `id uuid PK`, `flow_execution_id`, `action_type NOT NULL`, `action_config JSONB NOT NULL`, `attempt_count INT NOT NULL`, `tenant_id NOT NULL`, `action_index INT`. UNIQUE `(flow_execution_id, action_index)`.
- **Notas:** Migration `20260428000005`.

### `webhook_outbox` [Flows v2 Fase A]
- **Propósito:** Outbox de webhooks salientes para entrega at-least-once.
- **Notas:** RLS con policy `deny_all` para usuarios — solo `service_role`. Procesado por cron `process_outbox`. Migration `20260428000006`.

### `dashboard_definitions` [NUEVA — 2026-05-03]
- **Propósito:** Define los dashboards configurables por tenant.
- **Columnas clave:** `id uuid PK`, `tenant_id uuid NOT NULL`, `name text`, `slug text`, `is_default bool`, `layout jsonb`, `created_at timestamptz`.
- **Unicidad:** `UNIQUE(tenant_id, slug)`.
- **Notas:** Trigger `enforce_single_default_dashboard`. RLS tenant_isolation. Migration `20260503000001`.

### `dashboard_widgets` [NUEVA — 2026-05-03]
- **Propósito:** Define los widgets de un dashboard.
- **Columnas clave:** `id uuid PK`, `dashboard_id uuid FK→dashboard_definitions`, `tenant_id uuid`, `widget_type text` (CHECK: `kpi_card|bar_chart|operator_ranking|recent_activity_feed|execution_table|flow_action_button|operator_status_grid`), `title text`, `config jsonb`, `position int`.
- **Notas:** `config.layout_hint` controla agrupación: `kpi_row` o `chart_row`. Migration `20260503000001`.

### `dashboard_action_logs` [NUEVA — 2026-05-03]
- **Propósito:** Log de acciones disparadas desde botones de dashboard.
- **Notas:** Migration `20260503000001`.

### `saved_views` [NUEVA — 2026-05-04] <!-- ACTUALIZADO: tabla nueva -->
- **Propósito:** Vistas guardadas por usuario para pantalla de Ejecuciones.
- **Columnas clave:** `id uuid PK`, `tenant_id uuid NOT NULL FK→tenants CASCADE`, `created_by uuid NOT NULL`, `name text NOT NULL`, `is_starred bool DEFAULT false`, `filters jsonb DEFAULT '{}'`, `search text DEFAULT ''`, `sort_col text DEFAULT 'created_at'`, `sort_dir text DEFAULT 'desc' CHECK (sort_dir IN ('asc', 'desc'))`, `columns_config jsonb DEFAULT '[]'`, `grouping text DEFAULT 'date'`, `created_at timestamptz`, `updated_at timestamptz`.
- **Índice:** `idx_saved_views_tenant_user ON saved_views(tenant_id, created_by)`.
- **Notas:** Migration `20260504000001`.

### `supervisor_channel_access`
- **Propósito:** Controla qué canales puede ver cada `tenant_user` con rol supervisor o viewer.
- **Estado:** Migration `20260420000004` — aplicada manualmente 2026-04-26. RLS + 3 policies; índices por `tenant_user_id`, `channel_id`, `tenant_id`.

### `telegram_linking_tokens`
- **Propósito:** Tokens UUID de un solo uso para vincular operador con `telegram_chat_id`.
- **Columnas reales en prod:** `id uuid PK`, `token uuid UNIQUE DEFAULT gen_random_uuid()`, `operator_id uuid NOT NULL FK→operators CASCADE`, `channel_id uuid NOT NULL FK→channels CASCADE`, `tenant_id uuid NOT NULL FK→tenants CASCADE`, `expires_at timestamptz NOT NULL`, `used_at timestamptz`, `created_at timestamptz DEFAULT now()`.
- **Notas:** RLS habilitado. Migration `20260421000002`.

### `sessions`
- **Columnas reales en prod:** `id uuid PK`, `operator_id uuid`, `operator_phone text`, `operator_name text`, `status text DEFAULT 'open'`, `started_at timestamptz`, `closed_at timestamptz`, `checklist_completed bool DEFAULT false`, `created_at timestamptz`, `tenant_id uuid NOT NULL`.
- **Estado:** Tabla con integración parcial. `sessions.status` CHECK solo permite `'open'|'closed'`.

### `wa_messages`
- **Propósito:** Mensajes WhatsApp y Telegram (inbound y outbound).
- **Columnas reales en prod:** `id uuid PK`, `chat_id text`, `wa_message_id text`, `from_phone text`, `from_name text`, `message_type text`, `raw_body text`, `raw_payload jsonb DEFAULT '{}'`, `is_processed bool DEFAULT false`, `processed_at timestamptz`, `parse_error text`, `received_at timestamptz DEFAULT now()`, `chat_name text`, `operator_id uuid`, `session_id uuid`, `flow_number int`, `direction text DEFAULT 'inbound'`, `wa_status text DEFAULT 'pending'`, `status_updated_at timestamptz`, `error_code text`, `error_message text`, `unregistered bool DEFAULT false`, `tenant_id uuid`, `media_url text`, `media_type text`, `sent_by_user_id uuid`, `origin text DEFAULT 'human'` (human/ai_worker/broadcast), `ai_worker_id uuid`, `routing_request_id text`, `channel_id uuid`, `context_message_id text`, `context_from text`, `reaction_emoji text`, `reaction_message_id text`, `_deprecated_reply_to_message_id uuid`, `reactions jsonb DEFAULT '{}'`, `panel_read_at timestamptz`, `panel_read_by uuid FK→auth.users`, `broadcast_id uuid FK→broadcasts`.
- **Nota:** La columna `to_phone` mencionada en documentación anterior **no existe en prod**.
- **Realtime:** publicado en `supabase_realtime`.

### `wa_templates`
- **Propósito:** Plantillas Meta sincronizadas a Supabase.
- **Columnas reales en prod:** `id uuid PK`, `tenant_id uuid NOT NULL`, `meta_template_id text`, `name text NOT NULL`, `category text NOT NULL`, `language text DEFAULT 'es'`, `body_text text NOT NULL`, `variables jsonb DEFAULT '[]'`, `status text DEFAULT 'PENDING'`, `rejection_reason text`, `is_welcome bool DEFAULT false`, `created_at timestamptz`, `updated_at timestamptz`, `waba_id text`, `header_type TEXT`, `header_text TEXT`, `footer_text TEXT`, `buttons JSONB`. <!-- ACTUALIZADO: columnas header/footer/buttons añadidas via migration 54 -->
- **Unicidad:** `UNIQUE(tenant_id, name)`.

### `broadcasts`
- **Propósito:** Envíos masivos.
- **Columnas reales en prod:** `id uuid PK`, `tenant_id uuid NOT NULL`, `sent_by_user_id uuid`, `message_text text`, `template_id uuid`, `template_variables jsonb DEFAULT '[]'`, `segment_filters jsonb DEFAULT '{}'`, `recipient_count int DEFAULT 0`, `sent_count int DEFAULT 0`, `failed_count int DEFAULT 0`, `status text DEFAULT 'pending'`, `created_at timestamptz`, `completed_at timestamptz`.
- **Nota:** La columna `channel_id` no existe en esta tabla (se pasa en HTTP request pero no se persiste).

### `broadcast_recipients`
- **Columnas reales en prod:** `id uuid PK`, `broadcast_id uuid NOT NULL`, `operator_id uuid`, `phone text NOT NULL`, `wa_message_id text`, `status text DEFAULT 'pending'` (pending/sent/delivered/read/failed), `error_message text`, `sent_at timestamptz`.

### `user_read_receipts`
- **Columnas reales en prod:** `id uuid PK`, `user_id uuid NOT NULL`, `tenant_id uuid NOT NULL`, `chat_id text NOT NULL`, `last_read_at timestamptz NOT NULL`.

---

## 4. Migrations aplicadas (historial cronológico) <!-- ACTUALIZADO: migrations 57–64 añadidas; estado de aplicación reconciliado -->

> Ubicación: `conectamos_meta_api/supabase/migrations/`. Aplicación manual vía Supabase SQL Editor.

| # | Migration | Descripción | Estado |
|---|---|---|---|
| 1 | `20260407120000_initial.sql` | `wa_messages` inicial | Aplicada |
| 2 | `20260408000000_operators_sessions.sql` | `operators`, `sessions`, `flow_events`; columnas `operator_id`, `session_id`, `flow_number`, `direction` en `wa_messages` | Aplicada |
| 3 | `20260409000000_outbound_messages.sql` | `wa_status`, `status_updated_at`, `error_code`, `error_message` en `wa_messages` | Aplicada |
| 4 | `20260413000000_unregistered_column.sql` | `unregistered BOOLEAN` en `wa_messages` | Aplicada |
| 5 | `20260413100000_multitenancy.sql` | `tenants` (con todas las columnas WA/fiscales), `user_roles` (legacy) | Aplicada |
| 6 | `20260414000000_iam.sql` | `permissions`, `roles`, `role_permissions`, `tenant_users`, `invitations`; seed de 13 permisos, 3 roles sistema, 52 role_permissions | Aplicada |
| 7 | `20260415090000_ai_workers.sql` | `ai_workers` tabla | Aplicada |
| 8 | `20260415160310_remote_schema.sql` | `nombre`, `telefono` en `tenant_users` e `invitations` | Aplicada |
| 9 | `20260415200000_channels_tenant_worker.sql` | Índice sobre `channels.tenant_worker_id` | Aplicada |
| 10 | `20260415210000_flow_definitions_fix.sql` | UNIQUE restaurado + 3 índices de soporte en `flow_definitions` | Aplicada |
| 11 | `20260416000000_channels_and_flows.sql` | `channels`, `operator_channels`, `flow_definitions`, `flow_executions`, `flow_field_values`; `operators.ai_worker_id → _deprecated_*`; `worker_type`, `webhook_url`, `color` en `ai_workers`; `channel_id` en `wa_messages` | Aplicada |
| 12 | `20260416000001_update_code_references.md` | Archivo markdown de referencia — no SQL | N/A |
| 13 | `20260416000002_migrate_tenant_credentials.sql` | Placeholder para DROP de columnas WA legacy en `tenants` — **DIFERIDA** (ADR-045) | Pendiente |
| 14 | `20260416000003_worker_catalog.sql` | `ai_worker_catalog`, `tenant_workers`; `channels.tenant_worker_id`; `flow_definitions.tenant_worker_id`; seed de 3 Workers | Aplicada |
| 15 | `20260417000001_channel_config_restructure.sql` | Reestructura `channel_config` JSONB en `channels`; constraint CHECK validando estructura | Aplicada |
| 16 | `20260418000001_operator_flows_and_fields.sql` | Crear `operator_flows`, `operator_field_definitions`; ADD `operators.metadata JSONB`; RENAME `operator_channels` → `_deprecated_operator_channels` | Aplicada |
| 17 | `20260420000001_drop_channel_credential_columns.sql` | DROP `channels.phone_number_id` y `channels.waba_id`; índice GIN sobre `channel_config` | Aplicada |
| 18 | `20260420000002_drop_channel_wa_token.sql` | DROP `channels.wa_token` | Aplicada |
| 19 | `20260420000003_worker_catalog_updates.sql` | **[NO APLICADA O REVERTIDA]** Intentó ADD `visible_to_all`, CREATE `worker_catalog_tenant_visibility`. Ambas confirmadas como inexistentes en prod (ADR-100) | No aplicada |
| 20 | `20260420000004_supervisor_channel_access.sql` | CREATE `supervisor_channel_access`; RLS + 3 policies; índices. **Aplicada manualmente 2026-04-26** | Aplicada |
| 21 | `20260420000005_backfill_wa_messages_channel_id.sql` | Backfill de 252 mensajes con `channel_id=NULL` al canal activo del tenant `conectamos-demo` | Aplicada |
| 22 | `20260420000006_formalize_missing_migrations.sql` | Formalización idempotente de `user_read_receipts`, `wa_templates`, `broadcasts`, `broadcast_recipients`, RLS `wa_messages`, RLS `operators`, realtime `wa_messages` | Aplicada |
| 23 | `20260421000001_add_skills_to_worker_catalog.sql` | UPDATE Worker logística → paquetería; INSERT Worker transporte con `skills text[]` | Aplicada |
| 24 | `20260421000002_telegram_linking_tokens.sql` | CREATE `telegram_linking_tokens`; FK a operators, channels, tenants con CASCADE; RLS | Aplicada |
| 25 | `20260421000003_add_signup_source_to_channels.sql` | ADD COLUMN `signup_source VARCHAR(20) NOT NULL DEFAULT 'manual'` en `channels` | Aplicada |
| 26 | `20260422000000_drop_operators_flows_legacy.sql` | DROP COLUMN `operators.flows` (array legacy) | Aplicada |
| 27 | `20260422000001_add_reply_to_telegram.sql` | ADD COLUMN `reply_to_message_id uuid FK` a `wa_messages`. Deprecada en la misma sesión | Aplicada |
| 28 | `20260422000002_add_reactions_to_wa_messages.sql` | ADD COLUMN `reactions jsonb NOT NULL DEFAULT '{}'` a `wa_messages`. Columna huérfana — candidata a DROP | Aplicada |
| 29 | `20260422120000_operators_sprint_fields.sql` | ADD COLUMNS `email`, `profile_picture_url`, `nationality`, `identity_type`, `identity_number`, `created_by`, `updated_at`, `updated_by` a `operators`. Partial unique index `operators_identity_unique`. Trigger `updated_at` | Aplicada |
| 30 | `20260423000000_operators_status_add_deleted.sql` | Amplía CHECK de `operators.status` para incluir `'deleted'` | Aplicada |
| 31 | `20260423000001_deprecate_reply_to_message_id.sql` | RENAME `reply_to_message_id` → `_deprecated_reply_to_message_id` | Aplicada |
| 32 | `20260423000001_operator_export_config.sql` | ADD COLUMN `operator_export_config jsonb` a `tenants`. **Nota:** colisión de timestamp con migration 31 — deuda técnica | Aplicada |
| 32b | `20260423000002_panel_read_wa_messages.sql` | ADD COLUMNS `panel_read_at TIMESTAMPTZ`, `panel_read_by UUID FK→auth.users` a `wa_messages`. Índice parcial `idx_wa_messages_panel_read` | Aplicada |
| 33 | `20260424000001_escalations.sql` | CREATE `escalations`; ADD `flow_executions.active_channel_id` UUID FK; CHECK de `status` extendido con `'paused'`; 7 índices; trigger `updated_at`; RLS | Aplicada |
| 34 | `20260424000002_escalations_permissions.sql` | INSERT `escalations.view` y `escalations.manage` en `permissions` | Aplicada |
| 35 | `20260425000001_wa_messages_broadcast_id.sql` | ADD COLUMN `broadcast_id uuid REFERENCES broadcasts(id)` nullable a `wa_messages`. Índice parcial | Aplicada |
| 36 | `20260427000001_flows_v2_add_missing_columns.sql` | ADD `flow_execution_events.execution_id uuid FK` nullable + índice parcial. ADD `flow_field_values.captured_by uuid FK→operators` nullable | Aplicada (sandbox + prod) |
| 37 | `20260427000002_add_pending_completion_status.sql` | ADD `pending_completion` al CHECK de `flow_executions.status` | Aplicada (sandbox + prod) |
| 38 | `20260427000003_replace_unique_active_constraint.sql` | DROP `idx_flow_executions_unique_active` + CREATE `idx_flow_executions_unique_active_idempotency`. ADR-179 | Aplicada (sandbox + prod) |
| 39 | `20260427000004_enable_pgcrypto.sql` | CREATE EXTENSION IF NOT EXISTS pgcrypto. Idempotente. ADR-154 | Aplicada |
| 40 | `20260428000001_flows_v2_expand_definitions.sql` | ADD `slug`, backfill con deduplicación por CTE, UNIQUE INDEX | Aplicada (sandbox). Prod pendiente (ID-077) |
| 41 | `20260428000002_flows_v2_expand_executions.sql` | ADD `actor_type`, `flow_definition_snapshot`, `idempotency_key`, `parent_execution_id`. `in_progress` → `active`. `operator_id` y `channel_id` nullable | Aplicada (sandbox). Prod pendiente |
| 42 | `20260428000003_flows_v2_expand_field_values.sql` | ADD `source NOT NULL DEFAULT 'captured'` | Aplicada (sandbox). Prod pendiente |
| 43 | `20260428000004_flows_v2_create_integrations.sql` | CREATE `flow_integrations`. RLS. Permisos `view` y `manage` | Aplicada (sandbox). Prod pendiente |
| 44 | `20260428000005_flows_v2_create_actions_log.sql` | CREATE `flow_actions_log`. UNIQUE `(flow_execution_id, action_index)` | Aplicada (sandbox). Prod pendiente |
| 45 | `20260428000006_flows_v2_create_webhook_outbox.sql` | CREATE `webhook_outbox`. RLS `deny_all` para usuarios | Aplicada (sandbox). Prod pendiente |
| 46 | `20260428000007_flows_v2_rls_audit.sql` | Función `current_tenant_id()`. RLS tenant isolation en 6 tablas de flows | Aplicada (sandbox). Prod pendiente |
| 47 | `20260428000008_flows_v2_seed_permissions.sql` | 6 permisos nuevos de flows. Admin: 4. Supervisor: `execute_dashboard` y `view_all` | Aplicada (sandbox). Prod pendiente |
| 48 | `20260428000009_fix_mock_outbound_endpoint.sql` | UPDATE `endpoint_url` de `Mock Outbound` → `/_mock_webhook/receive`. Sin efecto útil (filas eliminadas) | Aplicada |
| 49 | `20260428000010_add_send_proactive_flow_definitions.sql` | ADD COLUMN `send_proactive boolean NOT NULL DEFAULT true` a `flow_definitions`. ADR-183 | Aplicada |
| 50 | `20260428000012_preferred_channel_types_and_channel_constraint.sql` | ADD COLUMN `preferred_channel_types text[] NOT NULL DEFAULT '{}'` a `operators`. CREATE UNIQUE INDEX `channels_unique_active_type_per_worker` | Aplicada |
| 51 | `20260429000001_create_flow_execution_events.sql` | CREATE tabla `flow_execution_events` (si no existe) con columnas base | Aplicada |
| 52 | `20260429000002_add_actor_ref_type_flow_executions.sql` | ADD columnas actor ref type relacionadas a `flow_executions` | Aplicada |
| 53 | `20260429000003_add_auth_config_to_ai_worker_catalog.sql` | ADD COLUMN `auth_config JSONB` a `ai_worker_catalog`. ADR-191 | Aplicada |
| 54 | `20260430000001_adr189_integrations_tenant_level.sql` | RENAME `flow_integrations.flow_definition_id` → `_deprecated_flow_definition_id`, DROP NOT NULL, índice en `tenant_worker_id`. ADR-189 | Aplicada manualmente en SQL Editor |
| 55 | `20260501000001_flow_execution_messages.sql` | ADD columnas para ligar mensajes a flow_executions | Aplicada |
| 56 | `20260503000001_create_dashboard_tables.sql` | CREATE `dashboard_definitions`, `dashboard_widgets`, `dashboard_action_logs`. RLS tenant_isolation. Trigger `enforce_single_default_dashboard`. Seed permisos `dashboards.view` y `dashboards.manage`. ADR-196 | Aplicada |
| 57 | `20260504000000_add_template_components_to_wa_templates.sql` | ADD COLUMN `header_type TEXT`, `header_text TEXT`, `footer_text TEXT`, `buttons JSONB` (nullable) a `wa_templates`. Cierra ID-062 | Aplicada <!-- ACTUALIZADO: migration aplicada, cierra ID-062 --> |
| 58 | `20260504000001_create_saved_views.sql` | CREATE `saved_views` con columnas `filters`, `search`, `sort_col`, `sort_dir`, `columns_config`, `grouping`, `is_starred`. Índice `idx_saved_views_tenant_user` | Aplicada <!-- ACTUALIZADO: tabla nueva saved_views --> |
| 59 | `20260505000001_operator_flows_unique_tenant.sql` | DROP CONSTRAINT `operator_flows_unique` + CREATE `operator_flows_unique_tenant (tenant_id, operator_id, flow_definition_id)`. ADR-200 | Aplicada en prod <!-- ACTUALIZADO: constraint multi-tenant en operator_flows --> |
| 60 | `20260505000001_prerequisite_flow_slug.sql` | ADD COLUMN `prerequisite_flow_slug text DEFAULT NULL` a `flow_definitions` | Aplicada <!-- ACTUALIZADO: columna prerequisite_flow_slug --> |
| 61 | `20260505200000_add_created_status_to_flow_executions.sql` | DROP + ADD CONSTRAINT `flow_executions_status_check` ampliado con status `'created'`. ADR-196 | Aplicada <!-- ACTUALIZADO: status 'created' para on_complete open_flow --> |
| 62 | `20260615000001_flows_v2_contract_executions.sql` | Backfill `actor_type` (NULLs → 'operator'/'system') + `flow_definition_snapshot` (NULLs → snapshot actual). SET NOT NULL en ambas. CHECK `actor_type IN (...)`. Fase C | Aplicada |
| 63 | `20260615000002_flows_v2_drop_legacy.sql` | DROP `escalated_at`, `escalated_to` de `flow_executions`. (`fields_status` y `attempts` comentadas — código Python pendiente de limpiar antes de DROP). ADR-180. Fase C | Aplicada |
| 64 | `20260615000003_flows_v2_finalize_rls.sql` | `current_tenant_id()` CREATE OR REPLACE. Policies `tenant_isolation` en 6 tablas de flows. `service_role_only` en `webhook_outbox`. Fase C | Aplicada |

**Nota sobre numeración:** El documento original usaba numeración de 1 a 56 con algunos gaps y sub-índices (32b, etc.) por colisiones de timestamp. Esta tabla usa numeración secuencial actualizada para los archivos presentes en el repositorio.

**Nota sobre migrations 40–47 (sandbox vs prod):** Las migrations de Flows v2 Fase A (`20260428000001`–`20260428000008`) están aplicadas en sandbox (`conectamos-demo`) pero **pendientes de aplicar en producción** (`tmr-prixz`). ID-077.

---

## 5. Cambios aplicados sin archivo de migration formal

> **IMPORTANTE:** deuda técnica pendiente de formalizar. Si se recrea la BD, estos cambios se pierden.

- ALTER TABLE `wa_templates` ADD COLUMN `waba_id TEXT` + UPDATE manual de filas existentes con WABA correspondiente.
- ALTER TABLE `wa_messages` ADD `media_url`, `media_type`, `sent_by_user_id`, `from_name`, `origin`.
- UPDATE de `tenant_users.nombre` donde era NULL (2026-04-17) — ver ADR-069.
- Operación manual: mover usuario `0b208d48` de "Jomi Prueba" a `4ea0c9d8` (conectamos-demo).
- Operación manual: DELETE de tenants de prueba `jomi-prueba` a `jomi-prueba-7` con CASCADE.
- UPDATE manual de `channel_config: {}` a estructura válida previo a migration `20260417000001`.
- UPDATE manual: `phone` de Santiago Kohn corregido; `telegram_chat_id` de José Miguel Kohn corregido de int a string `"6224256977"`.
- Policies RLS INSERT y UPDATE en bucket `wa-media` de Supabase Storage para usuarios autenticados.
- UPDATE directo: `webhook_url` de Worker transporte en `ai_worker_catalog` → URL ngrok de Gustavo (temporal, ID-070).
- INSERT directo: 6 flujos en `flow_definitions` para Worker transporte en `conectamos-demo`. `CREAR_VIAJE` posiblemente duplicado (ID-069).
- UPDATE directo: 2 `flow_executions` de prueba marcadas como `abandoned`.
- INSERT directo: Worker Mock en `ai_worker_catalog` + `tenant_workers` vinculado a `conectamos-demo` (`tenant_worker_id = 02182d45`).
- INSERT directo: 4 flows de prueba en `flow_definitions` de `conectamos-demo`. Asignados a José Miguel Kohn via `operator_flows`.
- INSERT directo: 4 flows E2E en `flow_definitions` (test-branching, test-fanout, test-fanout-hijo, test-loop).
- INSERT directo: 2 integraciones en `flow_integrations` de `conectamos-demo` (después eliminadas).
- INSERT directo: flows `crear-orden` y `operar-orden` con `on_complete` configurado para chaining E2E.
- Vercel env vars: `CRON_SECRET`, `MOCK_WEBHOOK_SECRET`, `PGCRYPTO_KEY`. <!-- ACTUALIZADO: CRON_SECRET añadida -->
- UPDATE directo: `webhook_url` de Worker Marco en `ai_worker_catalog` → ngrok temporal (ID-096).
- INSERT de 7 `flow_definitions` desde la plataforma para el tenant demo (Sprint 2): crear-orden-integracion, asignar-operador, operar-orden-integracion, crear-orden-int2, recolectar-orden-conv, operar-orden-conv, crear-orden-conv.
- UPDATE `preferred_channel_types=['telegram','whatsapp']` en José Miguel Kohn.
- Data seed: Dashboard `jcr-ops-intelligence` con 9 widgets insertado en `conectamos-demo` via SQL directo.
- Permisos `dashboards.view` y `dashboards.manage` asignados a roles admin/supervisor de todos los tenants.

---

## 6. Migrations pendientes / en revisión

- **`20260416000002_migrate_tenant_credentials.sql`** (placeholder existente) — DROP `wa_phone_number_id`, `wa_waba_id`, `wa_token` de `tenants`. Diferida hasta ADR-045. Backend ya no depende de estas columnas.
- **Migrations 40–47 (Flows v2 Fase A)** — aplicadas en sandbox. **Pendientes en producción** (ID-077). Aplicar con 24h de estabilidad entre entornos.
- DROP de `_deprecated_operator_channels` — diferido hasta confirmar que ningún código la referencia.
- Formalizar correcciones manuales de `phone` y `telegram_chat_id` como scripts de datos versionados.
- Evaluar DROP de `user_roles` legacy.
- Evaluar DROP de `sessions` y `flow_events` (tablas creadas pero con escasa integración real).
- Confirmar estado real de migration `20260420000003` en prod — si no fue aplicada, marcar definitivamente como NO APLICADA.
- DROP de `reactions JSONB` en `wa_messages` — columna huérfana (candidata a DROP).
- DROP de `_deprecated_reply_to_message_id` en `wa_messages` — diferido hasta confirmar que ningún código la referencia.
- Resolver colisión de timestamp `20260423000001` (dos migrations con mismo timestamp).
- Implementar escritura de `created_by`/`updated_by` en backend al POST/PUT de operadores (ID-058).
- Verificar si `origin='broadcast'` requiere actualizar CHECK constraint `wa_messages_origin_check`.
- Limpiar duplicado de `CREAR_VIAJE` en `flow_definitions` del tenant `conectamos-demo` (ID-069).
- Crear migration formal para asignar permisos `escalations.view` y `escalations.manage` a roles en seeds de `POST /tenants` (ID-064).
- Limpiar filas históricas con `field_key` inválidos en `flow_field_values` de `conectamos-demo`.
- Backfill `parent_execution_id` en executions existentes — Step 11 de Fase B, pendiente.
- `_deprecated_flow_definition_id` en `flow_integrations` — programar DROP físico una vez confirmado que ningún código la referencia.
- Evaluar DROP de tabla `flow_events` original (si existe separada de `flow_execution_events`).
- Migrar `assigned_flows` y `active_flows` al envelope del Worker — actualmente no implementados (ID-097).
- Agregar `'supervisor'` al CHECK de `sessions.status` o documentar `sessions` como en desuso.
- Lógica de retry con `is_processed` — columnas existen, falta el proceso de reintento (ID-067).

---

## 7. Áreas sensibles — cambios prohibidos sin aprobación

- `tenants.wa_token`, `wa_phone_number_id`, `wa_waba_id` — columnas legacy en `tenants`. El código ya no las usa; pendiente DROP físico (migration 000002). No modificar hasta ejecutar la migration.
- `channels.channel_config.credentials.access_token` — credencial Meta activa. Nunca devolver en claro en API (usar `_mask_channel_token()`). Para cambiar credenciales de canal con historial: desactivar y crear canal nuevo (ver ADR-094).
- `tenants.rfc`, `regimen_fiscal`, `uso_cfdi`, `email_contacto` — datos fiscales con impacto legal/facturación.
- `wa_messages` — históricos operativos. No DELETE masivo; soft delete preferido.
- `invitations.token` — no regenerar tokens activos sin actualizar `expires_at`.

---

## 8. Historial de actualizaciones del documento

| Fecha | Quién | Qué se actualizó |
|---|---|---|
| 2026-04-17 | Miguel Kohn | Consolidación inicial desde 11 conversaciones. Schema completo registrado. |
| 2026-04-20 | Miguel Kohn | Schema actualizado: `channels` sin columnas top-level; 8 migrations nuevas (12–19); nuevas tablas `operator_flows`, `operator_field_definitions`, `supervisor_channel_access`, `worker_catalog_tenant_visibility`. |
| 2026-04-21 | Miguel Kohn | `channels` con `signup_source`; `ai_worker_catalog` corregido; nueva tabla `telegram_linking_tokens`; migrations 20–23. |
| 2026-04-24 | Miguel Kohn | `operators` con columnas nuevas (sprint 04-23); migrations 24–29. |
| 2026-04-26 | Miguel Kohn | Nueva tabla `escalations`; `flow_executions` con `active_channel_id`; `wa_messages` con `broadcast_id`; migrations 30–32. |
| 2026-04-26 | Claude (Cowork) | Verificación contra `information_schema` real de Supabase. Corregidos ~20 PROD-DIFF. |
| 2026-04-28 | Miguel Kohn | Fase A sandbox (migrations 33–40), Fase B/C prod (migrations 41–47). Tablas nuevas: flow_integrations, flow_actions_log, webhook_outbox. flow_executions post-Fase C. flow_field_values con schema estricto. |
| 2026-05-03 | Miguel Kohn | CORRECCIÓN CRÍTICA: flow_events → flow_execution_events. ADR-189 flow_integrations a nivel tenant. Columnas nuevas: auth_config, send_proactive, preferred_channel_types, slug. Migrations 48–53. |
| 2026-05-06 | Miguel Kohn | 3 tablas dashboard nuevas. wa_templates con columnas header/footer/buttons (migration 54). operator_flows constraint actualizado a tenant+operator+flow (migration 56). Migrations 54–56. |
| 2026-05-06 | Claude (Cowork) | Migrations 57–64 añadidas al historial cronológico: saved_views (58), operator_flows_unique_tenant (59), prerequisite_flow_slug (60), add_created_status (61). Tablas nuevas: saved_views documentada. flow_definitions con prerequisite_flow_slug. flow_executions con status 'created'. wa_templates con header/footer/buttons (confirmado aplicado). Numeración secuencial completa reconciliada con ls del directorio migrations. |
